import uuid
import datetime
from typing import Optional
from sqlalchemy import String, Integer, Float, Boolean, DateTime, ForeignKey, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base

class DataSource(Base):
    __tablename__ = "data_sources"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    source_type: Mapped[str] = mapped_column(String(50), nullable=False) # authorized_api, licensed_dataset, user_entered, official_redirect
    is_official: Mapped[bool] = mapped_column(Boolean, default=False)
    official_url: Mapped[str] = mapped_column(String(255), nullable=True)
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    last_synced_at: Mapped[Optional[datetime.datetime]] = mapped_column(DateTime, nullable=True)

class LandRecord(Base):
    __tablename__ = "land_records"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    district_id: Mapped[int] = mapped_column(Integer, ForeignKey("districts.id"), index=True)
    taluk_id: Mapped[int] = mapped_column(Integer, ForeignKey("taluks.id"), index=True)
    village_id: Mapped[int] = mapped_column(Integer, ForeignKey("revenue_villages.id"), index=True)
    survey_number: Mapped[str] = mapped_column(String(50), index=True, nullable=False)
    subdivision_number: Mapped[str] = mapped_column(String(50), index=True, nullable=False)
    
    # Record metadata
    patta_number: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)
    owner_name_en: Mapped[str] = mapped_column(String(200), nullable=False)
    owner_name_ta: Mapped[str] = mapped_column(String(200), nullable=False)
    land_type: Mapped[str] = mapped_column(String(100), nullable=False) # Wet (நன்செய்), Dry (புன்செய்), Natham
    extent_hectares: Mapped[float] = mapped_column(Float, default=0.0)
    extent_ares: Mapped[float] = mapped_column(Float, default=0.0)
    extent_cents: Mapped[float] = mapped_column(Float, default=0.0)
    extent_sq_ft: Mapped[float] = mapped_column(Float, default=0.0)
    fmb_sketch_url: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    
    # Compliance & labeling
    is_demo: Mapped[bool] = mapped_column(Boolean, default=True) # Always explicit if not from govt live
    source_attribution: Mapped[str] = mapped_column(String(200), default="TN LandMate Development Dataset")
    official_verification_url: Mapped[str] = mapped_column(String(255), default="https://eservices.tn.gov.in/eservicesnew/land/chitta.html")
    created_at: Mapped[datetime.datetime] = mapped_column(DateTime, default=datetime.datetime.utcnow)
