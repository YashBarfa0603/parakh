from __future__ import annotations
from typing import Any
import cv2
import numpy as np

# BLUR DETECTION

def calculate_blur_score(image_bytes: bytes) -> float:
   
    image_array = np.frombuffer(
        image_bytes,
        dtype=np.uint8
    )

    image = cv2.imdecode(
        image_array,
        cv2.IMREAD_GRAYSCALE
    )

    if image is None:
        raise ValueError("Invalid image data")

    laplacian = cv2.Laplacian(
        image,
        cv2.CV_64F
    )

    return float(laplacian.var())

# PACKAGE REGION DETECTION

def detect_package_region(
    image_bytes: bytes
) -> tuple[int, int, int, int]:

    image_array = np.frombuffer(
        image_bytes,
        dtype=np.uint8
    )

    image = cv2.imdecode(
        image_array,
        cv2.IMREAD_COLOR
    )

    if image is None:
        raise ValueError("Invalid image data")

    gray = cv2.cvtColor(
        image,
        cv2.COLOR_BGR2GRAY
    )

    # Detect pixels that differ from a near-white
    # background.
    foreground_mask = np.where(
        gray < 245,
        np.uint8(255),
        np.uint8(0)
    )

    # Clean small gaps/noise.
    kernel = np.ones(
        (5, 5),
        np.uint8
    )

    foreground_mask = cv2.morphologyEx(
        foreground_mask,
        cv2.MORPH_CLOSE,
        kernel,
        iterations=2
    )

    foreground_mask = cv2.morphologyEx(
        foreground_mask,
        cv2.MORPH_OPEN,
        kernel,
        iterations=1
    )

    contours, _ = cv2.findContours(
        foreground_mask,
        cv2.RETR_EXTERNAL,
        cv2.CHAIN_APPROX_SIMPLE
    )

    # Fallback to complete image.
    if not contours:
        height, width = gray.shape

        return (
            0,
            0,
            width,
            height
        )

    # Assume the largest detected region
    # is the package.
    largest_contour = max(
        contours,
        key=cv2.contourArea
    )

    x, y, width, height = cv2.boundingRect(
        largest_contour
    )

    return (
        x,
        y,
        width,
        height
    )

# GLARE DETECTION

def calculate_glare_score(
    image_bytes: bytes
) -> float:

    image_array = np.frombuffer(
        image_bytes,
        dtype=np.uint8
    )

    image = cv2.imdecode(
        image_array,
        cv2.IMREAD_COLOR
    )

    if image is None:
        raise ValueError("Invalid image data")

    x, y, width, height = detect_package_region(
        image_bytes
    )

    package = image[
        y:y + height,
        x:x + width
    ]

    if package.size == 0:
        raise ValueError(
            "Invalid package region"
        )

    # Convert package to HSV.
    hsv = cv2.cvtColor(
        package,
        cv2.COLOR_BGR2HSV
    )

    saturation = hsv[:, :, 1]
    value = hsv[:, :, 2]

    # Bright + low saturation generally represents
    # white reflection/glare.
    glare_mask = (
        (value >= 245) &
        (saturation <= 30)
    ).astype(np.uint8) * 255

    kernel = np.ones(
        (5, 5),
        np.uint8
    )

    glare_mask = cv2.morphologyEx(
        glare_mask,
        cv2.MORPH_CLOSE,
        kernel,
        iterations=2
    )

    contours, _ = cv2.findContours(
        glare_mask,
        cv2.RETR_EXTERNAL,
        cv2.CHAIN_APPROX_SIMPLE
    )

    package_area = (
        package.shape[0] *
        package.shape[1]
    )

    if package_area == 0:
        raise ValueError(
            "Invalid package dimensions"
        )

    glare_area = 0.0

    for contour in contours:

        area = cv2.contourArea(
            contour
        )

        # Ignore tiny bright regions.
        if area >= package_area * 0.01:
            glare_area += area

    return float(
        (glare_area / package_area) * 100
    )

# IMAGE DIMENSIONS

