from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from app.core.config import settings
from app.database import init_db
from app.api import auth, todo, time_tracking, assets, site_routes, rss, monitor, settings as settings_api


@asynccontextmanager
async def lifespan(app: FastAPI):
    await init_db()
    yield


app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    openapi_url=f"{settings.API_V1_STR}/openapi.json",
    docs_url=f"{settings.API_V1_STR}/docs",
    redoc_url=f"{settings.API_V1_STR}/redoc",
    lifespan=lifespan
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix=settings.API_V1_STR)
app.include_router(todo.router, prefix=settings.API_V1_STR)
app.include_router(time_tracking.router, prefix=settings.API_V1_STR)
app.include_router(assets.router, prefix=settings.API_V1_STR)
app.include_router(site_routes.router, prefix=settings.API_V1_STR)
app.include_router(rss.router, prefix=settings.API_V1_STR)
app.include_router(monitor.router, prefix=settings.API_V1_STR)
app.include_router(settings_api.router, prefix=settings.API_V1_STR)


@app.get("/")
async def root():
    return {"message": "Arcol Protocol API", "version": settings.VERSION}


@app.get("/health")
async def health():
    return {"status": "healthy"}
