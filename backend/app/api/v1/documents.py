from typing import List
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.db.session import get_db
from app.models.document_guide import DocumentGuide
from app.schemas.document_guide import DocumentGuideResponse

router = APIRouter(prefix="/documents", tags=["Documents"])

@router.get("/guides", response_model=List[DocumentGuideResponse])
async def list_document_guides(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(DocumentGuide).order_by(DocumentGuide.order_index))
    guides = result.scalars().all()
    return [DocumentGuideResponse.model_validate(g) for g in guides]

@router.get("/guides/{slug}", response_model=DocumentGuideResponse)
async def get_document_guide(slug: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(DocumentGuide).where(DocumentGuide.slug == slug))
    guide = result.scalars().first()
    if not guide:
        raise HTTPException(status_code=404, detail="Document guide not found")
    return DocumentGuideResponse.model_validate(guide)

@router.post("/upload")
async def upload_document(file: UploadFile = File(...)):
    # Validate extension and size
    allowed_exts = [".pdf", ".jpg", ".jpeg", ".png"]
    filename = file.filename or "unknown"
    ext = "." + filename.split(".")[-1].lower() if "." in filename else ""
    if ext not in allowed_exts:
        raise HTTPException(status_code=400, detail="Only PDF, PNG, and JPG files are supported")
    
    content = await file.read()
    if len(content) > 10 * 1024 * 1024: # 10MB limit
        raise HTTPException(status_code=400, detail="File size exceeds maximum 10MB limit")
    
    return {
        "file_name": filename,
        "file_size_bytes": len(content),
        "content_type": file.content_type,
        "status": "uploaded_securely",
        "message": "File received in memory sandbox for temporary analysis"
    }
