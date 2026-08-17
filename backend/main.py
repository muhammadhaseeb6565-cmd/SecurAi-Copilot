from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from core.security_rag import stream_security_copilot, generate_incident_report, generate_code_patch
import asyncio
import json
import random
import subprocess
import psutil
import requests

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

class CodeRequest(BaseModel):
    code: str

class ReportRequest(BaseModel):
    alert_details: str

class ShodanRequest(BaseModel):
    ip: str
    api_key: str

class GithubPrRequest(BaseModel):
    repo: str
    pr_number: int
    pat: str

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

class UrlScanRequest(BaseModel):
    url: str

@app.post("/url-scan")
def url_scan(request: UrlScanRequest):
    try:
        url = request.url
        if not url.startswith("http"):
            url = "http://" + url
            
        alerts = []
        try:
            resp = requests.get(url, timeout=5)
            headers = resp.headers
            
            # Check security headers
            if "Strict-Transport-Security" not in headers:
                alerts.append({
                    "title": "Missing HSTS Header",
                    "severity": "High",
                    "time": "Just now",
                    "details": "The site is not enforcing HTTP Strict Transport Security (HSTS), leaving it vulnerable to MITM downgrade attacks."
                })
            
            if "X-Frame-Options" not in headers and "Content-Security-Policy" not in headers:
                alerts.append({
                    "title": "Missing Clickjacking Protection",
                    "severity": "Medium",
                    "time": "Just now",
                    "details": "Neither X-Frame-Options nor a frame-ancestors CSP directive is present. Vulnerable to Clickjacking."
                })
                
            if "X-Content-Type-Options" not in headers:
                alerts.append({
                    "title": "Missing MIME Sniffing Protection",
                    "severity": "Low",
                    "time": "Just now",
                    "details": "X-Content-Type-Options: nosniff is missing. Browsers may interpret files as different MIME types."
                })
                
            server = headers.get("Server", "")
            if server:
                alerts.append({
                    "title": "Server Information Disclosure",
                    "severity": "Low",
                    "time": "Just now",
                    "details": f"The server is exposing its software version: {server}. This assists attackers in finding CVEs."
                })
                
            if not alerts:
                alerts.append({
                    "title": "Basic Headers Secure",
                    "severity": "Low",
                    "time": "Just now",
                    "details": "Target URL implements standard security headers successfully."
                })
                
        except requests.exceptions.RequestException as e:
            alerts.append({
                "title": "Connection Failed",
                "severity": "High",
                "time": "Just now",
                "details": f"Could not connect to {url}. Error: {str(e)}"
            })

        return {"alerts": alerts}
    except Exception as e:
        return {"alerts": [{"title": "Scanner Error", "severity": "High", "time": "Just now", "details": str(e)}]}

@app.get("/system-metrics")
def system_metrics():
    try:
        cpu = psutil.cpu_percent(interval=0.1)
        ram = psutil.virtual_memory().percent
        disk = psutil.disk_usage('/').percent
        health = 100 - ((cpu + ram) / 2)
        if health < 0: health = 0
        return {
            "cpu_percent": cpu,
            "ram_percent": ram,
            "disk_percent": disk,
            "system_health": health
        }
    except Exception as e:
        return {"error": str(e)}

@app.post("/shodan-scan")
def shodan_scan(request: ShodanRequest):
    try:
        if not request.api_key:
            return {"error": "Shodan API Key is required."}
        url = f"https://api.shodan.io/shodan/host/{request.ip}?key={request.api_key}"
        resp = requests.get(url)
        if resp.status_code == 200:
            data = resp.json()
            return {
                "ip": data.get("ip_str"),
                "os": data.get("os", "Unknown"),
                "ports": data.get("ports", []),
                "vulns": data.get("vulns", []),
                "org": data.get("org", "Unknown"),
            }
        else:
            return {"error": f"Shodan API error: {resp.text}"}
    except Exception as e:
        return {"error": str(e)}

@app.post("/github-pr")
def github_pr(request: GithubPrRequest):
    try:
        headers = {"Accept": "application/vnd.github.v3.diff"}
        if request.pat and request.pat.strip() != "":
            headers["Authorization"] = f"token {request.pat}"
            
        url = f"https://api.github.com/repos/{request.repo}/pulls/{request.pr_number}"
        resp = requests.get(url, headers=headers)
        if resp.status_code == 200:
            diff_text = resp.text
            if not diff_text:
                return {"review": "PR contains no diff or is not accessible."}
            # Feed the diff to LangChain to get a review
            # We reuse the generate_code_patch function which calls LangChain
            from core.security_rag import generate_code_patch
            review = generate_code_patch(f"You are a Senior Application Security Engineer. Review the following GitHub PR diff for security vulnerabilities. Be extremely thorough. Point out missing authentication, SQL injection, secrets, etc.\n\n{diff_text}")
            return {"review": review}
        else:
            return {"error": f"GitHub API error: {resp.status_code} - {resp.text}"}
    except Exception as e:
        return {"error": str(e)}

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
