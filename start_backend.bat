@echo off
echo ====================================
echo Arcol Protocol - Backend Server
echo ====================================
echo.

cd /d "%~dp0backend"

echo Checking dependencies...
python -c "import fastapi, uvicorn, sqlalchemy" 2>nul
if errorlevel 1 (
    echo Installing dependencies...
    python -m pip install --user fastapi uvicorn sqlalchemy pydantic pydantic-settings python-jose passlib redis httpx asyncpg alembic psycopg2-binary bcrypt aiofiles feedparser beautifulsoup4 lxml psutil numpy pandas celery python-multipart aiosqlite email-validator pyjwt
)

echo.
echo Starting backend server...
echo Backend will be available at: http://localhost:8000
echo API Documentation: http://localhost:8000/api/v1/docs
echo.

python -m uvicorn app.main:app --reload --port 8000

pause
