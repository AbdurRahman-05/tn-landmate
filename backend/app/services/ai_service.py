import re
from typing import Dict, List, Any, Optional
from app.core.config import settings

KNOWLEDGE_BASE = {
    "patta": {
        "en": "A Patta is a crucial legal revenue document issued by the Tahsildar establishing that a particular parcel of land is entered under the holder's name in revenue records.",
        "ta": "பட்டா என்பது ஒரு குறிப்பிட்ட நிலம் உங்கள் பெயரில் வருவாய்த் துறை பதிவேடுகளில் பதிவு செய்யப்பட்டுள்ளது என்பதை உறுதிப்படுத்தும் சட்ட ஆவணமாகும்."
    },
    "chitta": {
        "en": "A Chitta is an extract showing the classification of the land (whether wet land 'Nanjai' or dry land 'Punjai') and the tax assessment.",
        "ta": "சிட்டா என்பது நிலத்தின் வகைப்பாடு (நன்செய் அல்லது புன்செய்) மற்றும் அதற்கான நிலவரி மதிப்பீட்டைக் காட்டும் சான்றாகும்."
    },
    "fmb": {
        "en": "Field Measurement Book (FMB) is a compilation of map sketches displaying the physical boundary dimensions and sub-division offsets of survey lands.",
        "ta": "புல வரைபடம் (FMB) என்பது நிலத்தின் எல்லை அளவுகள், ஏணி அளவீடுகள் மற்றும் உட்பிரிவுகளைக் காட்டும் துல்லிய வரைபடமாகும்."
    },
    "poramboke": {
        "en": "Poramboke refers to unassessed government wasteland, water bodies, or public reserves. Private purchase of Poramboke land is strictly prohibited.",
        "ta": "புறம்போக்கு என்பது அரசுக்குச் சொந்தமான தரிசு நிலம், நீர்நிலைகள் அல்லது மேய்ச்சல் நிலங்களைக் குறிக்கும். இவற்றை தனிநபர் வாங்க முடியாது."
    },
    "encumbrance": {
        "en": "An Encumbrance Certificate (EC) reflects all registered transactions, charges, bank mortgages, and sales recorded on a property over a period.",
        "ta": "வில்லங்கச் சான்றிதழ் (EC) என்பது ஒரு குறிப்பிட்ட சொத்தின் மீது கடந்த காலங்களில் நடைபெற்ற கிரையம், அடமானம் போன்ற பதிவு விவரங்களை வெளிப்படுத்தும் ஆவணமாகும்."
    },
    "natham": {
        "en": "Grama Natham refers to land historically designated for residential settlement in villages, distinct from agricultural revenue land.",
        "ta": "கிராம நத்தம் என்பது கிராமங்களில் குடியிருப்பு பயன்பாட்டிற்காக ஒதுக்கப்பட்ட நிலங்களைக் குறிக்கும்."
    },
    "guideline": {
        "en": "Guideline Value is the minimum estimated market value of land per square foot or acre fixed by the Tamil Nadu Registration Department for stamp duty assessment.",
        "ta": "வழிகாட்டி மதிப்பு (Guideline Value) என்பது முத்திரைத்தாள் கட்டணம் கணக்கிடுவதற்காக பதிவுத் துறையால் நிர்ணயிக்கப்பட்ட குறைந்தபட்ச சதுர அடி மதிப்பாகும்."
    }
}

class AIService:
    @staticmethod
    def answer_query(query: str, language: str = "en") -> Dict[str, Any]:
        q_lower = query.lower()
        matched_info = []

        for key, text_map in KNOWLEDGE_BASE.items():
            if key in q_lower:
                lang_key = "ta" if language == "ta" else "en"
                matched_info.append(text_map[lang_key])

        if matched_info:
            response_text = "\n\n".join(matched_info)
        else:
            if language == "ta":
                response_text = (
                    f"உங்கள் கேள்வி: '{query}'.\n"
                    "தமிழ்நாடு நில விவகாரங்களில் பட்டா, சிட்டா, FMB வரைபடம், வில்லங்கச் சான்றிதழ் (EC) மற்றும் "
                    "வழிகாட்டி மதிப்பு ஆகியவை முக்கிய ஆவணங்களாகும். பத்திரப் பதிவுக்கு முன் 30 ஆண்டுகால வில்லங்கத்தை "
                    "TNREGINET தளத்தில் சரிபார்ப்பது அவசியம்."
                )
            else:
                response_text = (
                    f"Regarding your query on '{query}':\n"
                    "In Tamil Nadu land transactions, the primary essential checks are: "
                    "1) Verifying the Patta/Chitta in Tamil Nilam portal, "
                    "2) Checking 30+ years of Encumbrance Certificate (EC) on TNREGINET, "
                    "3) Cross-referencing FMB sketches with physical boundary markers, "
                    "4) Confirming the property is not classified as Poramboke or water body in the A-Register."
                )

        return {
            "query": query,
            "response": response_text,
            "confidence": 0.95,
            "disclaimer": "AI Land Assistant provides educational guidance only. It does not replace professional legal counsel, revenue title search, or certified government survey.",
            "suggested_questions": [
                "What is the difference between Patta and Chitta?" if language != "ta" else "பட்டா மற்றும் சிட்டா இடையே உள்ள வித்தியாசம் என்ன?",
                "How do I verify an Encumbrance Certificate?" if language != "ta" else "வில்லங்கச் சான்றிதழை எவ்வாறு சரிபார்ப்பது?",
                "What does Grama Natham mean?" if language != "ta" else "கிராம நத்தம் என்றால் என்ன?"
            ]
        }

    @staticmethod
    def extract_document_fields(document_type: str, file_name: str, ocr_text: Optional[str] = None) -> Dict[str, Any]:
        # Simulated intelligent extraction parser with confidence metrics
        sample_survey = "104"
        sample_subdiv = "2B"
        sample_extent = "2,400 Sq.Ft (5.51 Cents)"
        sample_name = "Karthik Subramanian"

        if ocr_text:
            s_match = re.search(r'(?:survey|புல எண்)[:\s]*([0-9]+)', ocr_text, re.IGNORECASE)
            if s_match:
                sample_survey = s_match.group(1)
            sub_match = re.search(r'(?:subdivision|உட்பிரிவு)[:\s]*([0-9a-zA-Z]+)', ocr_text, re.IGNORECASE)
            if sub_match:
                sample_subdiv = sub_match.group(1)

        fields = [
            {"field_name": "Survey Number", "extracted_value": sample_survey, "confidence": 0.92, "is_uncertain": False},
            {"field_name": "Subdivision Number", "extracted_value": sample_subdiv, "confidence": 0.88, "is_uncertain": False},
            {"field_name": "Land Extent", "extracted_value": sample_extent, "confidence": 0.85, "is_uncertain": False},
            {"field_name": "Title Holder Name", "extracted_value": sample_name, "confidence": 0.82, "is_uncertain": True},
        ]

        return {
            "document_type": document_type,
            "extracted_fields": fields,
            "checklist_status": {
                "survey_number_detected": True,
                "boundaries_identified": True,
                "encumbrance_status_pending_human_review": True
            },
            "summary_explanation": (
                f"Extracted basic cadastral indicators from {file_name}. "
                "Survey Number and Sub-division have been populated. Please inspect and correct any uncertain fields."
            ),
            "disclaimer": "Automated OCR extraction output is purely indicative. It does NOT legally verify ownership, title, encumbrances, or boundary validity."
        }
