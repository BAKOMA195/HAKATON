from sqlalchemy import Column, Integer, String, Float, DateTime, Boolean, ForeignKey, Text, Enum
from sqlalchemy.orm import relationship
from app.database import Base
from datetime import datetime
import enum


# ============================================
# МОДЕЛИ БАЗЫ ДАННЫХ (таблицы)
# ============================================
# Каждая класс = одна таблица в БД
# Column = колонка таблицы
# relationship = связь между таблицами


class UserRole(str, enum.Enum):
    """
    Роли пользователей (из ТЗ):
    - client: обычный пользователь приложения
    - marketing: создаёт квесты и акции
    - admin: управляет призами и правилами
    - analyst: смотрит аналитику
    """
    CLIENT = "client"
    MARKETING = "marketing"
    ADMIN = "admin"
    ANALYST = "analyst"


class User(Base):
    """
    Таблица пользователей.
    Хранит данные клиента: логин, пароль, роль, баланс бонусов.
    """
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, index=True, nullable=False)
    email = Column(String(100), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)  # Пароль хранится в зашифрованном виде!
    role = Column(String(20), default=UserRole.CLIENT.value)
    full_name = Column(String(100), nullable=True)
    phone = Column(String(20), nullable=True)

    # Баланс бонусов - ключевое поле для геймификации
    bonus_balance = Column(Float, default=0.0)

    # Серия ежедневных входов (streak)
    daily_streak = Column(Integer, default=0)
    last_checkin_date = Column(DateTime, nullable=True)

    # Дата регистрации
    created_at = Column(DateTime, default=datetime.utcnow)
    is_active = Column(Boolean, default=True)

    # Связи с другими таблицами
    bonus_transactions = relationship("BonusTransaction", back_populates="user")
    completed_quests = relationship("UserQuest", back_populates="user")
    achievements = relationship("UserAchievement", back_populates="user")
    wheel_spins = relationship("WheelSpin", back_populates="user")


class Quest(Base):
    """
    Таблица квестов (заданий).
    Квесты бывают ежедневные и сезонные.
    """
    __tablename__ = "quests"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(200), nullable=False)  # Название квеста
    description = Column(Text, nullable=True)  # Описание
    bonus_reward = Column(Integer, nullable=False)  # Награда в бонусах
    quest_type = Column(String(20), default="daily")  # daily или seasonal
    action_type = Column(String(50), nullable=False)  # Тип действия: check_deposit, read_article и т.д.

    # Для сезонных квестов
    season_start = Column(DateTime, nullable=True)  # Начало сезона
    season_end = Column(DateTime, nullable=True)  # Конец сезона

    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)


class UserQuest(Base):
    """
    Таблица выполненных квестов пользователя.
    Связывает пользователя с квестом и фиксирует выполнение.
    """
    __tablename__ = "user_quests"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    quest_id = Column(Integer, ForeignKey("quests.id"))
    completed_at = Column(DateTime, default=datetime.utcnow)
    is_completed = Column(Boolean, default=False)

    user = relationship("User", back_populates="completed_quests")
    quest = relationship("Quest")


class BonusTransaction(Base):
    """
    Таблица транзакций бонусов.
    Каждая операция с бонусами записывается сюда - это аудит-лог!
    Важно для ТЗ: "транзакционная целостность бонусной экономики"
    """
    __tablename__ = "bonus_transactions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    amount = Column(Float, nullable=False)  # Сумма (положительная = начисление, отрицательная = списание)
    source = Column(String(50), nullable=False)  # Источник: daily_checkin, quest, wheel, marketplace
    description = Column(String(200), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    expires_at = Column(DateTime, nullable=True)  # Бонусы живут 12 месяцев (из ТЗ)

    user = relationship("User", back_populates="bonus_transactions")


class Achievement(Base):
    """
    Таблица достижений (бейджей).
    Хранит все возможные достижения в системе.
    """
    __tablename__ = "achievements"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)  # Название бейджа
    description = Column(Text, nullable=True)
    icon = Column(String(100), nullable=True)  # Путь к иконке
    requirement_type = Column(String(50), nullable=False)  # Тип требования
    requirement_value = Column(Integer, nullable=False)  # Значение для получения
    bonus_reward = Column(Integer, default=0)  # Бонусы за получение

    user_achievements = relationship("UserAchievement", back_populates="achievement")


