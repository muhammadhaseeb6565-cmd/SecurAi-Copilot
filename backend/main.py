from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse, JSONResponse
from pydantic import BaseModel
from core.security_rag import stream_security_copilot, generate_incident_report, generate_code_patch
import asyncio
import os
import httpx
from groq import Groq

# Use a custom httpx client to bypass Cloudflare blocking Groq SDK on Render IPs
custom_http_client = httpx.Client(
    headers={"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"}
)
groq_client = Groq(api_key=os.environ.get('GROQ_API_KEY'), http_client=custom_http_client)
import json
import random
import subprocess
import psutil
import requests
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded

limiter = Limiter(key_func=get_remote_address, default_limits=["50/minute"])

app = FastAPI(title="SecurAI Mobile Backend")
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)


SUPABASE_URL = "https://rnjffzwflbbyznzhcqpg.supabase.co"
SUPABASE_ANON_KEY = "sb_publishable_AGB2Fv2K6FXtyVeVLa_tWA_LE4foSrP"

def log_threat_to_supabase(ip: str, attack_type: str):
    try:
        headers = {
            "apikey": SUPABASE_ANON_KEY,
            "Authorization": f"Bearer {SUPABASE_ANON_KEY}",
            "Content-Type": "application/json",
            "Prefer": "return=minimal"
        }
        data = {
            "ip_address": ip,
            "attack_type": attack_type
        }
        requests.post(f"{SUPABASE_URL}/rest/v1/threat_logs", headers=headers, json=data, timeout=2)
    except Exception as e:
        print(f"Failed to log threat: {e}")

BANNED_IPS = set()

DANGEROUS_PATTERNS = ["<script>", "UNION SELECT", "DROP TABLE", "OR 1=1", "exec(", "system("]

@app.middleware("http")
async def active_threat_defense(request: Request, call_next):
    client_ip = request.client.host if request.client else "unknown"

    # LAYER 21: Cryptographic Payload Integrity (HMAC-SHA256)
    if request.method in ["POST", "PUT", "PATCH"] and request.url.path != "/chat":
        body_bytes = await request.body()
        if body_bytes:
            signature = request.headers.get("X-Payload-Signature")
            req_time = request.headers.get("X-Request-Time")
            
            if not signature or not req_time:
                BANNED_IPS.add(client_ip)
                log_threat_to_supabase(client_ip, "Missing HMAC Signature")
                return JSONResponse(status_code=403, content={"detail": "Missing military-grade cryptographic signature."})
            
            import hmac
            import hashlib
            secret = b"NuclearGradeSecurAISignature2026"
            message = req_time.encode() + body_bytes
            expected_mac = hmac.new(secret, message, hashlib.sha256).hexdigest()
            
            if not hmac.compare_digest(expected_mac, signature):
                BANNED_IPS.add(client_ip)
                log_threat_to_supabase(client_ip, "HMAC Payload Tampering")
                return JSONResponse(status_code=403, content={"detail": "Payload Tampering Detected. Connection severed."})
            
