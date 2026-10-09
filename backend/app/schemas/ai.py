from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field

class AIAssistantRequest(BaseModel):
    query: str = Field(..., min_length=2, description="Land or document related question")
    language: Optional[str] = "en" # en or ta
    context: Optional[str] = None

class AIAssistantResponse(BaseModel):
    query: str
    response: str
    confidence: float
    disclaimer: str
    suggested_questions: List[str]

class AIDocumentExtractRequest(BaseModel):
    document_type: str = Field(..., description="patta, chitta, sale_deed, ec")
    file_name: str
    ocr_raw_text: Optional[str] = None

class ExtractedField(BaseModel):
    field_name: str
    extracted_value: str
    confidence: float
    is_uncertain: bool

class AIDocumentExtractResponse(BaseModel):
    document_type: str
    extracted_fields: List[ExtractedField]
    checklist_status: Dict[str, bool]
    summary_explanation: str
    disclaimer: str
