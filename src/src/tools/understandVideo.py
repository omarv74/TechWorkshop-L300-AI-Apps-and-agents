import os
import cv2
import base64
import tempfile
import requests
from openai import AzureOpenAI
import numpy as np
import time
from dotenv import load_dotenv
# Load environment variables (Azure endpoint, deployment, keys, etc.)
load_dotenv()

# GPT model credentials
gpt_endpoint = os.getenv("gpt_endpoint")
gpt_deployment = os.getenv("gpt_deployment")
gpt_api_key = os.getenv("gpt_api_key")

# Initialize Azure OpenAI client
client = AzureOpenAI(
    azure_endpoint=gpt_endpoint,
    api_key=gpt_api_key,
    api_version="2025-01-01-preview",
)

def download_video_if_needed(video_path):
    """
    If video_path is a URL, download it to a temporary local file.
    Otherwise, return the original path.
    """
    if video_path.startswith("http://") or video_path.startswith("https://"):
        response = requests.get(video_path, stream=True)
        if response.status_code == 200:
            temp_file = tempfile.NamedTemporaryFile(delete=False, suffix=".mp4")
            with open(temp_file.name, 'wb') as f:
                for chunk in response.iter_content(chunk_size=8192):
                    f.write(chunk)
            print(f"Downloaded video to: {temp_file.name}")
            return temp_file.name, True
        else:
            raise Exception(f"Failed to download video: {video_path}")
    else:
        return video_path, False

def get_video_summary(video_path, seconds_per_frame=2):
    print(f"Processing video: {video_path} with frame interval: {seconds_per_frame}s")
    start_time = time.time()

    # Step 1: Download if needed
    local_video_path, is_temp_file = download_video_if_needed(video_path)

    def process_video(local_path, seconds_per_frame=2):
        start_proc = time.time()
        print(f"Extracting frames from: {local_path}")
        base64_frames = []

        video = cv2.VideoCapture(local_path)
        if not video.isOpened():
            raise Exception(f"Failed to open video: {local_path}")

        total_frames = int(video.get(cv2.CAP_PROP_FRAME_COUNT))
        print(f"Total frames: {total_frames}")
        fps = video.get(cv2.CAP_PROP_FPS)
        duration = total_frames / fps if fps > 0 else 0
        max_seconds = min(5, duration)
        max_frames = min(10, int(fps * max_seconds))
        if max_frames == 0:
            max_frames = min(10, total_frames)

        frame_indices = np.linspace(0, int(fps * max_seconds) - 1, num=max_frames, dtype=int)
        for idx in frame_indices:
            video.set(cv2.CAP_PROP_POS_FRAMES, idx)
            success, frame = video.read()
            if not success:
                continue
            frame = cv2.resize(frame, (224, 224))
            _, buffer = cv2.imencode(".jpg", frame, [int(cv2.IMWRITE_JPEG_QUALITY), 60])
            base64_image = base64.b64encode(buffer).decode("utf-8")
            base64_frames.append(base64_image)

        video.release()
        print(f"Extracted {len(base64_frames)} frames")
        print(f"process_video Execution Time: {time.time() - start_proc:.2f} seconds")
        return base64_frames

    def summarize_video(base64_frames):
        start_sum = time.time()
        selected_frames = base64_frames[:10]
        content = [{"type": "text", "text": "These are the frames from the video. Please summarize the video content."}]
        for img in selected_frames:
            content.append({
                "type": "image_url",
                "image_url": {
                    "url": f"data:image/jpeg;base64,{img}",
                    "detail": "low"
                }
            })

        chat_prompt = [
            {
                "role": "system",
                "content": [{
                    "type": "text",
                    "text": "You are a helpful assistant that summarizes video content using frames. Respond in Markdown.Keep the response concise and focused on the main points of the video."
                }]
            },
            {"role": "user", "content": content}
        ]

        completion = client.chat.completions.create(
            model=gpt_deployment,
            messages=chat_prompt,
            max_tokens=1000,
            top_p=1,
            frequency_penalty=0,
            presence_penalty=0,
        )

        print(f"summarize_video Execution Time: {time.time() - start_sum:.2f} seconds")
        return completion.choices[0].message.content

    try:
        base64_frames = process_video(local_video_path, seconds_per_frame)
        if not base64_frames:
            return "No frames extracted. Cannot summarize the video."
        summary = summarize_video(base64_frames)
    finally:
        if is_temp_file and os.path.exists(local_video_path):
            os.remove(local_video_path)

    print(f"get_video_summary Execution Time: {time.time() - start_time:.2f} seconds")
    return summary
# # Example usage
##tested with local path for video: C:\MSFT 2025\Painter Tape.mp4
# video_path =  "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4"
# summary = get_video_summary(video_path, seconds_per_frame=1)
# print(summary)