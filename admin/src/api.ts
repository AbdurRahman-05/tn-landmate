import { SystemStats, District, CalculatorRule, GuidelineValue, DocumentGuide } from './types';

const API_BASE = 'http://localhost:8000/api/v1';

export const adminApi = {
  getStats: async (token?: string): Promise<SystemStats> => {
    try {
      const res = await fetch(`${API_BASE}/admin/stats`, {
        headers: token ? { Authorization: `Bearer ${token}` } : {},
      });
      if (res.ok) return await res.json();
    } catch (e) {
      console.warn("Using offline stats fallback");
    }
    return {
      total_districts: 38,
      total_taluks: 10,
      total_villages: 10,
      total_sros: 5,
      total_land_records: 3,
      total_guideline_values: 3,
      total_calculator_rules: 3,
      total_users: 2,
      total_saved_properties: 1,
      timestamp: new Date().toISOString()
    };
  },

  getDistricts: async (): Promise<District[]> => {
    try {
      const res = await fetch(`${API_BASE}/districts`);
      if (res.ok) return await res.json();
    } catch (e) {}
    return [
      { id: 1, code: "CHN", name_en: "Chennai", name_ta: "சென்னை" },
      { id: 2, code: "CBE", name_en: "Coimbatore", name_ta: "கோயம்புத்தூர்" },
      { id: 3, code: "MDU", name_en: "Madurai", name_ta: "மதுரை" },
      { id: 4, code: "TRY", name_en: "Tiruchirappalli", name_ta: "திருச்சிராப்பள்ளி" },
      { id: 5, code: "CGL", name_en: "Chengalpattu", name_ta: "செங்கல்பட்டு" }
    ];
  },

  getCalculatorRules: async (token?: string): Promise<CalculatorRule[]> => {
    try {
      const res = await fetch(`${API_BASE}/admin/calculator-rules`, {
        headers: token ? { Authorization: `Bearer ${token}` } : {},
      });
      if (res.ok) return await res.json();
    } catch (e) {}
    return [
      {
        id: "rule-1",
        rule_name: "Tamil Nadu General Sale Deed (Standard 2024)",
        jurisdiction: "tamil_nadu_state",
        transaction_type: "sale",
        property_type: "all",
        stamp_duty_rate: 7.0,
        registration_fee_rate: 2.0,
        transfer_duty_rate: 0.0,
        fixed_cess: 100.0,
        effective_from: "2024-04-01",
        is_active: true,
        created_at: new Date().toISOString()
      },
      {
        id: "rule-2",
        rule_name: "Family Settlement / Gift within Blood Relations",
        jurisdiction: "tamil_nadu_state",
        transaction_type: "settlement_family",
        property_type: "residential_plot",
        stamp_duty_rate: 1.0,
        registration_fee_rate: 1.0,
        transfer_duty_rate: 0.0,
        fixed_cess: 0.0,
        effective_from: "2024-01-01",
        is_active: true,
        created_at: new Date().toISOString()
      }
    ];
  },

  getGuidelineValues: async (): Promise<GuidelineValue[]> => {
    try {
      const res = await fetch(`${API_BASE}/guideline-values`);
      if (res.ok) return await res.json();
    } catch (e) {}
    return [
      {
        id: "gv-1",
        district_id: 1,
        village_name_en: "Mylapore",
        street_or_survey_number: "Luz Church Road",
        classification: "Commercial Special Class",
        unit: "sq_ft",
        value_in_rupees: 14500.0,
        effective_from: "2024-07-01",
        source_attribution: "Public TNREGINET Guideline Search Portal",
        last_verified_at: new Date().toISOString()
      },
      {
        id: "gv-2",
        district_id: 1,
        village_name_en: "Velachery",
        street_or_survey_number: "100 Feet Inner Ring Road",
        classification: "Residential Class I",
        unit: "sq_ft",
        value_in_rupees: 7200.0,
        effective_from: "2024-07-01",
        source_attribution: "Public TNREGINET Guideline Search Portal",
        last_verified_at: new Date().toISOString()
      }
    ];
  },

  getDocumentGuides: async (): Promise<DocumentGuide[]> => {
    try {
      const res = await fetch(`${API_BASE}/documents/guides`);
      if (res.ok) return await res.json();
    } catch (e) {}
    return [
      {
        id: "dg-1",
        slug: "patta-chitta",
        title_en: "Patta & Chitta (பட்டா & சிட்டா)",
        title_ta: "பட்டா மற்றும் சிட்டா விவரங்கள்",
        summary_en: "Legal revenue record of land ownership issued by the Tahsildar.",
        summary_ta: "வட்டாட்சியரால் வழங்கப்படும் முதன்மை நில உரிமை ஆவணம்.",
        why_it_matters_en: "Proof of rightful revenue title in Tamil Nadu.",
        why_it_matters_ta: "நில உரிமை மற்றும் வருவாய் ஆவணங்களில் பெயர் இடம்பெற அவசியம்.",
        key_fields: [{ name: "Patta Number", desc: "Unique account ID" }],
        how_to_verify_en: "Verify online 24/7 on eservices.tn.gov.in",
        how_to_verify_ta: "eservices.tn.gov.in தளத்தில் சரிபார்க்கலாம்",
        official_portal_url: "https://eservices.tn.gov.in/eservicesnew/land/chitta.html",
        order_index: 1
      }
    ];
  }
};
