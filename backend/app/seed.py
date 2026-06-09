from sqlalchemy.orm import Session
from app.database import SessionLocal, Base, engine
from app.models import User, Quest, Achievement, Prize, UserRole, BonusTransaction
from app.auth import get_password_hash
from datetime import datetime, timedelta


def seed_database():
    # Создаём таблицы если их нет
    Base.metadata.create_all(bind=engine)
    """
    Заполнение базы данных тестовыми данными для демонстрации.
    Из ТЗ: "готовый seed-data для демонстрации: 10-20 клиентов, 30+ квестов, 20+ призов, лидерборд"
    """
    db = SessionLocal()
    
    try:
        # Проверяем, есть ли уже данные
        if db.query(User).first():
            print("База данных уже заполнена.")
            return
        
        print("Заполнение базы данных...")
        
        # --- Создаём тестовых пользователей ---
        users_data = [
            {"username": "client1", "email": "client1@test.ru", "role": "client", "full_name": "Иван Петров", "bonus_balance": 1500, "daily_streak": 5},
            {"username": "client2", "email": "client2@test.ru", "role": "client", "full_name": "Мария Сидорова", "bonus_balance": 3200, "daily_streak": 12},
            {"username": "client3", "email": "client3@test.ru", "role": "client", "full_name": "Алексей Козлов", "bonus_balance": 800, "daily_streak": 3},
            {"username": "client4", "email": "client4@test.ru", "role": "client", "full_name": "Елена Новикова", "bonus_balance": 5000, "daily_streak": 20},
            {"username": "client5", "email": "client5@test.ru", "role": "client", "full_name": "Дмитрий Волков", "bonus_balance": 250, "daily_streak": 1},
            {"username": "client6", "email": "client6@test.ru", "role": "client", "full_name": "Анна Морозова", "bonus_balance": 4100, "daily_streak": 15},
            {"username": "client7", "email": "client7@test.ru", "role": "client", "full_name": "Сергей Лебедев", "bonus_balance": 1800, "daily_streak": 7},
            {"username": "client8", "email": "client8@test.ru", "role": "client", "full_name": "Ольга Соколова", "bonus_balance": 600, "daily_streak": 2},
            {"username": "client9", "email": "client9@test.ru", "role": "client", "full_name": "Павел Кузнецов", "bonus_balance": 2900, "daily_streak": 10},
            {"username": "client10", "email": "client10@test.ru", "role": "client", "full_name": "Наталья Попова", "bonus_balance": 7500, "daily_streak": 25},
            {"username": "marketing1", "email": "marketing@sks.ru", "role": "marketing", "full_name": "Маркетолог СКС", "bonus_balance": 0, "daily_streak": 0},
            {"username": "admin1", "email": "admin@sks.ru", "role": "admin", "full_name": "Администратор СКС", "bonus_balance": 0, "daily_streak": 0},
            {"username": "analyst1", "email": "analyst@sks.ru", "role": "analyst", "full_name": "Аналитик СКС", "bonus_balance": 0, "daily_streak": 0},
        ]
        
        users = []
        for udata in users_data:
            user = User(
                username=udata["username"],
                email=udata["email"],
                hashed_password=get_password_hash("password123"),
                role=udata["role"],
                full_name=udata["full_name"],
                bonus_balance=udata["bonus_balance"],
                daily_streak=udata["daily_streak"],
                last_checkin_date=datetime.utcnow() - timedelta(days=1),
            )
            db.add(user)
            users.append(user)
        
        db.flush()  # Получаем ID пользователей
        
        # --- Создаём ежедневные квесты ---
        daily_quests = [
            {"title": "Проверить статус залога", "description": "Зайдите в раздел 'Мои залоги' и проверьте статус", "bonus_reward": 10, "action_type": "check_deposit"},
            {"title": "Прочитать статью о золоте", "description": "Прочитайте статью в разделе 'Обучение'", "bonus_reward": 15, "action_type": "read_article"},
            {"title": "Посмотреть калькулятор займа", "description": "Рассчитайте ежемесячный платёж в калькуляторе", "bonus_reward": 10, "action_type": "use_calculator"},
            {"title": "Обновить профиль", "description": "Добавьте фото или обновите контактные данные", "bonus_reward": 20, "action_type": "update_profile"},
            {"title": "Оценить приложение", "description": "Поставьте оценку в магазине приложений", "bonus_reward": 25, "action_type": "rate_app"},
            {"title": "Поделиться с другом", "description": "Отправьте реферальную ссылку другу", "bonus_reward": 30, "action_type": "share"},
            {"title": "Посмотреть каталог призов", "description": "Изучите доступные призы в каталоге", "bonus_reward": 5, "action_type": "browse_marketplace"},
            {"title": "Проверить лидерборд", "description": "Посмотрите свою позицию в рейтинге", "bonus_reward": 5, "action_type": "check_leaderboard"},
            {"title": "Изучить достижения", "description": "Посмотрите доступные бейджи", "bonus_reward": 5, "action_type": "check_achievements"},
            {"title": "Пригласить друга", "description": "Пригласите друга по реферальной ссылке (+200 после первого займа друга)", "bonus_reward": 200, "action_type": "refer_friend"},
        ]
        
        for qdata in daily_quests:
            quest = Quest(
                title=qdata["title"],
                description=qdata["description"],
                bonus_reward=qdata["bonus_reward"],
                quest_type="daily",
                action_type=qdata["action_type"],
                is_active=True,
            )
            db.add(quest)
        
        # --- Создаём сезонные квесты ---
        seasonal_quests = [
            {"title": "Новогодний квест: Собери 10 снежинок", "description": "Выполняйте ежедневные задания в декабре", "bonus_reward": 500, "action_type": "seasonal_winter", "season_start": datetime(2025, 12, 1), "season_end": datetime(2025, 12, 31)},
            {"title": "Летняя акция: Горячее предложение", "description": "Оформите займ летом и получите бонус", "bonus_reward": 1000, "action_type": "seasonal_summer", "season_start": datetime(2025, 6, 1), "season_end": datetime(2025, 8, 31)},
            {"title": "День ломбарда: Юбилейный квест", "description": "Специальный квест ко дню рождения компании", "bonus_reward": 2000, "action_type": "seasonal_birthday", "season_start": datetime(2025, 9, 1), "season_end": datetime(2025, 9, 30)},
        ]
        
        for qdata in seasonal_quests:
            quest = Quest(
                title=qdata["title"],
                description=qdata["description"],
                bonus_reward=qdata["bonus_reward"],
                quest_type="seasonal",
                action_type=qdata["action_type"],
                season_start=qdata["season_start"],
                season_end=qdata["season_end"],
                is_active=True,
            )
            db.add(quest)
        
        # --- Создаём достижения ---
        achievements = [
            {"name": "Первый шаг", "description": "Оформите первый займ", "icon": "first_step.png", "requirement_type": "loans_count", "requirement_value": 1, "bonus_reward": 50},
            {"name": "Опытный клиент", "description": "Оформите 5 займов", "icon": "experienced.png", "requirement_type": "loans_count", "requirement_value": 5, "bonus_reward": 200},
            {"name": "Ветеран", "description": "Год в программе лояльности", "icon": "veteran.png", "requirement_type": "days_in_program", "requirement_value": 365, "bonus_reward": 1000},
            {"name": "Бонусный охотник", "description": "Накопите 1000 бонусов", "icon": "bonus_hunter.png", "requirement_type": "bonus_balance", "requirement_value": 1000, "bonus_reward": 100},
            {"name": "Бонусный магнат", "description": "Накопите 10000 бонусов", "icon": "bonus_magnate.png", "requirement_type": "bonus_balance", "requirement_value": 10000, "bonus_reward": 500},
            {"name": "Постоянный гость", "description": "30 дней ежедневного входа подряд", "icon": "regular_guest.png", "requirement_type": "streak", "requirement_value": 30, "bonus_reward": 500},
            {"name": "Ранняя пташка", "description": "Визит в ОП до 10:00", "icon": "early_bird.png", "requirement_type": "early_visit", "requirement_value": 1, "bonus_reward": 100},
            {"name": "Точно в срок", "description": "Выкуп залога без просрочки", "icon": "on_time.png", "requirement_type": "no_late", "requirement_value": 1, "bonus_reward": 150},
        ]
        
        for adata in achievements:
            achievement = Achievement(
                name=adata["name"],
                description=adata["description"],
                icon=adata["icon"],
                requirement_type=adata["requirement_type"],
                requirement_value=adata["requirement_value"],
                bonus_reward=adata["bonus_reward"],
            )
            db.add(achievement)
        
        # --- Создаём призы ---
        prizes = [
            # Финансовые
            {"name": "Скидка 5% на проценты", "description": "Скидка на проценты следующего займа", "category": "financial", "bonus_cost": 500, "stock_quantity": 100},
            {"name": "Скидка 10% на проценты", "description": "Повышенная скидка на проценты", "category": "financial", "bonus_cost": 1000, "stock_quantity": 50},
            {"name": "Бесплатное хранение 7 дней", "description": "7 дней бесплатного хранения залога", "category": "financial", "bonus_cost": 300, "stock_quantity": 200},
            {"name": "Экспресс-обслуживание", "description": "Приоритетное обслуживание в ОП", "category": "financial", "bonus_cost": 200, "stock_quantity": 500},
            
            # Партнёрские
            {"name": "Сертификат Wildberries 500₽", "description": "Подарочный сертификат WB", "category": "partner", "bonus_cost": 500, "stock_quantity": 30},
            {"name": "Сертификат Wildberries 1000₽", "description": "Подарочный сертификат WB", "category": "partner", "bonus_cost": 1000, "stock_quantity": 15},
            {"name": "Сертификат OZON 500₽", "description": "Подарочный сертификат OZON", "category": "partner", "bonus_cost": 500, "stock_quantity": 30},
            {"name": "Сертификат Яндекс.Маркет 500₽", "description": "Подарочный сертификат", "category": "partner", "bonus_cost": 500, "stock_quantity": 30},
            {"name": "Сертификат в кинотеатр", "description": "Билет в кино на двоих", "category": "partner", "bonus_cost": 400, "stock_quantity": 20},
            
            # Мерч
            {"name": "Футболка СКС", "description": "Фирменная футболка с логотипом", "category": "merch", "bonus_cost": 800, "stock_quantity": 50},
            {"name": "Термокружка СКС", "description": "Стильная термокружка", "category": "merch", "bonus_cost": 600, "stock_quantity": 40},
            {"name": "Сумка-шоппер СКС", "description": "Эко-сумка с логотипом", "category": "merch", "bonus_cost": 400, "stock_quantity": 60},
            {"name": "Стикерпак СКС", "description": "Набор стикеров", "category": "merch", "bonus_cost": 100, "stock_quantity": 200},
            
            # Благотворительность
            {"name": "Пожертвование 100 бонусов", "description": "Переведите бонусы в благотворительный фонд", "category": "charity", "bonus_cost": 100, "stock_quantity": None},
            {"name": "Пожертвование 500 бонусов", "description": "Крупное пожертвование в фонд", "category": "charity", "bonus_cost": 500, "stock_quantity": None},
            
            # Эксклюзивные
            {"name": "Экскурсия в офис СКС", "description": "Экскурсия с обедом с топ-менеджментом", "category": "exclusive", "bonus_cost": 5000, "stock_quantity": 5},
            {"name": "VIP-обслуживание на месяц", "description": "Персональный менеджер на месяц", "category": "exclusive", "bonus_cost": 3000, "stock_quantity": 10},
            {"name": "Приглашение на закрытое мероприятие", "description": "VIP-мероприятие для клиентов", "category": "exclusive", "bonus_cost": 7000, "stock_quantity": 3},
        ]
        
        for pdata in prizes:
            prize = Prize(
                name=pdata["name"],
                description=pdata["description"],
                category=pdata["category"],
                bonus_cost=pdata["bonus_cost"],
                stock_quantity=pdata["stock_quantity"],
                is_active=True,
            )
            db.add(prize)
        
        # --- Создаём бонусные транзакции для лидерборда ---
        
        # Генерируем транзакции для клиентов
        for i, user in enumerate(users[:10]):  # Только клиенты
            # Ежедневные входы
            for day in range(user.daily_streak):
                transaction = BonusTransaction(
                    user_id=user.id,
                    amount=5,
                    source="daily_checkin",
                    description=f"Ежедневный вход (день {day + 1})",
                    created_at=datetime.utcnow() - timedelta(days=user.daily_streak - day),
                    expires_at=datetime.utcnow() + timedelta(days=365),
                )
                db.add(transaction)
            
            # Квесты
            for day in range(min(user.daily_streak, 5)):
                transaction = BonusTransaction(
                    user_id=user.id,
                    amount=15,
                    source="quest",
                    description="Ежедневный квест",
                    created_at=datetime.utcnow() - timedelta(days=day),
                    expires_at=datetime.utcnow() + timedelta(days=365),
                )
                db.add(transaction)
            
            # Колесо фортуны (для некоторых)
            if i % 3 == 0:
                transaction = BonusTransaction(
                    user_id=user.id,
                    amount=50,
                    source="wheel",
                    description="Колесо фортуны: 50 бонусов",
                    created_at=datetime.utcnow() - timedelta(days=2),
                    expires_at=datetime.utcnow() + timedelta(days=365),
                )
                db.add(transaction)
        
        db.commit()
        print("База данных успешно заполнена!")
        print(f"Создано пользователей: {len(users)}")
        print(f"Создано квестов: {len(daily_quests) + len(seasonal_quests)}")
        print(f"Создано достижений: {len(achievements)}")
        print(f"Создано призов: {len(prizes)}")
        
    except Exception as e:
        db.rollback()
        print(f"Ошибка при заполнении БД: {e}")
        raise
    finally:
        db.close()


if __name__ == "__main__":
    seed_database()
