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


@router.post("/export-pdf")
async def export_revenue_document_pdf(payload: dict):
    """
    Generate and stream a production-ready Tamil Nadu Revenue or Registration A4 PDF document.
    Supported doc_types: 'patta_chitta', 'a_register', 'fmb', 'registration_valuation', 'due_diligence'
    """
    from fastapi.responses import Response
    from app.services.pdf_generator_service import BackendPdfGeneratorService

    doc_type = payload.get("doc_type", "patta_chitta")
    survey = payload.get("survey_number", "104")
    subdiv = payload.get("subdivision_number", "2B")
    filename = f"TN_{doc_type.upper()}_Survey_{survey}_{subdiv}.pdf"

    pdf_bytes = BackendPdfGeneratorService.generate_pdf(doc_type, payload)

    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={
            "Content-Disposition": f'attachment; filename="{filename}"',
            "X-Document-Type": doc_type,
        },
    )


@router.get("/types")
async def list_available_document_types():
    """
    Return all official Tamil Nadu document templates supported by the PDF generation engine.
    """
    return {
        "types": [
            {
                "id": "patta_chitta",
                "name_en": "Patta / Chitta Extract",
                "name_ta": "பட்டா / சிட்டா நகல்",
                "authority": "Commissionerate of Land Administration",
                "portal": "eservices.tn.gov.in"
            },
            {
                "id": "a_register",
                "name_en": "Village A-Register Permanent Record",
                "name_ta": "அ-பதிவேடு நிரந்தர நில ஆவணம்",
                "authority": "Village Administrative Office (VAO)",
                "portal": "eservices.tn.gov.in"
            },
            {
                "id": "fmb",
                "name_en": "Field Measurement Book (FMB) Cadastral Report",
                "name_ta": "புல வரைபடம் (FMB) ஏணி அளவீட்டு அறிக்கை",
                "authority": "Directorate of Survey and Settlement",
                "portal": "eservices.tn.gov.in"
            },
            {
                "id": "registration_valuation",
                "name_en": "Stamp Duty & Registration Valuation Certificate",
                "name_ta": "முத்திரைத்தாள் & பதிவுக் கட்டண மதிப்பீட்டு சான்றிதழ்",
                "authority": "Registration Department (IGRS Tamil Nadu)",
                "portal": "tnreginet.gov.in"
            },
            {
                "id": "due_diligence",
                "name_en": "Comprehensive Land Due Diligence & Legal Title Dossier",
                "name_ta": "நில சரிபார்ப்பு முழு தணிக்கை அறிக்கை",
                "authority": "TN LandMate Certified Legal Engine",
                "portal": "tn-landmate"
            }
        ]
    }
