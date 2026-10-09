from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.db.session import get_db
from app.models.user import User
from app.models.property import SavedProperty
from app.schemas.property import PropertyCreate, PropertyUpdate, PropertyResponse
from app.core.deps import get_optional_current_user

router = APIRouter(prefix="/properties", tags=["Properties"])

@router.get("", response_model=List[PropertyResponse])
async def list_properties(
    local_device_id: Optional[str] = Query(None),
    current_user: Optional[User] = Depends(get_optional_current_user),
    db: AsyncSession = Depends(get_db)
):
    query = select(SavedProperty)
    if current_user:
        query = query.where(SavedProperty.user_id == current_user.id)
    elif local_device_id:
        query = query.where(SavedProperty.local_device_id == local_device_id)
    else:
        # Return empty list if guest doesn't supply a local_device_id
        return []
    
    result = await db.execute(query.order_by(SavedProperty.created_at.desc()))
    return [PropertyResponse.model_validate(p) for p in result.scalars().all()]

@router.post("", response_model=PropertyResponse, status_code=status.HTTP_201_CREATED)
async def create_property(
    prop_in: PropertyCreate,
    current_user: Optional[User] = Depends(get_optional_current_user),
    db: AsyncSession = Depends(get_db)
):
    prop = SavedProperty(
        user_id=current_user.id if current_user else None,
        local_device_id=prop_in.local_device_id,
        nickname=prop_in.nickname,
        district_name=prop_in.district_name,
        taluk_name=prop_in.taluk_name,
        village_name=prop_in.village_name,
        survey_number=prop_in.survey_number,
        subdivision_number=prop_in.subdivision_number,
        extent_value=prop_in.extent_value,
        extent_unit=prop_in.extent_unit,
        latitude=prop_in.latitude,
        longitude=prop_in.longitude,
        notes=prop_in.notes,
        estimated_market_value=prop_in.estimated_market_value
    )
    db.add(prop)
    await db.commit()
    await db.refresh(prop)
    return PropertyResponse.model_validate(prop)

@router.get("/{id}", response_model=PropertyResponse)
async def get_property(
    id: str,
    current_user: Optional[User] = Depends(get_optional_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(SavedProperty).where(SavedProperty.id == id))
    prop = result.scalars().first()
    if not prop:
        raise HTTPException(status_code=404, detail="Property not found")
    if current_user and prop.user_id and prop.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Unauthorized access to this property record")
    return PropertyResponse.model_validate(prop)

@router.patch("/{id}", response_model=PropertyResponse)
async def update_property(
    id: str,
    prop_update: PropertyUpdate,
    current_user: Optional[User] = Depends(get_optional_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(SavedProperty).where(SavedProperty.id == id))
    prop = result.scalars().first()
    if not prop:
        raise HTTPException(status_code=404, detail="Property not found")
    if current_user and prop.user_id and prop.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Unauthorized to modify this property record")
    
    update_data = prop_update.model_dump(exclude_unset=True)
    for field, val in update_data.items():
        setattr(prop, field, val)
    
    await db.commit()
    await db.refresh(prop)
    return PropertyResponse.model_validate(prop)

@router.delete("/{id}")
async def delete_property(
    id: str,
    current_user: Optional[User] = Depends(get_optional_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(SavedProperty).where(SavedProperty.id == id))
    prop = result.scalars().first()
    if not prop:
        raise HTTPException(status_code=404, detail="Property not found")
    if current_user and prop.user_id and prop.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Unauthorized to delete this property record")
    
    await db.delete(prop)
    await db.commit()
    return {"message": "Property record deleted successfully"}
