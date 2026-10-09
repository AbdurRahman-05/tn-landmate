import decimal
from typing import Dict, Any, Optional
from decimal import Decimal, ROUND_HALF_UP

# Exact Conversion Constants (relative to 1 Square Foot)
# 1 acre = 43,560 sq ft
# 1 cent = 435.6 sq ft
# 1 ground = 2,400 sq ft
# 1 sq yard = 9 sq ft
# 1 sq meter = 10.763910416709722 sq ft (since 1 meter = 3.280839895013123 ft)
# 1 hectare = 10,000 sq meters = 107639.10416709722 sq ft
# 1 sq km = 1,000,000 sq meters = 10763910.416709722 sq ft

SQFT_PER_UNIT = {
    "square_feet": Decimal("1.0"),
    "square_meters": Decimal("10.763910416709722"),
    "square_yards": Decimal("9.0"),
    "cents": Decimal("435.6"),
    "grounds": Decimal("2400.0"),
    "acres": Decimal("43560.0"),
    "hectares": Decimal("107639.10416709722"),
    "square_kilometers": Decimal("10763910.416709722"),
}

class LandCalculatorService:
    @staticmethod
    def convert_area(value: float, from_unit: str) -> Dict[str, Any]:
        unit_key = from_unit.lower().strip().replace(" ", "_").replace("-", "_")
        if unit_key not in SQFT_PER_UNIT:
            # Handle common aliases
            aliases = {
                "sqft": "square_feet",
                "sq_ft": "square_feet",
                "cent": "cents",
                "ground": "grounds",
                "acre": "acres",
                "hectare": "hectares",
                "sq_m": "square_meters",
                "sq_meter": "square_meters",
                "sq_meters": "square_meters",
                "sq_yard": "square_yards",
                "sq_yd": "square_yards",
                "sq_km": "square_kilometers"
            }
            unit_key = aliases.get(unit_key, "square_feet")

        val_dec = Decimal(str(value))
        factor_to_sqft = SQFT_PER_UNIT[unit_key]
        total_sqft = val_dec * factor_to_sqft

        # Convert to all 8 units
        sq_ft = float(total_sqft)
        sq_m = float(total_sqft / SQFT_PER_UNIT["square_meters"])
        sq_yd = float(total_sqft / SQFT_PER_UNIT["square_yards"])
        cents = float(total_sqft / SQFT_PER_UNIT["cents"])
        grounds = float(total_sqft / SQFT_PER_UNIT["grounds"])
        acres = float(total_sqft / SQFT_PER_UNIT["acres"])
        hectares = float(total_sqft / SQFT_PER_UNIT["hectares"])
        sq_km = float(total_sqft / SQFT_PER_UNIT["square_kilometers"])

        return {
            "input_value": value,
            "input_unit": unit_key,
            "square_feet": round(sq_ft, 4),
            "square_meters": round(sq_m, 4),
            "square_yards": round(sq_yd, 4),
            "cents": round(cents, 4),
            "grounds": round(grounds, 4),
            "acres": round(acres, 4),
            "hectares": round(hectares, 4),
            "square_kilometers": round(sq_km, 6),
            "formatted": {
                "square_feet": f"{sq_ft:,.2f} Sq.Ft",
                "cents": f"{cents:,.2f} Cents",
                "grounds": f"{grounds:,.2f} Grounds",
                "acres": f"{acres:,.4f} Acres",
                "hectares": f"{hectares:,.4f} Hectares",
                "square_meters": f"{sq_m:,.2f} Sq.M",
                "square_yards": f"{sq_yd:,.2f} Sq.Yds",
                "square_kilometers": f"{sq_km:,.6f} Sq.Km",
            }
        }

    @staticmethod
    def calculate_plot_area(
        shape: str,
        unit: str = "feet",
        length: Optional[float] = None,
        width: Optional[float] = None,
        base: Optional[float] = None,
        height: Optional[float] = None,
        parallel_side_a: Optional[float] = None,
        parallel_side_b: Optional[float] = None,
        trapezoid_height: Optional[float] = None,
        sections: Optional[list] = None
    ) -> Dict[str, Any]:
        # Linear unit conversion to feet
        unit_multiplier = 1.0
        if unit in ["meters", "meter", "m"]:
            unit_multiplier = 3.280839895
        elif unit in ["yards", "yard", "yd"]:
            unit_multiplier = 3.0

        shape_clean = shape.lower().strip()
        sq_ft = 0.0

        if shape_clean == "rectangle":
            l = (length or 0.0) * unit_multiplier
            w = (width or 0.0) * unit_multiplier
            sq_ft = l * w
        elif shape_clean == "triangle":
            b = (base or 0.0) * unit_multiplier
            h = (height or 0.0) * unit_multiplier
            sq_ft = 0.5 * b * h
        elif shape_clean == "trapezoid":
            a = (parallel_side_a or 0.0) * unit_multiplier
            b = (parallel_side_b or 0.0) * unit_multiplier
            h = (trapezoid_height or 0.0) * unit_multiplier
            sq_ft = 0.5 * (a + b) * h
        elif shape_clean == "composite" and sections:
            for sec in sections:
                l = (sec.length if hasattr(sec, 'length') else sec.get('length', 0.0)) * unit_multiplier
                w = (sec.width if hasattr(sec, 'width') else sec.get('width', 0.0)) * unit_multiplier
                sq_ft += (l * w)
        else:
            sq_ft = 0.0

        converted = LandCalculatorService.convert_area(sq_ft, "square_feet")

        return {
            "shape": shape_clean,
            "input_unit": unit,
            "total_square_feet": round(sq_ft, 4),
            "square_meters": converted["square_meters"],
            "square_yards": converted["square_yards"],
            "cents": converted["cents"],
            "grounds": converted["grounds"],
            "acres": converted["acres"],
            "hectares": converted["hectares"],
            "disclaimer": "Geometric calculation estimate. Real-world boundaries are subject to physical survey and field measurements."
        }

    @staticmethod
    def calculate_registration(
        property_value: float,
        stamp_duty_rate: float,
        registration_rate: float,
        fixed_cess: float = 100.0,
        rule_name: str = "Tamil Nadu Registration Department Rates",
        effective_from: Optional[str] = "2024-04-01",
        is_custom_rate: bool = False
    ) -> Dict[str, Any]:
        stamp_duty_amt = round((property_value * stamp_duty_rate) / 100.0, 2)
        reg_fee_amt = round((property_value * registration_rate) / 100.0, 2)
        total_govt = round(stamp_duty_amt + reg_fee_amt + fixed_cess, 2)
        total_cost = round(property_value + total_govt, 2)

        return {
            "property_value": property_value,
            "stamp_duty_rate_percent": stamp_duty_rate,
            "stamp_duty_amount": stamp_duty_amt,
            "registration_fee_rate_percent": registration_rate,
            "registration_fee_amount": reg_fee_amt,
            "fixed_cess_amount": fixed_cess,
            "total_government_charges": total_govt,
            "total_estimated_transaction_cost": total_cost,
            "effective_rule_applied": rule_name,
            "effective_from": effective_from,
            "is_custom_rate": is_custom_rate,
            "disclaimer": "Informational calculation based on configured rules. Final charges are subject to determination by the Sub-Registrar during execution."
        }
