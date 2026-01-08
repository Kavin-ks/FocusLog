import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../models/time_entry.dart';
import '../services/storage_service.dart';

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

  void _addCategory() async {
    final result = await _showCategoryDialog();
    if (result != null) {
      final newCat = ActivityCategory(DateTime.now().millisecondsSinceEpoch.toString(), result['name'], color: result['color']);
      setState(() {
        _settings = AppSettings(
          entriesPerPage: _settings.entriesPerPage,
          autoSplitCrossMidnight: _settings.autoSplitCrossMidnight,
          customCategories: [..._settings.customCategories, newCat],
        );
      });
    }
  }

  void _editCategory(ActivityCategory cat) async {
    final result = await _showCategoryDialog(initialName: cat.displayName, initialColor: cat.color);
    if (result != null) {
      final updated = ActivityCategory(cat.id, result['name'], isBuiltIn: cat.isBuiltIn, color: result['color']);
      setState(() {
        _settings = AppSettings(
          entriesPerPage: _settings.entriesPerPage,
          autoSplitCrossMidnight: _settings.autoSplitCrossMidnight,
          customCategories: _settings.customCategories.map((c) => c.id == cat.id ? updated : c).toList(),
        );
      });
    }
  }

  void _deleteCategory(ActivityCategory cat) async {
    final storage = StorageService();
    final isUsed = await storage.isCategoryUsed(cat.id);
    if (!mounted) return;
    if (!isUsed) {
      // Category is not used by any entries, safe to delete directly
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Remove category'),
          content: Text('Remove "${cat.displayName}"? This action cannot be undone.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
          ],
        ),
      );
      if (!mounted) return;
      if (confirm == true) {
        setState(() {
          _settings = AppSettings(
            entriesPerPage: _settings.entriesPerPage,
            autoSplitCrossMidnight: _settings.autoSplitCrossMidnight,
            customCategories: _settings.customCategories.where((c) => c.id != cat.id).toList(),
          );
        });
      }
    } else {
      // Category is in use: prevent data loss by requiring reassignment
      // Show all available categories (built-in + other custom) except the one being deleted
      final allCats = [...ActivityCategory.builtInCategories, ..._settings.customCategories.where((c) => c.id != cat.id)];
      if (!mounted) return;
      final selected = await showDialog<ActivityCategory>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Choose replacement'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Entries using "${cat.displayName}" need a new category. Choose one:'),
              const SizedBox(height: 16),
              ...allCats.map((c) => ListTile(
                title: Text(c.displayName),
                onTap: () => Navigator.of(context).pop(c),
              )),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ],
        ),
      );
      if (!mounted) return;
      if (selected != null) {
        await storage.reassignCategory(cat.id, selected.id);
        setState(() {
          _settings = AppSettings(
            entriesPerPage: _settings.entriesPerPage,
            autoSplitCrossMidnight: _settings.autoSplitCrossMidnight,
            customCategories: _settings.customCategories.where((c) => c.id != cat.id).toList(),
          );
        });
      }
    }
  }

  Future<Map<String, dynamic>?> _showCategoryDialog({String? initialName, Color? initialColor}) async {
    final nameController = TextEditingController(text: initialName);
    Color? selectedColor = initialColor;

    final mutedColors = [
      const Color(0xFF4CAF50), // Green
      const Color(0xFF2196F3), // Blue
      const Color(0xFFFF9800), // Orange
      const Color(0xFF9C27B0), // Purple
      const Color(0xFF757575), // Grey
      const Color(0xFF6C8EBF), // Muted blue
      const Color(0xFF7E8A97), // Grey-blue
      const Color(0xFFB5C1A9), // Sage
      const Color(0xFFBFA7C9), // Mauve
      const Color(0xFF9E9E9E), // Neutral grey
    ];

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(initialName == null ? 'Add Category' : 'Edit Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Category name'),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              const Text('Optional color (muted palette)'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: mutedColors.map((color) => GestureDetector(
                  onTap: () => setState(() => selectedColor = color),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      border: Border.all(color: selectedColor == color ? Colors.black : Colors.grey, width: selectedColor == color ? 2 : 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => setState(() => selectedColor = null),
                child: const Text('No color'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.of(context).pop({'name': nameController.text.trim(), 'color': selectedColor}),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final perPage = int.tryParse(_perPageController.text) ?? _settings.entriesPerPage;
    final updated = AppSettings(entriesPerPage: perPage.clamp(5, 1000), autoSplitCrossMidnight: _settings.autoSplitCrossMidnight, customCategories: _settings.customCategories);
    await _service.saveSettings(updated);
    if (!mounted) return;
    Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        // Responsive padding: 16 on mobile, 32 on larger screens for better spacing
        padding: EdgeInsets.all(MediaQuery.of(context).size.width > 600 ? 32 : 16),
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
                onChanged: (v) => setState(() => _settings = AppSettings(entriesPerPage: _settings.entriesPerPage, autoSplitCrossMidnight: v, customCategories: _settings.customCategories)),
              ),
              const SizedBox(height: 12),
              ExpansionTile(
                title: const Text('Categories', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                subtitle: const Text('Manage custom categories for time entries'),
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    'Custom categories are available in time entry forms. When deleting a category that has entries, you can choose where to move those entries.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  // Built-in categories (read-only)
                  ...ActivityCategory.builtInCategories.map((cat) => ListTile(
                    title: Text(cat.displayName),
                    subtitle: const Text('Built-in'),
                    trailing: const Icon(Icons.lock, size: 16),
                  )),
                  // Custom categories
                  ..._settings.customCategories.map((cat) => ListTile(
                    title: Text(cat.displayName),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editCategory(cat),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteCategory(cat),
                        ),
                      ],
                    ),
                  )),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _addCategory,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Category'),
                  ),
                  const SizedBox(height: 8),
                ],
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
