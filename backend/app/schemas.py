from pydantic import BaseModel, EmailStr
from typing import Optional, List
from datetime import datetime


# ============================================
# PYDANTIC СХЕМЫ (валидация данных)
# ============================================
# Схемы определяют, какие данные принимает и отдаёт API
# Это контракт между фронтендом и бэкендом


# --- Схемы для пользователей ---

class UserCreate(BaseModel):
    """Данные для регистрации нового пользователя"""
    username: str
    email: EmailStr
    password: str
    full_name: Optional[str] = None
    phone: Optional[str] = None


class UserResponse(BaseModel):
    """Данные пользователя в ответе API"""
    id: int
    username: str
    email: str
    role: str
    full_name: Optional[str]
    bonus_balance: float
    daily_streak: int
    created_at: datetime

    class Config:
        from_attributes = True  # Позволяет конвертировать SQLAlchemy модели


class UserLogin(BaseModel):
    """Данные для входа в систему"""
    username: str
    password: str


class Token(BaseModel):
    """JWT токен авторизации"""
    access_token: str
    token_type: str


# --- Схемы для квестов ---

class QuestResponse(BaseModel):
    """Квест в ответе API"""
    id: int
    title: str
    description: Optional[str]
    bonus_reward: int
    quest_type: str
    action_type: str
    is_active: bool

    class Config:
        from_attributes = True


class QuestCreate(BaseModel):
    """Создание нового квеста (для маркетолога)"""
    title: str
    description: Optional[str] = None
    bonus_reward: int
    quest_type: str = "daily"
    action_type: str
    season_start: Optional[datetime] = None
    season_end: Optional[datetime] = None


class QuestComplete(BaseModel):
    """Запрос на выполнение квеста"""
    quest_id: int


# --- Схемы для бонусов ---

class BonusTransactionResponse(BaseModel):
    """Транзакция бонусов в ответе API"""
    id: int
    amount: float
    source: str
    description: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True


# --- Схемы для колеса фортуны ---

class WheelSpinResponse(BaseModel):
    """Результат прокрутки колеса"""
    prize_type: str
    prize_value: float
    is_free: bool
    spun_at: datetime

    class Config:
        from_attributes = True


class WheelProbabilities(BaseModel):
    """Вероятности призов на колесе (для прозрачности - требование ТЗ)"""
    bonus_10: float = 30.0
    bonus_25: float = 25.0
    bonus_50: float = 20.0
    bonus_100: float = 15.0
    bonus_500: float = 8.0
    discount: float = 1.5
    badge: float = 0.5


# --- Схемы для достижений ---

class AchievementResponse(BaseModel):
    """Достижение в ответе API"""
    id: int
    name: str
    description: Optional[str]
    icon: Optional[str]
    bonus_reward: int

    class Config:
        from_attributes = True


class UserAchievementResponse(BaseModel):
    """Полученное достижение пользователя"""
    achievement: AchievementResponse
    earned_at: datetime

    class Config:
        from_attributes = True


# --- Схемы для каталога призов ---

class PrizeResponse(BaseModel):
    """Приз в каталоге"""
    id: int
    name: str
    description: Optional[str]
    category: str
    bonus_cost: int
    image_url: Optional[str]
    stock_quantity: Optional[int]
    is_active: bool

    class Config:
        from_attributes = True


class PrizeCreate(BaseModel):
    """Создание нового приза (для админа)"""
    name: str
    description: Optional[str] = None
    category: str
    bonus_cost: int
    image_url: Optional[str] = None
    stock_quantity: Optional[int] = None


class PrizeRedeem(BaseModel):
    """Запрос на выкуп приза"""
    prize_id: int


# --- Схемы для ежедневного входа ---

class DailyCheckinResponse(BaseModel):
    """Ответ на ежедневный вход"""
    bonus_earned: int
    current_streak: int
    streak_bonus: Optional[int] = None
    message: str


# --- Схемы для лидерборда ---

class LeaderboardEntry(BaseModel):
    """Запись в лидерборде"""
    rank: int
    pseudonym: str
    bonus_earned_month: float
    league: str


# --- Схемы для аналитики ---

class AnalyticsDashboard(BaseModel):
    """Дашборд аналитики для маркетолога"""
    dau: int  # Daily Active Users
    mau: int  # Monthly Active Users
    dau_mau_ratio: float
    total_quests_completed: int
    total_wheel_spins: int
    total_prizes_redeemed: int
    total_bonuses_issued: float
    total_bonuses_spent: float
    average_streak: float
