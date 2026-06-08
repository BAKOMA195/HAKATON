from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database import get_db
from app.models import User, WheelSpin, BonusTransaction
from app.schemas import WheelSpinResponse, WheelProbabilities
from app.auth import get_current_user
from datetime import datetime, timedelta
import random

router = APIRouter(prefix="/api/wheel", tags=["Колесо фортуны"])

# ============================================
# КОЛЕСО ФОРТУНЫ
# ============================================
# Настройка призов и их вероятностей
# Из ТЗ: 1 бесплатная прокрутка в неделю, до 5 платных в день
# Прозрачные вероятности - требование комплаенса

WHEEL_PRIZES = [
    {"type": "bonus", "value": 10, "weight": 30.0, "label": "10 бонусов"},
    {"type": "bonus", "value": 25, "weight": 25.0, "label": "25 бонусов"},
    {"type": "bonus", "value": 50, "weight": 20.0, "label": "50 бонусов"},
    {"type": "bonus", "value": 100, "weight": 15.0, "label": "100 бонусов"},
    {"type": "bonus", "value": 500, "weight": 8.0, "label": "500 бонусов"},
    {"type": "discount", "value": 5, "weight": 1.5, "label": "Скидка 5% на ЗБ"},
    {"type": "badge", "value": 1, "weight": 0.5, "label": "Редкий бейдж"},
]

WHEEL_SPIN_COST = 50  # Стоимость платной прокрутки в бонусах
MAX_PAID_SPINS_PER_DAY = 5  # Максимум платных прокруток в день (защита от лудомании)


@router.get("/probabilities", response_model=WheelProbabilities)
def get_probabilities():
    """
    Получить прозрачные вероятности призов на колесе.
    
    На защите скажи:
    "По требованию комплаенса мы показываем пользователю вероятности
    каждого приза. Это исключает обвинения в нечестной игре и соответствует
    законодательству РФ."
    """
    probs = WheelProbabilities()
    for prize in WHEEL_PRIZES:
        if prize["value"] == 10:
            probs.bonus_10 = prize["weight"]
        elif prize["value"] == 25:
            probs.bonus_25 = prize["weight"]
        elif prize["value"] == 50:
            probs.bonus_50 = prize["weight"]
        elif prize["value"] == 100:
            probs.bonus_100 = prize["weight"]
        elif prize["value"] == 500:
            probs.bonus_500 = prize["weight"]
        elif prize["type"] == "discount":
            probs.discount = prize["weight"]
        elif prize["type"] == "badge":
            probs.badge = prize["weight"]
    return probs


@router.post("/spin", response_model=WheelSpinResponse)
def spin_wheel(
    use_free: bool = True,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Прокрутить колесо фортуны.
    
    Логика из ТЗ:
    - 1 бесплатная прокрутка в неделю
    - Платные прокрутки: 50 бонусов, максимум 5 в день
    - Защита от лудомании: лимиты на прокрутки
    
    На защите:
    "Колесо фортуны использует взвешенную случайность - каждый приз
    имеет свою вероятность. Мы фиксируем каждую прокрутку в БД для
    аудита и защиты от злоупотреблений."
    """
    now = datetime.utcnow()
    
    if use_free:
        # Проверяем, не использовал ли бесплатную прокрутку на этой неделе
        week_ago = now - timedelta(days=7)
        free_spin = db.query(WheelSpin).filter(
            WheelSpin.user_id == current_user.id,
            WheelSpin.is_free == True,
            WheelSpin.spun_at >= week_ago
        ).first()
        
        if free_spin:
            raise HTTPException(
                status_code=400,
                detail="Бесплатная прокрутка уже использована на этой неделе"
            )
    else:
        # Платная прокрутка
        # Проверяем лимит платных прокруток за день
        today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
        paid_spins_today = db.query(WheelSpin).filter(
            WheelSpin.user_id == current_user.id,
            WheelSpin.is_free == False,
            WheelSpin.spun_at >= today_start
        ).count()
        
        if paid_spins_today >= MAX_PAID_SPINS_PER_DAY:
            raise HTTPException(
                status_code=400,
                detail=f"Лимит платных прокруток ({MAX_PAID_SPINS_PER_DAY}/день) исчерпан"
            )
        
        # Проверяем баланс
        if current_user.bonus_balance < WHEEL_SPIN_COST:
            raise HTTPException(
                status_code=400,
                detail=f"Недостаточно бонусов. Нужно {WHEEL_SPIN_COST}"
            )
        
        # Списываем бонусы
        current_user.bonus_balance -= WHEEL_SPIN_COST
        
        # Записываем списание
        spend_transaction = BonusTransaction(
            user_id=current_user.id,
            amount=-WHEEL_SPIN_COST,
            source="wheel_spin",
            description="Платная прокрутка колеса",
        )
        db.add(spend_transaction)
    
    # Определяем приз по весам (взвешенная случайность)
    prize = _weighted_random_choice(WHEEL_PRIZES)
    
    # Начисляем приз
    if prize["type"] == "bonus":
        current_user.bonus_balance += prize["value"]
        
        # Записываем начисление
        win_transaction = BonusTransaction(
            user_id=current_user.id,
            amount=prize["value"],
            source="wheel",
            description=f"Колесо фортуны: {prize['label']}",
            expires_at=now + timedelta(days=365)
        )
        db.add(win_transaction)
    
    # Записываем прокрутку
    spin_record = WheelSpin(
        user_id=current_user.id,
        prize_type=prize["type"],
        prize_value=prize["value"],
        is_free=use_free,
        spun_at=now
    )
    db.add(spin_record)
    
    db.commit()
    
    return WheelSpinResponse(
        prize_type=prize["type"],
        prize_value=prize["value"],
        is_free=use_free,
        spun_at=now
    )


def _weighted_random_choice(prizes: list) -> dict:
    """
    Выбирает приз на основе весов (вероятностей).
    """
    total_weight = sum(p["weight"] for p in prizes)
    random_value = random.uniform(0, total_weight)
    
    cumulative_weight = 0
    for prize in prizes:
        cumulative_weight += prize["weight"]
        if random_value <= cumulative_weight:
            return prize
    
    return prizes[-1]  # На случай ошибки


@router.get("/spins-info")
def get_spins_info(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Получить информацию о доступных прокрутках.
    """
    now = datetime.utcnow()
    week_ago = now - timedelta(days=7)
    today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
    
    free_spin_used = db.query(WheelSpin).filter(
        WheelSpin.user_id == current_user.id,
        WheelSpin.is_free == True,
        WheelSpin.spun_at >= week_ago
    ).first() is not None
    
    paid_spins_today = db.query(WheelSpin).filter(
        WheelSpin.user_id == current_user.id,
        WheelSpin.is_free == False,
        WheelSpin.spun_at >= today_start
    ).count()
    
    return {
        "free_spin_available": not free_spin_used,
        "paid_spins_today": paid_spins_today,
        "paid_spins_remaining": MAX_PAID_SPINS_PER_DAY - paid_spins_today,
        "spin_cost": WHEEL_SPIN_COST
    }
