import uuid
import datetime
from typing import Optional
from sqlalchemy import String, Integer, Float, DateTime, Date, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column
from app.db.base import Base

class GuidelineValue(Base):
    __tablename__ = "guideline_values"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    district_id: Mapped[int] = mapped_column(Integer, ForeignKey("districts.id"), index=True)
    sro_id: Mapped[Optional[int]] = mapped_column(Integer, ForeignKey("sub_registrar_offices.id"), index=True, nullable=True)
    village_id: Mapped[Optional[int]] = mapped_column(Integer, ForeignKey("revenue_villages.id"), index=True, nullable=True)
    
    village_name_en: Mapped[str] = mapped_column(String(150), index=True)
    street_or_survey_number: Mapped[str] = mapped_column(String(200), index=True)
    classification: Mapped[str] = mapped_column(String(100)) # Residential Class I, Commercial, Agricultural wet/dry
    unit: Mapped[str] = mapped_column(String(50), default="sq_ft") # sq_ft, cent, acre, ground
    value_in_rupees: Mapped[float] = mapped_column(Float, nullable=False)
    
    effective_from: Mapped[datetime.date] = mapped_column(Date, nullable=False)
    source_attribution: Mapped[str] = mapped_column(String(200), default="TN Registration Dept Public Guideline Records")
    last_verified_at: Mapped[datetime.datetime] = mapped_column(DateTime, default=datetime.datetime.utcnow)
