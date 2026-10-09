from typing import List, Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.db.session import get_db
from app.models.geography import District, Taluk, RevenueVillage, SubRegistrarOffice
from app.schemas.geography import (
    DistrictResponse, TalukResponse, RevenueVillageResponse, SubRegistrarOfficeResponse
)

router = APIRouter(tags=["Geography"])

@router.get("/districts", response_model=List[DistrictResponse])
async def list_districts(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(District).order_by(District.id))
    return [DistrictResponse.model_validate(d) for d in result.scalars().all()]

@router.get("/taluks", response_model=List[TalukResponse])
async def list_taluks(
    district_id: Optional[int] = Query(None, description="Filter by district ID"),
    db: AsyncSession = Depends(get_db)
):
    query = select(Taluk)
    if district_id:
        query = query.where(Taluk.district_id == district_id)
    result = await db.execute(query.order_by(Taluk.name_en))
    return [TalukResponse.model_validate(t) for t in result.scalars().all()]

@router.get("/villages", response_model=List[RevenueVillageResponse])
async def list_villages(
    taluk_id: Optional[int] = Query(None, description="Filter by taluk ID"),
    db: AsyncSession = Depends(get_db)
):
    query = select(RevenueVillage)
    if taluk_id:
        query = query.where(RevenueVillage.taluk_id == taluk_id)
    result = await db.execute(query.order_by(RevenueVillage.name_en))
    return [RevenueVillageResponse.model_validate(v) for v in result.scalars().all()]

@router.get("/sub-registrar-offices", response_model=List[SubRegistrarOfficeResponse])
async def list_sros(
    district_id: Optional[int] = Query(None, description="Filter by district ID"),
    db: AsyncSession = Depends(get_db)
):
    query = select(SubRegistrarOffice)
    if district_id:
        query = query.where(SubRegistrarOffice.district_id == district_id)
    result = await db.execute(query.order_by(SubRegistrarOffice.name_en))
    return [SubRegistrarOfficeResponse.model_validate(s) for s in result.scalars().all()]
