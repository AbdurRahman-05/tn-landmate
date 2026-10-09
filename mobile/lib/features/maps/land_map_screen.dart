import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../../shared/widgets/disclaimer_banner.dart';

class LandMapScreen extends ConsumerStatefulWidget {
  const LandMapScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LandMapScreen> createState() => _LandMapScreenState();
}

class _LandMapScreenState extends ConsumerState<LandMapScreen> {
  // Default coordinates: Chennai Central, Tamil Nadu
  double _lat = 13.0827;
  double _lng = 80.2707;

  void _copyCoords() {
    Clipboard.setData(ClipboardData(text: '$_lat, $_lng'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Coordinates copied to clipboard'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: lang == 'ta' ? 'புவியியல் அமைவிடம்' : 'Location & Coordinates',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DisclaimerBanner(
              text: lang == 'ta'
                  ? 'ஜிபிஎஸ் அட்ச/தீர்க்கரேகை அளவுகள் தோராய அமைவிடமே. இது அதிகாரப்பூர்வ நில அளவைத் துறை புல எல்லை அல்ல.'
                  : 'GPS coordinates are approximate geographic references. They do NOT represent certified cadastral survey parcel boundaries.',
            ),
            const SizedBox(height: 16),

            // Interactive Coordinate Simulation Viewer
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Container(
                    height: 220,
                    width: double.infinity,
                    color: const Color(0xFFE8F0EC),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Map Grid Simulation Pattern
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _MapGridPainter(),
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.forestGreen,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: const Icon(Icons.location_on, color: AppColors.mutedGold, size: 28),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.outline),
                              ),
                              child: Text(
                                'Lat: ${_lat.toStringAsFixed(4)} • Lng: ${_lng.toStringAsFixed(4)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.charcoal),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Survey Pin Reference',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.copy, size: 14),
                              label: const Text('Copy GPS', style: TextStyle(fontSize: 11)),
                              onPressed: _copyCoords,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Region: Chennai, Tamil Nadu • Datum: WGS 84',
                          style: const TextStyle(fontSize: 12, color: AppColors.charcoalLight),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFFCBD5E1).withOpacity(0.5)
      ..strokeWidth = 1.0;
    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
