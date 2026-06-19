from app.core.database import engine
from sqlalchemy import text

def add_column():
    with engine.begin() as conn:
        try:
            conn.execute(text("ALTER TABLE forms ADD COLUMN share_token VARCHAR UNIQUE;"))
            print("Successfully added share_token column to forms table.")
        except Exception as e:
            print(f"Error: {e}")

if __name__ == "__main__":
    add_column()
