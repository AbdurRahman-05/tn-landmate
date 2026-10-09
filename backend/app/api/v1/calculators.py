from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.db.session import get_db
from app.schemas.calculator import (
    AreaConversionRequest, AreaConversionResponse,
    PlotAreaRequest, PlotAreaResponse,
    RegistrationEstimateRequest, RegistrationEstimateResponse
)
from app.services.calculators import LandCalculatorService
from app.models.calculator_rule import CalculatorRule

router = APIRouter(prefix="/calculators", tags=["Calculators"])

@router.post("/area-conversion", response_model=AreaConversionResponse)
async def convert_area(request: AreaConversionRequest):
    try:
        result = LandCalculatorService.convert_area(request.value, request.from_unit)
        return AreaConversionResponse(**result)
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Conversion error: {str(e)}")

@router.post("/plot-area", response_model=PlotAreaResponse)
async def calculate_plot_area(request: PlotAreaRequest):
    try:
        result = LandCalculatorService.calculate_plot_area(
            shape=request.shape,
            unit=request.unit,
            length=request.length,
            width=request.width,
            base=request.base,
            height=request.height,
            parallel_side_a=request.parallel_side_a,
            parallel_side_b=request.parallel_side_b,
            trapezoid_height=request.trapezoid_height,
            sections=request.sections
        )
        return PlotAreaResponse(**result)
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Plot calculation error: {str(e)}")

@router.post("/registration-estimate", response_model=RegistrationEstimateResponse)
async def estimate_registration(
    request: RegistrationEstimateRequest,
    db: AsyncSession = Depends(get_db)
):
    # Determine rates: custom override or look up from active effective rules
    stamp_rate = 7.0
    reg_rate = 2.0
    cess = 100.0
    rule_name = "Default TN Registration Department Rates"
    eff_from = "2024-04-01"
    is_custom = False

    if request.custom_stamp_duty_rate is not None and request.custom_registration_rate is not None:
        stamp_rate = request.custom_stamp_duty_rate
        reg_rate = request.custom_registration_rate
        rule_name = "User Custom Defined Rate"
        eff_from = None
        is_custom = True
    else:
        # Query rules table
        query = select(CalculatorRule).where(
            CalculatorRule.transaction_type == request.transaction_type,
            CalculatorRule.is_active == True
        ).order_by(CalculatorRule.effective_from.desc())
        result = await db.execute(query)
        rule = result.scalars().first()
        if rule:
            stamp_rate = rule.stamp_duty_rate
            reg_rate = rule.registration_fee_rate
            cess = rule.fixed_cess
            rule_name = rule.rule_name
            eff_from = rule.effective_from.isoformat()

    calc = LandCalculatorService.calculate_registration(
        property_value=request.market_or_guideline_value,
        stamp_duty_rate=stamp_rate,
        registration_rate=reg_rate,
        fixed_cess=cess,
        rule_name=rule_name,
        effective_from=eff_from,
        is_custom_rate=is_custom
    )
    return RegistrationEstimateResponse(**calc)
