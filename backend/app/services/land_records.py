from typing import Optional, Dict, Any
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.models.land_record import LandRecord
from app.schemas.land_record import LandSearchResponse, LandRecordDetail

class LandRecordService:
    @staticmethod
    async def search_record(
        db: AsyncSession,
        district_id: int,
        taluk_id: int,
        village_id: int,
        survey_number: str,
        subdivision_number: str,
        record_type: str = "patta_chitta"
    ) -> LandSearchResponse:
        # Search internal database (demo/licensed dataset)
        query = select(LandRecord).where(
            LandRecord.district_id == district_id,
            LandRecord.taluk_id == taluk_id,
            LandRecord.village_id == village_id,
            LandRecord.survey_number == survey_number.strip(),
            LandRecord.subdivision_number == subdivision_number.strip()
        )
        result = await db.execute(query)
        record = result.scalars().first()

        if record:
            return LandSearchResponse(
                status="found",
                provider_type="licensed_dataset" if not record.is_demo else "demo_dataset",
                is_demo=record.is_demo,
                disclaimer="[DEMO RECORD] This information is for demonstration & testing purposes. For legally binding records, please verify with the official Tamil Nadu Revenue portal.",
                official_verification_url=record.official_verification_url or "https://eservices.tn.gov.in/eservicesnew/land/chitta.html",
                source_attribution=record.source_attribution,
                record=LandRecordDetail(
                    patta_number=record.patta_number,
                    owner_name_en=record.owner_name_en,
                    owner_name_ta=record.owner_name_ta,
                    land_type=record.land_type,
                    extent_hectares=record.extent_hectares,
                    extent_ares=record.extent_ares,
                    extent_cents=record.extent_cents,
                    extent_sq_ft=record.extent_sq_ft,
                    fmb_sketch_url=record.fmb_sketch_url
                )
            )
        
        # When not in local dataset, provide clean redirect guidance
        return LandSearchResponse(
            status="official_redirect_available",
            provider_type="official_redirect",
            is_demo=False,
            disclaimer="No authorized local cache found for this survey number. You can verify this record directly on the official Tamil Nadu e-Services portal.",
            official_verification_url=f"https://eservices.tn.gov.in/eservicesnew/land/chitta.html",
            source_attribution="Department of Survey and Settlement, Government of Tamil Nadu",
            record=None
        )
