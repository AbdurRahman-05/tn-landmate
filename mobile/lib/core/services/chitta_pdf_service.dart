import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'gov_portal_bridge.dart';

/// Builds a PDF of a Patta / Chitta record fetched from eservices.tn.gov.in.
///
/// Pages are drawn with Flutter's own text engine (correct Tamil shaping) onto A4 canvases
/// and embedded as images — fully on-device, no network, so it cannot hang. The layout
/// follows the portal's result page: its tables, in the same order, with the same text.
/// It is clearly marked as an informational copy (not a certified document).
class ChittaPdfService {
  // A4 at 150 DPI.
  static const double _w = 1240;
  static const double _h = 1754;
  static const double _margin = 70;
  static const double _contentW = _w - 2 * _margin;
  static const double _footerH = 70;
  static const double _cellPadX = 10;
  static const double _cellPadY = 8;

  static const Color _ink = Color(0xFF1F2937);
  static const Color _muted = Color(0xFF6B7280);
  static const Color _line = Color(0xFF9CA3AF);
  static const Color _headFill = Color(0xFFE8F0EC);
  static const Color _green = Color(0xFF1E5A42);

  static Future<Uint8List> build({
    required PortalResult result,
    required String title,
    required List<MapEntry<String, String>> details,
  }) async {
    final pages = <ui.Picture>[];
    late ui.PictureRecorder recorder;
    late Canvas canvas;
    var y = 0.0;
    var pageNo = 0;

    void finishPage() {
      _drawFooter(canvas, pageNo, result);
      pages.add(recorder.endRecording());
    }

    void newPage() {
      if (pageNo > 0) finishPage();
      pageNo++;
      recorder = ui.PictureRecorder();
      canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, _w, _h));
      canvas.drawRect(const Rect.fromLTWH(0, 0, _w, _h), Paint()..color = Colors.white);
      y = _margin;
    }

    double room() => _h - _footerH - y;

    // ---- header
    newPage();
    y += _text(canvas, title, _margin, y, _contentW, size: 34, bold: true, color: _green);
    y += 6;
    y += _text(canvas, 'Details from TN e-Services (eservices.tn.gov.in)', _margin, y, _contentW,
        size: 20, color: _muted);
    y += 14;
    canvas.drawLine(Offset(_margin, y), Offset(_w - _margin, y), Paint()
      ..color = _green
      ..strokeWidth = 3);
    y += 18;

    // ---- request details (district, taluk, village, survey …)
    final detailRows = details.map((e) => [e.key, e.value]).toList();
    y = _drawTable(() => canvas, detailRows, y, keyValue: true, onNewPage: () {
      newPage();
      return y;
    });
    y += 24;

    // ---- the portal's own tables, in page order
    for (final table in result.tables) {
      if (room() < 120) newPage();
      final keyValue = table.every((r) => r.length <= 2);
      y = _drawTable(() => canvas, table, y, keyValue: keyValue, onNewPage: () {
        newPage();
        return y;
      });
      y += 22;
    }
    finishPage();

    // ---- rasterise pages and pack into a PDF
    final doc = pw.Document(title: title, author: 'TN LandMate', subject: 'Patta / Chitta details');
    for (final picture in pages) {
      final image = await picture.toImage(_w.toInt(), _h.toInt());
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      picture.dispose();
      if (png == null) continue;
      final mem = pw.MemoryImage(png.buffer.asUint8List());
      doc.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.FullPage(ignoreMargins: true, child: pw.Image(mem, fit: pw.BoxFit.fill)),
      ));
    }
    return doc.save();
  }

  // ----------------------------------------------------------------- tables

  /// Draws [rows] starting at [startY]; breaks onto new pages as needed (repeating the
  /// header row of grid tables). Returns the y after the table.
  static double _drawTable(
    Canvas Function() canvasOf,
    List<List<String>> rows,
    double startY, {
    required bool keyValue,
    required double Function() onNewPage,
  }) {
    if (rows.isEmpty) return startY;
    final cols = rows.map((r) => r.length).reduce(math.max);
    final fontSize = cols > 6 ? 17.0 : 19.0;
    final widths = keyValue && cols == 2
        ? [_contentW * 0.38, _contentW * 0.62]
        : _columnWidths(rows, cols, fontSize);

    var y = startY;
    final header = !keyValue && rows.length > 1 ? rows.first : null;

    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      final isHeader = header != null && i == 0;
      // A one-cell row in a key/value table is a section heading.
      final spanning = row.length == 1 && cols > 1;
      final h = spanning
          ? _measure(row.first, _contentW - 2 * _cellPadX, fontSize, true) + 2 * _cellPadY
          : _rowHeight(row, widths, fontSize, isHeader || keyValue);

      if (y + h > _h - _footerH) {
        y = onNewPage();
        if (header != null && !isHeader) {
          final hh = _rowHeight(header, widths, fontSize, true);
          _drawRow(canvasOf(), header, widths, y, hh, fontSize, header: true, keyValue: false);
          y += hh;
        }
      }
      final canvas = canvasOf(); // current page (changes after a page break)
      if (spanning) {
        canvas.drawRect(Rect.fromLTWH(_margin, y, _contentW, h), Paint()..color = _headFill);
        _strokeRect(canvas, Rect.fromLTWH(_margin, y, _contentW, h));
        _text(canvas, row.first, _margin + _cellPadX, y + _cellPadY, _contentW - 2 * _cellPadX,
            size: fontSize, bold: true);
      } else {
        _drawRow(canvas, row, widths, y, h, fontSize, header: isHeader, keyValue: keyValue);
      }
      y += h;
    }
    return y;
  }

  static void _drawRow(Canvas canvas, List<String> row, List<double> widths, double y, double h,
      double fontSize, {required bool header, required bool keyValue}) {
    var x = _margin;
    for (var c = 0; c < widths.length; c++) {
      final rect = Rect.fromLTWH(x, y, widths[c], h);
      if (header || (keyValue && c == 0)) {
        canvas.drawRect(rect, Paint()..color = _headFill);
      }
      _strokeRect(canvas, rect);
      final text = c < row.length ? row[c] : '';
      _text(canvas, text, x + _cellPadX, y + _cellPadY, widths[c] - 2 * _cellPadX,
          size: fontSize, bold: header || (keyValue && c == 0));
      x += widths[c];
    }
  }

  static double _rowHeight(List<String> row, List<double> widths, double fontSize, bool bold) {
    var h = 0.0;
    for (var c = 0; c < widths.length; c++) {
      final text = c < row.length ? row[c] : '';
      h = math.max(h, _measure(text, widths[c] - 2 * _cellPadX, fontSize, bold));
    }
    return math.max(h, fontSize * 1.3) + 2 * _cellPadY;
  }

  /// Column widths from each column's natural text width, fitted to the page width.
  static List<double> _columnWidths(List<List<String>> rows, int cols, double fontSize) {
    final natural = List<double>.filled(cols, 0);
    for (final r in rows) {
      for (var c = 0; c < r.length; c++) {
        final tp = _painter(r[c], fontSize, false)..layout();
        natural[c] = math.max(natural[c], math.min(tp.width, 420) + 2 * _cellPadX + 2);
      }
    }
    const minW = 70.0;
    for (var c = 0; c < cols; c++) {
      natural[c] = math.max(natural[c], minW);
    }
    final total = natural.reduce((a, b) => a + b);
    final scale = _contentW / total;
    final widths = natural.map((w) => w * scale).toList();
    // Keep very narrow columns readable, taking the space from the widest one.
    for (var c = 0; c < cols; c++) {
      if (widths[c] < minW * 0.8) {
        final need = minW * 0.8 - widths[c];
        final widest = widths.indexOf(widths.reduce(math.max));
        if (widths[widest] - need > minW) {
          widths[widest] -= need;
          widths[c] += need;
        }
      }
    }
    return widths;
  }

  // ------------------------------------------------------------------- text

  static TextPainter _painter(String text, double size, bool bold, {Color color = _ink}) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: size,
          height: 1.3,
          color: color,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
  }

  static double _measure(String text, double maxWidth, double size, bool bold) {
    final tp = _painter(text, size, bold)..layout(maxWidth: math.max(maxWidth, 10));
    return tp.height;
  }

  /// Paints wrapped text and returns its height.
  static double _text(Canvas canvas, String text, double x, double y, double maxWidth,
      {double size = 19, bool bold = false, Color color = _ink}) {
    final tp = _painter(text, size, bold, color: color)..layout(maxWidth: math.max(maxWidth, 10));
    tp.paint(canvas, Offset(x, y));
    return tp.height;
  }

  static void _strokeRect(Canvas canvas, Rect r) {
    canvas.drawRect(
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = _line
        ..strokeWidth = 1.2,
    );
  }

  static void _drawFooter(Canvas canvas, int pageNo, PortalResult result) {
    final top = _h - _footerH + 14;
    canvas.drawLine(Offset(_margin, top - 8), Offset(_w - _margin, top - 8), Paint()
      ..color = _line
      ..strokeWidth = 1);
    final fetched = result.fetchedAt.toString().split('.').first;
    _text(
      canvas,
      'Source: eservices.tn.gov.in · fetched $fetched · Informational copy generated by TN LandMate — '
      'not a certified document. Verify on eservices.tn.gov.in.',
      _margin,
      top,
      _contentW - 110,
      size: 15,
      color: _muted,
    );
    final tp = _painter('Page $pageNo', 16, true, color: _muted)..layout();
    tp.paint(canvas, Offset(_w - _margin - tp.width, top));
  }
}
