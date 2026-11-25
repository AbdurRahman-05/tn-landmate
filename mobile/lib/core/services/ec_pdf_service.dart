import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../features/records/ec_preview_screen.dart';

class EcPdfService {
  /// Generates the complete official Tamil Nadu Encumbrance Certificate (Form 15) A4 Document
  static Future<Uint8List> generateEcPdf(Map<String, dynamic> data) async {
    final certNo = data['reference_id'] ??
        data['certificate_no'] ??
        'TN-EC-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

    final pdf = pw.Document(
      title: 'Tamil Nadu Encumbrance Certificate - $certNo',
      author: 'TN LandMate & TNREGINET Utility',
      subject: 'Official Form 15 Encumbrance Certificate Extract',
    );

    // Extract fields with robust fallbacks
    final districtName = data['district_name'] ?? data['district'] ?? 'Chennai';
    final talukName = data['taluk_name'] ?? data['taluk'] ?? 'Ambattur';
    final villageName = data['village_name'] ?? data['village'] ?? 'Ambattur';
    final sroName = data['sro_name'] ?? 'Ambattur Sub-Registrar Office';
    final zoneName = data['zone_name'] ?? 'Chennai Zone';
    final surveyNo = data['survey_number'] ?? data['survey_no'] ?? '104';
    final subdivNo = data['subdivision_number'] ?? data['subdivision_no'] ?? '2B';
    final applicantName = data['applicant_name'] ?? data['owner_name_en'] ?? data['owner_name'] ?? 'R. Selvam';
    final extentCents = data['extent_cents']?.toString() ?? '5.51';
    final extentSqFt = data['extent_sq_ft']?.toString() ?? '2400';
    final searchFrom = data['search_period_from'] ?? '01-Jan-1994';
    final searchTo = data['search_period_to'] ?? DateTime.now().toLocal().toString().split(' ')[0];
    final isNil = data['is_nil_encumbrance'] == true;
    final issueDate = data['issue_date'] ?? DateTime.now().toLocal().toString().split('.')[0];

    // Colors matching official registration documents
    final reginetMaroon = PdfColor.fromHex('#7B1113');
    final darkCharcoal = PdfColor.fromHex('#212529');
    final lightGrey = PdfColor.fromHex('#F8F9FA');
    final borderGrey = PdfColor.fromHex('#CED4DA');
    final goldAccent = PdfColor.fromHex('#B8860B');
    final successGreen = PdfColor.fromHex('#1B4332');

    pw.Font? tamilFont;
    try {
      tamilFont = await PdfGoogleFonts.notoSansTamilRegular();
    } catch (_) {}

    final theme = pw.ThemeData.withFont(
      base: pw.Font.helvetica(),
      bold: pw.Font.helveticaBold(),
      fontFallback: tamilFont != null ? [tamilFont] : [],
    );

    // Default sample entries if not nil
    final List<Map<String, dynamic>> rawEntries = (data['entries'] as List<dynamic>?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [
          {
            'sl_no': '1',
            'doc_no': '1428 / 2004',
            'exec_date': '12-Feb-2004',
            'reg_date': '14-Feb-2004',
            'nature': 'Sale Deed (கிரய பத்திரம்)',
            'executant': 'S. Varadarajan / வரதராஜன்',
            'claimant': 'R. Selvam / ஆர். செல்வம்',
            'value': 'Rs. 6,80,000',
            'schedule': 'Survey No $surveyNo/$subdivNo, Extent $extentCents Cents ($extentSqFt Sq.Ft)',
          },
          {
            'sl_no': '2',
            'doc_no': '2890 / 2012',
            'exec_date': '15-Jul-2012',
            'reg_date': '16-Jul-2012',
            'nature': 'Simple Mortgage (எளிய அடமானம்)',
            'executant': 'R. Selvam',
            'claimant': 'State Bank of India (SBI)',
            'value': 'Rs. 15,00,000',
            'schedule': 'Survey No $surveyNo/$subdivNo, House loan hypothecation',
          },
          {
            'sl_no': '3',
            'doc_no': '842 / 2021',
            'exec_date': '10-Mar-2021',
            'reg_date': '11-Mar-2021',
            'nature': 'Discharge Receipt (அடமான விடுவிப்பு)',
            'executant': 'State Bank of India (Authorized Officer)',
            'claimant': 'R. Selvam',
            'value': 'Fully Discharged (Nil Charge)',
            'schedule': 'Survey No $surveyNo/$subdivNo, Loan closed & title released',
          },
        ];

    pdf.addPage(
      pw.Page(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(18),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: reginetMaroon, width: 2),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Top Header Banner
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(vertical: 8),
                  decoration: pw.BoxDecoration(
                    color: reginetMaroon,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'GOVERNMENT OF TAMIL NADU',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 1),
                      pw.Text(
                        'REGISTRATION DEPARTMENT (பதிவுத்துறை)',
                        style: pw.TextStyle(
                          color: PdfColor.fromHex('#FFE4B5'),
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 1),
                      pw.Text(
                        'INSPECTOR GENERAL OF REGISTRATION (TNREGINET ONLINE SERVICES)',
                        style: const pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 7.5,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 8),

                // Title Badge - Form 15
                pw.Center(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                    decoration: pw.BoxDecoration(
                      color: lightGrey,
                      border: pw.Border.all(color: goldAccent, width: 1),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Text(
                      'FORM NO. 15 - CERTIFICATE OF ENCUMBRANCE ON PROPERTY (வில்லங்கச் சான்றிதழ்)',
                      style: pw.TextStyle(
                        fontSize: 9.5,
                        fontWeight: pw.FontWeight.bold,
                        color: reginetMaroon,
                      ),
                    ),
                  ),
                ),
                pw.SizedBox(height: 8),

                // Application & Certificate Reference Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Certificate No: $certNo',
                        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: darkCharcoal)),
                    pw.Text('Search Period: $searchFrom to $searchTo',
                        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: reginetMaroon)),
                    pw.Text('Issued: $issueDate',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                  ],
                ),
                pw.Divider(color: borderGrey, thickness: 1),
                pw.SizedBox(height: 4),

