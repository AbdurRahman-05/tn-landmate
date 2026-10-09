# TN LandMate (டி.என். லேண்ட்மேட்)

**TN LandMate** is a production-oriented Tamil Nadu land and property utility platform engineered for citizens, landowners, surveyors, and legal professionals. It combines an offline-first mobile calculator and property manager with an administrative governance engine and regulatory land data explorer.

---

## 1. System Architecture & Features

### Mobile Application (Flutter)
- **Offline Land Measurement Unit Converter**: Simultaneous conversion between 8 standard Tamil Nadu and metric units (Square Feet, Cents, Grounds, Acres, Hectares, Square Metres, Square Yards, Square Kilometres) with decimal-safe calculations.
- **Plot Area Geometry Calculator**: Exact and estimated geometric area calculation for Rectangles, Triangles, Trapezoids, and Composite L-shapes.
- **Statutory Stamp Duty & Registration Calculator**: Configurable estimation based on Tamil Nadu's 7% Stamp Duty + 2% Registration Fee standard rules.
- **Hierarchical Land Search**: Cascading revenue administrative hierarchy (District → Taluk → Revenue Village → Survey Number → Subdivision).
- **Authorized Provider Abstraction**: Clear distinction between licensed demo test fixtures and verified official government datasets.
- **Educational Document Guides**: Bilingual guidance (English & தமிழ்) for Patta, Chitta, A-Register, FMB (Field Measurement Book), Encumbrance Certificate (EC), and Sale Deeds.
- **Cadastral FMB Viewer**: Interactive schematic canvas with Pan & Pinch-to-Zoom for boundary polygons, central G-Lines, and ladder offsets.
- **Personal Property Portfolio**: Offline guest-mode persistence via local secure device storage with cloud sync support.
- **AI Land Document Assistant**: Natural language Q&A for Tamil Nadu land terminology and indicative cadastral field extraction.

### Backend (FastAPI & SQLAlchemy)
- Python 3.12+ async architecture with dual database support (PostgreSQL in production / Docker, SQLite fallback for zero-dependency local development).
- JWT authentication with refresh-token rotation, jti nonce guarantees, and instant revocation.
- Normalized models for 38 Tamil Nadu Revenue Districts, Taluks, Revenue Villages, and Sub-Registrar Offices.
- Alembic database migration management.

### Administration Portal (React + Vite + TypeScript)
- Department governance dashboard with key system metrics.
- Regulatory rule manager for effective-dated stamp duty and registration percentages.
- Street-level Guideline Value directory viewer.
- Tamil Nadu 38-district geographical configuration.

---

## 2. Prerequisites

| Tool | Recommended Version |
| :--- | :--- |
| **Python** | 3.12 or 3.13 |
| **Node.js** | 20.x or 22.x LTS |
| **npm** | 10.x or higher |
| **Flutter SDK** | 3.38+ |
| **Docker & Docker Compose** | Latest Desktop / Engine (Optional for containerized run) |

---

## 3. Quick Start & Local Execution

### 3.1 Database & Backend Setup

1. Navigate to the backend directory:
   ```bash
   cd backend
   ```
2. Install Python dependencies:
   ```bash
   pip install -r requirements.txt
   ```
3. Run Alembic migrations:
   ```bash
   python -m alembic upgrade head
   ```
