# TN LandMate — Backend Production Deployment Guide

This guide provides step-by-step instructions for deploying the **TN LandMate FastAPI backend** to production.

---

## Deployment Options Overview

| Platform | Best For | Complexity | Free Tier / Cost |
| :--- | :--- | :--- | :--- |
| **Render.com** (Recommended) | Quickest & easiest cloud deployment | Low (1-Click Blueprint) | Free tier available |
| **Railway.app** | High performance with zero DevOps | Low (Auto Dockerfile) | $5 credit / low cost |
| **VPS (Ubuntu + Docker)** | Full control, AWS EC2, DigitalOcean, Hetzner | Medium | $4 - $6 / month |
| **Google Cloud Run** | Scalable, pay-only-per-request serverless | Medium | Free tier includes 2M reqs/mo |

---

## Option 1: Deploy to Render.com (Recommended — 1-Click Blueprint)

We have pre-configured [render.yaml](file:///d:/Tn%20land%20app/render.yaml) at the repository root.

### Steps:
1. **Push your code to GitHub**:
   Ensure your project is pushed to a private or public GitHub repository.

2. **Sign in to Render**:
   Go to [https://render.com](https://render.com) and sign in with GitHub.

3. **Create a Blueprint**:
   - In the Render dashboard, click **"New +"** $\rightarrow$ **"Blueprint"**.
   - Select your `Tn land app` repository.
   - Render will detect [render.yaml](file:///d:/Tn%20land%20app/render.yaml) and automatically create:
     * **`tn-landmate-backend`** (Web Service in Singapore region for low latency to India)
     * **`tn-landmate-db`** (Managed PostgreSQL Database)

4. **Click "Apply"**:
   Render will:
   - Provision PostgreSQL.
   - Install dependencies (`pip install -r requirements.txt`).
   - Execute database migrations (`alembic upgrade head`).
   - Start the FastAPI server on `$PORT`.

5. **Your Live API Endpoint**:
   Your API will be immediately available at:
   ```
   https://tn-landmate-backend.onrender.com/api/v1/health
   ```

---

## Option 2: Deploy to Railway.app

We have pre-configured [railway.json](file:///d:/Tn%20land%20app/railway.json) using the production [Dockerfile](file:///d:/Tn%20land%20app/backend/Dockerfile).

### Steps:
1. Go to [https://railway.app](https://railway.app) and click **"New Project"**.
2. Select **"Deploy from GitHub repo"** and choose your repository.
3. Click **"+ New"** $\rightarrow$ **"Database"** $\rightarrow$ **"Add PostgreSQL"**.
4. In the service settings for the backend:
   - Root Directory: `backend`
   - Add environment variables:
     * `DATABASE_URL`: `${{Postgres.DATABASE_URL}}`
     * `SECRET_KEY`: Generate a random 32-character string
     * `ENVIRONMENT`: `production`
     * `DEBUG`: `false`
5. Railway will build the Docker container and give you a public domain (e.g. `https://tn-landmate.up.railway.app`).

---

## Option 3: Deploy to VPS with Docker Compose (DigitalOcean / AWS EC2 / Hetzner)

If you have a Linux server (Ubuntu 22.04 / 24.04 LTS):

### Steps on your server:

1. **Install Docker & Docker Compose**:
   ```bash
   curl -fsSL https://get.docker.com -o get-docker.sh
   sudo sh get-docker.sh
   sudo apt-get install -y docker-compose-plugin
   ```

2. **Clone your repository**:
   ```bash
   git clone https://github.com/your-username/tn-land-app.git
   cd tn-land-app
   ```

3. **Create production `.env`**:
   ```bash
   cp .env.example .env
   nano .env
   ```
   Set secure values:
   ```env
   POSTGRES_USER=landmate_admin
   POSTGRES_PASSWORD=SuperStrongProductionPassword123!
   POSTGRES_DB=tn_landmate
   SECRET_KEY=generate-a-strong-32-character-random-secret
   ENVIRONMENT=production
   DEBUG=false
   ```

4. **Start all containers**:
   ```bash
   docker compose up -d --build
   ```

5. **Verify health**:
   ```bash
   curl http://localhost:8000/api/v1/health
   # Response: {"status":"healthy","service":"TN LandMate API",...}
   ```

6. **Add SSL / HTTPS with Nginx & Certbot**:
   Point your domain (e.g. `api.yourlandapp.com`) to your server's IP, then run:
   ```bash
   sudo apt-get install -y nginx certbot python3-certbot-nginx
   sudo certbot --nginx -d api.yourlandapp.com
   ```

---

## Connecting the Mobile App to Deployed Backend

Once your backend is live (e.g. `https://tn-landmate-backend.onrender.com/api/v1`):

### Option A: Build-time Injection (Best Practice for APKs)
When building the APK or testing on a physical phone, pass `--dart-define`:
```bash
flutter build apk --release --dart-define=API_URL=https://tn-landmate-backend.onrender.com/api/v1
```

### Option B: Direct Code Update
In [api_client.dart](file:///d:/Tn%20land%20app/mobile/lib/core/network/api_client.dart):
```dart
static const String _envApiUrl = 'https://tn-landmate-backend.onrender.com/api/v1';
```

---

## Production Environment Variables Checklist

| Variable | Description | Example |
| :--- | :--- | :--- |
| `DATABASE_URL` | Async PostgreSQL connection string | `postgresql+asyncpg://user:pass@host:5432/db` |
| `SECRET_KEY` | JWT encryption key (min 32 characters) | `a8f5b4e9...` |
| `ENVIRONMENT` | Runtime environment | `production` |
| `DEBUG` | Enable/disable OpenAPI docs and verbose errors | `false` |
| `CORS_ORIGINS` | Allowed origins | `*` or specific app origins |
| `PORT` | Web port (automatically assigned by Render/Railway/Cloud Run) | `8000` or `10000` |
| `AI_PROVIDER` | Optional LLM provider (`openai`, `gemini`, or `mock`) | `openai` |
| `AI_API_KEY` | API Key for AI land consultant | `sk-...` |
