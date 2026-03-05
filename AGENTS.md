# AGENTS.md - Arcol Protocol

This file provides guidelines for agentic coding agents working on this repository.

## Project Overview

- **Name**: Arcol Protocol
- **Description**: A personalized information integration and display full-stack application with Flutter WebUI and Python FastAPI backend
- **Tech Stack**:
  - Backend: Python FastAPI, SQLAlchemy 2.0, PostgreSQL/SQLite, Redis, Celery
  - Frontend: Flutter/Dart 3.x, Riverpod, Dio, GoRouter

## Project Structure

```
Arcol-Protocol/
├── backend/                 # Python FastAPI application
│   ├── app/
│   │   ├── api/            # API route handlers
│   │   ├── core/           # Core config, security
│   │   ├── models/         # SQLAlchemy ORM models
│   │   ├── schemas/        # Pydantic schemas
│   │   └── main.py         # FastAPI app entry
│   ├── requirements.txt    # Python dependencies
│   └── Dockerfile
├── frontend/               # Flutter web application
│   ├── lib/
│   │   ├── api/           # API client
│   │   ├── config/        # App configuration
│   │   ├── models/        # Data models
│   │   ├── providers/     # Riverpod providers
│   │   ├── views/         # UI views/screens
│   │   └── main.dart      # Flutter entry
│   ├── pubspec.yaml       # Flutter dependencies
│   └── analysis_options.yaml
└── docker-compose.yml
```

---

## Build / Lint / Test Commands

### Backend (Python)

```bash
# Install dependencies
cd backend
pip install -r requirements.txt
pip install pytest pytest-asyncio httpx

# Run development server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Run tests
pytest                          # Run all tests
pytest tests/                   # Run tests in directory
pytest tests/test_file.py       # Run single test file
pytest tests/test_file.py::test_function_name  # Run single test function
pytest -v                       # Verbose output
pytest -k "test_name"           # Run tests matching pattern

# Linting (if ruff installed)
ruff check .
ruff check --fix .

# Type checking (if mypy installed)
mypy app/
```

### Frontend (Flutter)

```bash
# Install dependencies
cd frontend
flutter pub get

# Run development server
flutter run

# Build for web
flutter build web

# Run tests
flutter test                        # Run all tests
flutter test test/file_test.dart    # Run single test file
flutter test --plain-name "test name"  # Run test by name

# Linting / Analysis
flutter analyze
flutter analyze --no-fatal-infos    # Don't fail on infos

# Code generation (Riverpod)
dart run build_runner build
dart run build_runner build --delete-conflicting-outputs

# Format code
dart format .
```

---

## Code Style Guidelines

### Backend (Python)

#### Imports
- Standard library imports first
- Third-party imports second
- Local application imports third
- Each group separated by blank line
- Use absolute imports: `from app.api import auth`

```python
# Correct order
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Optional

from app.database import get_db
from app.core.security import get_password_hash
from app.models.user import User
from app.schemas.user import UserCreate
```

#### Naming Conventions
- Classes: `PascalCase` (e.g., `UserResponse`)
- Functions/variables: `snake_case` (e.g., `get_current_user`)
- Constants: `UPPER_SNAKE_CASE` (e.g., `MAX_RETRY_COUNT`)
- Private functions: `_private_function()`

#### Type Annotations
- Always use type hints for function parameters and return values
- Use `Optional[X]` instead of `X | None` for compatibility

```python
# Good
def get_user(user_id: int) -> Optional[User]:
    ...

async def create_user(user: UserCreate, db: AsyncSession) -> UserResponse:
    ...
```

#### Error Handling
- Use HTTPException for API errors with appropriate status codes
- Log errors in critical business logic
- Return meaningful error messages

```python
# Good
if not user:
    raise HTTPException(
        status_code=status.HTTP_404_NOT_FOUND,
        detail="User not found"
    )

# Logging example
import logging
logger = logging.getLogger(__name__)

logger.info(f"User {user_id} logged in")
logger.error(f"Failed to process request: {error}")
```

#### Database
- Use SQLAlchemy 2.0 async patterns
- NEVER concatenate SQL strings directly - use parameterized queries
- Always use proper relationship back_populates

```python
# Good - using SQLAlchemy
result = await db.execute(select(User).where(User.id == user_id))
user = result.scalar_one_or_none()

# Bad - direct SQL concatenation (NEVER DO THIS)
query = f"SELECT * FROM users WHERE id = {user_id}"
```

#### Async Patterns
- Use async/await for all I/O operations
- Use async task queues (Celery) for long-running operations
- Never block the event loop

```python
# Use async throughout
@router.get("/users")
async def get_users(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User))
    return result.scalars().all()
```