4. Start the FastAPI development server:
   ```bash
   python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
   ```
   - Interactive Swagger API Documentation: [http://localhost:8000/docs](http://localhost:8000/docs)
   - Alternative ReDoc: [http://localhost:8000/redoc](http://localhost:8000/redoc)

---

### 3.2 React Admin Dashboard

1. Navigate to the admin directory:
   ```bash
   cd admin
   ```
2. Install npm dependencies:
   ```bash
   npm install
   ```
3. Start the Vite development server:
   ```bash
   npm run dev
   ```
   - Open browser: [http://localhost:5173](http://localhost:5173)
4. Build for production:
   ```bash
   npm run build
   ```

---

### 3.3 Flutter Mobile Application

1. Navigate to the mobile directory:
   ```bash
   cd mobile
   ```
2. Fetch Flutter packages:
   ```bash
   flutter pub get
   ```
3. Run on connected Android device or emulator:
   ```bash
   flutter run
   ```

> **Note on Backend Base URL for Mobile Devices**:
> - **Android Emulator**: Uses `http://10.0.2.2:8000/api/v1` (configured as default in `api_client.dart`).
> - **iOS Simulator / Desktop / Web**: Uses `http://localhost:8000/api/v1`.
> - **Physical Phone via Wi-Fi/LAN**: Replace with your local machine's LAN IP address (e.g. `http://192.168.1.100:8000/api/v1`).

---

## 4. Running Automated Tests

### Backend Test Suite (Pytest)
```bash
cd backend
python -m pytest tests -v
```
*Executes 15 comprehensive unit & integration tests covering area conversion mathematics, geometric plot area, registration fee calculations, user authentication, token refresh rotation, and land search provider labels.*

### Mobile Test Suite (Flutter Test)
```bash
cd mobile
flutter test
```
*Executes unit conversion precision tests (cents, grounds, acres, hectares, square yards) and smoke test verification of the root application widget hierarchy.*

### Admin Dashboard TypeScript & Build Verification
```bash
cd admin
npm run build
```

---

## 5. Docker Compose Orchestration

To run the full stack (PostgreSQL, FastAPI Backend, React Admin) with a single command:

```bash
docker compose up --build -d
```

- **FastAPI Backend**: [http://localhost:8000/docs](http://localhost:8000/docs)
- **Admin Portal**: [http://localhost:5173](http://localhost:5173)
- **PostgreSQL**: `localhost:5432`

To shut down containers and maintain persistent database storage:
```bash
docker compose down
```

### Production Cloud Deployment (Render, Railway, VPS)
For step-by-step instructions on deploying the backend to **Render.com** (1-Click Blueprint with free PostgreSQL), **Railway.app**, or an **Ubuntu VPS**:
👉 See [docs/deployment-guide.md](file:///d:/Tn%20land%20app/docs/deployment-guide.md)

---


## 6. Android APK Build Instructions

To build a release Android APK:

1. Ensure the Android SDK and command-line tools are configured in your Flutter environment:
   ```bash
   flutter doctor
   ```
2. Navigate to `mobile/`:
   ```bash
   cd mobile
   ```
3. Build the release APK:
   ```bash
   flutter build apk --release
   ```
4. The generated APK will be available at:
   `mobile/build/app/outputs/flutter-apk/app-release.apk`

---

## 7. Compliance, Official Services & Integration Checklist

| Capability | Current Status in TN LandMate | Official Department Portal |
| :--- | :--- | :--- |
| **Land Area Mathematics** | Fully Offline & Autonomous | N/A (Standard revenue definitions) |
| **Patta / Chitta** | Authorized Redirect + Demo Dataset | [eservices.tn.gov.in](https://eservices.tn.gov.in/eservicesnew/land/chitta.html) |
| **A-Register** | Educational Guide + Official Redirect | [eservices.tn.gov.in](https://eservices.tn.gov.in/eservicesnew/land/areg.html) |
| **FMB Sketch** | Interactive Zoom Canvas + Direct Link | [eservices.tn.gov.in](https://eservices.tn.gov.in/eservicesnew/land/fmb.html) |
| **Guideline Value** | Cached Registry + TNREGINET Redirect | [tnreginet.gov.in](https://tnreginet.gov.in) |
| **Encumbrance (EC)** | Educational Guide + TNREGINET Link | [tnreginet.gov.in](https://tnreginet.gov.in) |
| **AI Assistant** | Offline Knowledge Base + Guardrails | Configurable via `AI_API_KEY` in `.env` |

> [!IMPORTANT]
> **Data Integrity Notice**: TN LandMate does not invent or fabricate live government land titles. In accordance with Tamil Nadu regulatory policies, demo records in development are explicitly watermarked `[DEMO RECORD]`, and users are directly guided to the Government of Tamil Nadu e-Services portals for certified, legally binding verification.
