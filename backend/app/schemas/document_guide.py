from typing import Optional, List, Dict, Any
import datetime
from pydantic import BaseModel

class DocumentGuideResponse(BaseModel):
    id: str
    slug: str
    title_en: str
    title_ta: str
    summary_en: str
    summary_ta: str
    why_it_matters_en: str
    why_it_matters_ta: str
    key_fields: List[Dict[str, Any]]
    how_to_verify_en: str
    how_to_verify_ta: str
    official_portal_url: str
    order_index: int

    class Config:
        from_attributes = True
