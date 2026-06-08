from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database import get_db
from app.models import User, Quest, UserQuest, BonusTransaction
from app.schemas import QuestResponse, QuestCreate, QuestComplete
from app.auth import get_current_user, require_role
from typing import List
from datetime import datetime, date

router = APIRouter(prefix="/api/quests", tags=["Квесты"])


@router.get("/daily", response_model=List[QuestResponse])
def get_daily_quests(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    """
    Получить 3 ежедневных квеста на сегодня.
    Квесты сбрасываются в 00:00.
    
    На защите:
    "Каждый день пользователь получает 3 квеста на выбор.
    Мы фильтруем по типу 'daily' и исключаем уже выполненные сегодня."
    """
    today = date.today()
    
    # Получаем все активные ежедневные квесты
    all_quests = db.query(Quest).filter(
        Quest.quest_type == "daily",
        Quest.is_active == True
    ).all()
    
    # Исключаем квесты, которые пользователь уже выполнил сегодня
    completed_today = db.query(UserQuest.quest_id).filter(
        UserQuest.user_id == current_user.id,
        UserQuest.is_completed == True,
        UserQuest.completed_at >= datetime.combine(today, datetime.min.time())
    ).subquery()
    
    available_quests = [q for q in all_quests if q.id not in [row[0] for row in db.query(completed_today).all()]]
    
    # Возвращаем максимум 3 квеста
    return available_quests[:3]


@router.post("/complete", status_code=status.HTTP_200_OK)
def complete_quest(
    quest_data: QuestComplete,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Выполнить квест и получить бонусы.
    
    На защите:
    "При выполнении квеста мы:
    1. Проверяем, что квест существует и активен
    2. Проверяем, что пользователь ещё не выполнял его сегодня
    3. Создаём запись о выполнении
    4. Начисляем бонусы на баланс
    5. Записываем транзакцию в audit log"
    """
    # Находим квест
    quest = db.query(Quest).filter(Quest.id == quest_data.quest_id).first()
    if not quest:
        raise HTTPException(status_code=404, detail="Квест не найден")
    
    if not quest.is_active:
        raise HTTPException(status_code=400, detail="Квест не активен")
    
    # Проверяем, не выполнял ли пользователь этот квест сегодня
    today = date.today()
    already_completed = db.query(UserQuest).filter(
        UserQuest.user_id == current_user.id,
        UserQuest.quest_id == quest_data.quest_id,
        UserQuest.is_completed == True,
        UserQuest.completed_at >= datetime.combine(today, datetime.min.time())
    ).first()
    
    if already_completed:
        raise HTTPException(status_code=400, detail="Квест уже выполнен сегодня")
    
    # Создаём запись о выполнении
    user_quest = UserQuest(
        user_id=current_user.id,
        quest_id=quest_data.quest_id,
        is_completed=True,
        completed_at=datetime.utcnow()
    )
    db.add(user_quest)
    
    # Начисляем бонусы
    current_user.bonus_balance += quest.bonus_reward
    
    # Записываем транзакцию
    from models import BonusTransaction
    transaction = BonusTransaction(
        user_id=current_user.id,
        amount=quest.bonus_reward,
        source="quest",
        description=f"Квест: {quest.title}",
        expires_at=datetime.utcnow().replace(year=datetime.utcnow().year + 1)  # 12 месяцев
    )
    db.add(transaction)
    
    db.commit()
    
    return {
        "message": f"Квест выполнен! Получено {quest.bonus_reward} бонусов",
        "bonus_earned": quest.bonus_reward,
        "new_balance": current_user.bonus_balance
    }


@router.get("/", response_model=List[QuestResponse])
def get_all_quests(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role("marketing"))
):
    """
    Получить все квесты (только для маркетологов).
    """
    return db.query(Quest).all()


@router.post("/", response_model=QuestResponse, status_code=status.HTTP_201_CREATED)
def create_quest(
    quest_data: QuestCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role("marketing"))
):
    """
    Создать новый квест (только для маркетологов).
    
    На защите:
    "Маркетологи могут создавать квесты через API.
    Это позволяет настраивать геймификацию без обновления приложения."
    """
    new_quest = Quest(**quest_data.dict())
    db.add(new_quest)
    db.commit()
    db.refresh(new_quest)
    return new_quest
