from __future__ import annotations

import os

import cloudinary
import cloudinary.uploader

from dotenv import load_dotenv


load_dotenv()


cloudinary.config(
    cloud_name=os.getenv("CLOUDINARY_CLOUD_NAME"),
    api_key=os.getenv("CLOUDINARY_API_KEY"),
    api_secret=os.getenv("CLOUDINARY_API_SECRET"),
    secure=True
)


def upload_image(file, folder: str):
    result = cloudinary.uploader.upload(
        file,
        folder=folder,
        resource_type="image"
    )

    return result