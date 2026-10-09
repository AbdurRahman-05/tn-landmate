import datetime
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from app.db.session import get_db
from app.core.deps import get_current_admin
from app.models import (
    User, District, Taluk, RevenueVillage, SubRegistrarOffice,
    LandRecord, GuidelineValue, CalculatorRule, SavedProperty
)
from app.schemas.admin import (
    SystemStatsResponse, CalculatorRuleCreate, CalculatorRuleResponse, GuidelineValueCreate
)
from app.schemas.guideline_value import GuidelineValueResponse

router = APIRouter(prefix="/admin", tags=["Administration"])

@router.get("/stats", response_model=SystemStatsResponse)
async def get_system_stats(
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    total_districts = (await db.execute(select(func.count(District.id)))).scalar_one()
    total_taluks = (await db.execute(select(func.count(Taluk.id)))).scalar_one()
    total_villages = (await db.execute(select(func.count(RevenueVillage.id)))).scalar_one()
    total_sros = (await db.execute(select(func.count(SubRegistrarOffice.id)))).scalar_one()
    total_records = (await db.execute(select(func.count(LandRecord.id)))).scalar_one()
    total_gvs = (await db.execute(select(func.count(GuidelineValue.id)))).scalar_one()
    total_rules = (await db.execute(select(func.count(CalculatorRule.id)))).scalar_one()
    total_users = (await db.execute(select(func.count(User.id)))).scalar_one()
    total_props = (await db.execute(select(func.count(SavedProperty.id)))).scalar_one()

    return SystemStatsResponse(
        total_districts=total_districts,
        total_taluks=total_taluks,
        total_villages=total_villages,
        total_sros=total_sros,
        total_land_records=total_records,
        total_guideline_values=total_gvs,
        total_calculator_rules=total_rules,
        total_users=total_users,
        total_saved_properties=total_props,
        timestamp=datetime.datetime.utcnow()
    )

@router.get("/calculator-rules", response_model=List[CalculatorRuleResponse])
async def list_admin_rules(
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(CalculatorRule).order_by(CalculatorRule.effective_from.desc()))
    return [CalculatorRuleResponse.model_validate(r) for r in result.scalars().all()]

@router.post("/calculator-rules", response_model=CalculatorRuleResponse, status_code=status.HTTP_201_CREATED)
async def create_calculator_rule(
    rule_in: CalculatorRuleCreate,
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    rule = CalculatorRule(**rule_in.model_dump())
    db.add(rule)
    await db.commit()
    await db.refresh(rule)
    return CalculatorRuleResponse.model_validate(rule)

@router.post("/guideline-values", response_model=GuidelineValueResponse, status_code=status.HTTP_201_CREATED)
async def create_guideline_value(
    gv_in: GuidelineValueCreate,
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    gv = GuidelineValue(**gv_in.model_dump())
    db.add(gv)
    await db.commit()
    await db.refresh(gv)
    return GuidelineValueResponse.model_validate(gv)
