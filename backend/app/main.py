from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.database import engine, Base
from app.routers import auth, quests, daily, wheel, marketplace, leaderboard, analytics

# ============================================
# ГЛАВНЫЙ ФАЙЛ ПРИЛОЖЕНИЯ (SKS Quest API)
# ============================================
# FastAPI - современный фреймворк для создания API на Python
# Автоматически генерирует Swagger документацию!
#
# На защите скажи:
# "Мы используем FastAPI - это современный Python фреймворк,
# который автоматически генерирует Swagger/OpenAPI документацию.
# Это позволяет фронтенд-разработчикам видеть все доступные
# эндпоинты и тестировать API прямо в браузере."

# Создаём таблицы в БД при запуске
Base.metadata.create_all(bind=engine)

# Инициализируем приложение
app = FastAPI(
    title="SKS Quest API",
    description="""
    ## API модуля геймификации СКС Онлайн
    
    Этот API реализует:
    - **Авторизация** - регистрация и вход с JWT токенами
    - **Ежедневный вход** - бонусы за серию дней
    - **Квесты** - ежедневные и сезонные задания
    - **Колесо фортуны** - прокрутка с прозрачными вероятностями
    - **Каталог призов** - трата бонусов на реальные призы
    - **Лидерборд** - анонимный рейтинг с лигами
    - **Достижения** - бейджи за ключевые вехи
    - **Аналитика** - дашборд для маркетологов
    
    ### Роли пользователей:
    - **client** - обычный пользователь
    - **marketing** - создание квестов
    - **admin** - управление призами
    - **analyst** - просмотр аналитики
    """,
    version="1.0.0",
)

# ============================================
# CORS (Cross-Origin Resource Sharing)
# ============================================
# Разрешаем запросы с фронтенда (мобильное приложение, веб-панель)
# Без этого браузер заблокирует запросы к API

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # В продакшене указать конкретные домены
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ============================================
# РЕГИСТРАЦИЯ РОУТЕРОВ (API маршрутов)
# ============================================
# Каждый роутер - это группа связанных эндпоинтов

app.include_router(auth.router)           # /api/auth/* - авторизация
app.include_router(quests.router)         # /api/quests/* - квесты
app.include_router(daily.router)          # /api/daily/* - ежедневный вход
app.include_router(wheel.router)          # /api/wheel/* - колесо фортуны
app.include_router(marketplace.router)    # /api/marketplace/* - каталог призов
app.include_router(leaderboard.router)    # /api/* - лидерборд и достижения
app.include_router(analytics.router)      # /api/analytics/* - аналитика


@app.get("/", tags=["Главная"])
def root():
    """
    Корневой эндпоинт. Проверка, что API работает.
    """
    return {
        "message": "SKS Quest API - Модуль геймификации СКС Онлайн",
        "docs": "/docs",  # Swagger документация
        "version": "1.0.0"
    }


@app.get("/health", tags=["Здоровье"])
def health_check():
    """
    Эндпоинт для проверки здоровья сервиса.
    Используется в Docker для проверки, что контейнер работает.
    """
    return {"status": "ok"}
