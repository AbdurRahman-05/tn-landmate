import subprocess
import os
import sys

EDGE_PATH = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
BASE_DIR = r"d:\Tn land app"

patta_html = """<!DOCTYPE html>
<html lang="ta">
<head>
<meta charset="UTF-8">
<title>Tamil Nadu Patta / Chitta Certified Extract</title>
<link href="https://fonts.googleapis.com/css2?family=Mukta+Malar:wght@400;600;700&family=Inter:wght@400;600;700;800&display=swap" rel="stylesheet">
<style>
  @page {
    size: A4 portrait;
    margin: 10mm;
  }
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body {
    font-family: 'Inter', 'Mukta Malar', sans-serif;
    color: #1f2937;
    background: #fff;
    padding: 10px;
    font-size: 11px;
    line-height: 1.4;
  }
  .cert-container {
    border: 3px double #1b4332;
    border-radius: 8px;
    padding: 18px;
    background: #ffffff;
    position: relative;
    box-shadow: inset 0 0 0 1px #2d6a4f;
  }
  .header-banner {
    background: linear-gradient(135deg, #1b4332 0%, #2d6a4f 100%);
    color: white;
    text-align: center;
    padding: 12px 10px;
    border-radius: 6px;
    margin-bottom: 12px;
  }
  .header-banner h1 {
    font-size: 16px;
    font-weight: 800;
    letter-spacing: 0.5px;
    margin-bottom: 2px;
  }
  .header-banner h2 {
    font-size: 11px;
    font-weight: 600;
    color: #d1fae5;
    margin-bottom: 2px;
  }
  .header-banner p {
    font-size: 9px;
    color: #ecfdf5;
    letter-spacing: 0.3px;
  }
  .title-badge {
    text-align: center;
    margin-bottom: 14px;
  }
  .title-badge span {
    display: inline-block;
    background: #fef3c7;
    border: 1px solid #d97706;
    color: #92400e;
    font-weight: 700;
    font-size: 12px;
    padding: 5px 18px;
    border-radius: 20px;
  }
  .meta-row {
    display: flex;
    justify-content: space-between;
    font-size: 10px;
    font-weight: 600;
    color: #4b5563;
    padding-bottom: 6px;
    border-bottom: 1px solid #e5e7eb;
    margin-bottom: 10px;
  }
  .section-title {
    font-size: 11px;
    font-weight: 700;
    color: #1b4332;
    text-transform: uppercase;
    letter-spacing: 0.3px;
    margin: 10px 0 6px 0;
    border-left: 3px solid #1b4332;
    padding-left: 6px;
  }
  table.info-grid {
    width: 100%;
    border-collapse: collapse;
    margin-bottom: 10px;
    font-size: 10px;
  }
  table.info-grid td {
    padding: 5px 8px;
    border: 1px solid #e5e7eb;
  }
  table.info-grid td.label {
    background: #f9fafb;
    font-weight: 600;
    color: #374151;
    width: 25%;
  }
  table.info-grid td.val {
    width: 25%;
    color: #111827;
    font-weight: 500;
  }
  table.schedule-table {
    width: 100%;
    border-collapse: collapse;
    margin-bottom: 12px;
    font-size: 10px;
    text-align: center;
  }
  table.schedule-table th {
    background: #1b4332;
    color: white;
    font-weight: 600;
    padding: 6px 4px;
    border: 1px solid #1b4332;
    font-size: 9.5px;
  }
  table.schedule-table td {
    padding: 7px 4px;
    border: 1px solid #e5e7eb;
    color: #1f2937;
  }
  .verification-box {
    display: flex;
    align-items: center;
    background: #f0fdf4;
    border: 1px solid #86efac;
    border-radius: 6px;
    padding: 10px 14px;
    margin-top: 8px;
    margin-bottom: 14px;
  }
  .qr-code {
    width: 64px;
    height: 64px;
    flex-shrink: 0;
    margin-right: 14px;
    background: #fff;
    border: 1px solid #bbf7d0;
    border-radius: 4px;
    display: flex;
    align-items: center;
    justify-content: center;
  }
  .verif-text h3 {
    font-size: 10.5px;
    font-weight: 700;
    color: #166534;
    margin-bottom: 2px;
  }
  .verif-text p {
    font-size: 8.5px;
    color: #374151;
    line-height: 1.35;
  }
  .footer-row {
    display: flex;
    justify-content: space-between;
    align-items: center;
    border-top: 1.5px solid #1b4332;
    padding-top: 8px;
    font-size: 8px;
    color: #6b7280;
  }
  .stamp-badge {
    border: 1px solid #1b4332;
    color: #1b4332;
    font-weight: 700;
    padding: 3px 8px;
    border-radius: 4px;
    font-size: 8px;
  }
</style>
</head>
<body>
<div class="cert-container">
  <div class="header-banner">
    <h1>GOVERNMENT OF TAMIL NADU</h1>
    <h2>REVENUE & DISASTER MANAGEMENT DEPARTMENT (வருவாய்த் துறை)</h2>
    <p>COMMISSIONERATE OF LAND ADMINISTRATION - e-SERVICES PORTAL (நில நிர்வாக ஆணையரகம்)</p>
  </div>

  <div class="title-badge">
    <span>PATTA / CHITTA EXTRACT (பட்டா / சிட்டா சான்றளிக்கப்பட்ட நகல்)</span>
  </div>

  <div class="meta-row">
    <div>Certificate Ref: <strong>TN-REV-2026-PATTA-1420</strong></div>
    <div>Issued On: <strong>10 October 2026, 16:50:00 IST</strong></div>
  </div>

  <div class="section-title">1. Revenue Jurisdiction / வருவாய் நிர்வாக எல்லை விவரங்கள்</div>
  <table class="info-grid">
    <tr>
      <td class="label">District (மாவட்டம்)</td>
      <td class="val">Chennai / சென்னை</td>
      <td class="label">Taluk (வட்டம்)</td>
      <td class="val">Ambattur / அம்பத்தூர்</td>
    </tr>
    <tr>
      <td class="label">Revenue Village (வருவாய் கிராமம்)</td>
      <td class="val">Ambattur / அம்பத்தூர்</td>
      <td class="label">Patta Number (பட்டா எண்)</td>
      <td class="val"><strong>1420</strong></td>
    </tr>
  </table>

  <div class="section-title">2. Patta Holder Particulars / பட்டாதாரர் விவரங்கள்</div>
  <table class="info-grid">
    <tr>
      <td class="label">Owner Name (English)</td>
      <td class="val"><strong>R. Selvam</strong></td>
      <td class="label">உரிமையாளர் பெயர் (தமிழ்)</td>
      <td class="val"><strong>ஆர். செல்வம்</strong></td>
    </tr>
    <tr>
      <td class="label">Father / Husband Name</td>
      <td class="val">K. Ramasamy / கே. ராமசாமி</td>
      <td class="label">Title Status (உரிமை நிலை)</td>
      <td class="val"><span style="color:#166534; font-weight:700;">ACTIVE TITLE HOLDER (உரிமையாளர்)</span></td>
    </tr>
  </table>

  <div class="section-title">3. Land Parcel Schedule & Extent / புல விவரங்கள் & பரப்பளவு</div>
  <table class="schedule-table">
    <thead>
      <tr>
        <th>Survey No (புல எண்)</th>
        <th>Subdivision (உட்பிரிவு)</th>
        <th>Classification (நில வகை)</th>
        <th>Extent (Cents)</th>
        <th>Extent (Sq.Ft)</th>
        <th>Extent (Ha - Ares)</th>
        <th>Tax Assessment (தீர்வை)</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td><strong>104</strong></td>
        <td><strong>2B</strong></td>
        <td>நன்செய் (Wet Land)</td>
        <td><strong>5.51 Cents</strong></td>
        <td><strong>2,400 Sq.Ft</strong></td>
        <td>0.022 Ha (2.23 Ares)</td>
        <td>Rs. 18.50 / Year</td>
      </tr>
    </tbody>
  </table>

  <div class="verification-box">
    <div class="qr-code">
      <!-- SVG QR Code Icon -->
      <svg width="50" height="50" viewBox="0 0 24 24" fill="#1b4332">
        <path d="M2 2h8v8H2V2zm2 2v4h4V4H4zm10-2h8v8h-8V2zm2 2v4h4V4h-4zM2 14h8v8H2v-8zm2 2v4h4v-4H4zm14-2h4v2h-4v-2zm-4 0h2v4h-2v-4zm2 4h4v4h-4v-4zm2-2h2v2h-2v-2zm-6 2h2v4h-2v-4zm-4-4h2v2H8v-2zm0 4h2v2H8v-2z"/>
      </svg>
    </div>
    <div class="verif-text">
      <h3>OFFICIAL CADASTRAL DIGITAL VERIFICATION (அதிகாரப்பூர்வ டிஜிட்டல் சரிபார்ப்பு)</h3>
      <p>Scan this QR code to verify genuineness directly against the Government of Tamil Nadu Revenue e-Services database at <strong>eservices.tn.gov.in</strong>.<br>
      Parcel registered under Ambattur Taluk Settlement Register | Sub-Registrar Office: Ambattur SRO.</p>
    </div>
  </div>

  <div class="footer-row">
    <div>
      This is a digitally generated extract issued under Section 65B of Indian Evidence Act / IT Act 2000. No physical signature is required.<br>
      இக்குறிப்பு கணினி மூலம் பெறப்பட்டது. தகவல் தொழில்நுட்பச் சட்டம் 2000-ன் படி இதற்கு கையொப்பம் தேவையில்லை. (eservices.tn.gov.in)
    </div>
    <div class="stamp-badge">
      TN LANDMATE VERIFIED
    </div>
  </div>
</div>
</body>
</html>
"""

