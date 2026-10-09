from typing import Optional
import datetime
from pydantic import BaseModel

class GuidelineValueResponse(BaseModel):
    id: str
    district_id: int
    sro_id: Optional[int] = None
    village_id: Optional[int] = None
    village_name_en: str
    street_or_survey_number: str
    classification: str
    unit: str
    value_in_rupees: float
    effective_from: datetime.date
    source_attribution: str
    last_verified_at: datetime.datetime

    class Config:
        from_attributes = True
