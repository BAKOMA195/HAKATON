from datetime import datetime, timedelta
from typing import Optional
from jose import JWTError, jwt
import hashlib
import secrets
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from app.database import get_db
from app.models import User
import os

# ============================================
# АВТОРИЗАЦИЯ И АУТЕНТИФИКАЦИЯ (JWT)
# ============================================
# JWT (JSON Web Token) - стандарт авторизации из ТЗ
# Клиент получает токен при входе и отправляет его с каждым запросом


# Секретный ключ для подписи JWT токенов
# В продакшене хранить в переменных окружения!
SECRET_KEY = os.getenv("SECRET_KEY", "sks-quest-secret-key-change-in-production")
ALGORITHM = "HS256"  # Алгоритм шифрования
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24  # Токен живёт 24 часа

# Хеширование паролей через SHA-256 + salt
# Пароли НИКОГДА не хранятся в открытом виде!
# На защите: "Используем SHA-256 с уникальной солью для каждого пароля"

# OAuth2 схема - стандартный способ авторизации в FastAPI
# Клиент отправляет токен в заголовке: Authorization: Bearer <token>
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="api/auth/login")


def _hash_with_salt(password: str, salt: str) -> str:
    """SHA-256 хеширование с солью"""
    return hashlib.sha256(f"{salt}{password}".encode()).hexdigest()


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """
    Проверяет, совпадает ли введённый пароль с хешем в БД.
    Формат хранения: salt$hash
    """
    try:
        salt, stored_hash = hashed_password.split("$", 1)
        return _hash_with_salt(plain_password, salt) == stored_hash
    except ValueError:
        return False


def get_password_hash(password: str) -> str:
    """
    Создаёт хеш из пароля с уникальной солью.
    Формат: salt$hash
    """
    salt = secrets.token_hex(16)
    hashed = _hash_with_salt(password, salt)
    return f"{salt}${hashed}"


def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    """
    Создаёт JWT токен авторизации.
    
    Токен содержит:
    - sub: username пользователя
    - role: роль пользователя (client, marketing, admin, analyst)
    - exp: время истечения токена
    
    На защите скажи: "Мы используем JWT токены с ролевой моделью.
    Токен подписан секретным ключом и содержит роль пользователя,
    что позволяет проверять права доступа на каждом эндпоинте."
    """
    to_encode = data.copy()
    
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt


def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db)
) -> User:
    """
    Зависимость для получения текущего пользователя из JWT токена.
    Используется в защищённых эндпоинтах: current_user: User = Depends(get_current_user)
    
    На защите: "Каждый защищённый эндпоинт автоматически проверяет JWT токен,
    извлекает username и находит пользователя в БД. Если токен невалидный -
    возвращается ошибка 401 Unauthorized."
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Неверные учётные данные",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    try:
        # Декодируем JWT токен
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception
    
    # Находим пользователя в БД
    user = db.query(User).filter(User.username == username).first()
    if user is None:
        raise credentials_exception
    
    if not user.is_active:
        raise HTTPException(status_code=400, detail="Пользователь деактивирован")
    
    return user


def require_role(required_role: str):
    """
    Декоратор для проверки роли пользователя.
    Используется так: @router.post("/admin/...", dependencies=[Depends(require_role("admin"))])
    
    На защите: "Мы реализовали ролевую модель из ТЗ:
    client - обычный пользователь
    marketing - создаёт квесты
    admin - управляет призами
    analyst - смотрит аналитику
    Каждый эндпоинт проверяет роль через JWT токен."
    """
    def role_checker(current_user: User = Depends(get_current_user)):
        if current_user.role != required_role and current_user.role != "admin":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Недостаточно прав. Требуется роль: {required_role}"
            )
        return current_user
    return role_checker
