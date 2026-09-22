from __future__ import annotations

import os
import base64
import mimetypes
import httpx
from dotenv import load_dotenv

load_dotenv()

API_KEY = os.getenv("NVIDIA_API_KEY")

if not API_KEY:
    raise RuntimeError("NVIDIA_API_KEY is not set")

IMAGE_PATH = "product.png"

mime_type = mimetypes.guess_type(IMAGE_PATH)[0] or "image/jpeg"

with open(IMAGE_PATH, "rb") as file:
    image_bytes = file.read()

encoded_image = base64.b64encode(image_bytes).decode("utf-8")

payload = {
    "input": [
        {
            "type": "image_url",
            "url": f"data:{mime_type};base64,{encoded_image}"
        }
    ],
    "merge_levels": ["word"]
}

headers = {
    "Authorization": f"Bearer {API_KEY}",
    "Content-Type": "application/json",
    "Accept": "application/json"
}

response = httpx.post(
    "https://ai.api.nvidia.com/v1/cv/nvidia/nemotron-ocr-v2",
    headers=headers,
    json=payload,
    timeout=120
)

print("Status:", response.status_code)
print(response.text)