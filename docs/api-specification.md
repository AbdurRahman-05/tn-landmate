# TN LandMate - API Specification (v1)

Base URL: `/api/v1`

---

## 1. Authentication & Users

### POST `/auth/register`
Creates a new citizen or surveyor account.
- **Request Body**:
  ```json
  {
    "email": "user@example.com",
    "password": "SecurePassword123!",
    "full_name": "Karthik Subramanian",
    "phone": "+919876543210",
    "preferred_language": "ta"
  }
  ```
- **Response `201 Created`**:
  ```json
  {
    "user": { "id": "uuid", "email": "user@example.com", "full_name": "Karthik Subramanian", "role": "citizen" },
    "access_token": "jwt...",
    "refresh_token": "jwt...",
    "token_type": "bearer"
  }
  ```

### POST `/auth/login`
- **Request Body**:
  ```json
  {
    "username": "user@example.com",
    "password": "SecurePassword123!"
  }
  ```
- **Response `200 OK`**:
  ```json
  {
    "access_token": "jwt...",
    "refresh_token": "jwt...",
    "token_type": "bearer",
    "user": { ... }
  }
  ```

### POST `/auth/refresh`
Rotates refresh tokens and returns a fresh short-lived access token.
- **Request Body**: `{ "refresh_token": "jwt..." }`
- **Response `200 OK`**: `{ "access_token": "jwt...", "refresh_token": "jwt..." }`

### POST `/auth/logout`
Revokes active refresh token.

### GET `/auth/me`
Returns active user profile.

---

## 2. Geographic Hierarchy

### GET `/districts`
Returns list of revenue districts in Tamil Nadu (e.g. Chennai, Coimbatore, Madurai, Tiruchirappalli, Chengalpattu, etc.).
- **Response `200 OK`**:
  ```json
  [
    { "id": 1, "name_en": "Chennai", "name_ta": "சென்னை", "code": "CHN" },
    { "id": 2, "name_en": "Coimbatore", "name_ta": "கோயம்புத்தூர்", "code": "CBE" }
  ]
  ```

### GET `/taluks?district_id={id}`
Returns taluks within a specific district.

### GET `/villages?taluk_id={id}`
Returns revenue villages within a specific taluk.

### GET `/sub-registrar-offices?district_id={id}`
Returns registration offices (SROs) for guideline value lookups.

---

## 3. Land Record Search & Integrations

### POST `/land/search`
Queries land record info based on hierarchy and survey numbers.
- **Request Body**:
  ```json
  {
    "district_id": 1,
    "taluk_id": 3,
    "village_id": 12,
    "survey_number": "104",
    "subdivision_number": "2B",
    "record_type": "patta_chitta"
  }
  ```
- **Response `200 OK`**:
  ```json
  {
    "status": "success",
    "provider_type": "licensed_dataset_or_demo",
    "is_demo": true,
    "disclaimer": "This is a demonstration record for development validation. For legally verified records, consult https://eservices.tn.gov.in.",
    "official_url": "https://eservices.tn.gov.in/eservicesnew/land/chitta.html",
    "record": {
      "patta_number": "1420",
      "owner_name_en": "S. Murugan",
      "owner_name_ta": "எஸ். முருகன்",
      "land_type": "நன்செய் (Wet Land)",
      "extent_hectares": 0.405,
      "extent_cents": 100.0,
      "fmb_available": true
    }
  }
  ```

### POST `/land/live/session`
Initiates a real-time session with `eservices.tn.gov.in`, retrieves session cookies and Base64 CAPTCHA challenge.
- **Request Body**:
  ```json
  {
    "district_id": 1,
    "taluk_id": 1,
    "village_id": 1,
    "survey_number": "104",
    "subdivision_number": "2B"
  }
  ```
- **Response `200 OK`**:
  ```json
  {
    "session_id": "uuid4",
    "is_live_portal": true,
    "portal_name": "TN Revenue e-Services (eservices.tn.gov.in)",
    "captcha_image_base64": "iVBORw0KGgo...",
    "captcha_type": "arithmetic",
    "challenge_text": "Enter characters shown in the CAPTCHA image",
    "expires_in_seconds": 180,
    "message": "Live session established directly with Tamil Nadu Revenue portal."
  }
  ```

### POST `/land/live/fetch`
Submits user-entered CAPTCHA to the official portal, parses HTML table extracts, and returns structured data directly to the native mobile UI.
- **Request Body**:
  ```json
  {
    "session_id": "uuid4",
    "captcha_value": "8429",
    "district_id": 1,
    "taluk_id": 1,
    "village_id": 1,
    "survey_number": "104",
    "subdivision_number": "2B",
    "district_name": "Chennai",
    "taluk_name": "Ambattur",
    "village_name": "Ambattur"
  }
  ```
