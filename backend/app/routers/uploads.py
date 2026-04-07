import os
import uuid
from pathlib import Path

from fastapi import APIRouter, Depends, UploadFile, File
from fastapi.responses import JSONResponse

from app.dependencies import get_current_admin
from app.models.user import User

router = APIRouter(prefix="/api/uploads", tags=["uploads"])

UPLOAD_DIR = Path(__file__).parent.parent.parent / "uploads"
ALLOWED_TYPES = {"image/jpeg", "image/png", "image/webp", "image/gif"}
MAX_SIZE = 5 * 1024 * 1024  # 5 MB


@router.post("")
async def upload_image(
    file: UploadFile = File(...),
    admin_user: User = Depends(get_current_admin),
) -> JSONResponse:
    if file.content_type not in ALLOWED_TYPES:
        return JSONResponse(
            status_code=400,
            content={"error": f"File type '{file.content_type}' not allowed. Use JPEG, PNG, WebP, or GIF."},
        )

    data = await file.read()
    if len(data) > MAX_SIZE:
        return JSONResponse(
            status_code=400,
            content={"error": "File too large. Maximum size is 5 MB."},
        )

    UPLOAD_DIR.mkdir(parents=True, exist_ok=True)

    ext = os.path.splitext(file.filename or "image.jpg")[1].lower()
    if ext not in {".jpg", ".jpeg", ".png", ".webp", ".gif"}:
        ext = ".jpg"
    filename = f"{uuid.uuid4().hex}{ext}"
    filepath = UPLOAD_DIR / filename

    with open(filepath, "wb") as f:
        f.write(data)

    url = f"/uploads/{filename}"
    return JSONResponse(content={"url": url, "filename": filename})
