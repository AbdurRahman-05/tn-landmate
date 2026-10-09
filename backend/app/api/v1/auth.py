import datetime
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.db.session import get_db
from app.models.user import User, RefreshToken
from app.schemas.auth import (
    UserCreate, UserLogin, UserResponse, TokenResponse,
    RefreshTokenRequest, RefreshTokenResponse
)
from app.core.security import (
    verify_password, get_password_hash, create_access_token,
    create_refresh_token, decode_token
)
from app.core.deps import get_current_user

router = APIRouter(prefix="/auth", tags=["Authentication"])

@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
async def register(user_in: UserCreate, db: AsyncSession = Depends(get_db)):
    # Check if email exists
    result = await db.execute(select(User).where(User.email == user_in.email.lower()))
    if result.scalars().first():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="A user with this email address already exists"
        )
    
    user = User(
        email=user_in.email.lower(),
        hashed_password=get_password_hash(user_in.password),
        full_name=user_in.full_name,
        phone=user_in.phone,
        role=user_in.role or "citizen",
        preferred_language=user_in.preferred_language or "en"
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)

    # Generate tokens
    access_token = create_access_token(user.id)
    refresh_token = create_refresh_token(user.id)

    db_rf = RefreshToken(
        user_id=user.id,
        token=refresh_token,
        expires_at=datetime.datetime.utcnow() + datetime.timedelta(days=7)
    )
    db.add(db_rf)
    await db.commit()

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="bearer",
        user=UserResponse.model_validate(user)
    )

@router.post("/login", response_model=TokenResponse)
async def login(credentials: UserLogin, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.email == credentials.username.lower()))
    user = result.scalars().first()
    if not user or not verify_password(credentials.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password"
        )
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User account is deactivated"
        )

    access_token = create_access_token(user.id)
    refresh_token = create_refresh_token(user.id)

    db_rf = RefreshToken(
        user_id=user.id,
        token=refresh_token,
        expires_at=datetime.datetime.utcnow() + datetime.timedelta(days=7)
    )
    db.add(db_rf)
    await db.commit()

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="bearer",
        user=UserResponse.model_validate(user)
    )

@router.post("/refresh", response_model=RefreshTokenResponse)
async def refresh_token_endpoint(rf_in: RefreshTokenRequest, db: AsyncSession = Depends(get_db)):
    payload = decode_token(rf_in.refresh_token)
    if not payload or payload.get("type") != "refresh":
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid refresh token")
    
    user_id = payload.get("sub")
    query = select(RefreshToken).where(
        RefreshToken.token == rf_in.refresh_token,
        RefreshToken.is_revoked == False
    )
    result = await db.execute(query)
    stored_rf = result.scalars().first()
    if not stored_rf:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Refresh token has been revoked or expired")
    
    # Revoke old token
    stored_rf.is_revoked = True
    
    # Generate new pair
    new_access_token = create_access_token(user_id)
    new_refresh_token = create_refresh_token(user_id)

    db.add(RefreshToken(
        user_id=user_id,
        token=new_refresh_token,
        expires_at=datetime.datetime.utcnow() + datetime.timedelta(days=7)
    ))
    await db.commit()

    return RefreshTokenResponse(
        access_token=new_access_token,
        refresh_token=new_refresh_token,
        token_type="bearer"
    )

@router.post("/logout")
async def logout(rf_in: RefreshTokenRequest, db: AsyncSession = Depends(get_db)):
    query = select(RefreshToken).where(RefreshToken.token == rf_in.refresh_token)
    result = await db.execute(query)
    token_record = result.scalars().first()
    if token_record:
        token_record.is_revoked = True
        await db.commit()
    return {"message": "Logged out successfully"}

@router.get("/me", response_model=UserResponse)
async def get_my_profile(current_user: User = Depends(get_current_user)):
    return UserResponse.model_validate(current_user)