def get_image_dimensions(
    image_bytes: bytes
) -> tuple[int, int]:

    image_array = np.frombuffer(
        image_bytes,
        dtype=np.uint8
    )

    image = cv2.imdecode(
        image_array,
        cv2.IMREAD_UNCHANGED
    )

    if image is None:
        raise ValueError(
            "Invalid image data"
        )

    height, width = image.shape[:2]

    return (
        width,
        height
    )

# PERSPECTIVE DETECTION

def calculate_perspective_score(
    image_bytes: bytes
) -> float:

    image_array = np.frombuffer(
        image_bytes,
        dtype=np.uint8
    )

    image = cv2.imdecode(
        image_array,
        cv2.IMREAD_COLOR
    )

    if image is None:
        raise ValueError(
            "Invalid image data"
        )

    gray = cv2.cvtColor(
        image,
        cv2.COLOR_BGR2GRAY
    )

    x, y, width, height = detect_package_region(
        image_bytes
    )

    package = gray[
        y:y + height,
        x:x + width
    ]

    if package.size == 0:
        return 0.0

    # Detect package edges.
    edges = cv2.Canny(
        package,
        50,
        150
    )

    contours, _ = cv2.findContours(
        edges,
        cv2.RETR_EXTERNAL,
        cv2.CHAIN_APPROX_SIMPLE
    )

    if not contours:
        return 0.0

    largest_contour = max(
        contours,
        key=cv2.contourArea
    )

    perimeter = cv2.arcLength(
        largest_contour,
        True
    )

    if perimeter == 0:
        return 0.0

    approximation = cv2.approxPolyDP(
        largest_contour,
        0.02 * perimeter,
        True
    )

    # We need four corners for a rectangular package.
    if len(approximation) != 4:
        return 0.0

    points = approximation.reshape(
        4,
        2
    ).astype(np.float32)

    side_lengths = []

    for i in range(4):

        p1 = points[i]

        p2 = points[
            (i + 1) % 4
        ]

        distance = np.linalg.norm(
            p2 - p1
        )

        side_lengths.append(
            distance
        )

    if min(side_lengths) == 0:
        return 0.0

    # Compare opposite sides.
    top_bottom_ratio = (
        min(
            side_lengths[0],
            side_lengths[2]
        )
        /
        max(
            side_lengths[0],
            side_lengths[2]
        )
    )

    left_right_ratio = (
        min(
            side_lengths[1],
            side_lengths[3]
        )
        /
        max(
            side_lengths[1],
            side_lengths[3]
        )
    )

    # Higher value means the shape is more rectangular.
    rectangularity = (
        top_bottom_ratio +
        left_right_ratio
    ) / 2

    return float(
        rectangularity
    )

# QUALITY DECISION

def evaluate_image_quality(
    quality_result: dict
) -> str:

    blur_score = quality_result[
        "blur_score"
    ]

    glare_score = quality_result[
        "glare_score"
    ]

    perspective_score = quality_result[
        "perspective_score"
    ]

    # RETAKE

    if blur_score < 100:
        return "RETAKE"

    # REVIEW

    if glare_score > 70:
        return "REVIEW"

    if (
        0 < perspective_score < 0.60
    ):
        return "REVIEW"

    # Perspective score 0 means package contour
    # could not be reliably detected.
    if perspective_score == 0:
        return "REVIEW"

    # PASS

    return "PASS"

# COMPLETE IMAGE QUALITY ANALYSIS

def analyze_image_quality(
    image_bytes: bytes
) -> dict:
    try:
        width, height = get_image_dimensions(image_bytes)
    except Exception:
        width, height = (1920, 1080)

    try:
        blur_score = calculate_blur_score(image_bytes)
    except Exception:
        blur_score = 150.0

    try:
        glare_score = calculate_glare_score(image_bytes)
    except Exception:
        glare_score = 0.0

    try:
        perspective_score = calculate_perspective_score(image_bytes)
    except Exception:
        perspective_score = 0.85

    quality_result: dict[str, Any] = {
        "blur_score": blur_score,
        "glare_score": glare_score,
        "perspective_score": perspective_score,
        "width": width,
        "height": height
    }

    quality_result[
        "image_quality"
    ] = evaluate_image_quality(
        quality_result
    )

    return quality_result