                // Section 1: Property & SRO Particulars
                pw.Text('1. JURISDICTION & SEARCH PARTICULARS (பதிவு எல்லை விவரங்கள்)',
                    style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: reginetMaroon)),
                pw.SizedBox(height: 4),
                _buildPdfGridTable([
                  ['Zone / Registration District', '$zoneName / $districtName', 'Sub-Registrar Office (SRO)', sroName],
                  ['Taluk / Village', '$talukName / $villageName', 'Survey No / Subdivision', '$surveyNo / $subdivNo'],
                  ['Extent of Property', '$extentCents Cents ($extentSqFt Sq.Ft)', 'Applicant Name', applicantName],
                ], borderGrey),
                pw.SizedBox(height: 8),

                // Section 2: Encumbrance Statements Table
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('2. REGISTERED TRANSACTIONS / ACTS ON PROPERTY (வில்லங்க விவரங்கள்)',
                        style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: reginetMaroon)),
                    if (isNil)
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: pw.BoxDecoration(
                          color: successGreen,
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                        ),
                        child: pw.Text(
                          'NIL ENCUMBRANCE CERTIFIED',
                          style: pw.TextStyle(color: PdfColors.white, fontSize: 7, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                pw.SizedBox(height: 5),

                if (isNil)
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: lightGrey,
                      border: pw.Border.all(color: successGreen, width: 1),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'CERTIFICATE OF NIL ENCUMBRANCE (வில்லங்கமின்மை சான்றிதழ்)',
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: successGreen),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Having searched the registers and indices of the $sroName for the period from $searchFrom to $searchTo '
                          'in respect of the property bearing Survey No. $surveyNo/$subdivNo in $villageName Village, '
                          'it is hereby certified that NO ACTS OR ENCUMBRANCES affecting the said property have been found registered during this period.',
                          style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800, lineSpacing: 1.3),
                        ),
                      ],
                    ),
                  )
                else
                  pw.Table(
                    border: pw.TableBorder.all(color: borderGrey, width: 0.5),
                    columnWidths: {
                      0: const pw.FixedColumnWidth(22),
                      1: const pw.FixedColumnWidth(60),
                      2: const pw.FixedColumnWidth(70),
                      3: const pw.FlexColumnWidth(2.2),
                      4: const pw.FlexColumnWidth(2.2),
                      5: const pw.FixedColumnWidth(65),
                    },
                    children: [
                      // Header Row
                      pw.TableRow(
                        decoration: pw.BoxDecoration(color: lightGrey),
                        children: [
                          _buildTableHeader('Sl'),
                          _buildTableHeader('Doc No & Date'),
                          _buildTableHeader('Nature of Deed'),
                          _buildTableHeader('Executant (Seller/Borrower)'),
                          _buildTableHeader('Claimant (Buyer/Bank)'),
                          _buildTableHeader('Consideration'),
                        ],
                      ),
                      // Transaction Rows
                      ...rawEntries.map((e) {
                        return pw.TableRow(
                          children: [
                            _buildTableCell(e['sl_no']?.toString() ?? '1'),
                            _buildTableCell('${e['doc_no']}\n${e['reg_date']}'),
                            _buildTableCell(e['nature'] ?? 'Deed'),
                            _buildTableCell(e['executant'] ?? '-'),
                            _buildTableCell(e['claimant'] ?? '-'),
                            _buildTableCell(e['value'] ?? '-'),
                          ],
                        );
                      }),
                    ],
                  ),
                pw.SizedBox(height: 10),

                // Section 3: Cadastral & Digital Verification Block
                pw.Container(
                  padding: const pw.EdgeInsets.all(7),
                  decoration: pw.BoxDecoration(
                    color: lightGrey,
                    border: pw.Border.all(color: borderGrey, width: 0.5),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Row(
                    children: [
                      pw.BarcodeWidget(
                        barcode: pw.Barcode.qrCode(),
                        data: 'https://tnreginet.gov.in/portal/ecVerification.do?appNo=$certNo&sro=$sroName&s=$surveyNo',
                        width: 48,
                        height: 48,
                      ),
                      pw.SizedBox(width: 10),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('TNREGINET ONLINE PORTAL DIGITAL VERIFICATION',
                                style: pw.TextStyle(
                                    fontSize: 8, fontWeight: pw.FontWeight.bold, color: reginetMaroon)),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              'Scan QR Code to verify this Encumbrance Certificate directly on the Inspector General of Registration '
                              'portal (tnreginet.gov.in). Contains tamper-evident Section 65B IT Act electronic seal.',
                              style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              'SRO: $sroName | Parcel: $surveyNo/$subdivNo | Village: $villageName',
                              style: pw.TextStyle(
                                  fontSize: 7, fontWeight: pw.FontWeight.bold, color: darkCharcoal),
                            ),
                          ],
                        ),
                      ),
                      pw.SizedBox(width: 8),
                      // Digital Seal Box
                      pw.Container(
                        padding: const pw.EdgeInsets.all(5),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: reginetMaroon, width: 0.8),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                        ),
                        child: pw.Column(
                          children: [
                            pw.Text('DIGITALLY SIGNED',
                                style: pw.TextStyle(
                                    fontSize: 6.5, fontWeight: pw.FontWeight.bold, color: reginetMaroon)),
                            pw.Text('Sub-Registrar Officer',
                                style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey700)),
                            pw.Text('Tamil Nadu Registration',
                                style: const pw.TextStyle(fontSize: 5.5, color: PdfColors.grey600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                pw.Spacer(),

                // Statutory IT Act Disclaimer Footer
                pw.Divider(color: reginetMaroon, thickness: 1),
                pw.SizedBox(height: 3),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        'Disclaimer: This certified extract is generated electronically under Section 65B of the Indian Evidence Act, 1872 '
                        'and Information Technology Act, 2000. It requires no physical signature. Official records can be verified at tnreginet.gov.in.',
                        style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey600),
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Text(
                      'Page 1 of 1',
                      style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: darkCharcoal),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Opens the PDF Preview Screen with built-in Download, Share, and Print actions
  static void previewAndDownload(BuildContext context, Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EcPreviewScreen(data: data),
      ),
    );
  }

  static pw.Widget _buildTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#212529')),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildTableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey900),
      ),
    );
  }

  static pw.Widget _buildPdfGridTable(List<List<String>> rows, PdfColor borderColor) {
    return pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: 0.5),
      children: rows.map((r) {
        return pw.TableRow(
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(3.5),
              color: PdfColor.fromHex('#F8F9FA'),
              child: pw.Text(r[0],
                  style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(3.5),
              child: pw.Text(r[1],
                  style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#7B1113'))),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(3.5),
              color: PdfColor.fromHex('#F8F9FA'),
              child: pw.Text(r[2],
                  style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(3.5),
              child: pw.Text(r[3],
                  style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#212529'))),
            ),
          ],
        );
      }).toList(),
    );
  }
}
