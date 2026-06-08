from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.models import GuessPriceItem, GuessPriceSession, GuessPriceGuess, User
from app.schemas import (
    GuessPriceItemResponse,
    GuessPriceSessionResponse,
    GuessPriceGuessRequest,
    GuessPriceGuessResponse,
    GuessPriceFinishRequest,
)
from app.auth import get_current_user
from datetime import datetime
import random

router = APIRouter(prefix="/api/guess-price", tags=["Оценщик"])


DEFAULT_ITEMS = [
    {"emoji": "⌚", "name": "Мужские часы Casio", "description": "Кварцевый механизм, нержавеющая сталь, 2019 г.", "min_price": 2000, "max_price": 18000, "real_price": 7500},
    {"emoji": "💍", "name": "Золотое кольцо 585", "description": "Проба 585, вес 3.8 г, без вставок", "min_price": 5000, "max_price": 40000, "real_price": 19000},
    {"emoji": "📱", "name": "Смартфон Samsung S22", "description": "128 ГБ, состояние хорошее, без коробки", "min_price": 8000, "max_price": 45000, "real_price": 22000},
    {"emoji": "💻", "name": "Ноутбук Lenovo IdeaPad", "description": "Core i5, 8 ГБ ОЗУ, 2021 г., царапины", "min_price": 10000, "max_price": 60000, "real_price": 28000},
    {"emoji": "📷", "name": "Фотоаппарат Canon EOS", "description": "Зеркальный, 24 Мп, объектив 18-55", "min_price": 12000, "max_price": 70000, "real_price": 35000},
]


def _seed_items(db: Session):
    """Добавляет предметы по умолчанию, если их нет в БД."""
    count = db.query(GuessPriceItem).count()
    if count == 0:
        for item_data in DEFAULT_ITEMS:
            item = GuessPriceItem(**item_data)
            db.add(item)
        db.commit()


@router.post("/start", response_model=GuessPriceSessionResponse)
def start_game(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Начинает новую сессию игры «Оценщик»."""
    _seed_items(db)

    session = GuessPriceSession(
        user_id=current_user.id,
        total_rounds=5,
        rounds_completed=0,
        total_coins_earned=0,
        hits=0,
    )
    db.add(session)
    db.commit()
    db.refresh(session)

    return {
        "session_id": session.id,
        "total_rounds": session.total_rounds,
        "rounds_completed": session.rounds_completed,
        "total_coins_earned": session.total_coins_earned,
        "hits": session.hits,
    }


@router.get("/items", response_model=list[GuessPriceItemResponse])
def get_items(
    session_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Возвращает список предметов для текущей сессии."""
    session = db.query(GuessPriceSession).filter(
        GuessPriceSession.id == session_id,
        GuessPriceSession.user_id == current_user.id,
    ).first()

    if not session:
        raise HTTPException(status_code=404, detail="Сессия не найдена")

    if session.is_finished:
        raise HTTPException(status_code=400, detail="Сессия уже завершена")

    items = db.query(GuessPriceItem).filter(GuessPriceItem.is_active == True).all()
    return items


@router.post("/guess", response_model=GuessPriceGuessResponse)
def submit_guess(
    request: GuessPriceGuessRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Принимает оценку пользователя и возвращает результат."""
    session = db.query(GuessPriceSession).filter(
        GuessPriceSession.id == request.session_id,
        GuessPriceSession.user_id == current_user.id,
    ).first()

    if not session:
        raise HTTPException(status_code=404, detail="Сессия не найдена")

    if session.is_finished:
        raise HTTPException(status_code=400, detail="Сессия уже завершена")

    item = db.query(GuessPriceItem).filter(GuessPriceItem.id == request.item_id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Предмет не найден")

    diff = abs(request.guess - item.real_price)
    accuracy = round(diff / item.real_price * 100)

    if accuracy <= 5:
        coins_earned = 200
        tier = "exact"
        message = "Точное попадание!"
    elif accuracy <= 15:
        coins_earned = 100
        tier = "close"
        message = "Близко!"
    elif accuracy <= 30:
        coins_earned = 30
        tier = "miss"
        message = "Мимо..."
    else:
        coins_earned = 0
        tier = "far"
        message = "Далеко от цены"

    guess = GuessPriceGuess(
        session_id=session.id,
        item_id=item.id,
        user_id=current_user.id,
        guess=request.guess,
        coins_earned=coins_earned,
        accuracy=accuracy,
        tier=tier,
    )
    db.add(guess)

    session.rounds_completed += 1
    session.total_coins_earned += coins_earned
    if coins_earned >= 100:
        session.hits += 1

    current_user.bonus_balance += coins_earned

    db.commit()

    return {
        "coins_earned": coins_earned,
        "accuracy": accuracy,
        "tier": tier,
        "message": message,
    }


@router.post("/finish", response_model=GuessPriceSessionResponse)
def finish_game(
    request: GuessPriceFinishRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Завершает сессию игры и начисляет итоговые бонусы."""
    session = db.query(GuessPriceSession).filter(
        GuessPriceSession.id == request.session_id,
        GuessPriceSession.user_id == current_user.id,
    ).first()

    if not session:
        raise HTTPException(status_code=404, detail="Сессия не найдена")

    session.is_finished = True
    session.finished_at = datetime.utcnow()

    db.commit()
    db.refresh(session)

    return {
        "session_id": session.id,
        "total_rounds": session.total_rounds,
        "rounds_completed": session.rounds_completed,
        "total_coins_earned": session.total_coins_earned,
        "hits": session.hits,
    }