#### Pydantic Models
- Use Pydantic v2 for request/response validation
- Use `Field()` for validation constraints

```python
from pydantic import BaseModel, Field, EmailStr

class UserCreate(BaseModel):
    username: str = Field(..., min_length=3, max_length=50)
    email: EmailStr | None = None
    password: str = Field(..., min_length=8)
```

---

### Frontend (Flutter/Dart)

#### Naming Conventions
- Files: `snake_case.dart` (e.g., `user_model.dart`)
- Classes: `PascalCase` (e.g., `class UserModel`)
- Variables/functions: `camelCase` (e.g., `userName`, `getUser()`)
- Private members: `_privateMethod()`

#### Project Structure
- NO business code in `lib/` root - use subdirectories
- Split by feature: `lib/features/feature_name/`
- Group by type: `models/`, `providers/`, `views/`, `widgets/`

```dart
// Good structure
lib/
├── api/
│   └── api_client.dart
├── config/
│   └── config.dart
├── models/
│   └── user.dart
├── providers/
│   └── user_provider.dart
└── views/
    └── user/
        └── user_view.dart
```

#### State Management
- Use Riverpod for all state management
- NEVER use `setState` as primary state management
- NEVER manually manage state in StatelessWidget
- NEVER use ChangeNotifier without proper disposal

```dart
// Good - Riverpod provider
final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  return UserNotifier(ref);
});

// Good - AsyncNotifier for async operations
class UserNotifier extends AsyncNotifier<User> {
  @override
  Future<User> build() async => await fetchUser();
}
```

#### Async Operations
- Async methods MUST return `Future<T>`, never `void`
- NEVER call async methods directly in `build()`

```dart
// Good
Future<void> loadData() async {
  final data = await fetchData();
  // ...
}

// Good - use WidgetsBinding.instance.addPostFrameCallback or useEffect equivalent
@override
void initState() {
  super.initState();
  Future.microtask(() => context.read(provider).loadData());
}
```

#### Type Safety
- Public API variables MUST have explicit type declarations
- Avoid `dynamic` - use proper types or `void`

```dart
// Good
final String userName;
final List<User> users;
Future<User> getUser(int id);

// Avoid
var userName;  // Bad
```

#### UI Guidelines
- NO hardcoded strings/colors/sizes - use Theme or constants
- NO nesting >4 layers in Column/Row - extract to widgets
- NO single file >300 lines - split into multiple files

```dart
// Good - use Theme
Text(
  'Hello',
  style: Theme.of(context).textTheme.titleLarge,
)

// Good - extract nested widgets
Column(
  children: [
    HeaderWidget(),
    ContentWidget(),
    FooterWidget(),
  ],
)
```

#### Null Safety
- Use null-safe operators: `?.`, `??`, `?:` 
- Avoid `!` operator when possible

```dart
// Good
final name = user?.name ?? 'Unknown';
final list = items?.isNotEmpty == true ? items : [];

// Avoid
final name = user!.name;  // Can throw
```

---

## Testing Guidelines

### Backend Tests
- Place tests in `backend/tests/` directory
- Use `pytest` with `pytest-asyncio` for async tests
- Test file naming: `test_*.py` or `*_test.py`
- Use fixtures for database setup

```python
# Example test structure
# backend/tests/test_auth.py
import pytest
from httpx import AsyncClient
from app.main import app

@pytest.fixture
async def client():
    async with AsyncClient(app=app, base_url="http://test") as ac:
        yield ac

@pytest.mark.asyncio
async def test_login(client):
    response = await client.post("/api/v1/auth/login", data={
        "username": "test",
        "password": "test"
    })
    assert response.status_code == 200
```

### Frontend Tests
- Place tests in `frontend/test/` directory
- Test file naming: `*_test.dart`

```dart
// Example test
import 'package:flutter_test/flutter_test';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  test('provider test', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    
    expect(container.read(someProvider), equals(expectedValue));
  });
}
```

---

## Docker Development

```bash
# Start all services
docker-compose up -d

# Start only backend
docker-compose up -d backend

# View logs
docker-compose logs -f backend

# Stop all services
docker-compose down
```

---

## Key Files Reference

| File | Purpose |
|------|---------|
| `backend/app/main.py` | FastAPI app entry point |
| `backend/app/core/config.py` | Settings configuration |
| `backend/app/database.py` | Database connection |
| `frontend/lib/main.dart` | Flutter app entry |
| `frontend/lib/api/api_client.dart` | HTTP client setup |
| `frontend/lib/config/config.dart` | App configuration |
| `docker-compose.yml` | Docker orchestration |
