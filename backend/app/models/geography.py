from typing import List, Optional
from sqlalchemy import String, Integer, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base

class District(Base):
    __tablename__ = "districts"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    code: Mapped[str] = mapped_column(String(20), unique=True, index=True)
    name_en: Mapped[str] = mapped_column(String(100), nullable=False, index=True)
    name_ta: Mapped[str] = mapped_column(String(100), nullable=False)

    taluks: Mapped[List["Taluk"]] = relationship("Taluk", back_populates="district", cascade="all, delete-orphan")
    sros: Mapped[List["SubRegistrarOffice"]] = relationship("SubRegistrarOffice", back_populates="district", cascade="all, delete-orphan")

class Taluk(Base):
    __tablename__ = "taluks"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    district_id: Mapped[int] = mapped_column(Integer, ForeignKey("districts.id", ondelete="CASCADE"), index=True)
    code: Mapped[str] = mapped_column(String(20), index=True)
    name_en: Mapped[str] = mapped_column(String(100), nullable=False, index=True)
    name_ta: Mapped[str] = mapped_column(String(100), nullable=False)

    district: Mapped["District"] = relationship("District", back_populates="taluks")
    villages: Mapped[List["RevenueVillage"]] = relationship("RevenueVillage", back_populates="taluk", cascade="all, delete-orphan")

class RevenueVillage(Base):
    __tablename__ = "revenue_villages"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    taluk_id: Mapped[int] = mapped_column(Integer, ForeignKey("taluks.id", ondelete="CASCADE"), index=True)
    code: Mapped[str] = mapped_column(String(20), index=True)
    name_en: Mapped[str] = mapped_column(String(100), nullable=False, index=True)
    name_ta: Mapped[str] = mapped_column(String(100), nullable=False)

    taluk: Mapped["Taluk"] = relationship("Taluk", back_populates="villages")

class SubRegistrarOffice(Base):
    __tablename__ = "sub_registrar_offices"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    district_id: Mapped[int] = mapped_column(Integer, ForeignKey("districts.id", ondelete="CASCADE"), index=True)
    zone: Mapped[str] = mapped_column(String(100), nullable=False)
    name_en: Mapped[str] = mapped_column(String(150), nullable=False)
    name_ta: Mapped[str] = mapped_column(String(150), nullable=False)
    address: Mapped[Optional[str]] = mapped_column(String(300), nullable=True)

    district: Mapped["District"] = relationship("District", back_populates="sros")
