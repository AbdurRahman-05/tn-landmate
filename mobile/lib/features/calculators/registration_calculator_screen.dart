import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/translations.dart';
import '../../core/providers.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../../shared/widgets/disclaimer_banner.dart';

class RegistrationCalculatorScreen extends ConsumerStatefulWidget {
  const RegistrationCalculatorScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RegistrationCalculatorScreen> createState() => _RegistrationCalculatorScreenState();
}

class _RegistrationCalculatorScreenState extends ConsumerState<RegistrationCalculatorScreen> {
  final TextEditingController _valCtrl = TextEditingController(text: '3000000'); // 30 Lakhs
  String _transactionType = 'sale';
  double _stampRate = 7.0;
  double _regRate = 2.0;

  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  void _onTransactionChanged(String? type) {
    if (type == null) return;
    setState(() {
      _transactionType = type;
      if (type == 'sale') {
        _stampRate = 7.0;
        _regRate = 2.0;
      } else if (type == 'settlement_family') {
        _stampRate = 1.0;
        _regRate = 1.0;
      } else if (type == 'gift') {
        _stampRate = 7.0;
        _regRate = 2.0;
      } else if (type == 'mortgage') {
        _stampRate = 1.0;
        _regRate = 1.0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final val = double.tryParse(_valCtrl.text.replaceAll(',', '').trim()) ?? 0;
    final stampAmt = (val * _stampRate) / 100;
    final regAmt = (val * _regRate) / 100;
    const cessAmt = 100.0;
    final totalGovt = stampAmt + regAmt + cessAmt;
    final totalCost = val + totalGovt;

    return Scaffold(
      appBar: CustomAppBar(
        title: AppTranslations.get('stamp_reg_calc', lang),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DisclaimerBanner(
              text: lang == 'ta'
                  ? 'இக்கட்டணங்கள் தமிழ்நாடு பத்திரப்பதிவுத் துறை சட்ட விதிகளின்படி உத்தேசமாக கணக்கிடப்பட்டவை. சார்பதிவாளர் அலுவலகத்தில் மதிப்பீடு மாறலாம்.'
                  : 'Calculations are estimates based on standard TN Registration Department schedules. Final stamp duty is adjudicated by the Sub-Registrar Office.',
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
                      lang == 'ta' ? 'பத்திரப் பதிவு வகை' : 'Transaction Type',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.charcoal),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.outline),
                        color: Colors.white,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _transactionType,
                          isExpanded: true,
                          items: [
                            DropdownMenuItem(
                              value: 'sale',
                              child: Text(lang == 'ta' ? 'கிரையப் பத்திரம் (Sale Deed - 7% + 2%)' : 'Sale Deed (7% Stamp + 2% Reg)'),
                            ),
                            DropdownMenuItem(
                              value: 'settlement_family',
                              child: Text(lang == 'ta' ? 'குடும்ப செட்டில்மென்ட் (Family Settlement - 1% + 1%)' : 'Family Settlement (1% + 1%)'),
                            ),
                            DropdownMenuItem(
                              value: 'gift',
                              child: Text(lang == 'ta' ? 'தான செட்டில்மென்ட் (Gift Deed - 7% + 2%)' : 'Gift Deed (7% + 2%)'),
                            ),
                            DropdownMenuItem(
                              value: 'mortgage',
                              child: Text(lang == 'ta' ? 'அடமானப் பத்திரம் (Mortgage Deed - 1% + 1%)' : 'Mortgage Deed (1% + 1%)'),
                            ),
                          ],
                          onChanged: _onTransactionChanged,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppTranslations.get('property_value', lang),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.charcoal),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _valCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        prefixText: '₹ ',
                        hintText: 'Enter consideration amount',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 10),
                    // Quick Value Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildValueChip('15 Lakhs', 1500000),
                          _buildValueChip('25 Lakhs', 2500000),
                          _buildValueChip('50 Lakhs', 5000000),
                          _buildValueChip('1 Crore', 10000000),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Cost Summary Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.outline),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        lang == 'ta' ? 'மதிப்பீட்டுக் கட்டண விவரம்' : 'Statutory Fee Breakdown',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.charcoal),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.forestGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'TN Rates 2024',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.forestGreen),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  _buildCostRow(
                    title: '${AppTranslations.get('stamp_duty', lang)} (${_stampRate.toStringAsFixed(1)}%)',
                    amount: _currencyFormat.format(stampAmt),
                    color: AppColors.forestGreenDark,
                  ),
                  const SizedBox(height: 8),
                  _buildCostRow(
                    title: '${AppTranslations.get('registration_fee', lang)} (${_regRate.toStringAsFixed(1)}%)',
                    amount: _currencyFormat.format(regAmt),
                    color: AppColors.forestGreenDark,
                  ),
                  const SizedBox(height: 8),
                  _buildCostRow(
                    title: lang == 'ta' ? 'கணினி கட்டணம் / பிற' : 'User Charges / Fixed Fee',
                    amount: _currencyFormat.format(cessAmt),
                    color: AppColors.charcoalLight,
                  ),
                  const Divider(height: 20),
                  _buildCostRow(
                    title: AppTranslations.get('total_charges', lang),
                    amount: _currencyFormat.format(totalGovt),
                    color: AppColors.terracotta,
                    isBold: true,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.forestGreen.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.forestGreen.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppTranslations.get('total_cost', lang),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.forestGreenDark),
                        ),
                        Text(
                          _currencyFormat.format(totalCost),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.forestGreenDark),
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

  Widget _buildCostRow({required String title, required String amount, required Color color, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.w500, color: AppColors.charcoal)),
        Text(amount, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: color)),
      ],
    );
  }

  Widget _buildValueChip(String label, double val) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        side: const BorderSide(color: AppColors.outline),
        onPressed: () {
          setState(() {
            _valCtrl.text = val.toInt().toString();
          });
        },
      ),
    );
  }
}
