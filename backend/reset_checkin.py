import sqlite3

conn = sqlite3.connect('sks_quest.db')
cursor = conn.cursor()

cursor.execute("""
    UPDATE users 
    SET last_checkin_date = '2026-06-08 00:00:00', 
        daily_streak = 6 
""")

conn.commit()
conn.close()
print('Готово! Все пользователи сброшены на серию 6')