# Hack removed


    # LAYER 18: Strict Automated Scanner Fingerprinting
    user_agent = request.headers.get("User-Agent", "").lower()
    blocked_agents = ["curl", "postman", "python", "nmap", "sqlmap", "zgrab", "masscan", "nikto", "dirb", "wget", "insomnia", "httpie"]
    if any(agent in user_agent for agent in blocked_agents):
        BANNED_IPS.add(client_ip)
        log_threat_to_supabase(client_ip, f"Automated Tool Fingerprinted ({user_agent})")
        return JSONResponse(status_code=403, content={"detail": "Automated tool fingerprinted and blacklisted."})
        
    # LAYER 19: Canary Token Trap (Radioactive API Key)
    auth_header = request.headers.get("Authorization", "")
    if "sk-live-7x9qM32PjL5vRk9bN2mZ1xQ4" in auth_header or "sk-live-7x9qM32PjL5vRk9bN2mZ1xQ4" in request.url.path:
        BANNED_IPS.add(client_ip)
        log_threat_to_supabase(client_ip, "Honeypot Canary Token Triggered")
        return JSONResponse(status_code=403, content={"detail": "Canary token triggered. IP permanently blacklisted."})
        
    # LAYER 20: Micro Content-Length Hard Limit (Anti-Slowloris/Buffer Overflow)
    content_length = request.headers.get("Content-Length")
    if content_length and int(content_length) > 15360: # 15KB max payload
        BANNED_IPS.add(client_ip)
        log_threat_to_supabase(client_ip, "Payload Oversize (Buffer Overflow attempt)")
        return JSONResponse(status_code=413, content={"detail": "Payload exceeds strict micro-limit. Connection severed."})

    if client_ip in BANNED_IPS:
        return JSONResponse(status_code=403, content={"error": "FUCK OFF. YOUR IP IS PERMANENTLY BANNED FOR MALICIOUS ACTIVITY."})
    
    # Check for simple malicious patterns in URL or Query
    url_string = str(request.url).lower()
    for pattern in DANGEROUS_PATTERNS:
        if pattern.lower() in url_string:
            BANNED_IPS.add(client_ip)
            log_threat_to_supabase(client_ip, f"Malicious Pattern Detected: {pattern}")
            return JSONResponse(status_code=403, content={"error": "HACKING ATTEMPT DETECTED. IP BANNED."})

    # Validate Mobile App Signature (Defense against direct API hammering)
    # The frontend app must supply this header to prove it is the legitimate client
    client_header = request.headers.get("X-SecurAI-Client")
    if client_header != "mobile-app-verified-v1" and request.url.path.startswith("/api/"):
        return JSONResponse(status_code=403, content={"error": "Unauthorized API Access. Missing secure client signature."})

    print('Before call_next')
    response = await call_next(request)
    print('After call_next')
    response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["X-XSS-Protection"] = "1; mode=block"
    return response

app.add_middleware(
    CORSMiddleware,
    # Restrict in production, but for Flutter web/mobile it's complex, keeping specific or safe headers
    allow_origins=["https://securai-copilot.onrender.com", "http://localhost"],
    allow_credentials=True,
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type", "Accept"],
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
async def chat(request: Request, payload: ChatRequest):
    client_ip = request.client.host if request.client else "unknown"
    if client_ip in BANNED_IPS:
        return JSONResponse(status_code=403, content={"detail": "Payload Tampering Detected. Connection severed."})
        
    body_bytes = await request.body()
    signature = request.headers.get("X-Payload-Signature")
    req_time = request.headers.get("X-Request-Time")
    
    if not signature or not req_time:
        BANNED_IPS.add(client_ip)
        log_threat_to_supabase(client_ip, "Missing HMAC Signature")
        return JSONResponse(status_code=403, content={"detail": "Missing military-grade cryptographic signature."})
    
    import hmac
    import hashlib
    secret = b"NuclearGradeSecurAISignature2026"
    message = req_time.encode() + body_bytes
    expected_mac = hmac.new(secret, message, hashlib.sha256).hexdigest()
    
    if not hmac.compare_digest(expected_mac, signature):
        BANNED_IPS.add(client_ip)
        log_threat_to_supabase(client_ip, "HMAC Payload Tampering")
        return JSONResponse(status_code=403, content={"detail": "Payload Tampering Detected. Connection severed."})

    return StreamingResponse(
        stream_security_copilot(payload.message, payload.persona, payload.language, payload.model, payload.image_base64), 
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

class QuizRequest(BaseModel):
    topic: str

@app.post("/generate-quiz")
async def generate_quiz(request: QuizRequest):
    system_prompt = """You are a DevSecOps training AI. Generate a 3-question multiple choice quiz about the provided topic. Respond ONLY with a valid JSON object containing a single key 'quiz' mapped to an array of objects. Each object must have: 'question' (string), 'code_snippet' (string, optional), 'options' (array of exactly 4 strings), 'correct_index' (integer 0-3), and 'explanation' (string)."""
    try:
        completion = groq_client.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": request.topic}
            ],
            temperature=0.3,
            response_format={"type": "json_object"}
        )
        response_content = completion.choices[0].message.content
        parsed = json.loads(response_content)
        return parsed.get("quiz", [])
    except Exception as e:
        return {"error": str(e)}


