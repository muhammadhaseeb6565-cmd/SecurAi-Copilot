from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from core.security_rag import stream_security_copilot, generate_incident_report, generate_code_patch
import asyncio
import json
import random
import subprocess

app = FastAPI(title="SecurAI Mobile Backend")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class ChatRequest(BaseModel):
    message: str
    persona: str = "auditor"
    language: str = "English"

class ReportRequest(BaseModel):
    alert_details: str

@app.get("/")
def read_root():
    return {"status": "Backend is running!"}

@app.post("/chat")
def chat(request: ChatRequest):
    return StreamingResponse(
        stream_security_copilot(request.message, request.persona, request.language), 
        media_type="text/event-stream"
    )

@app.post("/generate-report")
def generate_report(request: ReportRequest):
    response = generate_incident_report(request.alert_details)
    return {"report": response}

@app.post("/generate-patch")
def generate_patch(request: ReportRequest):
    response = generate_code_patch(request.alert_details)
    return {"patch": response}

@app.get("/run-scan")
def run_scan():
    try:
        bandit_result = subprocess.run(["bandit", "-r", "core", "main.py", "-f", "json"], capture_output=True, text=True)
        try:
            bandit_data = json.loads(bandit_result.stdout)
            bandit_issues = bandit_data.get("results", [])
        except Exception:
            bandit_issues = []

        safety_result = subprocess.run(["safety", "check", "-r", "requirements.txt", "--json"], capture_output=True, text=True)
        try:
            safety_data = json.loads(safety_result.stdout)
            safety_issues = safety_data.get("vulnerabilities", [])
        except Exception:
            safety_issues = []

        alerts = []
        for issue in bandit_issues:
            alerts.append({
                "title": f"Code Flaw: {issue.get('issue_text')}",
                "severity": issue.get('issue_severity', 'MEDIUM').capitalize(),
                "time": "Just now",
                "details": f"File: {issue.get('filename')}\nLine: {issue.get('line_number')}\nCode:\n{issue.get('code')}"
            })
            
        for issue in safety_issues:
            alerts.append({
                "title": f"Vulnerable Dependency: {issue.get('package_name')}",
                "severity": "High",
                "time": "Just now",
                "details": f"Version {issue.get('analyzed_version')} is vulnerable to {issue.get('vulnerability_id')}.\nAdvisory: {issue.get('advisory')}"
            })
            
        if not alerts:
            alerts.append({
                "title": "All Checks Passed",
                "severity": "Low",
                "time": "Just now",
                "details": "Bandit and Safety found no critical vulnerabilities in your codebase."
            })
            
        return {"alerts": alerts}
    except Exception as e:
        return {"alerts": [{"title": "Scanner Error", "severity": "High", "time": "Just now", "details": str(e)}]}

async def metrics_generator():
    while True:
        # Simulate live API traffic data
        data = {
            "total_requests": random.randint(1000, 5000),
            "auth_failures": random.randint(10, 100),
            "shadow_apis_detected": random.randint(0, 5),
            "anomaly_score": round(random.uniform(1.0, 9.9), 1),
            "threats": random.randint(0, 3)
        }
        yield f"data: {json.dumps(data)}\n\n"
        await asyncio.sleep(2)

@app.get("/metrics/stream")
async def metrics_stream():
    return StreamingResponse(metrics_generator(), media_type="text/event-stream")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
