from typing import Optional, List
from pydantic import BaseModel

class DistrictResponse(BaseModel):
    id: int
    code: str
    name_en: str
    name_ta: str

    class Config:
        from_attributes = True

class TalukResponse(BaseModel):
    id: int
    district_id: int
    code: str
    name_en: str
    name_ta: str

    class Config:
        from_attributes = True

class RevenueVillageResponse(BaseModel):
    id: int
    taluk_id: int
    code: str
    name_en: str
    name_ta: str

    class Config:
        from_attributes = True

class SubRegistrarOfficeResponse(BaseModel):
    id: int
    district_id: int
    zone: str
    name_en: str
    name_ta: str
    address: Optional[str] = None

    class Config:
        from_attributes = True
