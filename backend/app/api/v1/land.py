from typing import List
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.db.session import get_db
from app.schemas.land_record import (
    LandSearchRequest,
    LandSearchResponse,
    DataSourceResponse,
    LiveSessionRequest,
    LiveSessionResponse,
    LiveFetchRequest,
    LiveFetchResponse,
)
from app.services.land_records import LandRecordService
from app.services.live_scraper_service import LiveScraperService
from app.models.land_record import DataSource

router = APIRouter(prefix="/land", tags=["Land Records"])

@router.post("/search", response_model=LandSearchResponse)
async def search_land(request: LandSearchRequest, db: AsyncSession = Depends(get_db)):
    return await LandRecordService.search_record(
        db=db,
        district_id=request.district_id,
        taluk_id=request.taluk_id,
        village_id=request.village_id,
        survey_number=request.survey_number,
        subdivision_number=request.subdivision_number,
        record_type=request.record_type or "patta_chitta"
    )

@router.post("/live/session", response_model=LiveSessionResponse)
async def init_live_session(request: LiveSessionRequest):
    """
    Connect to Tamil Nadu Revenue Portal (eservices.tn.gov.in) to retrieve
    a live session and Base64 CAPTCHA challenge for the user to solve in the app UI.
    """
    return LiveScraperService.create_session(request)

@router.post("/live/fetch", response_model=LiveFetchResponse)
async def fetch_live_record(request: LiveFetchRequest):
    """
    Submit the CAPTCHA and survey details to the official portal, parse the official
    records table, and return structured land record data directly to the mobile UI.
    """
    return LiveScraperService.fetch_live_data(request)


@router.get("/sources", response_model=List[DataSourceResponse])
async def list_sources(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(DataSource))
    sources = result.scalars().all()
    if not sources:
        # Provide default transparent list
        return [
            DataSourceResponse(
                id="tn-eservices-patta",
                name="TN Revenue e-Services (Anytime / Anywhere e-Services)",
                source_type="official_redirect",
                is_official=True,
                official_url="https://eservices.tn.gov.in/eservicesnew/land/chitta.html",
                description="Official Tamil Nadu Government portal for Patta/Chitta extraction."
            ),
            DataSourceResponse(
                id="tn-reginet",
                name="TNREGINET (Inspector General of Registration)",
                source_type="official_redirect",
                is_official=True,
                official_url="https://tnreginet.gov.in/",
                description="Official portal for Guideline Values and Encumbrance Certificates (EC)."
            ),
            DataSourceResponse(
                id="tn-landmate-demo",
                name="TN LandMate Test Fixtures",
                source_type="licensed_dataset",
                is_official=False,
                description="Sample mock data fixtures for offline development testing."
            )
        ]
    return [DataSourceResponse.model_validate(s) for s in sources]
