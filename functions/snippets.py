from nltk import sent_tokenize
from difflib import SequenceMatcher
import google.generativeai as genai
import os

prompt = """You are an expert in social media, especially TikTok. The user will give you a transcript of a podcast.

Choose 3 lines that are most likely to go viral on TikTok.

Follow the exact format given below. Copy the entire line verbatim.

### Output format
- Lorem ipsum
- Lorem ipsum
- Lorem ipsum
"""

def generate_snippets(body):
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
    response = chat_session.send_message(body["transcript"]).text
    snippets = parse_snippets(response, body["transcript"])
    return { "snippets": snippets }

def find_closest_match(target_sentence, original_text_sentences):
    best_ratio = 0
    best_index = None
    for i, original_sentence in enumerate(original_text_sentences):
        ratio = SequenceMatcher(None, target_sentence.lower(), original_sentence.lower()).ratio()
        if ratio > best_ratio:
            best_ratio = ratio
            best_index = i
    return best_index

def parse_snippets(llm_response, transcript_text):
    sentences = sent_tokenize(transcript_text)
    snippets = [snippet.replace("-", "").strip() for snippet in llm_response.strip().split("\n")]

    output = []
    for snippet in snippets:
        # Even though we tell the LLM to copy lines verbatim, it sometimes doesn't!
        sentence_index = find_closest_match(snippet, sentences)
        snippet = ""

        # Add sentences until the snippet is at least 30 seconds of audio.
        # Our estimate assumes 150 words per minute, 0.5 minutes per snippet, 5 characters per word.
        min_length = 150 * 0.5 * 5
        while len(snippet) < min_length and sentence_index < len(sentences):
            snippet += " " + sentences[sentence_index]
            sentence_index += 1
        output.append(snippet)
    return output