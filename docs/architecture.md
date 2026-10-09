# TN LandMate - System Architecture Specification

## 1. Executive Summary & Product Overview
**TN LandMate** is a production-oriented Tamil Nadu land and property utility platform. It empowers citizens, property buyers, sellers, surveyors, and legal professionals to:
- Perform offline land measurement conversions and geometric plot area calculations (Sq.ft, Cents, Grounds, Acres, Hectares, Sq.m, Sq.yd).
- Explore authorized Tamil Nadu land record hierarchies (Districts -> Taluks -> Revenue Villages -> Survey Numbers -> Subdivisions).
- Understand vital land documents (Patta, Chitta, A-Register, FMB, Encumbrance Certificate, Sale Deed) in both **English** and **Tamil (தமிழ்)**.
- Query guideline values with effective-date tracking and official transparency disclaimers.
- Estimate stamp duty and registration charges via a configurable, effective-dated rules engine.
- Save and organize property portfolios locally (offline-first) with cloud sync for authenticated users.
- Interact with an AI Land Document Assistant for terminology, checklists, and document field extraction with strict fallback and privacy isolation.

---

## 2. Monorepo Organization

```
tn-landmate/
├── mobile/                    # Flutter 3.x application (Android / iOS / Web)
│   ├── lib/
│   │   ├── core/              # Config, theme, routing, network, storage, l10n
│   │   ├── features/          # Domain-driven feature modules
│   │   └── shared/            # Reusable UI widgets, badges, models
│   └── test/                  # Unit and widget test suite
├── backend/                   # FastAPI Python 3.12+ backend
│   ├── app/
│   │   ├── api/v1/            # Versioned API routes
│   │   ├── core/              # Config, security, JWT, rate limiting
│   │   ├── db/                # SQLAlchemy session & base
│   │   ├── models/            # Normalized SQL tables
│   │   ├── schemas/           # Pydantic v2 schemas
│   │   ├── services/          # Business logic & calculation engines
│   │   ├── repositories/      # Database access layer
│   │   └── integrations/      # Provider abstraction for Land Records & AI
│   ├── alembic/               # Database migrations
│   ├── tests/                 # Pytest test suite
│   ├── requirements.txt
│   └── Dockerfile
├── admin/                     # React 18 + TypeScript + Vite Admin Dashboard
│   ├── src/
│   │   ├── components/        # Layout, forms, modals, tables
│   │   ├── pages/             # Management screens (Rules, Guidelines, Guides, Data)
│   │   ├── services/          # API client with Axios
│   │   └── types/             # TS data contracts
│   ├── package.json
│   └── Dockerfile
├── infrastructure/            # Production / staging docker configs & CI workflows
├── docker-compose.yml         # Local development orchestrator
├── .env.example               # Environment variables template
├── README.md
└── docs/                      # Technical specifications & checklists
```

---

## 3. Technology Stack Breakdown

| Tier | Primary Technologies | Key Libraries & Tooling |
| :--- | :--- | :--- |
| **Mobile** | Flutter 3.38+, Dart 3.10+ | `flutter_riverpod`, `go_router`, `dio`, `flutter_secure_storage`, `shared_preferences`, `intl`, `flutter_localizations` |
| **Backend** | Python 3.12 / 3.13, FastAPI | `sqlalchemy` 2.x, `pydantic` v2, `alembic`, `python-jose`, `passlib[bcrypt]`, `httpx`, `pytest` |
| **Database** | PostgreSQL 16 (SQLite fallback for tests/zero-dep dev) | Normalized tables, composite indexes, JSONB for metadata |
| **Admin UI** | React 19 / 18, TypeScript, Vite | Modern CSS / Tailwind CSS, Lucide Icons, Axios, React Router |
| **DevOps** | Docker, Docker Compose | Multi-stage Docker builds, health checks, GitHub Actions CI |

---

## 4. Architectural Patterns & Domain Layering

### 4.1 Mobile Architecture (Flutter)
Adheres to Clean Architecture and Feature-First modularization:
- **Presentation Layer**: Riverpod `StateNotifierProvider` or `NotifierProvider`, pure declarative widgets, localized strings using `AppLocalizations` (`en`, `ta`).
- **Domain Layer**: Immutable entity models, calculation algorithms (offline-first math in pure Dart).
- **Data Layer**: Repositories abstracting local storage (`shared_preferences` / secure storage) and remote HTTP endpoints via `Dio` client with auto-refresh token interceptors.

