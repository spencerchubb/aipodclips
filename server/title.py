import google.generativeai as genai
import os

prompt = """Generate a title for the following transcript. The text might be truncated in a weird place, so just do your best. Only output the title, do NOT say anything else."""

def generate_title(transcript):
    genai.configure(api_key=os.environ["GEMINI_API_KEY"])
    model = genai.GenerativeModel(
        model_name="gemini-2.0-flash",
        generation_config={
            "temperature": 1,
            "top_p": 0.95,
            "top_k": 40,
            "max_output_tokens": 8192,
            "response_mime_type": "text/plain",
        },
        system_instruction=prompt,
    )
    chat_session = model.start_chat(history=[])
    response = chat_session.send_message(transcript['text'][:1000]).text
    return { "title": response }