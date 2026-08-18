import os
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

async def stream_security_copilot(message: str, persona: str = "auditor", language: str = "English"):
    api_key = os.getenv("GROQ_API_KEY", "mock_key_for_testing")
    
    if api_key == "mock_key_for_testing" or not api_key:
        yield "MOCK RESPONSE: Please set your GROQ_API_KEY in the backend to enable actual AI responses."
        return

    try:
        llm = ChatGroq(groq_api_key=api_key, model_name="llama-3.3-70b-versatile", streaming=True)
        
        system_prompt = PERSONAS.get(persona, PERSONAS["auditor"])
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

def generate_incident_report(alert_details: str) -> str:
    api_key = os.getenv("GROQ_API_KEY", "mock_key_for_testing")
    if api_key == "mock_key_for_testing" or not api_key:
        return "# MOCK INCIDENT REPORT\nPlease set GROQ_API_KEY."
    
    llm = ChatGroq(groq_api_key=api_key, model_name="llama-3.3-70b-versatile")
    prompt = f"Generate a formal, professional Security Incident Report in Markdown for the following alert:\n{alert_details}"
    try:
        return llm.invoke(prompt).content
    except Exception as e:
        return f"Error generating report: {str(e)}"

def generate_code_patch(alert_details: str) -> str:
    api_key = os.getenv("GROQ_API_KEY", "mock_key_for_testing")
    if api_key == "mock_key_for_testing" or not api_key:
        return "```python\n# Mock Patch\ndef fix_vulnerability():\n    pass\n```"
    
    llm = ChatGroq(groq_api_key=api_key, model_name="llama-3.3-70b-versatile")
    prompt = f"You are an expert Security Engineer. A vulnerability was detected: {alert_details}\nGenerate a secure code patch (in Python or Node.js) to fix this vulnerability. Output ONLY the markdown code block."
    try:
        return llm.invoke(prompt).content
    except Exception as e:
        return f"Error generating patch: {str(e)}"
