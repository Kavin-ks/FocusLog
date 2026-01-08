import 'package:flutter/material.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _service = SettingsService();
  late AppSettings _settings;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _perPageController;

  @override
  void initState() {
    super.initState();
    _settings = AppSettings.defaults();
    _perPageController = TextEditingController(text: _settings.entriesPerPage.toString());
    _load();
  }

  Future<void> _load() async {
    final s = await _service.loadSettings();
    if (!mounted) return;
    setState(() {
      _settings = s;
      _perPageController.text = s.entriesPerPage.toString();
    });
  }

  @override
  void dispose() {
    _perPageController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final perPage = int.tryParse(_perPageController.text) ?? _settings.entriesPerPage;
    final updated = AppSettings(entriesPerPage: perPage.clamp(5, 1000), autoSplitCrossMidnight: _settings.autoSplitCrossMidnight);
    await _service.saveSettings(updated);
    if (!mounted) return;
    Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _perPageController,
                decoration: const InputDecoration(labelText: 'Entries per page', helperText: 'Limit number of timeline entries shown'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n <= 0) return 'Please enter a positive number';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: _settings.autoSplitCrossMidnight,
                title: const Text('Auto-split cross-midnight entries'),
                subtitle: const Text('When enabled, entries with an end time earlier than start will be split across days automatically.'),
                onChanged: (v) => setState(() => _settings = AppSettings(entriesPerPage: _settings.entriesPerPage, autoSplitCrossMidnight: v)),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                  const SizedBox(width: 12),
                  ElevatedButton(onPressed: _save, child: const Text('Save')),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