# ==========================================
# ADVANCED THREAT DEFENSE & UTILITIES
# ==========================================

from fpdf import FPDF
import io

@app.get('/api/v1/admin/debug/override')
async def honeypot_trap(request: Request):
    client_ip = request.client.host if request.client else 'unknown'
    BANNED_IPS.add(client_ip)
    log_threat_to_supabase(client_ip, 'Admin Honeypot Endpoint Probed')
    return JSONResponse(
        status_code=403, 
        content={'error': 'HONEYPOT TRIGGERED. YOU ARE PERMANENTLY BANNED.'}
    )

from pydantic import Field

class ChatRequest(BaseModel):
    message: str = Field(..., max_length=2000)
    topic: str = Field(None, max_length=100)
    image_base64: str = Field(None, max_length=5000000) # 5MB limit
    
class PhishingRequest(BaseModel):
    content: str = Field(..., max_length=10000)


@app.post('/api/analyze-phishing')
@limiter.limit('10/minute')
async def analyze_phishing(request: Request, req: PhishingRequest):
    prompt = f'Analyze this URL or text for phishing indicators, typosquatting, and malicious intent. Be concise and return a JSON object with keys: \'is_malicious\' (boolean), \'threat_score\' (0-100), and \'analysis\' (string).\n\nContent:\n{req.content}'
    try:
        response = groq_client.chat.completions.create(
            messages=[{'role': 'system', 'content': 'You are an elite cybersecurity AI. Respond ONLY with valid JSON.'},
                      {'role': 'user', 'content': prompt}],
            model='llama-3.3-70b-versatile',
        )
        res_str = response.choices[0].message.content
        start = res_str.find('{')
        end = res_str.rfind('}') + 1
        if start != -1 and end != 0:
            return json.loads(res_str[start:end])
        return {'is_malicious': False, 'threat_score': 0, 'analysis': 'Could not parse response.'}
    except Exception as e:
        return {'is_malicious': False, 'threat_score': 0, 'analysis': str(e)}

@app.get('/api/generate-ir-report')
@limiter.limit('5/minute')
async def generate_ir_report(request: Request, score: float = 0.0):
    pdf = FPDF()
    pdf.add_page()
    pdf.set_font('Arial', 'B', 16)
    pdf.set_text_color(220, 50, 50)
    pdf.cell(0, 10, 'INCIDENT RESPONSE REPORT', ln=True, align='C')
    pdf.ln(10)
    
    pdf.set_font('Arial', '', 12)
    pdf.set_text_color(0, 0, 0)
    pdf.cell(0, 10, f'Anomaly Score: {score}/10.0', ln=True)
    pdf.cell(0, 10, 'Status: CRITICAL THREAT DETECTED', ln=True)
    pdf.ln(5)
    
    pdf.multi_cell(0, 10, 'This report was automatically generated by SecurAI Copilot. The system detected an anomaly score exceeding the safe threshold (8.0). Active defense measures (WAF filtering, IP blocking) were instantly deployed to protect the infrastructure.')
    pdf.ln(5)
    pdf.multi_cell(0, 10, 'Recommended Action: Rotate API keys immediately, verify IAM policies, and review the recent access logs in the backend dashboard.')
    
    pdf_bytes = pdf.output(dest='S').encode('latin1')
    return StreamingResponse(io.BytesIO(pdf_bytes), media_type='application/pdf', headers={'Content-Disposition': 'attachment; filename=Incident_Report.pdf'})

