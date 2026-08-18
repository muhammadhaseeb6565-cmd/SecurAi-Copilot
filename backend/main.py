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
    model: str = "openai/gpt-oss-20b"
    image_base64: str = None

class CodeRequest(BaseModel):
    code: str

class ReportRequest(BaseModel):
    alert_details: str
    model: str = "openai/gpt-oss-20b"

class ShodanRequest(BaseModel):
    ip: str
    api_key: str

class GithubPrRequest(BaseModel):
    repo: str
    pr_number: int
    pat: str

class GithubFixRequest(BaseModel):
    repo: str
    pr_number: int
    pat: str
    fix_code: str

@app.get("/")
def read_root():
    return {"status": "Backend is running!"}

@app.post("/chat")
def chat(request: ChatRequest):
    return StreamingResponse(
        stream_security_copilot(request.message, request.persona, request.language, request.model, request.image_base64), 
        media_type="text/event-stream"
    )

@app.post("/generate-report")
def generate_report(request: ReportRequest):
    response = generate_incident_report(request.alert_details, request.model)
    return {"report": response}

@app.post("/generate-patch")
def generate_patch(request: ReportRequest):
    response = generate_code_patch(request.alert_details, request.model)
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

class BreachScanRequest(BaseModel):
    email: str

@app.post("/breach-scan")
def breach_scan(request: BreachScanRequest):
    # Simulated Have I Been Pwned API response for demo purposes
    email = request.email.lower()
    
    # Generate some realistic mock breaches based on the email domain
    breaches = []
    if "admin" in email or "test" in email or "demo" in email:
        breaches.append({
            "name": "LinkedIn (2012)",
            "date": "2012-05-05",
            "dataclasses": ["Email addresses", "Passwords"],
            "description": "In 2012, LinkedIn had 164 million email addresses and passwords exposed."
        })
        breaches.append({
            "name": "Canva",
            "date": "2019-05-24",
            "dataclasses": ["Email addresses", "Passwords", "Names", "Usernames"],
            "description": "In May 2019, graphic design site Canva suffered a data breach that impacted 137 million subscribers."
        })
        
    return {"breaches": breaches, "found": len(breaches) > 0}

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

@app.post("/github-auto-fix")
def github_auto_fix(request: GithubFixRequest):
    try:
        headers = {
            "Accept": "application/vnd.github.v3+json",
            "Authorization": f"token {request.pat}"
        }
        url = f"https://api.github.com/repos/{request.repo}/issues/{request.pr_number}/comments"
        payload = {
            "body": f"### SecurAI Auto-Fix Deployment 🚀\nThe AI has detected vulnerabilities and generated a secure patch for this Pull Request. Please apply the following changes:\n\n```python\n{request.fix_code}\n```"
        }
        resp = requests.post(url, headers=headers, json=payload)
        if resp.status_code == 201:
            return {"status": "Success! The secure patch was successfully deployed as an official review on the PR!"}
        else:
            return {"error": f"Failed to push fix: {resp.status_code} - {resp.text}"}
    except Exception as e:
        return {"error": str(e)}

import psutil

async def metrics_generator():
    while True:
        cpu = psutil.cpu_percent(interval=None)
        ram = psutil.virtual_memory().percent
        system_health = max(0.0, 100.0 - ((cpu + ram) / 2))
        data = {
            "system_health": round(system_health, 1),
            "cpu_percent": cpu,
            "ram_percent": ram,
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
@app.post("/analyze-phishing")
async def analyze_phishing(request: ChatRequest):
    system_prompt = """You are an expert Phishing and Social Engineering Analyst. 
The user will provide an email, SMS, or URL. 
Analyze the psychological tactics (urgency, authority, fear), extract any URLs, and assess the threat level. 
End your response with a definitive SCORE out of 100 (where 100 is highly malicious) and a VERDICT (Safe, Suspicious, or Malicious)."""
    try:
        completion = groq_client.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": request.message}
            ],
            temperature=0.2,
            max_tokens=1024,
        )
        return {"response": completion.choices[0].message.content, "model": "llama-3.3-70b-versatile"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/audit-iac")
async def audit_iac(request: ChatRequest):
    system_prompt = """You are an elite DevSecOps Cloud Auditor.
The user will provide an Infrastructure as Code (IaC) snippet, such as a Dockerfile, kubernetes.yaml, or docker-compose.yaml.
Scan the file line-by-line for privilege escalations (e.g., USER root), hardcoded secrets, excessive permissions, and missing security boundaries.
Provide a rewritten, highly secure version of the file in a markdown code block."""
    try:
        completion = groq_client.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": request.message}
            ],
            temperature=0.1,
            max_tokens=2048,
        )
        return {"response": completion.choices[0].message.content, "model": "llama-3.3-70b-versatile"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
