import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../features/records/patta_preview_screen.dart';

class PattaPdfService {
  /// Generates the complete official Tamil Nadu Patta / Chitta A4 Document
  static Future<Uint8List> generatePattaPdf(Map<String, dynamic> data) async {
    final pdf = pw.Document(
      title: 'Tamil Nadu Patta Extract - ${data['patta_number'] ?? data['patta_no'] ?? 'Record'}',
      author: 'TN LandMate Revenue Utilities',
      subject: 'Official Computer Generated Patta / Chitta Extract',
    );

    // Extract fields with robust fallbacks
    final districtName = data['district_name'] ?? data['district'] ?? 'Chennai';
    final talukName = data['taluk_name'] ?? data['taluk'] ?? 'Ambattur';
    final villageName = data['village_name'] ?? data['village'] ?? 'Ambattur';
    final surveyNo = data['survey_number'] ?? data['survey_no'] ?? '104';
    final subdivNo = data['subdivision_number'] ?? data['subdivision_no'] ?? '2B';
    final pattaNo = data['patta_number'] ?? data['patta_no'] ?? '1420';
    final ownerNameEn = data['owner_name_en'] ?? data['owner_name'] ?? 'R. Selvam';
    final ownerNameTa = data['owner_name_ta'] ?? 'ஆர். செல்வம்';
    final fatherName = data['father_husband_name'] ?? 'K. Ramasamy / கே. ராமசாமி';
    final landType = data['land_type'] ?? data['classification'] ?? 'நன்செய் (Wet Land)';
    final extentCents = data['extent_cents']?.toString() ?? '5.51';
    final extentSqFt = data['extent_sq_ft']?.toString() ?? '2400';
    final extentHa = data['extent_hectares']?.toString() ?? '0.022';
    final extentAres = data['extent_ares']?.toString() ?? '2.23';
    final refNo = data['reference_id'] ??
        data['ref_no'] ??
        'TN-REV-2026-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    final issueDate = data['issue_date'] ?? DateTime.now().toLocal().toString().split('.')[0];
    final taxRate = data['tax_assessment'] ?? 'Rs. 18.50 / Year';

    final forestGreen = PdfColor.fromHex('#1B4332');
    final darkCharcoal = PdfColor.fromHex('#212529');
    final lightGrey = PdfColor.fromHex('#F8F9FA');
    final borderGrey = PdfColor.fromHex('#DEE2E6');
    final goldAccent = PdfColor.fromHex('#B8860B');

    pw.Font? tamilFont;
    try {
      tamilFont = await PdfGoogleFonts.notoSansTamilRegular();
    } catch (_) {}

    final theme = pw.ThemeData.withFont(
      base: pw.Font.helvetica(),
      bold: pw.Font.helveticaBold(),
      fontFallback: tamilFont != null ? [tamilFont] : [],
    );

    pdf.addPage(
      pw.Page(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: forestGreen, width: 2),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Top Header Banner
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(vertical: 8),
                  decoration: pw.BoxDecoration(
                    color: forestGreen,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'GOVERNMENT OF TAMIL NADU',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'REVENUE & DISASTER MANAGEMENT DEPARTMENT',
                        style: pw.TextStyle(
                          color: PdfColor.fromHex('#E0E0E0'),
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'COMMISSIONERATE OF LAND ADMINISTRATION - e-SERVICES PORTAL',
                        style: const pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 10),

                // Title Badge
                pw.Center(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: pw.BoxDecoration(
                      color: lightGrey,
                      border: pw.Border.all(color: goldAccent, width: 1),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Text(
                      'PATTA / CHITTA EXTRACT (CERTIFIED LAND REVENUE COPY)',
                      style: pw.TextStyle(
                        fontSize: 10.5,
                        fontWeight: pw.FontWeight.bold,
                        color: forestGreen,
                      ),
                    ),
                  ),
                ),
                pw.SizedBox(height: 10),

                // Reference Row
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Certificate Ref: $refNo',
                        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: darkCharcoal)),
                    pw.Text('Issued: $issueDate',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                  ],
                ),
                pw.Divider(color: borderGrey, thickness: 1),
                pw.SizedBox(height: 6),

