import pytest
from app.services.calculators import LandCalculatorService

def test_area_conversion_cents():
    # 1 cent = 435.6 sq ft
    result = LandCalculatorService.convert_area(1.0, "cents")
    assert result["square_feet"] == 435.6
    assert result["cents"] == 1.0

def test_area_conversion_grounds():
    # 1 ground = 2,400 sq ft
    result = LandCalculatorService.convert_area(1.0, "grounds")
    assert result["square_feet"] == 2400.0
    # 2400 / 435.6 ~= 5.51 cents
    assert round(result["cents"], 2) == 5.51

def test_area_conversion_acres():
    # 1 acre = 43,560 sq ft = 100 cents
    result = LandCalculatorService.convert_area(1.0, "acres")
    assert result["square_feet"] == 43560.0
    assert result["cents"] == 100.0

def test_area_conversion_hectares():
    # 1 hectare = 10,000 sq meters
    result = LandCalculatorService.convert_area(1.0, "hectares")
    assert round(result["square_meters"], 1) == 10000.0
    # ~2.471 acres
    assert round(result["acres"], 2) == 2.47

def test_area_conversion_square_yards():
    # 1 sq yard = 9 sq ft
    result = LandCalculatorService.convert_area(10.0, "square_yards")
    assert result["square_feet"] == 90.0

def test_plot_area_rectangle():
    # 60 ft x 40 ft = 2400 sq ft = 1 ground
    result = LandCalculatorService.calculate_plot_area(
        shape="rectangle",
        unit="feet",
        length=60.0,
        width=40.0
    )
    assert result["total_square_feet"] == 2400.0
    assert result["grounds"] == 1.0
    assert round(result["cents"], 2) == 5.51

def test_plot_area_triangle():
    # 0.5 * 50 * 40 = 1000 sq ft
    result = LandCalculatorService.calculate_plot_area(
        shape="triangle",
        unit="feet",
        base=50.0,
        height=40.0
    )
    assert result["total_square_feet"] == 1000.0

def test_plot_area_trapezoid():
    # 0.5 * (60 + 40) * 30 = 0.5 * 100 * 30 = 1500 sq ft
    result = LandCalculatorService.calculate_plot_area(
        shape="trapezoid",
        unit="feet",
        parallel_side_a=60.0,
        parallel_side_b=40.0,
        trapezoid_height=30.0
    )
    assert result["total_square_feet"] == 1500.0

def test_registration_estimate():
    # Rs. 10,00,000 @ 7% stamp duty and 2% registration fee
    result = LandCalculatorService.calculate_registration(
        property_value=1000000.0,
        stamp_duty_rate=7.0,
        registration_rate=2.0,
        fixed_cess=100.0
    )
    assert result["stamp_duty_amount"] == 70000.0
    assert result["registration_fee_amount"] == 20000.0
    assert result["total_government_charges"] == 90100.0
    assert result["total_estimated_transaction_cost"] == 1090100.0
