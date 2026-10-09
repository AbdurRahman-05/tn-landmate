import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/land_units.dart';
import '../../core/l10n/translations.dart';
import '../../core/providers.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../../shared/widgets/disclaimer_banner.dart';

class AreaConverterScreen extends ConsumerStatefulWidget {
  const AreaConverterScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AreaConverterScreen> createState() => _AreaConverterScreenState();
}

class _AreaConverterScreenState extends ConsumerState<AreaConverterScreen> {
  final TextEditingController _controller = TextEditingController(text: '1');
  String _selectedUnit = 'cents';
  Map<String, double> _results = {};

  @override
  void initState() {
    super.initState();
    _recalculate();
  }

  void _recalculate() {
    final val = double.tryParse(_controller.text.trim());
    if (val != null && val > 0) {
      setState(() {
        _results = LandUnits.convertAll(val, _selectedUnit);
      });
    } else {
      setState(() {
        _results = {};
      });
    }
  }

  void _copyResult(String unitKey, double val, String lang) {
    final label = lang == 'ta' ? LandUnits.unitLabelsTa[unitKey]! : LandUnits.unitLabelsEn[unitKey]!;
    final formatted = _formatNumber(unitKey, val);
    Clipboard.setData(ClipboardData(text: '$formatted $label'));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatNumber(String unitKey, double val) {
    if (unitKey == 'square_kilometers' || unitKey == 'hectares' || unitKey == 'acres') {
      return val.toStringAsFixed(4);
    }
    return val.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: AppTranslations.get('area_converter', lang),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Disclaimer Banner
            DisclaimerBanner(
              text: AppTranslations.get('calc_disclaimer', lang),
            ),
            const SizedBox(height: 16),

            // Input Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppTranslations.get('enter_value', lang),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.charcoal),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _controller,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              hintText: '0.0',
                              suffixIcon: _controller.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        _controller.clear();
                                        _recalculate();
                                      },
                                    )
                                  : null,
                            ),
                            onChanged: (_) => _recalculate(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.outline),
                              color: Colors.white,
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedUnit,
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.forestGreen),
                                items: LandUnits.sqftFactors.keys.map((key) {
                                  final label = lang == 'ta'
                                      ? LandUnits.unitLabelsTa[key]!
                                      : LandUnits.unitLabelsEn[key]!;
                                  return DropdownMenuItem<String>(
                                    value: key,
                                    child: Text(
                                      label.split('(')[0].trim(),
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (newVal) {
                                  if (newVal != null) {
                                    setState(() {
                                      _selectedUnit = newVal;
                                    });
                                    _recalculate();
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Quick Presets
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildPresetChip('1 Cent', 'cents', 1.0),
                          _buildPresetChip('1 Ground', 'grounds', 1.0),
                          _buildPresetChip('1 Acre', 'acres', 1.0),
                          _buildPresetChip('2,400 Sq.Ft', 'square_feet', 2400.0),
                          _buildPresetChip('100 Cents', 'cents', 100.0),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Conversion Results Section
            Text(
              AppTranslations.get('results', lang),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.charcoal),
            ),
            const SizedBox(height: 10),

            if (_results.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.outline),
                ),
                child: Text(
                  lang == 'ta' ? 'சரியான எண்ணை உள்ளிடவும்' : 'Enter a valid area number to view conversions',
                  style: const TextStyle(color: AppColors.charcoalLight, fontSize: 13),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: LandUnits.sqftFactors.keys.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final key = LandUnits.sqftFactors.keys.elementAt(index);
                  final val = _results[key] ?? 0.0;
                  final isCurrent = key == _selectedUnit;
                  final label = lang == 'ta' ? LandUnits.unitLabelsTa[key]! : LandUnits.unitLabelsEn[key]!;

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isCurrent ? AppColors.forestGreen.withOpacity(0.06) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCurrent ? AppColors.forestGreen : AppColors.outline,
                        width: isCurrent ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                                  color: isCurrent ? AppColors.forestGreen : AppColors.charcoalLight,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatNumber(key, val),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isCurrent ? AppColors.forestGreenDark : AppColors.charcoal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 18, color: AppColors.charcoalLight),
                          tooltip: 'Copy',
                          onPressed: () => _copyResult(key, val, lang),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, String unitKey, double val) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.forestGreen.withOpacity(0.08),
        side: BorderSide(color: AppColors.forestGreen.withOpacity(0.2)),
        onPressed: () {
          setState(() {
            _controller.text = val.toString();
            _selectedUnit = unitKey;
          });
          _recalculate();
        },
      ),
    );
  }
}
