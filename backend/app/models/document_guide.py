import uuid
import datetime
from typing import Optional
from sqlalchemy import String, Integer, DateTime, Text, JSON
from sqlalchemy.orm import Mapped, mapped_column
from app.db.base import Base

class DocumentGuide(Base):
    __tablename__ = "document_guides"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    slug: Mapped[str] = mapped_column(String(100), unique=True, index=True) # patta-chitta, a-register, fmb, encumbrance-certificate, sale-deed
    title_en: Mapped[str] = mapped_column(String(200), nullable=False)
    title_ta: Mapped[str] = mapped_column(String(200), nullable=False)
    
    summary_en: Mapped[str] = mapped_column(Text, nullable=False)
    summary_ta: Mapped[str] = mapped_column(Text, nullable=False)
    
    why_it_matters_en: Mapped[str] = mapped_column(Text, nullable=False)
    why_it_matters_ta: Mapped[str] = mapped_column(Text, nullable=False)
    
    key_fields: Mapped[list] = mapped_column(JSON, default=list) # List of dicts with field names and explanations
    how_to_verify_en: Mapped[str] = mapped_column(Text, nullable=False)
    how_to_verify_ta: Mapped[str] = mapped_column(Text, nullable=False)
    
    official_portal_url: Mapped[str] = mapped_column(String(255), nullable=False)
    order_index: Mapped[int] = mapped_column(Integer, default=0)
    created_at: Mapped[datetime.datetime] = mapped_column(DateTime, default=datetime.datetime.utcnow)
    updated_at: Mapped[datetime.datetime] = mapped_column(DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow)

