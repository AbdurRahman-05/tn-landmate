from typing import Optional, List
import datetime
from pydantic import BaseModel, Field

class PropertyCreate(BaseModel):
    nickname: str = Field(..., min_length=1, max_length=150)
    district_name: str
    taluk_name: str
    village_name: str
    survey_number: str
    subdivision_number: str
    extent_value: float = Field(default=0.0, ge=0)
    extent_unit: str = "cents"
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    notes: Optional[str] = None
    estimated_market_value: Optional[float] = None
    local_device_id: Optional[str] = None

class PropertyUpdate(BaseModel):
    nickname: Optional[str] = None
    district_name: Optional[str] = None
    taluk_name: Optional[str] = None
    village_name: Optional[str] = None
    survey_number: Optional[str] = None
    subdivision_number: Optional[str] = None
    extent_value: Optional[float] = None
    extent_unit: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    notes: Optional[str] = None
    estimated_market_value: Optional[float] = None

class PropertyResponse(BaseModel):
    id: str
    user_id: Optional[str] = None
    nickname: str
    district_name: str
    taluk_name: str
    village_name: str
    survey_number: str
    subdivision_number: str
    extent_value: float
    extent_unit: str
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    notes: Optional[str] = None
    estimated_market_value: Optional[float] = None
    created_at: datetime.datetime
    updated_at: datetime.datetime

    class Config:
        from_attributes = True
