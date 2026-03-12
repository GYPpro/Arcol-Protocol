# AGENTS.md - Arcol Protocol

**重要提示：请使用中文进行对话交流 / Please use Chinese for communication.**

---

This file provides guidelines for agentic coding agents working on this repository.

## 开发环境注意事项

### Flutter 环境
- **必须先执行**: `source ~/.bashrc` 加载 Flutter 环境
- Flutter 命令示例: `source ~/.bashrc && flutter build web --release`
- 开发服务器: `source ~/.bashrc && flutter run -d chrome`

---

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



## API 测试

项目提供了 API 测试脚本，可用于验证所有后端接口：

```bash
# 运行 API 测试
cd backend
python test_api.py

# 测试将创建临时用户并测试所有 CRUD 操作
# 测试通过后会自动清理测试数据
```