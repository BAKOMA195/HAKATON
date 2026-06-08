from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database import get_db
from app.models import User, Prize, PrizeRedemption, BonusTransaction
from app.schemas import PrizeResponse, PrizeCreate, PrizeRedeem
from app.auth import get_current_user, require_role
from typing import List
from datetime import datetime

router = APIRouter(prefix="/api/marketplace", tags=["Каталог призов"])


@router.get("/prizes", response_model=List[PrizeResponse])
def get_prizes(
    category: str = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Получить список призов в каталоге.
    Можно фильтровать по категории.
    
    Категории из ТЗ:
    - financial: финансовые призы (скидки, бесплатное хранение)
    - partner: партнёрские сертификаты (WB, OZON, Яндекс)
    - merch: мерч СКС (футболки, кружки)
    - charity: благотворительность
    - exclusive: эксклюзивные призы
    """
    query = db.query(Prize).filter(Prize.is_active == True)
    
    if category:
        query = query.filter(Prize.category == category)
    
    return query.all()


@router.post("/prizes", response_model=PrizeResponse, status_code=status.HTTP_201_CREATED)
def create_prize(
    prize_data: PrizeCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role("admin"))
):
    """
    Добавить новый приз в каталог (только для админов).
    """
    new_prize = Prize(**prize_data.dict())
    db.add(new_prize)
    db.commit()
    db.refresh(new_prize)
    return new_prize


@router.post("/redeem")
def redeem_prize(
    redeem_data: PrizeRedeem,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Выкупить приз за бонусы.
    
    Логика из ТЗ:
    - Проверяем баланс пользователя
    - Списываем бонусы
    - Создаём запись о выкупе
    - Если приз ограниченный - уменьшаем количество
    
    На защите:
    "При выкупе приза мы используем транзакцию БД для обеспечения
    целостности данных. Бонусы списываются и приз фиксируется
    атомарно - либо всё успешно, либо ничего не меняется."
    """
    # Находим приз
    prize = db.query(Prize).filter(Prize.id == redeem_data.prize_id).first()
    if not prize:
        raise HTTPException(status_code=404, detail="Приз не найден")
    
    if not prize.is_active:
        raise HTTPException(status_code=400, detail="Приз недоступен")
    
    # Проверяем наличие на складе
    if prize.stock_quantity is not None and prize.stock_quantity <= 0:
        raise HTTPException(status_code=400, detail="Приз закончился")
    
    # Проверяем баланс
    if current_user.bonus_balance < prize.bonus_cost:
        remaining = prize.bonus_cost - current_user.bonus_balance
        raise HTTPException(
            status_code=400,
            detail=f"Недостаточно бонусов. До приза осталось {remaining} бонусов. Получи их за квесты!"
        )
    
    # Списываем бонусы
    current_user.bonus_balance -= prize.bonus_cost
    
    # Уменьшаем количество на складе
    if prize.stock_quantity is not None:
        prize.stock_quantity -= 1
    
    # Создаём запись о выкупе
    redemption = PrizeRedemption(
        user_id=current_user.id,
        prize_id=prize.id,
        status="pending"
    )
    db.add(redemption)
    
    # Записываем транзакцию списания
    transaction = BonusTransaction(
        user_id=current_user.id,
        amount=-prize.bonus_cost,
        source="marketplace",
        description=f"Выкуп приза: {prize.name}"
    )
    db.add(transaction)
    
    db.commit()
    
    return {
        "message": f"Приз '{prize.name}' успешно выкуплен!",
        "prize_name": prize.name,
        "bonus_spent": prize.bonus_cost,
        "new_balance": current_user.bonus_balance,
        "redemption_id": redemption.id
    }


@router.get("/my-redemptions")
def get_my_redemptions(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Получить историю выкупленных призов пользователя.
    """
    redemptions = db.query(PrizeRedemption).filter(
        PrizeRedemption.user_id == current_user.id
    ).order_by(PrizeRedemption.redeemed_at.desc()).all()
    
    result = []
    for r in redemptions:
        prize = db.query(Prize).filter(Prize.id == r.prize_id).first()
        result.append({
            "prize_name": prize.name if prize else "Неизвестный приз",
            "category": prize.category if prize else "unknown",
            "bonus_cost": prize.bonus_cost if prize else 0,
            "status": r.status,
            "redeemed_at": r.redeemed_at
        })
    
    return result