### 4.2 Backend Architecture (FastAPI)
- **API Routers (`/api/v1`)**: Thin controllers handling request validation, query parameters, and OpenAPI response definitions.
- **Service Layer**: Pure business logic (e.g. `RegistrationCostEngine`, `PlotAreaEngine`, `LandRecordProviderManager`).
- **Repository Layer**: CRUD operations utilizing SQLAlchemy 2.0 select statements.
- **Security & Middleware**: CORS, Rate limiting, JWT bearer tokens with refresh token rotation and revocation table.

### 4.3 Land Record Provider Abstraction & Real-Time Data Flow
To ensure regulatory compliance while delivering authentic real-time data:
1. **Interactive In-App Live Government Portal (Real-Time Mode)**:
   - Uses embedded `webview_flutter` directly displaying Government of Tamil Nadu Revenue & Registration Department servers (`eservices.tn.gov.in` and `tnreginet.gov.in`).
   - Equipped with a **Floating Smart Assistant** that retains the user's selected District, Taluk, Village, Survey No, and Subdivision on-screen with one-tap copy shortcuts.
   - Solves the official government image CAPTCHA in real-time, fetching authentic, legally binding, digitally signed records.
   - Includes **"Import to Portfolio"** action allowing users to save the verified property directly into their LandMate portfolio.
2. **Authorized Official API**: Enabled seamlessly when enterprise or departmental credentials (`TNEGA_CLIENT_ID`, `TNEGA_API_KEY`) are configured.
3. **Licensed/Static Dataset**: Pre-compiled verified datasets with clear source attribution and last-updated date.
4. **User-Entered Records**: Allows landowners to store their own survey details locally/privately.
5. **Official Direct Portals**:
   - Patta/Chitta: `https://eservices.tn.gov.in/eservicesnew/land/chitta.html`
   - A-Register: `https://eservices.tn.gov.in/eservicesnew/land/areg.html`
   - FMB: `https://eservices.tn.gov.in/eservicesnew/land/fmb.html`
   - Tnreginet Guideline: `https://tnreginet.gov.in/portal/`
   - EC Search: `https://tnreginet.gov.in/`
All demo data in development mode is stamped with `is_demo=True` and clear visual flags.

---

## 5. Security, Privacy & Integrity Guardrails
1. **No Fake Data Claiming Official Status**: Any test record is explicitly labeled `[DEMO RECORD]`.
2. **Offline Resilience**: Area and plot calculations execute entirely locally on device without network roundtrips.
3. **Effective-Dated Rules**: Stamp duty and registration rates are never hardcoded; they reference time-bounded rule records (`effective_from`, `effective_to`, `jurisdiction`).
4. **Zero Secret Leakage**: All keys and database URLs reside in `.env`.
5. **AI Assistant Graceful Degradation**: If no OpenAI/Gemini/Anthropic API key is provided, the backend returns a structured educational disclaimer mode rather than failing with 500 errors.

---

## 6. Real-Time Live Government Portal Extraction Architecture
To allow users to view live Tamil Nadu revenue records directly inside the native Flutter mobile UI while respecting the official portal's security (anti-bot CAPTCHAs, dynamic `rno` session tokens, and cookie validation):

1. **Session & CAPTCHA Relay Gateway**:
   - `POST /api/v1/land/live/session`: Backend accesses `https://eservices.tn.gov.in/eservicesnew/index.html` with browser headers, fetches session cookies and `ajax_rno`, requests the live Base64 CAPTCHA (`ajax.html?page=CaptchaArith`), and returns `{ session_id, captcha_image_base64 }`.
   - If the government server rate-limits or resets connection (10054/500), an intelligent fallback challenge is provided with high-contrast Base64 image so development and testing proceed uninterrupted.
2. **Native Mobile Modal Dialog**:
   - Flutter displays the official Base64 CAPTCHA image with a Refresh option and input field.
3. **Form Submission & Response Parsing**:
   - `POST /api/v1/land/live/fetch`: Submits the user-typed CAPTCHA and survey details with active session cookies to `https://eservices.tn.gov.in/eservicesnew/land/chittaExtract_en.html`.
   - `BeautifulSoup` parses the HTML extract tables (Owner Name in Tamil & English, Patta Number, Land Classification, and Area in Hectares/Ares/Cents).
4. **Native In-App Rendering**:
   - Flutter renders the live record directly on `LandSearchScreen` with a glowing green `LIVE OFFICIAL GOVT DATA` badge, official reference code, and instant 1-tap actions to save to portfolio or estimate stamp duty.

