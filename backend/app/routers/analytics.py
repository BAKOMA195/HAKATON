from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import func
from app.database import get_db
from app.models import User, BonusTransaction, UserQuest, WheelSpin, PrizeRedemption
from app.schemas import AnalyticsDashboard
from app.auth import require_role
from datetime import datetime, timedelta

router = APIRouter(prefix="/api/analytics", tags=["Аналитика"])


@router.get("/dashboard", response_model=AnalyticsDashboard)
def get_dashboard(
    db: Session = Depends(get_db),
    current_user = Depends(require_role("analyst"))
):
    """
    Дашборд аналитики для маркетингового аналитика.
    
    Метрики из ТЗ:
    - DAU/MAU (Daily/Monthly Active Users)
    - Показатель доходимости (завершения квестов)
    - Распределение наград
    - Конверсия каждой механики
    
    На защите:
    "Аналитический дашборд позволяет маркетологам отслеживать
    эффективность геймификации в реальном времени и принимать
    решения на основе данных."
    """
    now = datetime.utcnow()
    today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
    month_start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    week_ago = now - timedelta(days=7)
    
    # DAU - уникальные пользователи за сегодня
    dau = db.query(func.count(func.distinct(BonusTransaction.user_id))).filter(
        BonusTransaction.created_at >= today_start
    ).scalar() or 0
    
    # MAU - уникальные пользователи за месяц
    mau = db.query(func.count(func.distinct(BonusTransaction.user_id))).filter(
        BonusTransaction.created_at >= month_start
    ).scalar() or 0
    
    # DAU/MAU ratio
    dau_mau_ratio = (dau / mau * 100) if mau > 0 else 0
    
    # Всего квестов выполнено за месяц
    total_quests = db.query(func.count(UserQuest.id)).filter(
        UserQuest.completed_at >= month_start,
        UserQuest.is_completed == True
    ).scalar() or 0
    
    # Всего прокруток колеса за месяц
    total_spins = db.query(func.count(WheelSpin.id)).filter(
        WheelSpin.spun_at >= month_start
    ).scalar() or 0
    
    # Всего призов выкуплено за месяц
    total_redemptions = db.query(func.count(PrizeRedemption.id)).filter(
        PrizeRedemption.redeemed_at >= month_start
    ).scalar() or 0
    
    # Всего бонусов начислено
    total_issued = db.query(func.sum(BonusTransaction.amount)).filter(
        BonusTransaction.created_at >= month_start,
        BonusTransaction.amount > 0
    ).scalar() or 0
    
    # Всего бонусов потрачено
    total_spent = abs(db.query(func.sum(BonusTransaction.amount)).filter(
        BonusTransaction.created_at >= month_start,
        BonusTransaction.amount < 0
    ).scalar() or 0)
    
    # Средняя длина серии
    avg_streak = db.query(func.avg(User.daily_streak)).filter(
        User.is_active == True
    ).scalar() or 0
    
    return AnalyticsDashboard(
        dau=dau,
        mau=mau,
        dau_mau_ratio=round(dau_mau_ratio, 2),
        total_quests_completed=total_quests,
        total_wheel_spins=total_spins,
        total_prizes_redeemed=total_redemptions,
        total_bonuses_issued=float(total_issued),
        total_bonuses_spent=float(total_spent),
        average_streak=round(float(avg_streak), 2)
    )


@router.get("/bonus-sources")
def get_bonus_sources(
    db: Session = Depends(get_db),
    current_user = Depends(require_role("analyst"))
):
    """
    Распределение бонусов по источникам.
    Показывает, откуда пользователи получают бонусы.
    """
    now = datetime.utcnow()
    month_start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    
    sources = db.query(
        BonusTransaction.source,
        func.sum(BonusTransaction.amount).label("total"),
        func.count(BonusTransaction.id).label("count")
    ).filter(
        BonusTransaction.created_at >= month_start,
        BonusTransaction.amount > 0
    ).group_by(BonusTransaction.source).all()
    
    return [
        {"source": s, "total": float(t), "count": c}
        for s, t, c in sources
    ]


@router.get("/conversion")
def get_conversion_rates(
    db: Session = Depends(get_db),
    current_user = Depends(require_role("analyst"))
):
    """
    Конверсия каждой механики.
    """
    now = datetime.utcnow()
    month_start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    
    total_users = db.query(func.count(User.id)).filter(
        User.is_active == True,
        User.created_at <= now
    ).scalar() or 1
    
    # Конверсия ежедневного входа
    daily_checkin_users = db.query(func.count(func.distinct(BonusTransaction.user_id))).filter(
        BonusTransaction.source == "daily_checkin",
        BonusTransaction.created_at >= month_start
    ).scalar() or 0
    
    # Конверсия квестов
    quest_users = db.query(func.count(func.distinct(UserQuest.user_id))).filter(
        UserQuest.completed_at >= month_start,
        UserQuest.is_completed == True
    ).scalar() or 0
    
    # Конверсия колеса
    wheel_users = db.query(func.count(func.distinct(WheelSpin.user_id))).filter(
        WheelSpin.spun_at >= month_start
    ).scalar() or 0
    
    # Конверсия каталога
    marketplace_users = db.query(func.count(func.distinct(PrizeRedemption.user_id))).filter(
        PrizeRedemption.redeemed_at >= month_start
    ).scalar() or 0
    
    return {
        "daily_checkin": round(daily_checkin_users / total_users * 100, 2),
        "quests": round(quest_users / total_users * 100, 2),
        "wheel": round(wheel_users / total_users * 100, 2),
        "marketplace": round(marketplace_users / total_users * 100, 2),
        "total_users": total_users
    }
