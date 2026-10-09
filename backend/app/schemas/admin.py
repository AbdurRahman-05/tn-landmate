from typing import Optional, List, Dict, Any
import datetime
from pydantic import BaseModel

class SystemStatsResponse(BaseModel):
    total_districts: int
    total_taluks: int
    total_villages: int
    total_sros: int
    total_land_records: int
    total_guideline_values: int
    total_calculator_rules: int
    total_users: int
    total_saved_properties: int
    timestamp: datetime.datetime

class CalculatorRuleCreate(BaseModel):
    rule_name: str
    jurisdiction: str = "tamil_nadu_state"
    transaction_type: str = "sale"
    property_type: str = "all"
    stamp_duty_rate: float
    registration_fee_rate: float
    transfer_duty_rate: float = 0.0
    fixed_cess: float = 0.0
    effective_from: datetime.date
    effective_to: Optional[datetime.date] = None
    official_order_ref: Optional[str] = None
    is_active: bool = True

class CalculatorRuleResponse(CalculatorRuleCreate):
    id: str
    created_at: datetime.datetime

    class Config:
        from_attributes = True

class GuidelineValueCreate(BaseModel):
    district_id: int
    sro_id: Optional[int] = None
    village_id: Optional[int] = None
    village_name_en: str
    street_or_survey_number: str
    classification: str
    unit: str = "sq_ft"
    value_in_rupees: float
    effective_from: datetime.date
    source_attribution: str = "TN Registration Dept Public Guideline Records"
