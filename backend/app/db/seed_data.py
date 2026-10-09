import datetime
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.models import (
    User, District, Taluk, RevenueVillage, SubRegistrarOffice,
    CalculatorRule, GuidelineValue, LandRecord, DocumentGuide, DataSource
)
from app.core.security import get_password_hash

async def seed_initial_data(session: AsyncSession):
    # 1. Seed Districts if empty
    dist_check = await session.execute(select(District).limit(1))
    if not dist_check.scalars().first():
        tn_districts = [
            (1, "CHN", "Chennai", "சென்னை"),
            (2, "CBE", "Coimbatore", "கோயம்புத்தூர்"),
            (3, "MDU", "Madurai", "மதுரை"),
            (4, "TRY", "Tiruchirappalli", "திருச்சிராப்பள்ளி"),
            (5, "CGL", "Chengalpattu", "செங்கல்பட்டு"),
            (6, "KCH", "Kancheepuram", "காஞ்சிபுரம்"),
            (7, "SLM", "Salem", "சேலம்"),
            (8, "TPR", "Tiruppur", "திருப்பூர்"),
            (9, "ERD", "Erode", "ஈரோடு"),
            (10, "VLR", "Vellore", "வேலூர்"),
            (11, "TNV", "Tirunelveli", "திருநெல்வேலி"),
            (12, "TTK", "Thoothukudi", "தூத்துக்குடி"),
            (13, "KKI", "Kanniyakumari", "கன்னியாகுமரி"),
            (14, "TNJ", "Thanjavur", "தஞ்சாவூர்"),
            (15, "DGL", "Dindigul", "திண்டுக்கல்"),
            (16, "TVR", "Tiruvarur", "திருவாரூர்"),
            (17, "NGP", "Nagapattinam", "நாகப்பட்டினம்"),
            (18, "CDL", "Cuddalore", "கடலூர்"),
            (19, "VPM", "Viluppuram", "விழுப்புரம்"),
            (20, "TVM", "Tiruvannamalai", "திருவண்ணாமலை"),
            (21, "TLR", "Tiruvallur", "திருவள்ளூர்"),
            (22, "NMK", "Namakkal", "நாமக்கல்"),
            (23, "KRR", "Karur", "கரூர்"),
            (24, "DPG", "Dharmapuri", "தர்மபுரி"),
            (25, "KRI", "Krishnagiri", "கிருஷ்ணகிரி"),
            (26, "RPT", "Ranipet", "ராணிப்பேட்டை"),
            (27, "TPT", "Tirupathur", "திருப்பத்தூர்"),
            (28, "KLK", "Kallakurichi", "கள்ளக்குறிச்சி"),
            (29, "TEN", "Tenkasi", "தென்காசி"),
            (30, "MYL", "Mayiladuthurai", "மயிலாடுதுறை"),
            (31, "PDK", "Pudukkottai", "புதுக்கோட்டை"),
            (32, "SVG", "Sivaganga", "சிவகங்கை"),
            (33, "RMD", "Ramanathapuram", "ராமநாதபுரம்"),
            (34, "VRD", "Virudhunagar", "விருதுநகர்"),
            (35, "TNI", "Theni", "தேனி"),
            (36, "NLG", "Nilgiris", "நீலகிரி"),
            (37, "PBL", "Perambalur", "பெரம்பலூர்"),
            (38, "AYR", "Ariyalur", "அரியலூர்"),
        ]
        for d_id, code, name_en, name_ta in tn_districts:
            session.add(District(id=d_id, code=code, name_en=name_en, name_ta=name_ta))
        await session.commit()

        # Seed Taluks for sample key districts
        taluks = [
            # Chennai
            (1, 1, "AMB", "Ambattur", "அம்பத்தூர்"),
            (2, 1, "MYL", "Mylapore", "மயிலாப்பூர்"),
            (3, 1, "VEL", "Velachery", "வேளச்சேரி"),
            (4, 1, "GND", "Guindy", "கிண்டி"),
            # Coimbatore
            (5, 2, "CBN", "Coimbatore North", "கோவை வடக்கு"),
            (6, 2, "CBS", "Coimbatore South", "கோவை தெற்கு"),
            # Madurai
            (7, 3, "MDN", "Madurai North", "மதுரை வடக்கு"),
            (8, 3, "MDS", "Madurai South", "மதுரை தெற்கு"),
            # Chengalpattu
            (9, 5, "TAM", "Tambaram", "தாம்பரம்"),
            (10, 5, "VND", "Vandalur", "வண்டலூர்"),
        ]
        for t_id, d_id, code, name_en, name_ta in taluks:
            session.add(Taluk(id=t_id, district_id=d_id, code=code, name_en=name_en, name_ta=name_ta))
        await session.commit()

        # Seed Revenue Villages
        villages = [
            (1, 1, "AMB-01", "Ambattur", "அம்பத்தூர்"),
            (2, 1, "KOR-02", "Korattur", "கொரட்டூர்"),
            (3, 2, "MYL-01", "Mylapore", "மயிலாப்பூர்"),
            (4, 2, "ALP-02", "Alwarpet", "ஆழ்வார்பேட்டை"),
            (5, 3, "VEL-01", "Velachery", "வேளச்சேரி"),
            (6, 4, "GND-01", "Guindy Park", "கிண்டி பூங்கா"),
            (7, 5, "GND-02", "Ganapathy", "கணபதி"),
            (8, 6, "RSP-01", "RS Puram", "ஆர்.எஸ். புரம்"),
            (9, 7, "ANA-01", "Anaiyur", "அணையூர்"),
            (10, 9, "TAM-01", "Tambaram East", "தாம்பரம் கிழக்கு"),
        ]
        for v_id, t_id, code, name_en, name_ta in villages:
            session.add(RevenueVillage(id=v_id, taluk_id=t_id, code=code, name_en=name_en, name_ta=name_ta))
        await session.commit()

        # Seed Sub-Registrar Offices
        sros = [
            (1, 1, "Chennai Central", "Mylapore SRO", "மயிலாப்பூர் சார்பதிவாளர் அலுவலகம்", "Kutchery Road, Mylapore, Chennai"),
            (2, 1, "Chennai North", "Ambattur SRO", "அம்பத்தூர் சார்பதிவாளர் அலுவலகம்", "MTH Road, Ambattur, Chennai"),
            (3, 1, "Chennai South", "Velachery SRO", "வேளச்சேரி சார்பதிவாளர் அலுவலகம்", "100 Feet Bypass Rd, Velachery"),
            (4, 2, "Coimbatore", "Gandhipuram SRO", "காந்திபுரம் சார்பதிவாளர் அலுவலகம்", "Cross Cut Road, Coimbatore"),
            (5, 5, "Chengalpattu", "Tambaram SRO", "தாம்பரம் சார்பதிவாளர் அலுவலகம்", "GST Road, Tambaram, Chennai"),
        ]
        for s_id, d_id, zone, name_en, name_ta, addr in sros:
            session.add(SubRegistrarOffice(id=s_id, district_id=d_id, zone=zone, name_en=name_en, name_ta=name_ta, address=addr))
        await session.commit()

    # 2. Seed Calculator Rules
    rule_check = await session.execute(select(CalculatorRule).limit(1))
    if not rule_check.scalars().first():
        rules = [
            CalculatorRule(
                rule_name="Tamil Nadu General Sale Deed (Standard 2024)",
                jurisdiction="tamil_nadu_state",
                transaction_type="sale",
                property_type="all",
                stamp_duty_rate=7.0,
                registration_fee_rate=2.0,
                transfer_duty_rate=0.0,
                fixed_cess=100.0,
                effective_from=datetime.date(2024, 4, 1),
                official_order_ref="G.O. (Ms) No. 23 Commercial Taxes and Registration",
                is_active=True
            ),
            CalculatorRule(
                rule_name="Family Settlement / Gift within Blood Relations",
                jurisdiction="tamil_nadu_state",
                transaction_type="settlement_family",
                property_type="residential_plot",
                stamp_duty_rate=1.0, # Concessional
                registration_fee_rate=1.0,
                transfer_duty_rate=0.0,
                fixed_cess=0.0,
                effective_from=datetime.date(2024, 1, 1),
                official_order_ref="TN Family Transfer Concession Notification",
                is_active=True
            ),
            CalculatorRule(
                rule_name="Simple Mortgage Deed (Without Possession)",
                jurisdiction="tamil_nadu_state",
                transaction_type="mortgage",
                property_type="all",
                stamp_duty_rate=1.0,
                registration_fee_rate=1.0,
                transfer_duty_rate=0.0,
                fixed_cess=0.0,
                effective_from=datetime.date(2023, 7, 1),
                official_order_ref="TN Registration Schedule I Art 40",
                is_active=True
            )
        ]
        for r in rules:
            session.add(r)
        await session.commit()

    # 3. Seed Guideline Values (Demonstration samples with clear attribution)
    gv_check = await session.execute(select(GuidelineValue).limit(1))
    if not gv_check.scalars().first():
        gvs = [
            GuidelineValue(
                district_id=1,
                sro_id=1,
                village_id=3,
                village_name_en="Mylapore",
                street_or_survey_number="Luz Church Road",
                classification="Commercial Special Class",
                unit="sq_ft",
                value_in_rupees=14500.0,
                effective_from=datetime.date(2024, 7, 1),
                source_attribution="Public TNREGINET Guideline Search Portal"
            ),
            GuidelineValue(
                district_id=1,
                sro_id=3,
                village_id=5,
                village_name_en="Velachery",
                street_or_survey_number="100 Feet Inner Ring Road",
                classification="Residential Class I",
                unit="sq_ft",
                value_in_rupees=7200.0,
                effective_from=datetime.date(2024, 7, 1),
                source_attribution="Public TNREGINET Guideline Search Portal"
            ),
            GuidelineValue(
                district_id=2,
                sro_id=4,
                village_id=8,
                village_name_en="RS Puram",
                street_or_survey_number="Diwan Bahadur Road (DB Road)",
                classification="Commercial Prime",
                unit="sq_ft",
                value_in_rupees=11000.0,
                effective_from=datetime.date(2024, 7, 1),
                source_attribution="Public TNREGINET Guideline Search Portal"
            )
        ]
        for g in gvs:
            session.add(g)
        await session.commit()

    # 4. Seed Demo Land Records (Explicitly labeled is_demo=True)
    lr_check = await session.execute(select(LandRecord).limit(1))
    if not lr_check.scalars().first():
        records = [
            LandRecord(
                district_id=1,
                taluk_id=1,
                village_id=1,
                survey_number="104",
                subdivision_number="2B",
                patta_number="1420",
                owner_name_en="K. Selvaraj & S. Meenakshi",
                owner_name_ta="கே. செல்வராஜ் & எஸ். மீனாட்சி",
                land_type="நத்தம் மனை (Grama Natham Residential)",
                extent_hectares=0.0223,
                extent_ares=2.23,
                extent_cents=5.51,
                extent_sq_ft=2400.0,
                is_demo=True,
                source_attribution="TN LandMate Development Test Dataset (Demo Record)",
                official_verification_url="https://eservices.tn.gov.in/eservicesnew/land/chitta.html"
            ),
            LandRecord(
                district_id=1,
                taluk_id=3,
                village_id=5,
                survey_number="320",
                subdivision_number="1A",
                patta_number="892",
                owner_name_en="R. Arumugam",
                owner_name_ta="ஆர். ஆறுமுகம்",
                land_type="நன்செய் (Wet Land Agricultural)",
                extent_hectares=0.4047,
                extent_ares=40.47,
                extent_cents=100.0,
                extent_sq_ft=43560.0,
                is_demo=True,
                source_attribution="TN LandMate Development Test Dataset (Demo Record)",
                official_verification_url="https://eservices.tn.gov.in/eservicesnew/land/chitta.html"
            ),
            LandRecord(
                district_id=2,
                taluk_id=5,
                village_id=7,
                survey_number="45",
                subdivision_number="3",
                patta_number="311",
                owner_name_en="M. Thangavel",
                owner_name_ta="எம். தங்கவேல்",
                land_type="புன்செய் (Dry Land)",
                extent_hectares=0.8094,
                extent_ares=80.94,
                extent_cents=200.0,
                extent_sq_ft=87120.0,
                is_demo=True,
                source_attribution="TN LandMate Development Test Dataset (Demo Record)",
                official_verification_url="https://eservices.tn.gov.in/eservicesnew/land/chitta.html"
            )
        ]
        for rec in records:
            session.add(rec)
        await session.commit()

    # 5. Seed Document Guides
    guide_check = await session.execute(select(DocumentGuide).limit(1))
    if not guide_check.scalars().first():
        guides = [
            DocumentGuide(
                slug="patta-chitta",
                title_en="Patta & Chitta (பட்டா & சிட்டா)",
                title_ta="பட்டா மற்றும் சிட்டா விவரங்கள்",
                summary_en="Patta is the legal revenue record of land ownership issued by the Tahsildar. Chitta provides details of the land area, classification (wet/dry), and revenue tax assessment.",
                summary_ta="பட்டா என்பது வட்டாட்சியரால் வழங்கப்படும் நில உரிமை வருவாய்த்துறை ஆவணமாகும். சிட்டா என்பது நிலத்தின் வகைப்பாடு (நன்செய்/புன்செய்) மற்றும் வரி விவரங்களைக் குறிக்கும்.",
                why_it_matters_en="Having a Patta transferred in your name is essential proof of rightful possession and revenue title in Tamil Nadu. It is required for loans, construction permits, and legal safety.",
                why_it_matters_ta="நில உரிமை மற்றும் வருவாய் ஆவணங்களில் உங்கள் பெயர் இடம்பெற பட்டா மிக முக்கியம். வங்கி கடன் மற்றும் கட்டிட அனுமதிக்கு இது கட்டாயம்.",
                key_fields=[
                    {"name": "Patta Number (பட்டா எண்)", "desc": "Unique account number under the revenue village registry."},
                    {"name": "Owner Name (உரிமையாளர் பெயர்)", "desc": "Name(s) of registered titleholders."},
                    {"name": "Survey & Subdivision (புல எண் மற்றும் உட்பிரிவு)", "desc": "Official cadastral parcel reference."},
                    {"name": "Land Type (நில வகைப்பாடு)", "desc": "Nanjai (Wet), Punjai (Dry), or Natham."}
                ],
                how_to_verify_en="Verify online 24/7 on Tamil Nadu Revenue e-Services portal using District, Taluk, Village, and Survey/Subdivision number.",
                how_to_verify_ta="தமிழ்நாடு அரசு இ-சேவை இணையதளத்தில் (eservices.tn.gov.in) மாவட்டம், வட்டம், கிராமம் மற்றும் புல எண் கொண்டு சரிபார்க்கலாம்.",
                official_portal_url="https://eservices.tn.gov.in/eservicesnew/land/chitta.html",
                order_index=1
            ),
            DocumentGuide(
                slug="a-register",
                title_en="A-Register (அ-பதிவேடு)",
                title_ta="அ-பதிவேடு (கிராம நில உரிமை ஆவணம்)",
                summary_en="The primary village permanent land register maintained by the Village Administrative Officer (VAO) containing historical land details, soil classification, and assessment.",
                summary_ta="கிராம நிர்வாக அலுவலரால் (VAO) பராமரிக்கப்படும் முதன்மை நிரந்தர நிலப் பதிவேடு. இதில் மண் தரம், பரப்பு மற்றும் வரி மதிப்பீடு இருக்கும்.",
                why_it_matters_en="Critical to check if the land is classified as Government Poramboke, temple land, water body, or Ryotwari private land before purchasing.",
                why_it_matters_ta="நீங்கள் வாங்கும் நிலம் அரசு புறம்போக்கு, கோயில் நிலம் அல்லது நீர்நிலையா என கண்டறிய இது மிக அவசியமானது.",
                key_fields=[
                    {"name": "Old Survey No (பழைய புல எண்)", "desc": "Cadastral survey history."},
                    {"name": "Ryotwari or Inam (ராயத்துவாரி வகை)", "desc": "Tenure classification."},
                    {"name": "Classification (வகைப்பாடு)", "desc": "Whether dry, wet, or poramboke."}
                ],
                how_to_verify_en="Extract extract online via e-Services or obtain a certified copy from the respective Taluk office.",
                how_to_verify_ta="இ-சேவை தளம் அல்லது வட்டாட்சியர் அலுவலகம் மூலம் சரிபார்க்கலாம்.",
                official_portal_url="https://eservices.tn.gov.in/eservicesnew/land/areg.html",
                order_index=2
            ),
            DocumentGuide(
                slug="fmb",
                title_en="Field Measurement Book (FMB / புல வரைபடம்)",
                title_ta="புல வரைபடம் (FMB - Field Measurement Book)",
                summary_en="A compilation of survey map sketches showing precise plot boundaries, ladder measurements (offset lines), and neighbor boundary points.",
                summary_ta="நிலத்தின் உண்மையான எல்லைகள், வெளி அளவுகள் மற்றும் அளவீட்டு ஏணி விவரங்கள் கொண்ட துல்லிய வரைபடம்.",
                why_it_matters_en="FMB confirms whether the physical boundary matches the registered extent and prevents boundary encroachment disputes.",
                why_it_matters_ta="பத்திரத்தில் உள்ள பரப்பளவும் களத்தில் உள்ள நில அளவும் சரியாக பொருந்துகிறதா என்பதை உறுதி செய்ய உதவுகிறது.",
                key_fields=[
                    {"name": "Ladder Measurements (ஏணி அளவுகள்)", "desc": "Offset distances used by government surveyors."},
                    {"name": "G-Line (மையக் கோடு)", "desc": "Baseline dividing the survey field for triangular triangulation."}
                ],
                how_to_verify_en="Download authorized sketch from Tamil Nilam e-Services using Survey and Subdivision number.",
                how_to_verify_ta="தமிழ் நிலம் இணையதளத்தில் உங்கள் புல எண் உள்ளிட்டு FMB நகலை பதிவிறக்கலாம்.",
                official_portal_url="https://eservices.tn.gov.in/eservicesnew/land/fmb.html",
                order_index=3
            ),
            DocumentGuide(
                slug="encumbrance-certificate",
                title_en="Encumbrance Certificate (EC / வில்லங்கச் சான்றிதழ்)",
                title_ta="வில்லங்கச் சான்றிதழ் (Encumbrance Certificate)",
                summary_en="Record of all registered legal transactions (sale, mortgage, lease, gift, release) registered on the property over a specific time period (typically 30+ years).",
                summary_ta="ஒரு குறிப்பிட்ட காலத்தில் அந்த சொத்தின் மீது பதிவு செய்யப்பட்ட அனைத்து கிரையம், அடமானம் போன்ற பத்திரப் பதிவுகளின் வரலாறு.",
                why_it_matters_en="Verifies that the seller has clear marketable title without existing unpaid bank mortgages or unauthorized court attachments.",
                why_it_matters_ta="சொத்தின் மீது வேறு யாருக்கும் அடமான உரிமையோ, நீதிமன்ற தடையோ இல்லை என்பதை உறுதி செய்ய வேண்டும்.",
                key_fields=[
                    {"name": "Document Number & Year (ஆவண எண்)", "desc": "Registration ID at SRO."},
                    {"name": "Executant and Claimant (எழுதிக்கொடுத்தவர் / பெற்றவர்)", "desc": "Parties involved in the deed."}
                ],
                how_to_verify_en="Search and view digitally signed Encumbrance Certificates on TNREGINET portal.",
                how_to_verify_ta="TNREGINET இணையதளத்தில் வில்லங்கச் சான்றிதழை இலவசமாக தேடி பதிவிறக்கம் செய்யலாம்.",
                official_portal_url="https://tnreginet.gov.in/",
                order_index=4
            ),
            DocumentGuide(
                slug="sale-deed",
                title_en="Sale Deed & Parent Documents (கிரையப் பத்திரம் & மூல ஆவணங்கள்)",
                title_ta="கிரையப் பத்திரம் மற்றும் மூல ஆவணங்கள்",
                summary_en="The principal legal instrument through which title and ownership are transferred from the seller to the buyer upon consideration.",
                summary_ta="சொத்தின் உரிமையை விற்பனையாளரிடமிருந்து வாங்குபவருக்கு மாற்றும் முதன்மை சட்ட ஆவணம்.",
                why_it_matters_en="Establishes absolute ownership chain. Buyer must trace uninterrupted ownership through parent deeds for at least 30 uninterrupted years.",
                why_it_matters_ta="சொத்தின் தொடர்ச்சியான 30 ஆண்டுகால உரிமைச் சங்கிலியை (Chain of Title) உறுதி செய்ய மூல ஆவணங்கள் அவசியமாகும்.",
                key_fields=[
                    {"name": "Schedule of Property (சொத்து விவரம்)", "desc": "Four boundary descriptions (North, South, East, West)."},
                    {"name": "Consideration Amount (கிரயத் தொகை)", "desc": "Total value agreed and paid."}
                ],
                how_to_verify_en="Verify certified copy at the respective Sub-Registrar Office where the deed was executed.",
                how_to_verify_ta="சம்பந்தப்பட்ட சார்பதிவாளர் அலுவலகத்தில் சான்றளிக்கப்பட்ட நகல் (Certified Copy) பெற்று ஒப்பிட்டு சரிபார்க்கவும்.",
                official_portal_url="https://tnreginet.gov.in/",
                order_index=5
            )
        ]
        for g in guides:
            session.add(g)
        await session.commit()

    # 6. Seed Default Users
    user_check = await session.execute(select(User).limit(1))
    if not user_check.scalars().first():
        admin_user = User(
            email="admin@tnlandmate.gov.in",
            hashed_password=get_password_hash("Admin@123456"),
            full_name="TN Land Admin",
            phone="+919876500001",
            role="admin",
            preferred_language="en",
            is_active=True
        )
        citizen_user = User(
            email="citizen@tnlandmate.in",
            hashed_password=get_password_hash("User@123456"),
            full_name="Karthik Subramanian",
            phone="+919876543210",
            role="citizen",
            preferred_language="ta",
            is_active=True
        )
        session.add(admin_user)
        session.add(citizen_user)
        await session.commit()