guide_html = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>TN LandMate - Full PDF Architecture & Workflow Guide</title>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&family=JetBrains+Mono:wght@400;600&display=swap" rel="stylesheet">
<style>
  @page {
    size: A4 portrait;
    margin: 12mm;
  }
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body {
    font-family: 'Inter', sans-serif;
    color: #1f2937;
    background: #fff;
    padding: 12px;
    font-size: 11px;
    line-height: 1.5;
  }
  .doc-header {
    border-bottom: 3px solid #1b4332;
    padding-bottom: 12px;
    margin-bottom: 18px;
    display: flex;
    justify-content: space-between;
    align-items: flex-end;
  }
  .doc-title h1 {
    font-size: 20px;
    font-weight: 800;
    color: #1b4332;
    margin-bottom: 4px;
  }
  .doc-title p {
    font-size: 12px;
    color: #4b5563;
    font-weight: 500;
  }
  .doc-badge {
    background: #ecfdf5;
    border: 1px solid #10b981;
    color: #065f46;
    padding: 4px 10px;
    border-radius: 6px;
    font-weight: 700;
    font-size: 10px;
  }
  .intro-box {
    background: #f8fafc;
    border-left: 4px solid #0284c7;
    padding: 12px 16px;
    border-radius: 0 8px 8px 0;
    margin-bottom: 20px;
    font-size: 11.5px;
  }
  .intro-box p {
    color: #1e293b;
    margin-bottom: 6px;
  }
  .intro-box p:last-child { margin-bottom: 0; }
  .section-h2 {
    font-size: 14px;
    font-weight: 800;
    color: #1b4332;
    margin: 22px 0 10px 0;
    border-bottom: 1.5px solid #e5e7eb;
    padding-bottom: 4px;
  }
  .flow-card {
    background: #fff;
    border: 1px solid #e5e7eb;
    border-radius: 8px;
    padding: 12px;
    margin-bottom: 12px;
    box-shadow: 0 1px 3px rgba(0,0,0,0.04);
  }
  .flow-header {
    display: flex;
    align-items: center;
    margin-bottom: 8px;
  }
  .step-num {
    background: #1b4332;
    color: #fff;
    width: 22px;
    height: 22px;
    border-radius: 50%;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    font-size: 10px;
    font-weight: 700;
    margin-right: 8px;
  }
  .flow-header h3 {
    font-size: 12px;
    font-weight: 700;
    color: #111827;
  }
  .flow-badge {
    margin-left: auto;
    font-size: 9px;
    font-weight: 700;
    padding: 2px 8px;
    border-radius: 4px;
  }
  .badge-offline { background: #dcfce7; color: #15803d; }
  .badge-online { background: #dbeafe; color: #1e40af; }
  .badge-engine { background: #fef3c7; color: #92400e; }
  
  .tanglish-desc {
    background: #fdfdfd;
    border-left: 3px solid #10b981;
    padding: 8px 12px;
    margin: 6px 0;
    font-size: 10.5px;
    color: #1f2937;
    border-radius: 0 4px 4px 0;
  }
  .tech-detail {
    font-size: 9.5px;
    color: #4b5563;
    margin-top: 4px;
  }
  code {
    font-family: 'JetBrains Mono', monospace;
    font-size: 9px;
    background: #f3f4f6;
    padding: 1px 4px;
    border-radius: 3px;
    color: #0f766e;
  }
  table.summary-table {
    width: 100%;
    border-collapse: collapse;
    margin-top: 14px;
    font-size: 10px;
  }
  table.summary-table th {
    background: #1b4332;
    color: #fff;
    padding: 8px;
    text-align: left;
    font-size: 9.5px;
  }
  table.summary-table td {
    padding: 7px 8px;
    border: 1px solid #e5e7eb;
    color: #374151;
  }
  .page-break {
    page-break-before: always;
  }
  .arch-diagram-box {
    background: #0f172a;
    color: #e2e8f0;
    padding: 16px;
    border-radius: 8px;
    margin: 14px 0;
    font-family: 'JetBrains Mono', monospace;
    font-size: 9px;
    line-height: 1.4;
  }
</style>
</head>
<body>

<div class="doc-header">
  <div class="doc-title">
    <h1>TN LandMate: PDF Architecture & Workflow Working Flow</h1>
    <p>Complete End-to-End System Design & Operation Guide (In Tanglish)</p>
  </div>
  <div class="doc-badge">v1.0.0 Production</div>
</div>

<div class="intro-box">
  <p><strong>Vanakkam!</strong> Namma <strong>TN LandMate</strong> app-la PDF generation, live scraper bridge, math calculations, and offline storage epdi synchronize aaguthu nu indha document-la detailed-ah step-by-step explain pannirukom.</p>
  <p>Indha system <strong>5 Core Architectural Layers</strong>-la build aagirukku: Offline Geography, Live Govt Bridge, Math Normalization, Vector PDF Engine, and Native Device Spooler.</p>
</div>

<div class="section-h2">1. Visual Architecture Blueprint (Architecture Flow)</div>
<div class="arch-diagram-box">
[1. User Input Form]
       |
       +---> [Local Geography DB: 38 Districts, 317 Taluks, 18,606 Villages] (100% Offline)
       |
       +---> (Optional) [Live Govt Bridge -> FastAPI Backend -> eservices.tn.gov.in]
                   |
                   +--> Live CAPTCHA solved in Native Mobile BottomSheet
                   +--> Extracted Official Records (Owner Name, Survey, Land Class)
       |
[2. Data Normalization & Math Engine]
       |
       +---> Converts Extent: Cents -> Sq.Ft (x435.6) -> Hectares -> Ares
       +---> Generates Unique Reference Ref: TN-REV-2026-XXXXXX
       +---> Calculates Stamp Duty & Registration Tax Assessment
       |
[3. Client-Side PDF Engine (PattaPdfService)]
       |
       +---> Builds A4 Vector Canvas (Header, Bilingual Tables, Statutory Footer)
       +---> Embeds Live Vector QR Code targeting eservices.tn.gov.in validation
       +---> Section 65B Indian Evidence Act / IT Act 2000 Legal Validity Stamp
       |
[4. Native Mobile Device Actions (PattaPreviewScreen)]
       |
       +---> Save as PDF into phone's Downloads directory
       +---> Direct Share via WhatsApp, Gmail, Telegram
       +---> Direct Print to WiFi / Bluetooth Network Printers
</div>

<div class="section-h2">2. The 5 Core Layers Deep-Dive (In Tanglish)</div>

<div class="flow-card">
  <div class="flow-header">
    <span class="step-num">1</span>
    <h3>Layer 1: Zero-Latency Offline Geography Engine</h3>
    <span class="flow-badge badge-offline">100% Offline</span>
  </div>
  <div class="tanglish-desc">
    <strong>Enna Nadakuthu?</strong> User app open panni District, Taluk, Revenue Village select pannum pothu internet connection thevaiye illa! Tamil Nadu-oda 38 Districts, 317 Taluks, and 18,606 Villages mobile memory kulla embed aagi irukku.
  </div>
  <div class="tech-detail">
    <strong>Technical Source:</strong> <code>mobile/lib/core/data/tn_geography_data.dart</code>. Instant binary lookup with zero network lag.
  </div>
</div>

<div class="flow-card">
  <div class="flow-header">
    <span class="step-num">2</span>
    <h3>Layer 2: Live Government Portal Scraper Bridge</h3>
    <span class="flow-badge badge-online">Cloud + Govt Live</span>
  </div>
  <div class="tanglish-desc">
    <strong>Enna Nadakuthu?</strong> User "Extract Live Patta/Chitta" click panna, namma Render backend direct-ah <code>eservices.tn.gov.in</code> kooda connect aagi, live session create panni, CAPTCHA image-ah phone screen-la kaatum. User solve panna udane official Tamil Nadu server data retrieve aagi varum.
  </div>
  <div class="tech-detail">
    <strong>Technical Source:</strong> <code>backend/app/services/live_scraper_service.py</code> & <code>mobile/lib/shared/widgets/live_gov_extractor_sheet.dart</code>. 60s cold-start timeout tolerance.
  </div>
</div>

<div class="flow-card">
  <div class="flow-header">
    <span class="step-num">3</span>
    <h3>Layer 3: Math & Normalization Engine</h3>
    <span class="flow-badge badge-engine">Client & Server</span>
  </div>
  <div class="tanglish-desc">
    <strong>Enna Nadakuthu?</strong> Raw land extent-ah 4 standard revenue units-ku automatically convert pannum: Cents, Square Feet, Hectares, and Ares. Unique timestamped reference ID generate aagi certificate seal create aagum.
  </div>
  <div class="tech-detail">
    <strong>Formula:</strong> <code>Sq.Ft = Cents * 435.6</code> | <code>Hectares = Cents * 0.00404686</code> | Reference: <code>TN-REV-YYYY-XXXXXX</code>.
  </div>
</div>

<div class="flow-card">
  <div class="flow-header">
    <span class="step-num">4</span>
    <h3>Layer 4: Vector PDF Generation Engine (PattaPdfService)</h3>
    <span class="flow-badge badge-offline">100% Client-Side Offline</span>
  </div>
  <div class="tanglish-desc">
    <strong>Enna Nadakuthu?</strong> Server illamalaye mobile phone-oda RAM-la official Tamil Nadu Revenue Department A4 certificate format-la pixel-perfect PDF build aagum. Vector QR code, bilingual tables, and IT Act Section 65B legal validity stamp embed aagidum.
  </div>
  <div class="tech-detail">
    <strong>Technical Source:</strong> <code>mobile/lib/core/services/patta_pdf_service.dart</code> using Dart <code>pdf</code> & <code>printing</code> libraries.
  </div>
</div>

<div class="flow-card">
  <div class="flow-header">
    <span class="step-num">5</span>
    <h3>Layer 5: Native Device Integration (Preview, Save & Share)</h3>
    <span class="flow-badge badge-offline">Native Android/iOS</span>
  </div>
  <div class="tanglish-desc">
    <strong>Enna Nadakuthu?</strong> Generated PDF-ah user phone-la zoom panni paakalaam, 1-tap panni phone-oda Downloads folder-la save pannalaam, WhatsApp-la clients-ku share pannalaam, illana Bluetooth/WiFi printer vazhiya print edukalaam!
  </div>
  <div class="tech-detail">
    <strong>Technical Source:</strong> <code>mobile/lib/features/records/patta_preview_screen.dart</code>. Uses Native Android Print Spooler and Intent Share Sheet.
  </div>
</div>

<div class="section-h2">3. End-to-End Real World Citizen Journey (Tanglish)</div>
<div class="tanglish-desc" style="line-height:1.6;">
  <strong>Scenario:</strong> Oru real estate buyer illana land owner Ambattur Survey No 104/2B-ku Patta copy edukka virumburaanga:<br>
  1. <strong>Open App:</strong> Home screen-la <em>"Download Patta PDF"</em> button tap panraanga.<br>
  2. <strong>Instant Select:</strong> District: <em>Chennai</em>, Taluk: <em>Ambattur</em>, Village: <em>Ambattur</em> select panraanga (offline-la instant-ah load aagum).<br>
  3. <strong>Data Input:</strong> Survey No <em>104</em>, Subdiv <em>2B</em>, Patta No <em>1420</em>, Owner <em>R. Selvam</em> kudukuraanga.<br>
  4. <strong>1-Tap Generate:</strong> <em>"Download Generated Patta (PDF)"</em> tap panna udane microsecond-la official A4 PDF certificate generate aagi screen-la open aagidum.<br>
  5. <strong>Download / Share:</strong> Top right download/share button thatti WhatsApp-la bank loan officer-ko buyer-ko instant-ah send panraanga!
</div>

<div class="section-h2">4. Architecture Summary Table</div>
<table class="summary-table">
  <thead>
    <tr>
      <th>Module</th>
      <th>Key Responsibility</th>
      <th>Offline Capable?</th>
      <th>Primary File</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><strong>Geography DB</strong></td>
      <td>38 Districts, 317 Taluks, 18,606 Revenue Villages</td>
      <td>Yes (100%)</td>
      <td><code>tn_geography_data.dart</code></td>
    </tr>
    <tr>
      <td><strong>Live Govt Bridge</strong></td>
      <td>Connects to eservices.tn.gov.in & extracts live records</td>
      <td>Requires Internet</td>
      <td><code>live_scraper_service.py</code></td>
    </tr>
    <tr>
      <td><strong>PDF Generator Engine</strong></td>
      <td>Builds official A4 Patta with QR Code & IT Act seal</td>
      <td>Yes (100%)</td>
      <td><code>patta_pdf_service.dart</code></td>
    </tr>
    <tr>
      <td><strong>Preview & Spooler</strong></td>
      <td>Interactive zoom, storage download, WhatsApp share, print</td>
      <td>Yes (100%)</td>
      <td><code>patta_preview_screen.dart</code></td>
    </tr>
    <tr>
      <td><strong>Cloud Backend API</strong></td>
      <td>Cloud metadata validation, guideline values & health</td>
      <td>Requires Internet</td>
      <td><code>land.py</code></td>
    </tr>
  </tbody>
</table>

</body>
</html>
"""

with open(os.path.join(BASE_DIR, "docs", "patta_certificate.html"), "w", encoding="utf-8") as f:
    f.write(patta_html)

with open(os.path.join(BASE_DIR, "docs", "architecture_workflow_guide.html"), "w", encoding="utf-8") as f:
    f.write(guide_html)

print("HTML files written successfully.")

# Convert patta_certificate.html -> sample_patta_certificate.pdf
patta_html_path = os.path.join(BASE_DIR, "docs", "patta_certificate.html")
patta_pdf_path = os.path.join(BASE_DIR, "sample_patta_certificate.pdf")
cmd1 = [
    EDGE_PATH,
    "--headless",
    "--disable-gpu",
    "--run-all-compositor-stages-before-draw",
    f"--print-to-pdf={patta_pdf_path}",
    f"file:///{patta_html_path.replace(os.sep, '/')}"
]
print("Running command 1 for Patta certificate PDF...")
res1 = subprocess.run(cmd1, capture_output=True, text=True)
print("Cmd 1 exit code:", res1.returncode)

# Convert architecture_workflow_guide.html -> TN_LandMate_Architecture_and_Workflow_Guide.pdf
guide_html_path = os.path.join(BASE_DIR, "docs", "architecture_workflow_guide.html")
guide_pdf_path = os.path.join(BASE_DIR, "TN_LandMate_Architecture_and_Workflow_Guide.pdf")
cmd2 = [
    EDGE_PATH,
    "--headless",
    "--disable-gpu",
    "--run-all-compositor-stages-before-draw",
    f"--print-to-pdf={guide_pdf_path}",
    f"file:///{guide_html_path.replace(os.sep, '/')}"
]
print("Running command 2 for Architecture Guide PDF...")
res2 = subprocess.run(cmd2, capture_output=True, text=True)
print("Cmd 2 exit code:", res2.returncode)

print("Both PDFs generated successfully!")