class UserAchievement(Base):
    """
    Таблица полученных достижений пользователя.
    """
    __tablename__ = "user_achievements"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    achievement_id = Column(Integer, ForeignKey("achievements.id"))
    earned_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="achievements")
    achievement = relationship("Achievement", back_populates="user_achievements")


class WheelSpin(Base):
    """
    Таблица прокруток колеса фортуны.
    Фиксирует каждую прокрутку для защиты от лудомании (лимиты из ТЗ).
    """
    __tablename__ = "wheel_spins"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    prize_type = Column(String(50), nullable=False)  # Тип приза: bonus, discount, badge
    prize_value = Column(Float, nullable=False)  # Значение приза
    is_free = Column(Boolean, default=False)  # Бесплатная или платная прокрутка
    spun_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="wheel_spins")


class Prize(Base):
    """
    Таблица призов в каталоге (Marketplace).
    Клиенты тратят бонусы на эти призы.
    """
    __tablename__ = "prizes"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(200), nullable=False)
    description = Column(Text, nullable=True)
    category = Column(String(50), nullable=False)  # financial, partner, merch, charity, exclusive
    bonus_cost = Column(Integer, nullable=False)  # Цена в бонусах
    image_url = Column(String(255), nullable=True)
    stock_quantity = Column(Integer, nullable=True)  # Ограниченное количество (None = безлимит)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)


class PrizeRedemption(Base):
    """
    Таблица выкупленных призов.
    Фиксирует, кто и когда купил приз.
    """
    __tablename__ = "prize_redemptions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    prize_id = Column(Integer, ForeignKey("prizes.id"))
    redeemed_at = Column(DateTime, default=datetime.utcnow)
    status = Column(String(20), default="pending")  # pending, delivered, cancelled

    user = relationship("User")
    prize = relationship("Prize")


class SeasonalCampaign(Base):
    """
    Таблица сезонных кампаний (Новогодний квест, Летняя акция и т.д.).
    """
    __tablename__ = "seasonal_campaigns"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(200), nullable=False)
    description = Column(Text, nullable=True)
    start_date = Column(DateTime, nullable=False)
    end_date = Column(DateTime, nullable=False)
    final_reward_bonus = Column(Integer, default=0)
    final_reward_badge = Column(String(100), nullable=True)
    is_active = Column(Boolean, default=True)


class GuessPriceItem(Base):
    """
    Таблица предметов для игры «Оценщик».
    """
    __tablename__ = "guess_price_items"

    id = Column(Integer, primary_key=True, index=True)
    emoji = Column(String(10), nullable=False)
    name = Column(String(200), nullable=False)
    description = Column(Text, nullable=True)
    min_price = Column(Integer, nullable=False)
    max_price = Column(Integer, nullable=False)
    real_price = Column(Integer, nullable=False)
    is_active = Column(Boolean, default=True)


class GuessPriceSession(Base):
    """
    Таблица сессий игры «Оценщик».
    """
    __tablename__ = "guess_price_sessions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    total_rounds = Column(Integer, default=5)
    rounds_completed = Column(Integer, default=0)
    total_coins_earned = Column(Integer, default=0)
    hits = Column(Integer, default=0)
    started_at = Column(DateTime, default=datetime.utcnow)
    finished_at = Column(DateTime, nullable=True)
    is_finished = Column(Boolean, default=False)

    user = relationship("User")


class GuessPriceGuess(Base):
    """
    Таблица попыток оценки в игре «Оценщик».
    """
    __tablename__ = "guess_price_guesses"

    id = Column(Integer, primary_key=True, index=True)
    session_id = Column(Integer, ForeignKey("guess_price_sessions.id"))
    item_id = Column(Integer, ForeignKey("guess_price_items.id"))
    user_id = Column(Integer, ForeignKey("users.id"))
    guess = Column(Integer, nullable=False)
    coins_earned = Column(Integer, default=0)
    accuracy = Column(Integer, nullable=False)
    tier = Column(String(20), nullable=False)
    guessed_at = Column(DateTime, default=datetime.utcnow)

    session = relationship("GuessPriceSession")
    item = relationship("GuessPriceItem")
    user = relationship("User")
