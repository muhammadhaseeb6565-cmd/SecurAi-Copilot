# 🛡️ SecurAI Copilot

**An Enterprise-Grade, AI-Driven DevSecOps Mobile Application.**

SecurAI Copilot is a cross-platform mobile application designed to bridge the gap between artificial intelligence and proactive cybersecurity. It equips security engineers, developers, and IT administrators with a portable, military-grade platform for real-time threat intelligence, automated vulnerability remediation, and active threat defense.

---

## 🚀 Core Features & Capabilities

*   **🤖 Security AI Assistant:** Powered by Groq's ultra-low latency **LLaMA-3.3-70B** model, it analyzes logs, writes secure code patches, and explains complex vulnerabilities in real-time. Supports multiple personas (Auditor, Ninja, Teacher).
*   **📡 Live OSINT & Threat Hunting:** Integrates directly with the **Shodan API** to scan IP addresses for open ports, exposed services, and known CVEs.
*   **🐙 GitHub PR Auditor & Auto-Fix:** Automatically audits GitHub pull requests for security flaws and provides instant, deployable code patches.
*   **🚨 Data Breach Scanner:** Verifies if email addresses have been compromised in known data breaches using the **HaveIBeenPwned** API.
*   **🎣 URL Phishing Scanner:** Uses heuristic analysis and AI to determine if URLs contain malicious payloads, typosquatting, or phishing attempts.
*   **🎓 DevSecOps Training:** Generates dynamic, AI-powered multiple-choice quizzes to continuously train users on modern security concepts.
*   **📄 Incident Reports:** Compiles critical findings into professional PDF incident reports that can be saved or shared directly from the mobile app.

---

## 🏰 Top 1% Extreme Security Architecture

The backend and frontend implement aggressive, zero-trust security measures to protect the application itself from reverse engineering and direct API attacks:

*   **🔒 Cryptographic Payload Integrity (HMAC-SHA256):** Every API request is signed using a secret HMAC signature. Any tampering of the payload in transit results in an immediate, permanent IP ban.
*   **👁️ Active Threat Logger:** All hacking attempts (e.g., using Postman, curl, or SQL injection payloads) are blocked and logged to a persistent **Supabase** database, viewable via the app's Live Threat Logs screen.
*   **☢️ Radioactive Honeypots:** The API exposes fake admin tokens. Any automated bot or malicious actor attempting to use them is instantly blacklisted.
*   **🛡️ Micro Content-Length Limits:** Strict payload size limits (maximum 15KB) are enforced to prevent buffer overflows and Slowloris Denial-of-Service attacks.
*   **📱 Mobile-Only Enclaves:** The backend cryptographically verifies `X-SecurAI-Client` headers to prevent direct API hammering from unauthorized external scripts.

---

## 🛠️ Technology Stack

**Frontend:**
*   **Flutter & Dart** (Cross-platform support, compiled to Android APK)
*   **Supabase Auth** (Enterprise-grade user management)
*   **Printing & PDF** (Native PDF generation and sharing)

**Backend:**
*   **Python & FastAPI** (High-speed asynchronous API)
*   **Groq API & LangChain** (Lightning-fast AI inference)
*   **Supabase PostgreSQL** (Persistent Threat Logging with RLS)
*   **Uvicorn** (ASGI web server)

**Deployment:**
*   **GitHub Actions:** Automated CI/CD for APK generation.
*   **Render:** Backend hosting with automatic deployments.

---

## 🚀 Running the Project Locally

### 1. Start the Backend (FastAPI)
Navigate to the backend directory and install the requirements:
```bash
cd backend
pip install -r requirements.txt
```
Run the server:
```bash
uvicorn main:app --host 0.0.0.0 --port 8000
```
*(Requires a `.env` file in the backend directory with your `GROQ_API_KEY`!)*

### 2. Start the Frontend (Flutter)
Open a new terminal, navigate to the frontend directory, and get the dependencies:
```bash
cd frontend
flutter pub get
```
Run the app in your browser or on an emulator:
```bash
flutter run
```

---

## 🤝 Acknowledgments
This project was built as a Final Project Deliverable for **The Arzens Internship** (AI, Automation and Security Engineering Intern Advanced Track). 
Submitted by **Muhammad Haseeb**.