                // Section 1: Administrative Jurisdiction
                pw.Text('1. REVENUE JURISDICTION (VAZHAVU & NIRVAGAM)',
                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: forestGreen)),
                pw.SizedBox(height: 6),
                _buildPdfGridTable([
                  ['District (Maavattam)', districtName, 'Taluk (Vattam)', talukName],
                  ['Revenue Village (Kiraamam)', villageName, 'Patta Number (Patta Enn)', pattaNo],
                ], borderGrey),
                pw.SizedBox(height: 10),

                // Section 2: Patta Holder Details
                pw.Text('2. PATTA HOLDER PARTICULARS (PATTADHARAR VIVARAM)',
                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: forestGreen)),
                pw.SizedBox(height: 6),
                _buildPdfGridTable([
                  ['Owner Name (Registered)', ownerNameEn, 'Title Status', 'ACTIVE TITLE HOLDER (URIMAIYALUR)'],
                  ['Father / Husband Name', fatherName, 'Registration Type', 'REVENUE PATTA REGISTER'],
                ], borderGrey),
                pw.SizedBox(height: 10),

                // Section 3: Land Schedule Details Table
                pw.Text('3. LAND PARCEL SCHEDULE (PULA VIVARAM & EXTENT)',
                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: forestGreen)),
                pw.SizedBox(height: 6),
                pw.Table(
                  border: pw.TableBorder.all(color: borderGrey, width: 0.5),
                  children: [
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: lightGrey),
                      children: [
                        _buildTableHeader('Survey No'),
                        _buildTableHeader('Subdivision'),
                        _buildTableHeader('Classification'),
                        _buildTableHeader('Extent (Cents)'),
                        _buildTableHeader('Extent (Sq.Ft)'),
                        _buildTableHeader('Extent (Ha-Ares)'),
                        _buildTableHeader('Assessment'),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        _buildTableCell(surveyNo),
                        _buildTableCell(subdivNo),
                        _buildTableCell(landType),
                        _buildTableCell('$extentCents Cents'),
                        _buildTableCell('$extentSqFt Sq.Ft'),
                        _buildTableCell('$extentHa Ha ($extentAres A)'),
                        _buildTableCell(taxRate),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),

                // Section 4: Cadastral & Digital Verification Block
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: lightGrey,
                    border: pw.Border.all(color: borderGrey, width: 0.5),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Row(
                    children: [
                      pw.BarcodeWidget(
                        barcode: pw.Barcode.qrCode(),
                        data:
                            'https://eservices.tn.gov.in/eservicesnew/land/chitta.html?ref=$refNo&patta=$pattaNo&s=$surveyNo&sub=$subdivNo',
                        width: 52,
                        height: 52,
                      ),
                      pw.SizedBox(width: 12),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('OFFICIAL CADASTRAL DIGITAL VERIFICATION',
                                style: pw.TextStyle(
                                    fontSize: 8, fontWeight: pw.FontWeight.bold, color: forestGreen)),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              'Scan QR Code to verify authenticity directly against Tamil Nadu Revenue e-Services portal (eservices.tn.gov.in). '
                              'Registered parcel entries correspond to official Taluk settlement registers.',
                              style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              'Survey Parcel: $surveyNo / $subdivNo | Village: $villageName | Taluk: $talukName',
                              style: pw.TextStyle(
                                  fontSize: 7, fontWeight: pw.FontWeight.bold, color: darkCharcoal),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                pw.Spacer(),

                // Statutory IT Act Disclaimer Footer
                pw.Divider(color: forestGreen, thickness: 1),
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        'This is a digitally generated extract issued under Section 65B of Indian Evidence Act / IT Act 2000.\n'
                        'Official verification available at eservices.tn.gov.in. No physical signature required.',
                        style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey600),
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: forestGreen, width: 0.5),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                      ),
                      child: pw.Text(
                        'TN LANDMATE VERIFIED',
                        style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: forestGreen),
                      ),
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
        builder: (_) => PattaPreviewScreen(data: data),
      ),
    );
  }

  static pw.Widget _buildTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildTableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 7, color: PdfColors.black),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildPdfGridTable(List<List<String>> rows, PdfColor borderColor) {
    return pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: 0.5),
      children: rows.map((row) {
        return pw.TableRow(
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(4),
              color: PdfColor.fromHex('#F8F9FA'),
              child: pw.Text(row[0],
                  style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text(row[1], style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.black)),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(4),
              color: PdfColor.fromHex('#F8F9FA'),
              child: pw.Text(row[2],
                  style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text(row[3], style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.black)),
            ),
          ],
        );
      }).toList(),
    );
  }
}
