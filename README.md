# PARAKH (परख)
 
### Smart Compliance Verification for Packaged Commodities
 
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.128+-009688?logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![Python](https://img.shields.io/badge/Python-3.11+-3776AB?logo=python&logoColor=white)](https://www.python.org)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15+-4169E1?logo=postgresql&logoColor=white)](https://www.postgresql.org)
[![OpenCV](https://img.shields.io/badge/OpenCV-5.x-5C3EE8?logo=opencv&logoColor=white)](https://opencv.org)
[![NVIDIA Nemotron](https://img.shields.io/badge/OCR-NVIDIA%20Nemotron%20V2-76B900?logo=nvidia&logoColor=white)](https://developer.nvidia.com)
[![Smart India Hackathon](https://img.shields.io/badge/SIH-orange)](https://www.sih.gov.in)
 
---
 
## 📌 Overview
 
**PARAKH (परख)** — Hindi for *"to test"* or *"to verify"* — is an end-to-end digital inspection and enforcement platform built for the **Legal Metrology Department, Ministry of Consumer Affairs, Food & Public Distribution, Government of India**.
 
Under the **Legal Metrology (Packaged Commodities) Rules, 2011**, every pre-packaged commodity sold in India must carry mandatory statutory declarations — MRP inclusive of all taxes, net quantity, manufacturing and expiry dates, consumer care contact details, and manufacturer/importer information.
 
Today, verifying these declarations is largely a manual, paper-driven process: slow, inconsistent across inspectors, and difficult to audit. PARAKH replaces that workflow with an automated pipeline — combining computer vision, OCR, visual-language understanding, and a deterministic rules engine — that:
 
1. **Authenticates** the inspector and creates an inspector-scoped inspection record.
2. **Captures** multi-angle packaging photos (Front, Back, Top, Bottom) through a guided Flutter camera flow.
3. **Validates image quality and integrity** — rejecting glare, blur, and skew, and fingerprinting every original image before any processing.
4. **Extracts text and visual context** using OCR combined with vision-language model (VLM) understanding.
5. **Identifies and disambiguates entities** (MRP, net quantity, dates, manufacturer, consumer care, country of origin) via NER and contextual extraction.
6. **Cross-verifies findings** through a multi-agent verification stage that flags conflicting or uncertain data for review.
7. **Evaluates compliance deterministically** against an applicability engine and the Legal Metrology Rules Engine, with per-clause findings tied to evidence.
8. **Seals the final decision and report** with canonical SHA-256 fingerprints, producing a tamper-evident, version-tracked, court-admissible record.
## 🎯 Why PARAKH
 
| Manual Inspection Today | With PARAKH |
|:---|:---|
| Paper checklists, inconsistent across inspectors | Standardized, rule-driven scoring for every product |
| No image quality control — blurry or glared photos slip through | Automated CV quality gate rejects unusable images at capture time |
| Front/back label data easily mixed up during manual review | OCR + VLM + NER pipeline correctly attributes each field to its source face and context |
| Findings taken at face value with no cross-checking | Multi-agent verification flags conflicting or uncertain extractions for REVIEW |
| Reports can be edited after the fact with no audit trail | SHA-256 sealed records are tamper-evident, with versioned hashes on any decision change |
| Inspection numbering is ad hoc | Inspector-scoped, sequential, auditable numbering |
 
---
 
## 🏛️ System Architecture & Technical Flow
 
```mermaid
flowchart TD
    subgraph Auth["1️⃣ Login & Authentication"]
        A[Inspector Login - Flutter/Dart] --> A2[FastAPI + JWT Auth]
        A2 --> A3[bcrypt Password Hashing]
        A3 --> A4[(PostgreSQL via SQLAlchemy)]
    end
 
    subgraph Create["2️⃣ Create Inspection"]
        A4 --> B[REST API Creates Inspection Record]
        B --> B2[Linked to Authenticated Inspector]
    end
 
    subgraph Capture["3️⃣ Capture Package"]
        B2 --> C[Flutter Camera / Image Picker]
        C --> C2[Front / Back / Top / Bottom Faces]
        C2 --> C3[(Cloudinary - Image Storage)]
        C2 --> C4[(PostgreSQL - Metadata & Linkage)]
    end
 
    subgraph QualityGate["4️⃣ Image Analysis & Integrity"]
        C3 --> D[OpenCV Quality Checks]
        D -->|Blur / Glare / Perspective| D2{Quality Valid?}
        C3 --> D3[SHA-256 Fingerprint of Original Bytes]
    end
 
    subgraph StartAnalysis["5️⃣ Start Analysis"]
        D2 -->|Pass| E[Inspector Triggers Analysis]
        E --> E2[FastAPI Processes All Active Images]
    end
 
    subgraph OCRStage["6️⃣ OCR + Visual Understanding"]
        E2 --> F[NVIDIA Nemotron OCR V2]
        F --> F2[Text + Confidence + Bounding Boxes]
        E2 --> F3[VLM Visual Context Understanding]
    end
 
    subgraph NERStage["7️⃣ NER & Contextual Extraction"]
        F2 --> G[Named Entity Recognition]
        F3 --> G
        G --> G2[MRP / Net Qty / Dates / Manufacturer / Consumer Care / Origin]
        G2 --> G3[Contextual Disambiguation - e.g. Serving Size vs Net Qty]
    end
 
    subgraph MultiAgent["8️⃣ Multi-Agent Verification"]
        G3 --> H[Cross-Check Image + Text + Entities + Context]
        H -->|Conflict / Low Confidence| H2[Flag for REVIEW]
        H -->|Consistent| H3[Confirmed Structured Declarations]
    end
 
    subgraph RulesEngine["9️⃣ Legal Metrology Verification"]
        H3 --> I[Applicability Engine]
        I --> I2[Deterministic Rule 6 Compliance Engine]
        I2 --> I3[Per-Clause Findings]
    end
 
    subgraph InspectorReview["🔟 Evidence & Inspector Review"]
        I3 --> J[Findings Linked to Evidence & Requirement]
        J --> J2[Inspector Reviews / Corrects Extractions]
        J2 --> J3{Decision: PASS / FAIL / REVIEW}
    end
 
    subgraph Finalize["1️⃣1️⃣ Finalization & Security"]
        J3 --> K[Canonical SHA-256 Hash of Finalized Record]
        K --> K2[Decision Versioning on Later Changes]
    end
 
    subgraph ReportGen["1️⃣2️⃣ Report Generation"]
        K2 --> L[ReportLab PDF Generation]
        L --> L2[Product, Declarations, Findings, Rules, Evidence, Decision]
        L2 --> L3[Independent SHA-256 Hash of Final PDF]
    end
```
 
---
 
## ✨ Key Features
 
### 🔐 1. Login & Authentication
- Flutter/Dart frontend authenticates against a FastAPI backend using **JWT** (OAuth2 bearer flow, `python-jose`).
- Passwords are hashed with salted **bcrypt** (`passlib`) — never stored in plaintext.
- Inspector records and sessions are managed in **PostgreSQL** via **SQLAlchemy 2.0**.
### 🆕 2. Inspection Creation
- REST endpoints create a new inspection record and bind it to the authenticated inspector's session — no cross-account data leakage.
### 📸 3. Guided Multi-Angle Capture
- Comprehensive scanning coverage across **Front**, **Back**, **Top**, and **Bottom** faces using Flutter's Camera and Image Picker APIs.
- Captured images are uploaded to **Cloudinary** (encrypted evidence hosting); metadata and the image-to-inspection relationship are persisted in PostgreSQL.
### 🔍 4. Automated Image Quality & Integrity Gate
- **Blur Detection** — Laplacian variance scoring rejects unreadable, out-of-focus captures.
- **Specular Glare Analysis** — HSV reflection profiling flags bright reflections on glossy laminates and foil pouches.
- **Perspective Rectangularity** — geometric contour analysis measures surface skew and tilt, all via **OpenCV**.
- **Pre-processing Integrity Fingerprint** — the original image bytes are hashed with **SHA-256** *before* any enhancement or further processing, establishing an unbroken chain of evidence.
### ▶️ 5. Inspector-Triggered Analysis
- Analysis begins only once the inspector explicitly starts it after the required faces are collected.
- The FastAPI backend then batch-processes every active image belonging to that inspection.
### 🧠 6. OCR + Visual-Language Understanding
- Text extraction is powered by **NVIDIA Nemotron OCR V2**, returning text, confidence scores, and spatial bounding boxes.
- OCR output is fused with **VLM (Vision-Language Model)**-based visual understanding so the system reasons about packaging layout and context, not just raw text.
### 🏷️ 7. NER & Contextual Extraction
- **Named Entity Recognition** classifies extracted text into statutory categories — MRP, net quantity, manufacture/expiry dates, manufacturer/importer, consumer care, and country of origin.
- **Contextual extraction** disambiguates visually similar values (e.g., distinguishing a *serving size* from the actual *net quantity* declaration).
### 🕵️ 8. Multi-Agent Verification
- A multi-agent verification architecture cross-checks image evidence, extracted text, resolved entities, and surrounding context against each other.
- Conflicting or low-confidence findings are flagged for **REVIEW** rather than silently accepted.
### ⚖️ 9. Applicability & Legal Metrology Rules Engine
Structured, verified declarations are passed through an **applicability engine** (determines which statutory clauses apply to the given commodity) and then a **deterministic Rules Engine** evaluating the **Legal Metrology (Packaged Commodities) Rules, 2011**. AI performs perception and interpretation; the rules engine performs the actual compliance evaluation — keeping the legal decision deterministic and auditable.
 
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
 
### 🧾 10. Evidence-Linked Inspector Review
- Every finding is traceable to its supporting package image and the specific statutory requirement it evaluates.
- The inspector reviews and can correct extracted information before recording the final **PASS**, **FAIL**, or **REVIEW** decision — with a mandatory audit justification for any override.
### 👮 11. Inspector-Scoped Numbering, Finalization & Decision Versioning
- **Sequential inspection numbering** — every inspector has their own sequence, prefixed with their official badge (e.g. `LM-DL-2026-001-0001`, `LM-DL-2026-001-0002`).
- On finalization, PARAKH generates a **canonical SHA-256 integrity hash** over the finalized inspection record.
- If a decision is later changed, a **new decision version** is created with its own corresponding integrity hash — preserving full history rather than overwriting it.
### 📄 12. Cryptographically Sealed Report Generation
- The inspection report is generated with **ReportLab**, including product details, statutory declarations, findings, applicable rules, linked evidence, and the inspector's decision.
- The formatted PDF (following Government of India guidelines, including the Ashoka Lion emblem and structured finding tables) receives its own **independent SHA-256 hash**, sealing the generated document itself.
---
 
## 🛠️ Technology Stack
 
| Layer | Technologies |
|:---|:---|
| **Mobile Client** | Flutter 3.x, Dart, Dio, Provider/Service pattern, Camera API, Image Picker, Shared Preferences, Intl |
| **Backend Framework** | FastAPI (Python 3.11+), Uvicorn, Pydantic v2 |
| **Database & ORM** | PostgreSQL 15+, SQLAlchemy 2.0 (psycopg3) |
| **Image Quality (CV)** | OpenCV (cv2), NumPy — blur, glare, and perspective/skew detection |
| **OCR** | NVIDIA Nemotron OCR V2 — text, confidence scores, spatial bounding boxes |
| **Visual Understanding** | Vision-Language Model (VLM) for packaging layout & visual context reasoning |
| **Entity & Context Extraction** | NER pipeline + contextual disambiguation heuristics |
| **Verification** | Multi-agent verification architecture (cross-checks image, text, entity & context signals) |
| **Compliance Logic** | Applicability Engine + deterministic Legal Metrology Rules Engine (Rule 6) |
| **Document Engine** | ReportLab (vector PDF generation) |
| **Cloud Storage** | Cloudinary (secure, encrypted evidence hosting) |
| **Integrity & Security** | SHA-256 canonical hashing (image, decision, and report level), OAuth2 / JWT (`python-jose`), Passlib (bcrypt) |
 
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
│   │   ├── rules/                   # Applicability engine & Legal Metrology rule evaluators
│   │   ├── vision/                  # OpenCV quality gate, OCR & VLM integration
│   │   ├── nlp/                     # NER & contextual entity extraction
│   │   ├── verification/            # Multi-agent verification stage
│   │   ├── schemas/                 # Pydantic request/response schemas
│   │   └── services/                # Hash sealing, decision versioning, PDF generation
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
| NVIDIA Nemotron OCR V2 access | API key / endpoint for OCR + VLM calls |
 
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
NEMOTRON_OCR_API_KEY=your_nemotron_ocr_key
NEMOTRON_OCR_ENDPOINT=your_nemotron_ocr_endpoint
```
 
Install dependencies and start the server:
 
```bash
uv sync
uv run python run.py
```
 
The backend starts on port `8000`. Interactive Swagger docs are available at `http://localhost:8000/docs`.
 
> ⚠️ **Note:** Never commit your `.env` file or real Cloudinary/JWT/Nemotron credentials. Add `.env` to `.gitignore` and rotate `JWT_SECRET_KEY` before any production deployment.
 
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
 
# Target a specific device (e.g. iPhone / Android using USB)
flutter run -d <DEVICE_ID>
```
 
---
 
## 📡 API Reference
 
Once the backend is running, full interactive documentation is available at:
 
- **Swagger UI** — `http://localhost:8000/docs`
- **ReDoc** — `http://localhost:8000/redoc`
### Authentication
 
| Method | Endpoint | Purpose |
|:---|:---|:---|
| `POST` | `/api/auth/signup` | Register a new inspector |
| `POST` | `/api/auth/login` | Inspector login, issues JWT |
| `GET` | `/api/auth/me` | Get current authenticated inspector |
| `GET` | `/api/auth/approved-test` | Verify inspector approval status |
| `GET` | `/api/auth/inspector-access-test` | Verify inspector-scoped access |
 
### Admin
 
| Method | Endpoint | Purpose |
|:---|:---|:---|
| `POST` | `/api/admin/login` | Admin login |
| `GET` | `/api/admin/me` | Get current authenticated admin |
| `GET` | `/api/admin/inspector` | List all inspectors |
| `PATCH` | `/api/admin/inspectors/{inspector_id}/approve` | Approve a registered inspector |
| `PATCH` | `/api/admin/inspectors/{inspector_id}/reject` | Reject a registered inspector |
 
### Inspections
 
| Method | Endpoint | Purpose |
|:---|:---|:---|
| `POST` | `/api/inspections/` | Create a new inspection record |
| `POST` | `/api/inspections/{inspection_id}/images` | Upload a package image for the inspection |
| `GET` | `/api/inspections/{inspection_id}/images/status` | Get multi-angle capture status |
| `POST` | `/api/inspections/{inspection_id}/analyze` | Trigger OCR, VLM, NER & multi-agent verification |
| `GET` | `/api/inspections/{inspection_id}` | Get full inspection details |
| `GET` | `/api/inspections/{inspection_id}/declarations` | Get extracted statutory declarations |
| `PUT` | `/api/inspections/{inspection_id}/declarations` | Inspector correction of declarations |
| `GET` | `/api/inspections/{inspection_id}/findings` | Get Rule 6 compliance findings |
| `POST` | `/api/inspections/{inspection_id}/finalize` | Finalize inspection & seal decision (SHA-256) |
| `GET` | `/api/inspections/{inspection_id}/report` | Download the sealed PDF report |
 
### Default
 
| Method | Endpoint | Purpose |
|:---|:---|:---|
| `GET` | `/` | API root / health check |
 
---
 
## 🔒 Security & Privacy
 
- **No plaintext passwords** — inspector passwords are hashed with salted `bcrypt`.
- **Zero-data-leakage architecture** — on logout, all in-memory inspection sessions, tokens, and cached lists are scrubbed from the device.
- **Chain-of-custody image integrity** — every original image is SHA-256 fingerprinted immediately on upload, before any enhancement or AI processing.
- **Tamper-evident decision sealing** — once an inspector finalizes an inspection, its canonical parameters are permanently hashed; any later change creates a new, independently hashed decision version rather than overwriting history.
- **Tamper-evident report sealing** — the generated PDF report is separately SHA-256 hashed, independent of the underlying decision hash.
- **Local network safety** — iOS App Transport Security exceptions are scoped strictly to local debugging networks (`NSAllowsLocalNetworking`) and should be removed for production builds.
---
 
## 🗺️ Roadmap
 
- [ ] Offline-first capture with background sync for low-connectivity field areas
- [ ] Multi-language OCR support for regional-language packaging
- [ ] Analytics dashboard for department-level compliance trends
- [ ] Role-based access control for supervisors and regional officers
---
 
## 📜 License
 
This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
 
---
 
<div align="center">
  <b>Developed for the Smart India Hackathon (SIH)</b><br/>
  <i>National Legal Metrology Digital Transformation Initiative</i><br/>
  <b>Government of India</b>
</div>
