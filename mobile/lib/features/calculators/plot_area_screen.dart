import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/land_units.dart';
import '../../core/l10n/translations.dart';
import '../../core/providers.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../../shared/widgets/disclaimer_banner.dart';

class PlotAreaScreen extends ConsumerStatefulWidget {
  const PlotAreaScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PlotAreaScreen> createState() => _PlotAreaScreenState();
}

class _PlotAreaScreenState extends ConsumerState<PlotAreaScreen> {
  int _selectedShapeIndex = 0; // 0: Rectangle, 1: Triangle, 2: Trapezoid, 3: Composite

  // Rectangle
  final _rectLengthCtrl = TextEditingController(text: '60');
  final _rectWidthCtrl = TextEditingController(text: '40');

  // Triangle
  final _triBaseCtrl = TextEditingController(text: '50');
  final _triHeightCtrl = TextEditingController(text: '40');

  // Trapezoid
  final _trapA = TextEditingController(text: '60');
  final _trapB = TextEditingController(text: '40');
  final _trapH = TextEditingController(text: '30');

  // Composite Sections
  final List<Map<String, TextEditingController>> _sections = [
    {'l': TextEditingController(text: '40'), 'w': TextEditingController(text: '30')},
    {'l': TextEditingController(text: '20'), 'w': TextEditingController(text: '15')},
  ];

  double _totalSqFt = 2400.0;

  @override
  void initState() {
    super.initState();
    _computeArea();
  }

  void _computeArea() {
    double sqft = 0.0;
    if (_selectedShapeIndex == 0) {
      final l = double.tryParse(_rectLengthCtrl.text.trim()) ?? 0;
      final w = double.tryParse(_rectWidthCtrl.text.trim()) ?? 0;
      sqft = l * w;
    } else if (_selectedShapeIndex == 1) {
      final b = double.tryParse(_triBaseCtrl.text.trim()) ?? 0;
      final h = double.tryParse(_triHeightCtrl.text.trim()) ?? 0;
      sqft = 0.5 * b * h;
    } else if (_selectedShapeIndex == 2) {
      final a = double.tryParse(_trapA.text.trim()) ?? 0;
      final b = double.tryParse(_trapB.text.trim()) ?? 0;
      final h = double.tryParse(_trapH.text.trim()) ?? 0;
      sqft = 0.5 * (a + b) * h;
    } else {
      for (var s in _sections) {
        final l = double.tryParse(s['l']!.text.trim()) ?? 0;
        final w = double.tryParse(s['w']!.text.trim()) ?? 0;
        sqft += (l * w);
      }
    }

    setState(() {
      _totalSqFt = sqft;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final cents = _totalSqFt / 435.6;
    final grounds = _totalSqFt / 2400.0;
    final acres = _totalSqFt / 43560.0;
    final sqM = _totalSqFt / 10.7639;

    return Scaffold(
      appBar: CustomAppBar(
        title: AppTranslations.get('plot_calculator', lang),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DisclaimerBanner(
              text: lang == 'ta'
                  ? 'வடிவவியல் கணக்கீடுகள் உத்தேசமானவை. நிலத்தின் நேரடி எல்லைகள் பட்டா மற்றும் FMB வரைபடத்திற்கு உட்பட்டவை.'
                  : 'Geometric calculation estimate. Real-world boundaries are subject to physical survey and FMB sketches.',
            ),
            const SizedBox(height: 16),

            // Shape Selector Segment
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildShapeTab(0, AppTranslations.get('rectangle', lang), Icons.crop_landscape),
                  _buildShapeTab(1, AppTranslations.get('triangle', lang), Icons.change_history),
                  _buildShapeTab(2, AppTranslations.get('trapezoid', lang), Icons.architecture),
                  _buildShapeTab(3, AppTranslations.get('composite', lang), Icons.dashboard_outlined),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Dimension Input Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lang == 'ta' ? 'அளவுகள் (அடி / Feet)' : 'Dimensions (in Feet)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.charcoal),
                    ),
                    const SizedBox(height: 12),
                    if (_selectedShapeIndex == 0) ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _rectLengthCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(labelText: AppTranslations.get('length', lang) + ' (ft)'),
                              onChanged: (_) => _computeArea(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _rectWidthCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(labelText: AppTranslations.get('width', lang) + ' (ft)'),
                              onChanged: (_) => _computeArea(),
                            ),
                          ),
                        ],
                      ),
                    ] else if (_selectedShapeIndex == 1) ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _triBaseCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(labelText: AppTranslations.get('base', lang) + ' (ft)'),
                              onChanged: (_) => _computeArea(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _triHeightCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(labelText: AppTranslations.get('height', lang) + ' (ft)'),
                              onChanged: (_) => _computeArea(),
                            ),
                          ),
                        ],
                      ),
                    ] else if (_selectedShapeIndex == 2) ...[
                      TextField(
                        controller: _trapA,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(labelText: AppTranslations.get('parallel_side_a', lang) + ' (ft)'),
                        onChanged: (_) => _computeArea(),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _trapB,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(labelText: AppTranslations.get('parallel_side_b', lang) + ' (ft)'),
                              onChanged: (_) => _computeArea(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _trapH,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(labelText: AppTranslations.get('height', lang) + ' (ft)'),
                              onChanged: (_) => _computeArea(),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      ..._sections.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final sec = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Text('${idx + 1}.', style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: sec['l'],
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: InputDecoration(labelText: 'L (ft)', contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                                  onChanged: (_) => _computeArea(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: sec['w'],
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: InputDecoration(labelText: 'W (ft)', contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                                  onChanged: (_) => _computeArea(),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 6),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: Text(lang == 'ta' ? 'பிரிவு சேர்க்க' : 'Add Section'),
                        onPressed: () {
                          setState(() {
                            _sections.add({
                              'l': TextEditingController(text: '10'),
                              'w': TextEditingController(text: '10'),
                            });
                          });
                          _computeArea();
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Computed Area Results Box
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.forestGreen,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.forestGreen.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        lang == 'ta' ? 'மொத்த மனைப் பரப்பு' : 'Calculated Plot Area',
                        style: const TextStyle(color: Color(0xFFD1E7DD), fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.mutedGold.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('ESTIMATE', style: TextStyle(color: AppColors.mutedGold, fontSize: 10, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_totalSqFt.toStringAsFixed(2)} Sq.Ft',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const Divider(color: Color(0xFF2B7A5A), height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMetricItem(cents.toStringAsFixed(2), lang == 'ta' ? 'சென்ட் (Cents)' : 'Cents'),
                      _buildMetricItem(grounds.toStringAsFixed(2), lang == 'ta' ? 'கிரவுண்டு (Grounds)' : 'Grounds'),
                      _buildMetricItem(acres.toStringAsFixed(4), lang == 'ta' ? 'ஏக்கர் (Acres)' : 'Acres'),
                      _buildMetricItem(sqM.toStringAsFixed(1), 'Sq.Metres'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(String val, String label) {
    return Column(
      children: [
        Text(val, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.mutedGold)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70)),
      ],
    );
  }

  Widget _buildShapeTab(int index, String label, IconData icon) {
    final isSelected = _selectedShapeIndex == index;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.forestGreen),
        label: Text(label),
        selected: isSelected,
        selectedColor: AppColors.forestGreen,
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.charcoal,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
        onSelected: (val) {
          if (val) {
            setState(() {
              _selectedShapeIndex = index;
            });
            _computeArea();
          }
        },
      ),
    );
  }
}
