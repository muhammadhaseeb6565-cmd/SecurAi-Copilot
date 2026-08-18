import os
import re
import requests
from dotenv import load_dotenv
from langchain_groq import ChatGroq
from langchain_core.messages import HumanMessage, SystemMessage
from langchain_core.prompts import ChatPromptTemplate

load_dotenv()

PERSONAS = {
    "auditor": "You are a strict DevSecOps Security Auditor. Find flaws and be concise.",
    "teacher": "You are a patient Security Teacher. Explain concepts clearly and simply.",
    "ninja": "You are a Code Ninja. Provide fast, secure code snippets with no extra text."
}

def extract_cve_and_fetch(message: str) -> str:
    cve_match = re.search(r"CVE-\d{4}-\d+", message, re.IGNORECASE)
    if cve_match:
        cve_id = cve_match.group(0).upper()
        try:
            res = requests.get(f"https://cve.circl.lu/api/cve/{cve_id}", timeout=3)
            if res.status_code == 200:
                data = res.json()
                if data:
                    summary = data.get("summary", "No summary found.")
                    cvss = data.get("cvss", "N/A")
                    return f"\n\n[Agent RAG Context: The user mentioned {cve_id}. Live OSINT Data -> CVSS Score: {cvss}. Summary: {summary}]"
        except Exception:
            pass
    return ""

def get_app_context() -> str:
    return """
You are the AI core of 'SecurAI Copilot', a powerful enterprise cybersecurity application.
You are fully aware of this app's features, which the user can access from the app's UI:
1. Live Shodan OSINT (Scans IP addresses for open ports and vulnerabilities).
2. Data Breach Scanner (Checks emails against HaveIBeenPwned).
3. GitHub PR Auditor (Scans code pull requests for vulnerabilities).
4. Live URL Scanner (Analyzes URLs for phishing/malware).
5. Incident Reports (Generates professional PDF reports of alerts).

If the user asks how to do something related to these, guide them to use the tools built into SecurAI Copilot!
Act as a true Agentic AI: analyze the user's intent, refer to the app's capabilities, and provide comprehensive, context-aware cybersecurity guidance.
"""

async def stream_security_copilot(message: str, persona: str = "auditor", language: str = "English", model_name: str = "openai/gpt-oss-20b"):
    api_key = os.getenv("GROQ_API_KEY", "mock_key_for_testing")
    
    if api_key == "mock_key_for_testing" or not api_key:
        yield "MOCK RESPONSE: Please set your GROQ_API_KEY in the backend to enable actual AI responses."
        return

    try:
        llm = ChatGroq(groq_api_key=api_key, model_name=model_name, streaming=True)
        
        system_prompt = get_app_context() + "\n\n" + PERSONAS.get(persona, PERSONAS["auditor"])
        
        osint_context = extract_cve_and_fetch(message)
        if osint_context:
            system_prompt += osint_context

        # Append the language constraint directly to the system prompt
        if language.lower() == "roman urdu":
            system_prompt += f"\nCRITICAL INSTRUCTION: You MUST translate and write your entire response exclusively in Roman Urdu (Urdu written in the English alphabet). You MUST use pure Urdu vocabulary (e.g. 'hifazat', 'masla', 'istamal', 'shukriya') and strictly AVOID Hindi vocabulary (e.g. do not use 'suraksha', 'samasya', 'prayog', 'dhanyavad')."
        else:
            system_prompt += f"\nCRITICAL INSTRUCTION: You MUST translate and write your entire response exclusively in {language}."

        prompt = ChatPromptTemplate.from_messages([
            ("system", system_prompt),
            ("human", "{input}"),
        ])
        
        chain = prompt | llm
        
        async for chunk in chain.astream({"input": message}):
            if chunk.content:
                yield chunk.content
    except Exception as e:
        yield f"Error connecting to Groq AI: {str(e)}"

def generate_incident_report(alert_details: str, model_name: str = "openai/gpt-oss-20b") -> str:
    api_key = os.getenv("GROQ_API_KEY", "mock_key_for_testing")
    if api_key == "mock_key_for_testing" or not api_key:
        return "# MOCK INCIDENT REPORT\nPlease set GROQ_API_KEY."
    
    llm = ChatGroq(groq_api_key=api_key, model_name=model_name)
    prompt = f"Generate a formal, professional Security Incident Report in Markdown for the following alert:\n{alert_details}"
    try:
        return llm.invoke(prompt).content
    except Exception as e:
        return f"Error generating report: {str(e)}"

def generate_code_patch(alert_details: str, model_name: str = "openai/gpt-oss-20b") -> str:
    api_key = os.getenv("GROQ_API_KEY", "mock_key_for_testing")
    if api_key == "mock_key_for_testing" or not api_key:
        return "```python\n# Mock Patch\ndef fix_vulnerability():\n    pass\n```"
    
    llm = ChatGroq(groq_api_key=api_key, model_name=model_name)
    prompt = f"You are an expert Security Engineer. A vulnerability was detected: {alert_details}\nGenerate a secure code patch (in Python or Node.js) to fix this vulnerability. Output ONLY the markdown code block."
    try:
        return llm.invoke(prompt).content
    except Exception as e:
        return f"Error generating patch: {str(e)}"
