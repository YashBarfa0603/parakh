from __future__ import annotations

from app.services.cloudinary_service import upload_image


image_path = "leetcode.jpg"

result = upload_image(
    image_path,
    "parakh/test"
)

print("Upload successful!")
print("Public ID:", result["public_id"])
print("Secure URL:", result["secure_url"])
print("Asset ID:", result["asset_id"])
print("Width:", result["width"])
print("Height:", result["height"])