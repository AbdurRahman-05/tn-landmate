export interface SystemStats {
  total_districts: number;
  total_taluks: number;
  total_villages: number;
  total_sros: number;
  total_land_records: number;
  total_guideline_values: number;
  total_calculator_rules: number;
  total_users: number;
  total_saved_properties: number;
  timestamp: string;
}

export interface District {
  id: number;
  code: string;
  name_en: string;
  name_ta: string;
}

export interface Taluk {
  id: number;
  district_id: number;
  code: string;
  name_en: string;
  name_ta: string;
}

export interface RevenueVillage {
  id: number;
  taluk_id: number;
  code: string;
  name_en: string;
  name_ta: string;
}

export interface CalculatorRule {
  id: string;
  rule_name: string;
  jurisdiction: string;
  transaction_type: string;
  property_type: string;
  stamp_duty_rate: number;
  registration_fee_rate: number;
  transfer_duty_rate: number;
  fixed_cess: number;
  effective_from: string;
  effective_to?: string | null;
  official_order_ref?: string | null;
  is_active: boolean;
  created_at: string;
}

export interface GuidelineValue {
  id: string;
  district_id: number;
  village_name_en: string;
  street_or_survey_number: string;
  classification: string;
  unit: string;
  value_in_rupees: number;
  effective_from: string;
  source_attribution: string;
  last_verified_at: string;
}

export interface DocumentGuide {
  id: string;
  slug: string;
  title_en: string;
  title_ta: string;
  summary_en: string;
  summary_ta: string;
  why_it_matters_en: string;
  why_it_matters_ta: string;
  key_fields: { name: string; desc: string }[];
  how_to_verify_en: string;
  how_to_verify_ta: string;
  official_portal_url: string;
  order_index: number;
}
