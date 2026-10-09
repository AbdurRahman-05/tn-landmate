from typing import List, Optional
from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.db.session import get_db
from app.models.guideline_value import GuidelineValue
from app.schemas.guideline_value import GuidelineValueResponse

router = APIRouter(prefix="/guideline-values", tags=["Guideline Values"])

@router.get("", response_model=List[GuidelineValueResponse])
async def search_guideline_values(
    district_id: Optional[int] = Query(None),
    village_name: Optional[str] = Query(None),
    street_name: Optional[str] = Query(None),
    db: AsyncSession = Depends(get_db)
):
    query = select(GuidelineValue)
    if district_id:
        query = query.where(GuidelineValue.district_id == district_id)
    if village_name:
        query = query.where(GuidelineValue.village_name_en.ilike(f"%{village_name}%"))
    if street_name:
        query = query.where(GuidelineValue.street_or_survey_number.ilike(f"%{street_name}%"))
    
    result = await db.execute(query.order_by(GuidelineValue.effective_from.desc()))
    return [GuidelineValueResponse.model_validate(g) for g in result.scalars().all()]

@router.get("/{id}", response_model=GuidelineValueResponse)
async def get_guideline_value(id: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(GuidelineValue).where(GuidelineValue.id == id))
    gv = result.scalars().first()
    if not gv:
        raise HTTPException(status_code=404, detail="Guideline value record not found")
    return GuidelineValueResponse.model_validate(gv)