- **Response `200 OK`**:
  ```json
  {
    "success": true,
    "message": "Live Government Data extracted successfully",
    "is_live_portal": true,
    "source_portal": "https://eservices.tn.gov.in/eservicesnew/land/chitta.html",
    "fetched_at": "2026-10-09 17:05:00",
    "official_reference_number": "TN-GOV-104-2B-3924",
    "disclaimer": "Live official extract retrieved from Government of Tamil Nadu Revenue e-Services.",
    "record": {
      "patta_number": "3924",
      "owner_name_en": "M. Rajendran & R. Kavitha",
      "owner_name_ta": "மு. ராஜேந்திரன் & ரா. கவிதா",
      "land_type": "நத்தம் மனை (Grama Natham Residential)",
      "extent_hectares": 0.0223,
      "extent_ares": 2.23,
      "extent_cents": 5.51,
      "extent_sq_ft": 2400.0,
      "fmb_sketch_url": "https://eservices.tn.gov.in/..."
    }
  }
  ```


### GET `/land/sources`
Returns available sources and their operational status and verification timestamps.

---

## 4. Calculators

### POST `/calculators/area-conversion`
Pure math area conversion across all standard TN and metric units.
- **Request Body**:
  ```json
  {
    "value": 5.0,
    "from_unit": "cents"
  }
  ```
- **Response `200 OK`**:
  ```json
  {
    "square_feet": 2178.0,
    "cents": 5.0,
    "grounds": 0.9075,
    "acres": 0.05,
    "hectares": 0.02023,
    "square_meters": 202.34,
    "square_yards": 242.0
  }
  ```

### POST `/calculators/plot-area`
Computes area from geometric dimensions (Rectangle, Triangle, Trapezoid, L-shape/composite).
- **Request Body**:
  ```json
  {
    "shape": "trapezoid",
    "unit": "feet",
    "dimensions": {
      "parallel_side_a": 60,
      "parallel_side_b": 40,
      "height": 50
    }
  }
  ```
- **Response `200 OK`**:
  ```json
  {
    "shape": "trapezoid",
    "square_feet": 2500.0,
    "cents": 5.739,
    "grounds": 1.041,
    "acres": 0.0574,
    "disclaimer": "Estimated geometric area. Real-world boundaries are subject to physical survey."
  }
  ```

### POST `/calculators/registration-estimate`
Computes stamp duty, registration fee, and total acquisition estimate based on effective-dated rates.
- **Request Body**:
  ```json
  {
    "transaction_type": "sale",
    "property_category": "residential_plot",
    "market_or_guideline_value": 3500000.0,
    "jurisdiction": "chennai_corporation"
  }
  ```
- **Response `200 OK`**:
  ```json
  {
    "stamp_duty_rate_percent": 7.0,
    "stamp_duty_amount": 245000.0,
    "registration_fee_rate_percent": 2.0,
    "registration_fee_amount": 70000.0,
    "total_government_charges": 315000.0,
    "estimated_total_cost": 3815000.0,
    "rule_applied": "TN Registration Department Rates 2024",
    "effective_from": "2024-04-01",
    "disclaimer": "Informational estimate based on configured rates. Actual fee is determined by the registering authority at the SRO."
  }
  ```

---

## 5. Guideline Values

### GET `/guideline-values?village_id=...&street_name=...`
Returns guideline value history, unit of measure, and effective date.

---

## 6. Property Management (User Portfolio)

- `GET /properties`: List user's saved properties.
- `POST /properties`: Create a saved property.
- `GET /properties/{id}`: Retrieve property details + notes.
- `PATCH /properties/{id}`: Update property fields.
- `DELETE /properties/{id}`: Delete property.

---

## 7. Document Guides & AI Assistant

- `GET /documents/guides`: List educational guides (Patta, Chitta, A-Register, FMB, EC, Sale Deed).
- `GET /documents/guides/{slug}`: Read specific guide with bilingual content and legal checklist.
- `POST /ai/ask`: Educational land terminology query & FAQ assistant.
- `POST /ai/extract-document`: Simulated or real OCR extraction for survey numbers and extents.

---

## 8. Administration Endpoints (Admin Role Required)

- `GET /admin/stats`: Summary counts of districts, villages, rules, users, and audit logs.
- `POST /admin/calculator-rules`: Create/update effective-dated registration rules.
- `POST /admin/guideline-values/import`: CSV or JSON import of guideline datasets with validation.
- `PUT /admin/document-guides/{id}`: Update bilingual guidance content.
