# PARAKH (परख)
 
### AI-Powered Automated Legal Metrology Inspection & Statutory Compliance Platform
 
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.128+-009688?logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![Python](https://img.shields.io/badge/Python-3.11+-3776AB?logo=python&logoColor=white)](https://www.python.org)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15+-4169E1?logo=postgresql&logoColor=white)](https://www.postgresql.org)
[![OpenCV](https://img.shields.io/badge/OpenCV-5.x-5C3EE8?logo=opencv&logoColor=white)](https://opencv.org)
[![Smart India Hackathon](https://img.shields.io/badge/SIH Project-orange)](https://www.sih.gov.in)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
 
---
 
## 📌 Overview
 
**PARAKH (परख)** — Hindi for *"to test"* or *"to verify"* — is an end-to-end digital inspection and enforcement platform built for the **Legal Metrology Department, Ministry of Consumer Affairs, Food & Public Distribution, Government of India**.
 
Under the **Legal Metrology (Packaged Commodities) Rules, 2011**, every pre-packaged commodity sold in India must carry mandatory statutory declarations — MRP inclusive of all taxes, net quantity, manufacturing and expiry dates, consumer care contact details, and manufacturer/importer information.
 
Today, verifying these declarations is largely a manual, paper-driven process: slow, inconsistent across inspectors, and difficult to audit. PARAKH replaces that workflow with an automated computer-vision and AI pipeline that:
 
1. **Captures** multi-angle packaging photos in a guided, real-time flow.
2. **Validates image quality** and rejects glare, blur, skew, or duplicate/reused images before they enter the pipeline.
3. **Extracts statutory declarations** across multiple package faces without conflating front-of-pack and back-of-pack data.
4. **Evaluates compliance deterministically** against Legal Metrology Rules, with per-clause findings.
5. **Seals the final report** with a cryptographic SHA-256 fingerprint, producing a tamper-evident, court-admissible record.
## 🎯 Why PARAKH
 
| Manual Inspection Today | With PARAKH |
|:---|:---|
| Paper checklists, inconsistent across inspectors | Standardized, rule-driven scoring for every product |
| No image quality control — blurry or glared photos slip through | Automated quality gate rejects unusable images at capture time |
| Front/back label data easily mixed up during manual review | Dual-angle OCR correctly attributes each field to its source face |
| Reports can be edited after the fact with no audit trail | SHA-256 sealed reports are tamper-evident by design |
| Inspection numbering is ad hoc | Inspector-scoped, sequential, auditable numbering |
 
---
 
## 🏛️ System Architecture
 
```mermaid
flowchart TD
    subgraph MobileApp["📱 Flutter Field App (iOS / Android)"]
        A[Inspector Login / Auth] --> B[Multi-Angle Package Capture]
        B --> C[Real-Time Orientation & Framing]
        C --> D[Secure Image Upload]
    end
 
    subgraph BackendPipeline["⚙️ Backend Pipeline (FastAPI / OpenCV / AI)"]
        D --> E[Image Quality & Authenticity Gate]
        E -->|Blur / Glare / Perspective / Duplicate Check| F{Quality Valid?}
        F -->|Fail| G[Prompt Retake / Flag Advisory WARN]
        F -->|Pass| H[Dual-Angle OCR & Entity Extraction]
        H --> I[Statutory Rule Compliance Engine]
        I -->|Rule 6 Verification| J[Compliance Findings & Scoring]
    end
 
    subgraph Finalization["🛡️ Verification & Sealing"]
        J --> K[Inspector Review & Discretionary Override]
        K --> L[Inspector Sign-Off]
        L --> M[SHA-256 Canonical Hash Generation]
        M --> N[Official Legal Metrology PDF Report]
        N --> O[Tamper-Proof Audit Trail]
    end
```
 
---
 
## ✨ Key Features
 
### 📸 1. Guided Multi-Angle Capture
- Comprehensive scanning coverage across **Front**, **Back**, **Top**, **Bottom**, **Left**, and **Right** faces.
- On-device guidance ensures optimal alignment, framing, and packaging isolation before an image is accepted.
### 🔍 2. Automated Computer-Vision Quality Gate
- **Blur Detection** — Laplacian variance scoring rejects unreadable, out-of-focus captures.
- **Specular Glare Analysis** — HSV reflection profiling flags bright reflections on glossy laminates and foil pouches.
- **Perspective Rectangularity** — Geometric contour analysis measures surface skew and tilt.
- **Image Authenticity & Anti-Fraud** — SHA-256 fingerprinting prevents cross-angle photo reuse or duplicate uploads.
### 🧠 3. Dual-Angle OCR & Entity Fusion
- Resolves the common problem of front-of-pack (brand, quantity) and back-of-pack (MRP, batch, manufacturer, consumer care) data getting conflated.
- Maps extracted text to the correct statutory declaration category using purpose-built heuristic and regex parsers.
### ⚖️ 4. Rule 6 Statutory Compliance Engine
Evaluates packaged commodities against the **Legal Metrology (Packaged Commodities) Rules, 2011**:
 
| Rule Reference | Statutory Obligation | Automated Check |
|:---|:---|:---|
| **Rule 6(1)(a)** | Manufacturer / Packer / Importer identity & address | Verifies complete entity name and physical address |
| **Rule 6(1)(b)** | Generic or common name of commodity | Extracts and classifies against commodity taxonomies |
| **Rule 6(1)(c)** | Net quantity in standard SI units (kg, g, L, mL, N) | Validates unit and numeral formatting |
| **Rule 6(1)(d)** | Month and year of manufacture / packing | Validates format (`MM/YYYY` or `MMM YYYY`) |
| **Rule 6(1)(da)** | Expiry date / best-before period | Verifies expiration and shelf-life clarity |
| **Rule 6(1)(e)** | Maximum Retail Price (MRP) | Verifies price and mandatory *"inclusive of all taxes"* clause |
| **Rule 6(1)(f)** | Consumer care details | Validates phone number, email, and redressal address |
| **Rule 6(1)(g)** | Country of origin | Mandatory detection for all imported products |
 
### 👮 5. Inspector-Scoped Numbering & Account Isolation
- **Sequential inspection numbering** — every inspector has their own sequence, prefixed with their official badge (e.g. `LM-DL-2026-001-0001`, `LM-DL-2026-001-0002`).
- **Complete session isolation** — no cross-account data leakage across logins or shared field devices.
- **Inspector-in-the-loop override** — automated findings can be reviewed and manually adjusted, with a mandatory audit justification recorded for each change.
### 📄 6. Cryptographic Sealing & Tamper-Evident Reports
- **Canonical SHA-256 fingerprint** seals the inspection record, timestamps, and findings together.
- **Court-admissible PDF generation** formatted to Government of India guidelines, including the Ashoka Lion emblem, structured finding tables, and verification metadata.
---
 
## 🛠️ Technology Stack
 
| Layer | Technologies |
|:---|:---|
| **Mobile Client** | Flutter 3.x, Dart, Dio, Provider/Service pattern, Camera API, Shared Preferences, Intl |
| **Backend Framework** | FastAPI (Python 3.11+), Uvicorn, Pydantic v2 |
| **Database & ORM** | PostgreSQL 15+, SQLAlchemy 2.0 (psycopg3) |
| **Computer Vision** | OpenCV (cv2), NumPy |
| **Document Engine** | ReportLab (vector PDF generation) |
| **Cloud Storage** | Cloudinary (secure, encrypted evidence hosting) |
| **Security & Auth** | OAuth2 / JWT (python-jose), Passlib (bcrypt), SHA-256 |
 
---
 
## 📁 Repository Structure
 
```
parakh/
├── lib/                             # Flutter mobile application
│   ├── core/                        # Themes, routes, constants, date utilities
│   │   ├── constants.dart           # API config & base URLs
│   │   ├── date_utils.dart          # UTC-to-local timezone parsing & formatting
│   │   ├── routes.dart              # Application route definitions
│   │   └── theme.dart               # Colors, typography, spacing tokens
│   ├── model/                       # Data models (Inspection, Declarations, Findings)
│   ├── screens/                     # Application screens
│   │   ├── auth/                    # Splash, login, registration
│   │   ├── home/                    # Inspector dashboard & today's activity
│   │   ├── scan/                    # Guided camera, capture review, analysis
│   │   ├── result/                  # Declarations review, evidence trace
│   │   ├── review/                  # Inspector sign-off, finalization
│   │   └── reports/                 # Searchable reports list, PDF view
│   ├── services/                    # API client, auth service, inspection service
│   └── widgets/                     # Reusable UI components & Ashoka emblem
│
├── backend/                         # FastAPI backend
│   ├── app/
│   │   ├── database.py              # PostgreSQL connection & SessionLocal
│   │   ├── models/                  # SQLAlchemy models (Inspector, Inspection, Images)
│   │   ├── routers/                 # API endpoints (Auth, Inspections, Audit)
│   │   ├── rules/                   # Legal Metrology statutory rule evaluators
│   │   ├── schemas/                 # Pydantic request/response schemas
│   │   └── services/                # OCR, quality gates, hash sealing, PDF generation
│   ├── run.py                       # Server entrypoint
│   └── pyproject.toml               # Python dependencies (managed via uv)
│
├── ios/                             # iOS native project & development signing
├── android/                         # Android native project
└── README.md                        # Documentation
```
 
---
 
## 🚀 Getting Started
 
### Prerequisites
 
| Requirement | Version |
|:---|:---|
| Flutter SDK | `^3.12.0` or later |
| Python | `3.11+` |
| [uv](https://github.com/astral-sh/uv) | Latest (fast Python package manager) |
| PostgreSQL | `15+`, running locally or remotely |
 
### 1. Backend Setup
 
```bash
cd backend
```
 
Create a `.env` file in `backend/` with your database and service configuration:
 
```ini
DATABASE_URL=postgresql+psycopg://username:password@localhost:5432/parakh
JWT_SECRET_KEY=your-secure-secret-key
JWT_ALGORITHM=HS256
JWT_EXPIRE_MINUTES=43200
CLOUDINARY_CLOUD_NAME=your_cloudinary_name
CLOUDINARY_API_KEY=your_cloudinary_key
CLOUDINARY_API_SECRET=your_cloudinary_secret
```
 
Install dependencies and start the server:
 
```bash
uv sync
uv run python run.py
```
 
The backend starts on port `8000`. Interactive Swagger docs are available at `http://localhost:8000/docs`.
 
> ⚠️ **Note:** Never commit your `.env` file or real Cloudinary/JWT credentials. Add `.env` to `.gitignore` and rotate `JWT_SECRET_KEY` before any production deployment.
 
### 2. Mobile App Setup
 
```bash
cd ..
flutter pub get
```
 
Configure the API base URL in `lib/core/constants.dart` (or via in-app settings):
 
- **Simulator / Emulator** — point to your active backend host (e.g. `10.0.2.2:8000` for Android emulators).
- **Physical Device** — connect to the same network as your backend workstation and use its LAN IP.
Run the app:
 
```bash
# Run on connected device or simulator
flutter run
 
# Target a specific device (e.g. iPhone over USB)
flutter run -d <DEVICE_ID>
```
 
---
 
## 📡 API Reference
 
Once the backend is running, full interactive documentation is available at:
 
- **Swagger UI** — `http://localhost:8000/docs`
- **ReDoc** — `http://localhost:8000/redoc`
Core endpoint groups exposed by the backend:
 
| Group | Purpose |
|:---|:---|
| `/auth` | Inspector registration, login, and JWT issuance |
| `/inspections` | Create, update, and retrieve inspection records |
| `/inspections/{id}/images` | Upload and validate multi-angle package images |
| `/inspections/{id}/report` | Generate and retrieve the sealed PDF report |
| `/audit` | Query the tamper-evident audit trail |
 
---
 
## 🔒 Security & Privacy
 
- **No plaintext passwords** — inspector passwords are hashed with salted `bcrypt`.
- **Zero-data-leakage architecture** — on logout, all in-memory inspection sessions, tokens, and cached lists are scrubbed from the device.
- **Tamper-evident SHA-256 sealing** — once an inspector finalizes an inspection, its canonical parameters are permanently hashed; any later alteration invalidates the seal.
- **Local network safety** — iOS App Transport Security exceptions are scoped strictly to local debugging networks (`NSAllowsLocalNetworking`) and should be removed for production builds.
---
 
## 🗺️ Roadmap
 
- [ ] Offline-first capture with background sync for low-connectivity field areas
- [ ] Multi-language OCR support for regional-language packaging
- [ ] Analytics dashboard for department-level compliance trends
- [ ] Role-based access control for supervisors and regional officers
---
 
## 🤝 Contributing
 
Contributions, bug reports, and feature suggestions are welcome.
 
1. Fork the repository and create a feature branch.
2. Make your changes with clear, focused commits.
3. Ensure the backend passes its test suite and the Flutter app builds cleanly.
4. Open a pull request describing the change and its motivation.
---
 
## 📜 License
 
This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
 
---
 
<div align="center">
  <b>Developed for the Smart India Hackathon (SIH)</b><br/>
  <i>National Legal Metrology Digital Transformation Initiative</i><br/>
  <b>Government of India</b>
</div>
