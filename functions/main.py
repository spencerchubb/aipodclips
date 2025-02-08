from flask import Flask, request
from flask_cors import CORS
from firebase_admin import credentials, initialize_app, storage
import datetime
import yt_dlp
import tempfile
import json
import uuid
from create_video import create_video
from snippets import generate_snippets

initialize_app(credentials.Certificate("firebase_private_key.json"))

app = Flask(__name__)
CORS(app)

@app.route('/api', methods=['POST'])
def api():
    body = request.json
    print(body)

    if body["action"] == "hello":
        return {"message": "Hello world!"}
    elif body["action"] == "create":
        return create(body)
    elif body["action"] == "download":
        return download(body)
    elif body["action"] == "generate_snippets":
        return generate_snippets(body)
    elif body["action"] == "transcribe":
        return transcribe(body)
    else:
        return {"message": "Unknown action!"}

def create(body):
    video_id = body["video_id"]
    snippet = body["snippet"]

    with tempfile.TemporaryDirectory() as temp_dir:
        bucket = storage.bucket("aipodclips-8369c.firebasestorage.app")
        input_path = f"{temp_dir}/input_{video_id}.mp4"
        output_path = f"{temp_dir}/output_{video_id}.mp4"

        # Download video
        blob = bucket.blob(f"video_inputs/{video_id}.mp4")
        blob.download_to_filename(input_path)

        # Download transcript
        blob = bucket.blob(f"transcripts/{video_id}.json")
        transcript_path = f"{temp_dir}/transcript_{video_id}.json"
        transcript = blob.download_to_filename(transcript_path)
        transcript = json.load(open(transcript_path))

        # Create video
        create_video(input_path, output_path, transcript, snippet)

        # Upload video to firebase storage
        snippet_id = str(uuid.uuid4())
        blob = bucket.blob(f"video_outputs/{snippet_id}.mp4")
        blob.upload_from_filename(output_path)

        return {"snippet_id": snippet_id}

def download(body):
    url = body["url"]
    video_id = body["video_id"]
    
    # Initialize Firebase Storage bucket
    bucket = storage.bucket("aipodclips-8369c.firebasestorage.app")
    
    # Create a temporary directory to store the download
    with tempfile.TemporaryDirectory() as temp_dir:
        ydl_opts = {
            'format': 'best',
            'outtmpl': f'{temp_dir}/%(id)s.%(ext)s',
            'nocheckcertificate': True,
            'no_cache_dir': True,
            'no_mtime': True,  # Prevents timestamp modification
            'noprogress': True,  # Reduces output noise
        }
        
        try:
            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                # Download the video
                print("downloading video")
                info = ydl.extract_info(url, download=True)
                video_title = info['title']
                video_path = f"{temp_dir}/{info['id']}.{info['ext']}"
                
                print("uploading to firebase")
                # Upload to Firebase Storage
                blob = bucket.blob(f"video_inputs/{video_id}.mp4")
                blob.upload_from_filename(video_path)
                
                return {
                    "message": "Video downloaded successfully",
                    "url": blob.public_url,
                    "title": video_title,
                }
        except Exception as e:
            print(f"YouTube DL Error: {str(e)}")
            return {"message": f"Error downloading video: {str(e)}"}

def transcribe(body):
    video_id = body["video_id"]
    bucket = storage.bucket("aipodclips-8369c.firebasestorage.app")

    # Get video
    blob = bucket.blob(f"video_inputs/{video_id}.mp4")
    signed_url = blob.generate_signed_url(expiration=datetime.timedelta(minutes=15))

    # Generate transcript
    transcript = fireworks_transcribe(signed_url)
    
    # Upload transcript
    blob = bucket.blob(f"transcripts/{video_id}.json")
    blob.upload_from_string(json.dumps(transcript))

    return transcript

def fireworks_transcribe(url):
    from fireworks.client.audio import AudioInference

    client = AudioInference(
        model="whisper-v3-turbo",
        base_url="https://audio-turbo.us-virginia-1.direct.fireworks.ai",
    )

    print("transcribing audio")
    result = client.transcribe(
        audio=url,
        language="en",
        response_format="verbose_json",
        timestamp_granularities=["word"],
    ).model_dump()
    return result
