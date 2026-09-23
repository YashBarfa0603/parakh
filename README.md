# PARAKH (परख)
### AI-Powered Automated Legal Metrology Inspection & Statutory Compliance Platform

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.128+-009688?logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![Python](https://img.shields.io/badge/Python-3.11+-3776AB?logo=python&logoColor=white)](https://www.python.org)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15+-4169E1?logo=postgresql&logoColor=white)](https://www.postgresql.org)
[![OpenCV](https://img.shields.io/badge/OpenCV-5.x-5C3EE8?logo=opencv&logoColor=white)](https://opencv.org)
[![Smart India Hackathon](https://img.shields.io/badge/SIH-Finalist_Project-orange)](https://www.sih.gov.in)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## 📌 Overview

**PARAKH (परख)** is an end-to-end digital inspection and enforcement solution built for the **Legal Metrology Department, Ministry of Consumer Affairs, Food & Public Distribution, Government of India**.

Under the **Legal Metrology (Packaged Commodities) Rules, 2011**, all pre-packaged goods distributed in India must carry mandatory statutory declarations (such as MRP inclusive of all taxes, net quantity, manufacturing & expiry dates, consumer care contacts, and manufacturer/importer information).

PARAKH replaces slow, manual, and error-prone field audits with an automated computer-vision and AI pipeline capable of:
1. **Verifying multi-angle packaging** in real-time.
2. **Detecting image quality issues** (glare, blur, skew, duplicate reuse).
3. **Extracting statutory declarations** across multiple package faces without confusion.
4. **Evaluating statutory compliance** deterministically against Legal Metrology Rules.
5. **Sealing audit reports** with cryptographic SHA-256 canonical fingerprints.

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
- Comprehensive scanning coverage: **Front**, **Back**, **Top**, **Bottom**, **Left**, and **Right** faces.
- On-device guidance ensures optimal alignment and packaging isolation.

### 🔍 2. Automated Computer-Vision Quality Gate
- **Blur Detection**: Laplacian variance scoring prevents unreadable, out-of-focus text from entering the pipeline.
- **Specular Glare Analysis**: HSV reflection profiling detects bright reflections on glossy laminates and foil pouches.
- **Perspective Rectangularity**: Geometric contour analysis evaluates surface skew and tilt.
- **Image Authenticity & Anti-Fraud**: SHA-256 fingerprinting prevents cross-angle photo reuse or duplicate uploads.

### 🧠 3. Dual-Angle OCR & Entity Fusion
- Resolves the common industry problem where Front packaging (brand name, quantity) and Back packaging (MRP, batch, manufacturer, consumer care) get conflated.
- Intelligently maps extracted text chunks to statutory declaration categories using dedicated heuristic and regex parsers.

### ⚖️ 4. Rule 6 Statutory Compliance Engine
Evaluates packaged commodities against the **Legal Metrology (Packaged Commodities) Rules, 2011**:

| Rule Reference | Statutory Obligation | Automated Check |
|:---|:---|:---|
| **Rule 6(1)(a)** | Manufacturer / Packer / Importer Identity & Address | Verified complete entity name and physical location |
| **Rule 6(1)(b)** | Generic or Common Name of Commodity | Extracted and classified against commodity taxonomies |
| **Rule 6(1)(c)** | Net Quantity in Standard SI Units (kg, g, L, mL, N) | Verified unit validity and numeral formatting |
| **Rule 6(1)(d)** | Month and Year of Manufacture / Packing | Format verified (`MM/YYYY` or `MMM YYYY`) |
| **Rule 6(1)(da)**| Expiry Date / Best Before Period | Verified expiration and shelf-life clarity |
| **Rule 6(1)(e)** | Maximum Retail Price (MRP) | Verified price with mandatory *"Inclusive of all taxes"* clause |
| **Rule 6(1)(f)** | Consumer Care Details | Phone number, valid email, and physical redressal address |
| **Rule 6(1)(g)** | Country of Origin | Mandatory detection for all imported products |

### 👮 5. Inspector-Scoped Numbering & Account Isolation
- **Sequential Inspection Numbering**: Every inspector receives their own sequence prefixed with their official badge (e.g. `LM-DL-2026-001-0001`, `LM-DL-2026-001-0002`).
- **Complete Session Isolation**: Zero cross-account data leakage across logins or shared field devices.
- **Inspector-in-the-Loop Override**: Automated findings can be reviewed and manually updated with mandatory audit justifications.

### 📄 6. Cryptographic Sealing & Tamper-Evident Reports
- **Canonical SHA-256 Fingerprint**: Digitally seals the inspection record, timestamps, and findings.
- **Court-Admissible PDF Generation**: Formatted under Government of India guidelines with Ashoka Lion emblem, structured finding tables, and verification metadata.

---

## 🛠️ Technology Stack

| Layer | Technologies |
|:---|:---|
| **Mobile Client** | Flutter 3.x, Dart, Dio, Provider/Service Pattern, Camera API, Shared Preferences, Intl |
| **Backend Framework** | FastAPI (Python 3.11+), Uvicorn, Pydantic v2 |
| **Database & ORM** | PostgreSQL 15+, SQLAlchemy 2.0 (psycopg3) |
| **Computer Vision** | OpenCV (cv2), NumPy |
| **Document Engine** | ReportLab (vector PDF generation) |
| **Cloud Storage** | Cloudinary (secure encrypted evidence hosting) |
| **Security & Auth** | OAuth2 / JWT (python-jose), Passlib (bcrypt), SHA-256 |

---

## 📁 Repository Structure

```
parakh/
├── lib/                             # Flutter Mobile Application
│   ├── core/                        # Themes, routes, constants, date utilities
│   │   ├── constants.dart           # API config & base URLs
│   │   ├── date_utils.dart          # UTC-to-local timezone parsing & formatting
│   │   ├── routes.dart              # Application route definitions
│   │   └── theme.dart               # Colors, typography, spacing tokens
│   ├── model/                       # Data models (Inspection, Declarations, Findings)
│   ├── screens/                     # Application screens
│   │   ├── auth/                    # Splash, Login, Registration
│   │   ├── home/                    # Inspector Dashboard & Today's Activity
│   │   ├── scan/                    # Guided Camera, Capture Review, Analysis
│   │   ├── result/                  # Declarations Review, Evidence Trace
│   │   ├── review/                  # Inspector Sign-off, Finalization
│   │   └── reports/                 # Searchable Reports List, PDF View
│   ├── services/                    # API client, auth service, inspection service
│   └── widgets/                     # Reusable UI components & Ashoka emblem
│
├── backend/                         # FastAPI Backend
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
- **Flutter SDK**: `^3.12.0` or later
- **Python**: `3.11+`
- **uv**: Ultra-fast Python package manager ([Astral uv](https://github.com/astral-sh/uv))
- **PostgreSQL**: Installed and running locally or remotely

---

### 1. Backend Setup

1. **Navigate to the backend directory**:
   ```bash
   cd backend
   ```

2. **Configure Environment Variables**:
   Create a `.env` file in the `backend/` directory with your database and service configurations:
   ```ini
   DATABASE_URL=postgresql+psycopg://username:password@localhost:5432/parakh
   JWT_SECRET_KEY=your-secure-secret-key
   JWT_ALGORITHM=HS256
   JWT_EXPIRE_MINUTES=43200
   CLOUDINARY_CLOUD_NAME=your_cloudinary_name
   CLOUDINARY_API_KEY=your_cloudinary_key
   CLOUDINARY_API_SECRET=your_cloudinary_secret
   ```

3. **Install dependencies and start the backend**:
   ```bash
   uv sync
   uv run python run.py
   ```
   The backend service starts on port `8000`.  
   Interactive Swagger documentation will be accessible at `/docs`.

---

### 2. Mobile App Setup

1. **Navigate to the project root**:
   ```bash
   cd ..
   ```

2. **Install Flutter packages**:
   ```bash
   flutter pub get
   ```

3. **Configure API Base URL**:
   Configure the API base URL in `lib/core/constants.dart` (or via the app settings):
   - **Simulator / Emulation**: Points to your active backend host.
   - **Physical Device**: Connect to the same network as your backend workstation.

4. **Run on Connected Device**:
   ```bash
   # Run on connected device or simulator
   flutter run

   # Specific device deployment (e.g., iPhone over USB)
   flutter run -d <DEVICE_ID>
   ```

---

## 🔒 Security & Privacy

- **No Plaintext Passwords**: Inspector passwords are hashed using salted `bcrypt`.
- **Zero-Data Leakage Architecture**: When an inspector logs out, all in-memory inspection sessions, tokens, and cached lists are scrubbed.
- **Tamper-Evident SHA-256 Sealing**: Once an inspection is finalized by an inspector, its canonical parameters are permanently hashed. Any subsequent alteration invalidates the audit seal.
- **Local Network Safe**: Configured with strict iOS App Transport Security exceptions limited to local debugging networks (`NSAllowsLocalNetworking`).

---

## 📜 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

<div align="center">
  <b>Developed for the Smart India Hackathon (SIH)</b><br/>
  <i>National Legal Metrology Digital Transformation Initiative</i><br/>
  <b>Government of India</b>
</div>
