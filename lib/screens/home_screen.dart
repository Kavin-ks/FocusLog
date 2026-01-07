import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/export_options_sheet.dart';

import '../models/time_entry.dart';
import '../services/storage_service.dart';
import '../widgets/day_summary.dart';
import '../widgets/time_entry_card.dart';
import '../widgets/timeline_view.dart';
import '../widgets/category_summary.dart';
import 'add_entry_dialog.dart';
import 'weekly_overview_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storage = StorageService();
  List<TimeEntry> _entries = [];
  DateTime _selectedDate = DateTime.now();
  bool _loading = true;
  final TextEditingController _reflectionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadEntries();
    _loadReflection();
  }

  Future<void> _loadEntries() async {
    setState(() => _loading = true);
    final entries = await _storage.loadEntries(_selectedDate);
    entries.sort((a, b) => a.startTime.compareTo(b.startTime));
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  List<TimeEntry> get _entriesForSelectedDate {
    return _entries;
  }

  Future<void> _openAddDialog([TimeEntry? existing]) async {
    final result = await showDialog<TimeEntry>(
      context: context,
      builder: (_) => AddEntryDialog(entry: existing, selectedDate: _selectedDate),
    );

    if (result != null) {
      if (existing == null) {
        await _storage.addEntry(_selectedDate, result);
      } else {
        await _storage.updateEntry(_selectedDate, result);
      }
      await _loadEntries();
    }
  }

  Future<void> _deleteEntry(String id) async {
    await _storage.deleteEntry(_selectedDate, id);
    await _loadEntries();
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
      _loadEntries();
      _loadReflection();
    });
  }

  void _setToday() {
    setState(() {
      _selectedDate = DateTime.now();
      _loadEntries();
      _loadReflection();
    });
  }

  void _setYesterday() {
    setState(() {
      _selectedDate = DateTime.now().subtract(const Duration(days: 1));
      _loadEntries();
      _loadReflection();
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _loadEntries();
        _loadReflection();
      });
    }
  }

  Future<void> _loadReflection() async {
    final r = await _storage.loadReflection(_selectedDate);
    setState(() {
      _reflectionController.text = r ?? '';
    });
  }

  Future<void> _saveReflection() async {
    await _storage.saveReflection(_selectedDate, _reflectionController.text);
  }

  // Helper: are we showing today's date? Used to disable the "next" arrow and
  // the Today button for a calm, minimal UX.
  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  // Helper: are we showing yesterday's date? This controls whether the
  // "Yesterday" quick button should be active.
  bool get _isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return _selectedDate.year == yesterday.year &&
        _selectedDate.month == yesterday.month &&
        _selectedDate.day == yesterday.day;
  }

  Future<void> _exportData(String format) async {
    // Calm and minimal export flow: create file, then present share dialog or copy option.
    String content;
    String filename;
    if (format == 'json') {
      content = await _storage.exportAllAsJson();
      filename = 'focuslog_export_${DateTime.now().toIso8601String()}.json';
    } else {
      content = await _storage.exportAllAsCsv();
      filename = 'focuslog_export_${DateTime.now().toIso8601String()}.csv';
    }

    // Save to temporary file and show the modular export sheet
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsString(content);

      if (!mounted) return;

      // The export sheet is a small reusable component that keeps the UI calm and minimal.
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        builder: (context) => ExportOptionsSheet(file: file, content: content),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  Future<void> _confirmClearAll() async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear all data'),
          content: const Text('This will permanently remove all saved entries and reflections. If you want to keep a copy, consider exporting your data first.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Clear data'),
            ),
          ],
        );
      },
    );

    if (proceed == true) {
      await _storage.clearAllData();
      await _loadEntries();
      await _loadReflection();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All data cleared')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final todaysEntries = _entriesForSelectedDate;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: const Text('FocusLog'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_view_week),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const WeeklyOverviewScreen(),
                ),
              );
            },
            tooltip: 'Weekly Overview',
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'export_json') {
                await _exportData('json');
              } else if (value == 'export_csv') {
                await _exportData('csv');
              } else if (value == 'clear_all') {
                _confirmClearAll();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'export_json', child: Text('Export JSON')),
              const PopupMenuItem(value: 'export_csv', child: Text('Export CSV')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'clear_all', child: Text('Clear all data')),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date selector
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chevron_left),
                                  onPressed: () => _changeDate(-1),
                                  tooltip: 'Previous day',
                                ),
                                Expanded(
                                  child: Text(
                                    DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
                                    style: Theme.of(context).textTheme.titleMedium,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.chevron_right),
                                  onPressed: _isToday ? null : () => _changeDate(1),
                                  tooltip: 'Next day',
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                OutlinedButton(
                                  onPressed: _isToday ? null : _setToday,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  ),
                                  child: const Text('Today'),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton(
                                  onPressed: _isYesterday ? null : _setYesterday,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  ),
                                  child: const Text('Yesterday'),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton(
                                  onPressed: _pickDate,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.calendar_today, size: 16),
                                      SizedBox(width: 4),
                                      Text('Pick Date'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Day summary
                    DaySummary(entries: todaysEntries, date: _selectedDate),
                    const SizedBox(height: 16),

                    // Category summary
                    CategorySummary(entries: todaysEntries),
                    const SizedBox(height: 16),

                    // Timeline
                    const Text('Timeline', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    if (todaysEntries.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'No entries yet. Use the + button to log a period. No judgement—just clarity.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      )
                    else
                      TimelineView(entries: todaysEntries),

                    const SizedBox(height: 20),

                    // Reflection
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Reflection', style: Theme.of(context).textTheme.headlineMedium),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _reflectionController,
                              maxLines: 6,
                              decoration: const InputDecoration(
                                hintText: 'What helped me today? What drained me today?',
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton(
                                  onPressed: _saveReflection,
                                  child: const Text('Save reflection'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddDialog(),
        tooltip: 'Add entry',
        child: const Icon(Icons.add),
      ),
    );
  }
}
