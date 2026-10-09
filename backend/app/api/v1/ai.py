from fastapi import APIRouter
from app.schemas.ai import (
    AIAssistantRequest, AIAssistantResponse,
    AIDocumentExtractRequest, AIDocumentExtractResponse
)
from app.services.ai_service import AIService

router = APIRouter(prefix="/ai", tags=["AI Land Assistant"])

@router.post("/ask", response_model=AIAssistantResponse)
async def ask_assistant(request: AIAssistantRequest):
    result = AIService.answer_query(request.query, request.language or "en")
    return AIAssistantResponse(**result)

@router.post("/extract-document", response_model=AIDocumentExtractResponse)
async def extract_document_fields(request: AIDocumentExtractRequest):
    result = AIService.extract_document_fields(
        document_type=request.document_type,
        file_name=request.file_name,
        ocr_text=request.ocr_raw_text
    )
    return AIDocumentExtractResponse(**result)
