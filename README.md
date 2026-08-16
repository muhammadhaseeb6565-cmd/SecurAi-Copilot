# 🛡️ SecurAI Copilot

**An Enterprise-Grade DevSecOps AI Assistant and Network Analysis Platform.**

SecurAI Copilot is a cross-platform mobile and web application designed to act as a 24/7 intelligent security assistant. It integrates AI-driven network analysis, real-time threat reporting, automated DevSecOps training, and interactive deployment automation.

---

## 🚀 Features

*   **🤖 AI Security Copilot:** Chat with a highly context-aware AI powered by **LLaMA 3 (Groq API)**. The AI supports multiple personas (Security Auditor, Code Ninja, Patient Teacher) and natively translates concepts into multiple languages, including Roman Urdu and Urdu.
*   **🔒 Secure Authentication:** Built with **Supabase Auth** for enterprise-grade email and password user management.
*   **📡 Real-Time Network Mapping:** Visualize complex network topologies, scan for active threats, and analyze open ports and firewall configurations instantly.
*   **📜 Automated Threat Reporting:** Instantly generate Markdown-formatted incident reports and vulnerability summaries with one click.
*   **🎓 DevSecOps Training Hub:** Access AI-generated courses, flashcards, and simulated vulnerability patching environments to train junior security engineers.
*   **⚡ Blazing Fast Architecture:** A lightweight **Flutter** frontend paired with a high-performance **FastAPI** backend for zero-latency AI streaming.

---

## 🛠️ Technology Stack

**Frontend:**
*   **Flutter & Dart** (Cross-platform support for Android, iOS, Web, and Windows)
*   **Supabase** (Pure Dart integration for Authentication and Vector Database mapping)
*   **Provider** (State Management & Theming)

**Backend:**
*   **Python & FastAPI** (High-speed asynchronous API)
*   **LangChain** (Orchestrating the LLM interaction chain)
*   **Groq API** (Ultra-low latency LLaMA 3 inference engine)
*   **Uvicorn** (Lightning-fast ASGI web server)

---

## 💻 Running the Project Locally

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
*(Remember to create a `.env` file in the backend directory with your `GROQ_API_KEY`!)*

### 2. Start the Frontend (Flutter)
Open a new terminal, navigate to the frontend directory, and get the dependencies:
```bash
cd frontend
flutter pub get
```
Run the app in your browser or on an emulator:
```bash
flutter run -d chrome
```

---

## ☁️ Deployment

*   **Backend:** Configured to be deployed easily on free Docker-compatible platforms (like **Replit** or HuggingFace Spaces) via the provided `requirements.txt`.
*   **Frontend:** Can be compiled into an Android `.apk` via `flutter build apk` or hosted as a static web app via Vercel using `flutter build web`.

---

## 🤝 Contributing
This project was built as a Final Project Proposal for **The Arzens Internship**. Contributions, forks, and feature requests are welcome!
