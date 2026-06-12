from app.core.database import engine, Base
import app.main  # This ensures all the tables are loaded into memory
Base.metadata.create_all(bind=engine)
print("Boom! Tables built successfully.")