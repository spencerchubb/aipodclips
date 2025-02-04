from transcribe import transcribe_audio_in_chunks
from firebase_functions import https_fn, options
from firebase_admin import credentials, initialize_app, storage
import yt_dlp
import tempfile
import os
import json

app = initialize_app(credentials.Certificate("firebase_private_key.json"))

@https_fn.on_request(cors=options.CorsOptions(cors_origins="*", cors_methods=["get", "post"]))
def api(req: https_fn.Request) -> https_fn.Response:
    body = req.json
    print(body)

    if body["action"] == "hello":
        return {"message": "Hello world!"}
    elif body["action"] == "choose_snippets":
        return choose_snippets(body)
    elif body["action"] == "download":
        return download(body)
    elif body["action"] == "transcribe":
        # Download from firebase storage to temp path
        bucket = storage.bucket("aipodclips-8369c.firebasestorage.app")
        blob = bucket.blob(f"videos/{body['url'].split('/')[-1]}")
        temp_path = tempfile.NamedTemporaryFile(delete=False)
        blob.download_to_filename(temp_path.name)
        return transcribe_audio_in_chunks(temp_path.name)
    else:
        return {"message": "Unknown action!"}

def choose_snippets(body):
    import google.generativeai as genai

    genai.configure(api_key=os.environ["GEMINI_API_KEY"])
    prompt = '''You are an expert at psychology and social media virality, especially for short form video. The user will give you a transcript of a podcast. Choose snippets of about 15 to 30 seconds that would go viral and make people want to watch the whole podcast. Output the options as a list of strings. Do not say anything else. Choose 3 options

### Example output format
["snippet 1", "snippet 2", "snippet 3"]'''
    generation_config = {
        "temperature": 1,
        "top_p": 0.95,
        "top_k": 40,
        "max_output_tokens": 8192,
        "response_mime_type": "text/plain",
    }
    model = genai.GenerativeModel(
        model_name="gemini-2.0-flash-exp",
        generation_config=generation_config,
        system_instruction=prompt,
    )
    chat_session = model.start_chat(history=[])
    response = chat_session.send_message(body["transcript"]).text
    return {
        "snippets": json.loads(response)
    }

def download(body):
    url = body["url"]
    
    # Initialize Firebase Storage bucket
    bucket = storage.bucket("aipodclips-8369c.firebasestorage.app")
    
    # Create a temporary directory to store the download
    with tempfile.TemporaryDirectory() as temp_dir:
        ydl_opts = {
            'format': 'best',
            'outtmpl': f'{temp_dir}/%(id)s.%(ext)s',
        }
        
        try:
            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                # Download the video
                info = ydl.extract_info(url, download=True)
                video_id = info['id']
                video_ext = info['ext']
                video_title = info['title']
                video_path = f"{temp_dir}/{video_id}.{video_ext}"
                
                # Upload to Firebase Storage
                blob = bucket.blob(f"videos/{video_id}.{video_ext}")
                blob.upload_from_filename(video_path)
                
                return {
                    "url": blob.public_url,
                    "title": video_title,
                }
        except Exception as e:
            print(f"Error: {str(e)}")
            return {"message": f"Error downloading video: {str(e)}"}