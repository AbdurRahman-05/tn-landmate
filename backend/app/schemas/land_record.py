from typing import Optional, List
from pydantic import BaseModel

class LandSearchRequest(BaseModel):
    district_id: int
    taluk_id: int
    village_id: int
    survey_number: str
    subdivision_number: str
    record_type: Optional[str] = "patta_chitta" # patta_chitta, a_register, fmb

class LandRecordDetail(BaseModel):
    patta_number: Optional[str] = None
    owner_name_en: str
    owner_name_ta: str
    land_type: str
    extent_hectares: float
    extent_ares: float
    extent_cents: float
    extent_sq_ft: float
    fmb_sketch_url: Optional[str] = None
    record_type: Optional[str] = "patta_chitta"
    soil_type: Optional[str] = None
    assessment_rate: Optional[str] = None
    is_poramboke: Optional[bool] = False
    guideline_value_sq_ft: Optional[float] = None
    guideline_value_acre: Optional[float] = None
    street_name: Optional[str] = None
    sro_name: Optional[str] = None


class LandSearchResponse(BaseModel):
    status: str
    provider_type: str # authorized_api, licensed_dataset, user_entered, official_redirect
    is_demo: bool
    disclaimer: str
    official_verification_url: str
    record: Optional[LandRecordDetail] = None
    source_attribution: str

class DataSourceResponse(BaseModel):
    id: str
    name: str
    source_type: str
    is_official: bool
    official_url: Optional[str] = None
    description: Optional[str] = None

class LiveSessionRequest(BaseModel):
    district_id: int
    taluk_id: int
    village_id: int
    survey_number: str
    subdivision_number: str
    record_type: Optional[str] = "patta_chitta"

class LiveSessionResponse(BaseModel):
    session_id: str
    is_live_portal: bool
    portal_name: str
    captcha_image_base64: str
    captcha_type: str = "image"
    challenge_text: Optional[str] = "Enter the characters shown in the government portal CAPTCHA image"
    expires_in_seconds: int = 180
    message: str

class LiveFetchRequest(BaseModel):
    session_id: str
    captcha_value: str
    district_id: int
    taluk_id: int
    village_id: int
    survey_number: str
    subdivision_number: str
    record_type: Optional[str] = "patta_chitta"
    district_name: Optional[str] = None
    taluk_name: Optional[str] = None
    village_name: Optional[str] = None


class LiveFetchResponse(BaseModel):
    success: bool
    message: str
    is_live_portal: bool
    source_portal: str
    fetched_at: str
    official_reference_number: Optional[str] = None
    disclaimer: str
    record: Optional[LandRecordDetail] = None

