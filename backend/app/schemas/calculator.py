from typing import Dict, List, Optional, Any
from pydantic import BaseModel, Field

class AreaConversionRequest(BaseModel):
    value: float = Field(..., gt=0, description="Numerical area value to convert")
    from_unit: str = Field(..., description="Source unit: square_feet, square_meters, square_yards, cents, grounds, acres, hectares, square_kilometers")

class AreaConversionResponse(BaseModel):
    input_value: float
    input_unit: str
    square_feet: float
    square_meters: float
    square_yards: float
    cents: float
    grounds: float
    acres: float
    hectares: float
    square_kilometers: float
    formatted: Dict[str, str]

class PlotSection(BaseModel):
    name: Optional[str] = "Section"
    length: float = Field(..., gt=0)
    width: float = Field(..., gt=0)

class PlotAreaRequest(BaseModel):
    shape: str = Field(..., description="rectangle, triangle, trapezoid, composite")
    unit: str = Field(default="feet", description="feet, meters, yards")
    
    # Rectangle
    length: Optional[float] = None
    width: Optional[float] = None
    
    # Triangle
    base: Optional[float] = None
    height: Optional[float] = None
    
    # Trapezoid
    parallel_side_a: Optional[float] = None
    parallel_side_b: Optional[float] = None
    trapezoid_height: Optional[float] = None
    
    # Composite
    sections: Optional[List[PlotSection]] = None

class PlotAreaResponse(BaseModel):
    shape: str
    input_unit: str
    total_square_feet: float
    square_meters: float
    square_yards: float
    cents: float
    grounds: float
    acres: float
    hectares: float
    disclaimer: str

class RegistrationEstimateRequest(BaseModel):
    transaction_type: str = Field(default="sale", description="sale, settlement_family, mortgage, gift")
    property_category: str = Field(default="residential_plot")
    market_or_guideline_value: float = Field(..., gt=0, description="Total property consideration or guideline value in INR")
    jurisdiction: Optional[str] = "tamil_nadu_state"
    custom_stamp_duty_rate: Optional[float] = None
    custom_registration_rate: Optional[float] = None

class RegistrationEstimateResponse(BaseModel):
    property_value: float
    transaction_type: str
    stamp_duty_rate_percent: float
    stamp_duty_amount: float
    registration_fee_rate_percent: float
    registration_fee_amount: float
    fixed_cess_amount: float
    total_government_charges: float
    total_estimated_transaction_cost: float
    effective_rule_applied: str
    effective_from: Optional[str] = None
    is_custom_rate: bool = False
    disclaimer: str
