import uuid
import datetime
from typing import Optional, List
from sqlalchemy import String, Integer, Float, DateTime, ForeignKey, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base

class SavedProperty(Base):
    __tablename__ = "saved_properties"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id: Mapped[Optional[str]] = mapped_column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=True, index=True)
    local_device_id: Mapped[Optional[str]] = mapped_column(String(100), nullable=True, index=True) # For guest mode sync
    
    nickname: Mapped[str] = mapped_column(String(150), nullable=False)
    district_name: Mapped[str] = mapped_column(String(100), nullable=False)
    taluk_name: Mapped[str] = mapped_column(String(100), nullable=False)
    village_name: Mapped[str] = mapped_column(String(100), nullable=False)
    survey_number: Mapped[str] = mapped_column(String(50), nullable=False)
    subdivision_number: Mapped[str] = mapped_column(String(50), nullable=False)
    
    extent_value: Mapped[float] = mapped_column(Float, default=0.0)
    extent_unit: Mapped[str] = mapped_column(String(50), default="cents") # cents, sq_ft, grounds, acres
    
    latitude: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    longitude: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    
    notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    estimated_market_value: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    
    created_at: Mapped[datetime.datetime] = mapped_column(DateTime, default=datetime.datetime.utcnow)
    updated_at: Mapped[datetime.datetime] = mapped_column(DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow)

    user = relationship("User", back_populates="properties")
    attachments = relationship("PropertyAttachment", back_populates="property", cascade="all, delete-orphan")

class PropertyAttachment(Base):
    __tablename__ = "property_attachments"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    property_id: Mapped[str] = mapped_column(String(36), ForeignKey("saved_properties.id", ondelete="CASCADE"), index=True)
    file_name: Mapped[str] = mapped_column(String(255), nullable=False)
    file_type: Mapped[str] = mapped_column(String(50), nullable=False) # patta_pdf, sale_deed_pdf, photo_jpg
    file_url: Mapped[str] = mapped_column(String(512), nullable=False)
    file_size_bytes: Mapped[int] = mapped_column(Integer, default=0)
    created_at: Mapped[datetime.datetime] = mapped_column(DateTime, default=datetime.datetime.utcnow)

    property = relationship("SavedProperty", back_populates="attachments")
