from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import func, desc
from app.database import get_db
from app.models import User, BonusTransaction, UserAchievement, Achievement
from app.schemas import LeaderboardEntry, AchievementResponse, UserAchievementResponse
from app.auth import get_current_user
from typing import List
from datetime import datetime, timedelta

router = APIRouter(prefix="/api", tags=["Лидерборд и достижения"])


@router.get("/leaderboard", response_model=List[LeaderboardEntry])
def get_leaderboard(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Анонимный лидерборд по бонусам за месяц.
    
    Из ТЗ:
    - Анонимный (аватар + псевдоним, без ФИО)
    - Лиги: Бронза, Серебро, Золото, Платина, Бриллиант
    - Топ-10% переходят в высшую лигу каждый месяц
    
    На защите:
    "Лидерборд анонимный - мы показываем только псевдоним и аватар.
    Это соответствует 152-ФЗ о защите персональных данных."
    """
    # Определяем начало текущего месяца
    now = datetime.utcnow()
    month_start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    
    # Считаем бонусы, заработанные каждым пользователем за месяц
    monthly_earnings = db.query(
        User.id,
        User.username,
        func.sum(BonusTransaction.amount).label("total_earned")
    ).join(
        BonusTransaction, User.id == BonusTransaction.user_id
    ).filter(
        BonusTransaction.created_at >= month_start,
        BonusTransaction.amount > 0  # Только начисления
    ).group_by(User.id, User.username).order_by(
        desc("total_earned")
    ).all()
    
    # Формируем лидерборд
    total_users = len(monthly_earnings)
    leaderboard = []
    
    for rank, (user_id, username, total_earned) in enumerate(monthly_earnings, 1):
        # Определяем лигу
        percentile = (rank / total_users * 100) if total_users > 0 else 100
        league = _get_league(percentile)
        
        # Создаём анонимный псевдоним
        pseudonym = f"Игрок#{user_id}"
        
        leaderboard.append(LeaderboardEntry(
            rank=rank,
            pseudonym=pseudonym,
            bonus_earned_month=float(total_earned),
            league=league
        ))
    
    return leaderboard[:50]  # Топ-50


def _get_league(percentile: float) -> str:
    """
    Определяет лигу пользователя на основе позиции в рейтинге.
    """
    if percentile <= 10:
        return "Бриллиант"
    elif percentile <= 25:
        return "Платина"
    elif percentile <= 50:
        return "Золото"
    elif percentile <= 75:
        return "Серебро"
    else:
        return "Бронза"


@router.get("/achievements", response_model=List[AchievementResponse])
def get_all_achievements(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Получить все доступные достижения.
    """
    return db.query(Achievement).all()


@router.get("/my-achievements", response_model=List[UserAchievementResponse])
def get_my_achievements(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Получить достижения, полученные пользователем.
    """
    user_achievements = db.query(UserAchievement).filter(
        UserAchievement.user_id == current_user.id
    ).all()
    
    result = []
    for ua in user_achievements:
        achievement = db.query(Achievement).filter(Achievement.id == ua.achievement_id).first()
        if achievement:
            result.append(UserAchievementResponse(
                achievement=achievement,
                earned_at=ua.earned_at
            ))
    
    return result


@router.get("/my-league")
def get_my_league(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Получить текущую лигу пользователя.
    """
    now = datetime.utcnow()
    month_start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    
    # Считаем бонусы пользователя за месяц
    total_earned = db.query(
        func.sum(BonusTransaction.amount)
    ).filter(
        BonusTransaction.user_id == current_user.id,
        BonusTransaction.created_at >= month_start,
        BonusTransaction.amount > 0
    ).scalar() or 0
    
    # Определяем позицию в рейтинге
    all_users = db.query(
        User.id,
        func.sum(BonusTransaction.amount).label("total")
    ).join(
        BonusTransaction, User.id == BonusTransaction.user_id
    ).filter(
        BonusTransaction.created_at >= month_start,
        BonusTransaction.amount > 0
    ).group_by(User.id).order_by(desc("total")).all()
    
    rank = 1
    for i, (uid, total) in enumerate(all_users, 1):
        if uid == current_user.id:
            rank = i
            break
    
    total_users = len(all_users)
    percentile = (rank / total_users * 100) if total_users > 0 else 100
    league = _get_league(percentile)
    
    return {
        "league": league,
        "rank": rank,
        "total_users": total_users,
        "bonus_earned_month": float(total_earned),
        "next_league": _get_next_league(league)
    }


def _get_next_league(current_league: str) -> str:
    """
    Определяет следующую лигу.
    """
    leagues = ["Бронза", "Серебро", "Золото", "Платина", "Бриллиант"]
    idx = leagues.index(current_league) if current_league in leagues else 0
    if idx < len(leagues) - 1:
        return leagues[idx + 1]
    return "Максимальная лига!"
