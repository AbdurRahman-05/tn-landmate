import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Test full A4 canvas painter renders Tamil Patta without error', () async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const width = 1240.0;
    const height = 1754.0;

    // Background
    canvas.drawRect(const Rect.fromLTWH(0, 0, width, height), Paint()..color = Colors.white);

    // Header text painter
    final painter = TextPainter(
      text: const TextSpan(
        text: 'தமிழ்நாடு அரசு\nவருவாய் மற்றும் பேரிடர் மேலாண்மைத் துறை\nநில உரிமை விவரங்கள் : இ. எண் 10(1) பிரிவு',
        style: TextStyle(fontSize: 26, color: Colors.black, fontWeight: FontWeight.bold, height: 1.3),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    painter.layout(maxWidth: width);
    painter.paint(canvas, Offset((width - painter.width) / 2, 80));

    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    expect(bytes.isNotEmpty, isTrue);
    print('A4 Canvas rendered successfully: ${bytes.length} bytes');
  });
}
