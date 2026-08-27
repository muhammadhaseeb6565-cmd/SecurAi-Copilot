import os
import re

backend_main = r"F:\The Arzens Intership Tasks\SecurAI Copilot\backend\main.py"
with open(backend_main, "r", encoding="utf-8") as f:
    content = f.read()

quiz_func_old = """@app.post("/generate-quiz")
async def generate_quiz(request: QuizRequest):
    system_prompt = \"\"\"You are a DevSecOps training AI. Generate a 3-question multiple choice quiz about the provided topic. Respond ONLY with a valid JSON array of objects. Each object must have: 'question' (string), 'code_snippet' (string, optional), 'options' (array of exactly 4 strings), 'correct_index' (integer 0-3), and 'explanation' (string).\"\"\"
    try:
        completion = groq_client.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": request.topic}
            ],
            temperature=0.3
        )
        response_content = completion.choices[0].message.content
        start_idx = response_content.find('[')
        end_idx = response_content.rfind(']') + 1
        if start_idx != -1 and end_idx != 0:
            response_content = response_content[start_idx:end_idx]
        return json.loads(response_content)
    except Exception as e:
        return {"error": str(e)}"""

quiz_func_new = """@app.post("/generate-quiz")
async def generate_quiz(request: QuizRequest):
    system_prompt = \"\"\"You are a DevSecOps training AI. Generate a 3-question multiple choice quiz about the provided topic. Respond ONLY with a valid JSON object containing a single key 'quiz' mapped to an array of objects. Each object must have: 'question' (string), 'code_snippet' (string, optional), 'options' (array of exactly 4 strings), 'correct_index' (integer 0-3), and 'explanation' (string).\"\"\"
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
        return {"error": str(e)}"""

content = content.replace(quiz_func_old, quiz_func_new)

with open(backend_main, "w", encoding="utf-8") as f:
    f.write(content)

print("Updated backend generate-quiz to use json_object")
