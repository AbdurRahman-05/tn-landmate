import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/l10n/translations.dart';
import '../../core/providers.dart';
import '../../shared/widgets/custom_app_bar.dart';

class AddEditPropertyScreen extends ConsumerStatefulWidget {
  const AddEditPropertyScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AddEditPropertyScreen> createState() => _AddEditPropertyScreenState();
}

class _AddEditPropertyScreenState extends ConsumerState<AddEditPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameCtrl = TextEditingController();
  final _districtCtrl = TextEditingController(text: 'Chennai');
  final _talukCtrl = TextEditingController(text: 'Ambattur');
  final _villageCtrl = TextEditingController(text: 'Ambattur');
  final _surveyCtrl = TextEditingController();
  final _subdivCtrl = TextEditingController();
  final _extentCtrl = TextEditingController(text: '5.5');
  String _extentUnit = 'cents';
  final _notesCtrl = TextEditingController();

  void _saveProperty() {
    if (!_formKey.currentState!.validate()) return;

    final prop = {
      'id': 'prop-${DateTime.now().millisecondsSinceEpoch}',
      'nickname': _nicknameCtrl.text.trim(),
      'district_name': _districtCtrl.text.trim(),
      'taluk_name': _talukCtrl.text.trim(),
      'village_name': _villageCtrl.text.trim(),
      'survey_number': _surveyCtrl.text.trim(),
      'subdivision_number': _subdivCtrl.text.trim(),
      'extent_value': double.tryParse(_extentCtrl.text.trim()) ?? 0,
      'extent_unit': _extentUnit,
      'notes': _notesCtrl.text.trim(),
      'created_at': DateTime.now().toIso8601String(),
    };

    ref.read(propertiesProvider.notifier).addProperty(prop);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: AppTranslations.get('add_property', lang),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nicknameCtrl,
                        decoration: InputDecoration(
                          labelText: AppTranslations.get('nickname', lang),
                          prefixIcon: const Icon(Icons.label_outline, size: 20),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a property nickname' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _districtCtrl,
                              decoration: const InputDecoration(labelText: 'District'),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _talukCtrl,
                              decoration: const InputDecoration(labelText: 'Taluk'),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _villageCtrl,
                        decoration: const InputDecoration(labelText: 'Revenue Village'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _surveyCtrl,
                              decoration: const InputDecoration(labelText: 'Survey No'),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _subdivCtrl,
                              decoration: const InputDecoration(labelText: 'Sub-division No'),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _extentCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Extent Value'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              value: _extentUnit,
                              decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12)),
                              items: const [
                                DropdownMenuItem(value: 'cents', child: Text('Cents')),
                                DropdownMenuItem(value: 'sq_ft', child: Text('Sq.Ft')),
                                DropdownMenuItem(value: 'grounds', child: Text('Grounds')),
                                DropdownMenuItem(value: 'acres', child: Text('Acres')),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _extentUnit = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _notesCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: AppTranslations.get('notes', lang),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: Text(AppTranslations.get('save_property', lang)),
                  onPressed: _saveProperty,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
