from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from app.database import get_db
from app.models import User
from app.schemas import UserCreate, UserResponse, Token, UserLogin
from app.auth import get_password_hash, verify_password, create_access_token, get_current_user
from datetime import timedelta
from app.auth import ACCESS_TOKEN_EXPIRE_MINUTES

router = APIRouter(prefix="/api/auth", tags=["Авторизация"])


@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
def register(user_data: UserCreate, db: Session = Depends(get_db)):
    """
    Регистрация нового пользователя.
    
    На защите скажи:
    "При регистрации пароль сразу хешируется через bcrypt и никогда
    не хранится в открытом виде. Это соответствует требованиям безопасности
    и 152-ФЗ о защите персональных данных."
    """
    # Проверяем, не занят ли username
    existing_user = db.query(User).filter(User.username == user_data.username).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="Имя пользователя уже занято")
    
    # Проверяем, не занят ли email
    existing_email = db.query(User).filter(User.email == user_data.email).first()
    if existing_email:
        raise HTTPException(status_code=400, detail="Email уже зарегистрирован")
    
    # Хешируем пароль и создаём пользователя
    hashed_password = get_password_hash(user_data.password)
    new_user = User(
        username=user_data.username,
        email=user_data.email,
        hashed_password=hashed_password,
        full_name=user_data.full_name,
        phone=user_data.phone,
        role="client",  # По умолчанию роль клиента
        bonus_balance=0.0,
        daily_streak=0,
    )
    
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    
    return new_user


@router.post("/login", response_model=Token)
def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db)
):
    """
    Вход пользователя. Возвращает JWT токен.
    
    На защите:
    "Используем OAuth2 Password Flow - стандартный способ авторизации.
    Клиент отправляет username/password, получает JWT токен,
    который отправляет с каждым последующим запросом в заголовке Authorization."
    """
    # Находим пользователя по username
    user = db.query(User).filter(User.username == form_data.username).first()
    
    # Проверяем пароль
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Неверное имя пользователя или пароль",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Создаём JWT токен с данными пользователя
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.username, "role": user.role},
        expires_delta=access_token_expires,
    )
    
    return {"access_token": access_token, "token_type": "bearer"}


@router.get("/me", response_model=UserResponse)
def get_me(current_user: User = Depends(get_current_user)):
    """
    Получить данные текущего авторизованного пользователя.
    """
    return current_user
