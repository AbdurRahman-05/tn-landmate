from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from app.core.config import settings

def get_async_database_url(url: str) -> str:
    # Render, Railway, and Heroku provide postgres:// or postgresql://
    # Async SQLAlchemy requires postgresql+asyncpg://
    if url.startswith("postgres://"):
        return url.replace("postgres://", "postgresql+asyncpg://", 1)
    if url.startswith("postgresql://") and "+asyncpg" not in url and "+psycopg" not in url:
        return url.replace("postgresql://", "postgresql+asyncpg://", 1)
    return url

async_db_url = get_async_database_url(settings.DATABASE_URL)

# Engine configuration
connect_args = {}
if "sqlite" in async_db_url:
    connect_args = {"check_same_thread": False}

engine = create_async_engine(
    async_db_url,
    echo=False,
    connect_args=connect_args,
    future=True
)


AsyncSessionLocal = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False
)

async def get_db():
    async with AsyncSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()
