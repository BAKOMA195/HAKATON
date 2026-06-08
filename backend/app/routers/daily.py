from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database import get_db
from app.models import User, BonusTransaction
from app.schemas import DailyCheckinResponse
from app.auth import get_current_user
from datetime import datetime, date, timedelta

router = APIRouter(prefix="/api/daily", tags=["Ежедневный вход"])


@router.post("/checkin", response_model=DailyCheckinResponse)
def daily_checkin(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Ежедневный вход в приложение.
    Начисляет бонусы за вход и поддерживает серию (streak).
    
    Логика из ТЗ:
    - За каждый день входа: 5 бонусов
    - 7 дней подряд: +50 бонусов
    - 14 дней подряд: +150 бонусов
    - 30 дней подряд: +500 бонусов
    - Серия сбрасывается при пропуске дня
    
    На защите скажи:
    "Мы реализовали механику ежедневного входа с прогрессивной наградой.
    Система отслеживает серию дней и сбрасывает её при пропуске.
    Это формирует привычку ежедневного использования приложения."
    """
    today = date.today()
    
    # Проверяем, не заходил ли пользователь уже сегодня
    if current_user.last_checkin_date:
        last_checkin = current_user.last_checkin_date.date()
        if last_checkin == today:
            raise HTTPException(status_code=400, detail="Вы уже заходили сегодня!")
        
        # Проверяем, не пропущен ли день (серия сбрасывается)
        if last_checkin < today - timedelta(days=1):
            current_user.daily_streak = 0  # Сброс серии
    
    # Увеличиваем серию
    current_user.daily_streak += 1
    current_user.last_checkin_date = datetime.utcnow()
    
    # Базовая награда за вход
    base_bonus = 5
    streak_bonus = 0
    message = f"Ежедневный вход! +{base_bonus} бонусов"
    
    # Прогрессивные награды за серию
    if current_user.daily_streak == 7:
        streak_bonus = 50
        message = f"🔥 7 дней подряд! +{base_bonus} + {streak_bonus} бонусов"
    elif current_user.daily_streak == 14:
        streak_bonus = 150
        message = f"🔥🔥 14 дней подряд! +{base_bonus} + {streak_bonus} бонусов"
    elif current_user.daily_streak == 30:
        streak_bonus = 500
        message = f"🔥🔥🔥 30 дней! Легенда! +{base_bonus} + {streak_bonus} бонусов"
    
    total_bonus = base_bonus + streak_bonus
    
    # Начисляем бонусы
    current_user.bonus_balance += total_bonus
    
    # Записываем транзакцию
    transaction = BonusTransaction(
        user_id=current_user.id,
        amount=total_bonus,
        source="daily_checkin",
        description=f"Ежедневный вход (серия: {current_user.daily_streak} дней)",
        expires_at=datetime.utcnow() + timedelta(days=365)  # 12 месяцев
    )
    db.add(transaction)
    
    db.commit()
    
    return DailyCheckinResponse(
        bonus_earned=total_bonus,
        current_streak=current_user.daily_streak,
        streak_bonus=streak_bonus if streak_bonus > 0 else None,
        message=message
    )


@router.get("/streak")
def get_streak(
    current_user: User = Depends(get_current_user)
):
    """
    Получить информацию о текущей серии входов.
    """
    return {
        "streak": current_user.daily_streak,
        "last_checkin": current_user.last_checkin_date,
        "next_milestone": _get_next_milestone(current_user.daily_streak)
    }


def _get_next_milestone(current_streak: int) -> dict:
    """
    Определяет следующую награду за серию.
    """
    milestones = {
        0: {"days": 7, "bonus": 50, "message": "7 дней = 50 бонусов"},
        6: {"days": 7, "bonus": 50, "message": "7 дней = 50 бонусов"},
        7: {"days": 14, "bonus": 150, "message": "14 дней = 150 бонусов"},
        13: {"days": 14, "bonus": 150, "message": "14 дней = 150 бонусов"},
        14: {"days": 30, "bonus": 500, "message": "30 дней = 500 бонусов"},
        29: {"days": 30, "bonus": 500, "message": "30 дней = 500 бонусов"},
    }
    
    # Находим ближайший milestone
    for streak, info in sorted(milestones.items()):
        if current_streak < info["days"]:
            return {
                "days_left": info["days"] - current_streak,
                "bonus": info["bonus"],
                "message": info["message"]
            }
    
    return {"message": "Максимальная серия достигнута!"}
