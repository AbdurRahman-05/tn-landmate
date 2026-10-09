import uuid
import datetime
from typing import Optional
from sqlalchemy import String, Float, Boolean, DateTime, Date, Text
from sqlalchemy.orm import Mapped, mapped_column
from app.db.base import Base

class CalculatorRule(Base):
    __tablename__ = "calculator_rules"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    rule_name: Mapped[str] = mapped_column(String(150), nullable=False)
    jurisdiction: Mapped[str] = mapped_column(String(100), default="tamil_nadu_state") # tamil_nadu_state, chennai_corporation
    transaction_type: Mapped[str] = mapped_column(String(100), default="sale") # sale, gift, settlement, mortgage, lease
    property_type: Mapped[str] = mapped_column(String(100), default="all") # agricultural, residential_plot, commercial, apartment
    
    # Rates
    stamp_duty_rate: Mapped[float] = mapped_column(Float, default=7.0) # Percentage e.g. 7.0%
    registration_fee_rate: Mapped[float] = mapped_column(Float, default=2.0) # Percentage e.g. 2.0%
    transfer_duty_rate: Mapped[float] = mapped_column(Float, default=0.0) # Optional local body surcharge
    fixed_cess: Mapped[float] = mapped_column(Float, default=0.0) # Fixed extra rupee fees
    
    # Effective Dating & Governance
    effective_from: Mapped[datetime.date] = mapped_column(Date, nullable=False)
    effective_to: Mapped[Optional[datetime.date]] = mapped_column(Date, nullable=True)
    official_order_ref: Mapped[Optional[str]] = mapped_column(String(200), nullable=True) # e.g. G.O. Ms No. 23 Commercial Taxes
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime.datetime] = mapped_column(DateTime, default=datetime.datetime.utcnow)
