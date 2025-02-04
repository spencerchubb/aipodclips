from firebase_functions import https_fn, options
from firebase_admin import credentials, initialize_app, storage
import yt_dlp
import tempfile

app = initialize_app(credentials.Certificate("firebase_private_key.json"))

@https_fn.on_request(cors=options.CorsOptions(cors_origins="*", cors_methods=["get", "post"]))
def api(req: https_fn.Request) -> https_fn.Response:
    body = req.json
    print(body)

    if body["action"] == "hello":
        return {"message": "Hello world!"}
    elif body["action"] == "download":
        return download(body)
    else:
        return {"message": "Unknown action!"}

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