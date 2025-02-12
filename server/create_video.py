import moviepy as mp
import cv2

# TODO: Make this dynamic based on the video
TARGET_W = 202
TARGET_H = 360

def create_video(input_video_path, output_video_path, transcript, snippet):
    start_time, end_time = calculate_times(transcript, snippet)

    # Get chunks within the start and end time
    chunks = [chunk for chunk in transcript["words"] if chunk["start"] >= start_time and chunk["end"] <= end_time]

    lines = build_lines(chunks)
    
    video = mp.VideoFileClip(input_video_path)

    # Trim video
    video = video.subclipped(start_time, end_time)

    # Adjust timestamps
    first_timestamp = lines[0]["timestamp"]
    for i in range(len(lines)):
        lines[i]["timestamp"] = lines[i]["timestamp"] - first_timestamp
    start_time -= first_timestamp
    end_time -= first_timestamp
    
    for line in lines:
        print(f"{line['timestamp']}: {line['line']}")

    # Crop faces
    video = crop_faces(video)

    # Render subtitles
    video_clips = []
    for i in range(len(lines)):
        clip_start_time = lines[i]["timestamp"]
        clip_end_time = lines[i+1]["timestamp"] if i+1 < len(lines) else end_time
        try:
            video_clip = video.subclipped(clip_start_time, clip_end_time)
        except Exception as e:
            print(f"Error with subclipping: {e}")
            continue
        text_clip = mp.TextClip(text=lines[i]["line"], font="Arial.ttf", font_size=18, stroke_color="white", color="black", stroke_width=1)
        text_clip = text_clip.with_duration(clip_end_time - clip_start_time)
        text_clip = text_clip.with_position((0.5 - 0.5 * text_clip.size[0] / TARGET_W, 0.5), relative=True)
        video_clip = mp.CompositeVideoClip([video_clip, text_clip])
        video_clips.append(video_clip)
    
    # Combine all video clips
    video = mp.concatenate_videoclips(video_clips)
    video.write_videofile(output_video_path, codec="libx264")

def calculate_times(transcript, snippet):
    snippet_remaining = snippet.strip()
    start_time = None
    end_time = None
    for chunk in transcript["words"]:
        chunk_text = chunk["word"].strip()
        if snippet_remaining.startswith(chunk_text):
            # print(f"Found: {chunk_text}, remaining: {snippet_remaining[:20]}")
            start_time = start_time or chunk["start"]
            snippet_remaining = snippet_remaining[len(chunk_text):].strip()
            if snippet_remaining == "":
                end_time = chunk["end"]
                break
        else:
            # Reset
            # print(f"Resetting. Not found: {chunk_text}")
            snippet_remaining = snippet.strip()
            start_time = None
    return start_time, end_time

def build_lines(chunks):
    max_len = 20
    lines = []
    for chunk in chunks:
        chunk_text = chunk["word"].strip()
        if len(lines) > 0 and len(lines[-1]["line"]) + len(chunk_text) <= max_len:
            lines[-1]["line"] += " " + chunk_text
        else:
            lines.append({ "line": chunk_text, "timestamp": chunk["start"] })
    return lines

def fit_to_16_9(x, y, w, h, max_x, max_y):

    # Add padding to the left and right to fit the target width
    padding = (TARGET_W - w) / 2
    x = x - padding
    
    if x < 0:
        x = 0
    if x > max_x:
        x = max_x - w
    return int(x), 0, TARGET_W, TARGET_H

def crop_faces(clip):

    # Tuples of (x, y, w, h, frame_index)
    clips_data = []

    current_clip = None
    threshold = 150
    for frame_index, frame in enumerate(clip.iter_frames(fps=clip.fps, dtype='uint8')):
        rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        face_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_frontalface_default.xml')
        faces = face_cascade.detectMultiScale(rgb_frame, scaleFactor=1.1, minNeighbors=5)

        if len(faces) > 0:
            x, y, w, h = faces[0]  # Take the first detected face

            if current_clip is None or abs(x - current_clip[0]) > threshold or abs(y - current_clip[1]) > threshold:
                x, y, w, h = fit_to_16_9(x, y, w, h, frame.shape[0], frame.shape[1])
                current_clip = (x, y, w, h, frame_index)
                # print("New clip!", current_clip)
                clips_data.append(current_clip)
    
    clips = []
    for i in range(len(clips_data)):
        x, y, w, h, frame_index = clips_data[i]
        start_time = frame_index / clip.fps
        end_time = clips_data[i+1][4] / clip.fps if i+1 < len(clips_data) else clip.duration
        subclip = mp.VideoClip.subclipped(clip, start_time, end_time)
        subclip = mp.VideoClip.cropped(subclip, x1=x, y1=y, width=w, height=h)
        clips.append(subclip)

    video = mp.concatenate_videoclips(clips, method="compose")
    return video
