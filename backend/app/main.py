import contextlib
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import RedirectResponse

from app.core.config import settings
from app.db.base import Base
from app.db.session import engine, AsyncSessionLocal
from app.db.seed_data import seed_initial_data

from app.api.v1.health import router as health_router
from app.api.v1.auth import router as auth_router
from app.api.v1.geography import router as geography_router
from app.api.v1.calculators import router as calculators_router
from app.api.v1.land import router as land_router
from app.api.v1.guideline_values import router as guideline_router
from app.api.v1.properties import router as properties_router
from app.api.v1.documents import router as documents_router
from app.api.v1.ai import router as ai_router
from app.api.v1.admin import router as admin_router

@contextlib.asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: initialize database tables and seed data
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    async with AsyncSessionLocal() as session:
        await seed_initial_data(session)
        
    yield
    # Shutdown
    await engine.dispose()

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    description="Production-ready Tamil Nadu Land & Property Utilities API (TN LandMate)",
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/api/v1/openapi.json"
)

# CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount API Routers
api_v1_prefix = settings.API_V1_STR
app.include_router(health_router, prefix=api_v1_prefix)
app.include_router(auth_router, prefix=api_v1_prefix)
app.include_router(geography_router, prefix=api_v1_prefix)
app.include_router(calculators_router, prefix=api_v1_prefix)
app.include_router(land_router, prefix=api_v1_prefix)
app.include_router(guideline_router, prefix=api_v1_prefix)
app.include_router(properties_router, prefix=api_v1_prefix)
app.include_router(documents_router, prefix=api_v1_prefix)
app.include_router(ai_router, prefix=api_v1_prefix)
app.include_router(admin_router, prefix=api_v1_prefix)

@app.get("/", include_in_schema=False)
async def root():
    return RedirectResponse(url="/docs")
