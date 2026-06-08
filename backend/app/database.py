from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os

# DATABASE_URL - строка подключения к базе данных
# Для разработки используем SQLite (простая файловая БД)
# Для продакшена заменим на PostgreSQL: "postgresql://user:pass@localhost/sks_quest"
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./sks_quest.db")

# Создаём движок БД - это соединение с базой данных
# check_same_thread=False нужен для SQLite в многопоточном режиме
engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})

# SessionLocal - фабрика сессий для работы с БД
# autocommit=False - не коммитим автоматически, контролируем транзакции вручную
# autoflush=False - не сбрасываем изменения автоматически
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Base - базовый класс для всех моделей таблиц
Base = declarative_base()


# Зависимость для получения сессии БД в эндпоинтах
# Используется как: db: Session = Depends(get_db)
def get_db():
    db = SessionLocal()
    try:
        yield db  # Отдаём сессию эндпоинту
    finally:
        db.close()  # Гарантированно закрываем после запроса
