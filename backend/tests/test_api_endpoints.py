import pytest

@pytest.mark.asyncio
async def test_health_check(client):
    response = await client.get("/api/v1/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert "TN LandMate" in data["app_name"]

@pytest.mark.asyncio
async def test_area_conversion_api(client):
    payload = {"value": 10.0, "from_unit": "cents"}
    response = await client.post("/api/v1/calculators/area-conversion", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["cents"] == 10.0
    assert data["square_feet"] == 4356.0

@pytest.mark.asyncio
async def test_plot_area_api(client):
    payload = {
        "shape": "rectangle",
        "unit": "feet",
        "length": 50,
        "width": 40
    }
    response = await client.post("/api/v1/calculators/plot-area", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["total_square_feet"] == 2000.0

@pytest.mark.asyncio
async def test_auth_registration_and_login(client):
    register_payload = {
        "email": "surveyor.test@tnlandmate.in",
        "password": "Password123!",
        "full_name": "Test Surveyor",
        "phone": "+919988776655",
        "role": "surveyor",
        "preferred_language": "ta"
    }
    reg_res = await client.post("/api/v1/auth/register", json=register_payload)
    assert reg_res.status_code == 201
    reg_data = reg_res.json()
    assert "access_token" in reg_data
    assert reg_data["user"]["email"] == "surveyor.test@tnlandmate.in"

    # Login
    login_payload = {
        "username": "surveyor.test@tnlandmate.in",
        "password": "Password123!"
    }
    login_res = await client.post("/api/v1/auth/login", json=login_payload)
    assert login_res.status_code == 200
    login_data = login_res.json()
    assert "access_token" in login_data
    token = login_data["access_token"]

    # Access /auth/me
    headers = {"Authorization": f"Bearer {token}"}
    me_res = await client.get("/api/v1/auth/me", headers=headers)
    assert me_res.status_code == 200
    assert me_res.json()["email"] == "surveyor.test@tnlandmate.in"

@pytest.mark.asyncio
async def test_property_crud(client):
    # Register a user
    user_payload = {
        "email": "property.owner@tnlandmate.in",
        "password": "Password123!",
        "full_name": "Owner Kumar",
        "role": "citizen"
    }
    reg = await client.post("/api/v1/auth/register", json=user_payload)
    token = reg.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Create Property
    prop_payload = {
        "nickname": "Madurai Ancestral Plot",
        "district_name": "Madurai",
        "taluk_name": "Madurai North",
        "village_name": "Anaiyur",
        "survey_number": "142",
        "subdivision_number": "3B",
        "extent_value": 12.5,
        "extent_unit": "cents",
        "notes": "Verified clear title with VAO"
    }
    create_res = await client.post("/api/v1/properties", json=prop_payload, headers=headers)
    assert create_res.status_code == 201
    created_prop = create_res.json()
    prop_id = created_prop["id"]
    assert created_prop["nickname"] == "Madurai Ancestral Plot"

    # List properties
    list_res = await client.get("/api/v1/properties", headers=headers)
    assert list_res.status_code == 200
    props = list_res.json()
    assert len(props) >= 1

    # Update property
    update_res = await client.patch(
        f"/api/v1/properties/{prop_id}",
        json={"nickname": "Updated Madurai Plot"},
        headers=headers
    )
    assert update_res.status_code == 200
    assert update_res.json()["nickname"] == "Updated Madurai Plot"

    # Delete property
    del_res = await client.delete(f"/api/v1/properties/{prop_id}", headers=headers)
    assert del_res.status_code == 200

@pytest.mark.asyncio
async def test_land_search_demo_label(client):
    search_payload = {
        "district_id": 1,
        "taluk_id": 1,
        "village_id": 1,
        "survey_number": "104",
        "subdivision_number": "2B"
    }
    res = await client.post("/api/v1/land/search", json=search_payload)
    assert res.status_code == 200
    data = res.json()
    assert data["status"] == "found"
    assert data["is_demo"] is True
    assert "DEMO" in data["disclaimer"]
    assert data["record"]["patta_number"] == "1420"

@pytest.mark.asyncio
async def test_live_session_and_fetch(client):
    # 1. Request live session & CAPTCHA
    session_req = {
        "district_id": 1,
        "taluk_id": 1,
        "village_id": 1,
        "survey_number": "104",
        "subdivision_number": "2B"
    }
    s_res = await client.post("/api/v1/land/live/session", json=session_req)
    assert s_res.status_code == 200
    s_data = s_res.json()
    assert "session_id" in s_data
    assert "captcha_image_base64" in s_data
    assert len(s_data["captcha_image_base64"]) > 50

    session_id = s_data["session_id"]

    # 2. Test invalid captcha handling
    bad_fetch = {
        "session_id": session_id,
        "captcha_value": "WRONG_CAPTCHA",
        "district_id": 1,
        "taluk_id": 1,
        "village_id": 1,
        "survey_number": "104",
        "subdivision_number": "2B",
        "district_name": "Chennai",
        "taluk_name": "Ambattur",
        "village_name": "Ambattur"
    }
    f_res = await client.post("/api/v1/land/live/fetch", json=bad_fetch)
    assert f_res.status_code == 200
    f_data = f_res.json()
    assert f_data["success"] is False
    assert "CAPTCHA" in f_data["message"]

@pytest.mark.asyncio
async def test_geography_hierarchy(client):
    # 1. Fetch all 38 districts
    d_res = await client.get("/api/v1/districts")
    assert d_res.status_code == 200
    districts = d_res.json()
    assert len(districts) == 38
    chennai = next(d for d in districts if d["name_en"] == "Chennai")
    assert chennai["id"] == 1
    assert chennai["name_ta"] == "சென்னை"

    # 2. Fetch taluks for Chennai
    t_res = await client.get(f"/api/v1/taluks?district_id={chennai['id']}")
    assert t_res.status_code == 200
    taluks = t_res.json()
    assert len(taluks) >= 4
    ambattur = next(t for t in taluks if t["name_en"] == "Ambattur")
    assert ambattur["name_ta"] == "அம்பத்தூர்"

    # 3. Fetch villages for Ambattur
    v_res = await client.get(f"/api/v1/villages?taluk_id={ambattur['id']}")
    assert v_res.status_code == 200
    villages = v_res.json()
    assert len(villages) >= 1
    assert any(v["name_en"] == "Ambattur" for v in villages)

