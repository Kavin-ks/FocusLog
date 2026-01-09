import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
// share_plus is used by the export sheet; not required directly here
import '../widgets/export_options_sheet.dart';

import '../models/time_entry.dart';
import '../services/storage_service.dart';
import '../services/settings_service.dart';
import '../widgets/day_summary.dart';
import '../widgets/section_header.dart';
import '../widgets/card_surface.dart';
// time_entry_card is not directly used in this screen; kept commented for future
// import '../widgets/time_entry_card.dart';
import '../widgets/timeline_view.dart';
import '../widgets/category_summary.dart';
import '../widgets/baseline_comparison.dart';
import 'add_entry_dialog.dart';
import 'weekly_overview_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late StorageService _storage;
  final SettingsService _settingsService = SettingsService();
  List<TimeEntry> _entries = [];
  AppSettings? _settings;
  DateTime _selectedDate = DateTime.now();
  bool _loading = true;
  final TextEditingController _reflectionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Get services from provider
    final auth = Provider.of<AuthService>(context, listen: false);
    _storage = Provider.of<StorageService>(context, listen: false);
    // Redirect to login if not authenticated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!auth.isLoggedIn) {
        Navigator.of(context).pushReplacementNamed('/');
        return;
      }
    });

    _loadSettings();
    _loadEntries();
    _loadReflection();
  }

  Future<void> _loadSettings() async {
    final s = await _settingsService.loadSettings();
    if (!mounted) return;
    setState(() => _settings = s);
  }

  Future<void> _loadEntries() async {
    setState(() => _loading = true);
    final entries = await _storage.loadEntries(_selectedDate, _settings?.customCategories);
    entries.sort((a, b) => a.startTime.compareTo(b.startTime));
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  List<TimeEntry> get _entriesForSelectedDate {
    return _entries;
  }

  bool _showInsights = true;

  List<String> _generateInsights() {
    final entries = _entriesForSelectedDate;
    // Require sufficient data to avoid insights on sparse days
    final totalMinutes = entries.fold<int>(0, (s, e) => s + e.durationMinutes);
    if (entries.length < 3 || totalMinutes < 60) {
      return [];
    }

    final categoryTotals = <ActivityCategory, int>{};
    for (final e in entries) {
      categoryTotals[e.category] = (categoryTotals[e.category] ?? 0) + e.durationMinutes;
    }
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    if (sortedCategories.isNotEmpty) {
      final dominantCategory = sortedCategories.first.key;
      // Skip if dominant category is scroll (unintentional browsing)
      if (dominantCategory.id != 'scroll') {
        final dominantMinutes = sortedCategories.first.value;
        final dominantHigh = entries
            .where((e) => e.category == dominantCategory && e.energyLevel == EnergyLevel.high)
            .fold<int>(0, (s, e) => s + e.durationMinutes);
        
        final ratio = dominantHigh / dominantMinutes;
        if (ratio >= 0.6) {
          return ['Most time in ${dominantCategory.displayName.toLowerCase()} was recorded when energy was high.'];
        }
      }
    }

    // Rule 2: Unintentional timing pattern
    // Check if unintentional time clusters in one time-of-day bucket
    // 50% represents clear majority concentration
    final unintentionalEntries = entries.where((e) => e.intent == IntentTag.unintentional).toList();
    final unintentionalTotal = unintentionalEntries.fold<int>(0, (s, e) => s + e.durationMinutes);
    if (unintentionalTotal > 0) {
      int morning = 0, afternoon = 0, evening = 0, night = 0;
      for (final e in unintentionalEntries) {
        final hour = e.startTime.hour;
        if (hour >= 5 && hour < 11) {
          morning += e.durationMinutes;
        } else if (hour >= 11 && hour < 17) {
          afternoon += e.durationMinutes;
        } else if (hour >= 17 && hour < 22) {
          evening += e.durationMinutes;
        } else {
          night += e.durationMinutes;
        }
      }

      final parts = {
        'morning': morning,
        'afternoon': afternoon,
        'evening': evening,
        'night': night,
      };

      final top = parts.entries.reduce((a, b) => a.value >= b.value ? a : b);
      if (top.value / unintentionalTotal >= 0.5) {
        return ['A large portion of unintentional time occurred in the ${top.key}.'];
      }
    }

    // No insights if no rules match
    return [];
  }

  Future<void> _openAddDialog([TimeEntry? existing]) async {
    final allCategories = <ActivityCategory>[...ActivityCategory.builtInCategories, ...(_settings?.customCategories ?? [])];
    final result = await showDialog<Object?>(
      context: context,
      builder: (_) => AddEntryDialog(entry: existing, selectedDate: _selectedDate, categories: allCategories),
    );

    if (result != null) {
      if (result is TimeEntry) {
        if (existing == null) {
          await (_storage as dynamic).addEntry(_selectedDate, result);
        } else {
          // If editing, update the entry stored under the original date
          await (_storage as dynamic).updateEntry(_selectedDate, result);
        }
      } else if (result is List<TimeEntry>) {
        // Split entry case: return multiple entries to store under their respective dates
        if (existing == null) {
          for (final e in result) {
            final dateKey = DateTime(e.startTime.year, e.startTime.month, e.startTime.day);
            await (_storage as dynamic).addEntry(dateKey, e);
          }
        } else {
          // Editing existing entry that now spans days: remove original and add new parts
          final originalDate = DateTime(existing.startTime.year, existing.startTime.month, existing.startTime.day);
          await (_storage as dynamic).deleteEntry(originalDate, existing.id);
          for (final e in result) {
            final dateKey = DateTime(e.startTime.year, e.startTime.month, e.startTime.day);
            await (_storage as dynamic).addEntry(dateKey, e);
          }
        }
      }

      await _loadEntries();
    }
  }

  // Deleted unused `_deleteEntry` helper to avoid analyzer warnings; use
  // `StorageService.deleteEntry` directly where needed.

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
    final r = await (_storage as dynamic).loadReflection(_selectedDate);
    setState(() {
      _reflectionController.text = r ?? '';
    });
  }

  Future<void> _saveReflection() async {
    await (_storage as dynamic).saveReflection(_selectedDate, _reflectionController.text);
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
    String content = '';
    String filename = '';
    if (format == 'json') {
      content = await (_storage as dynamic).exportAllAsJson();
      filename = 'focuslog_export_${DateTime.now().toIso8601String()}.json';
    } else {
      content = await (_storage as dynamic).exportAllAsCsv();
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export error: $e')));
      }
    }
  }

  Future<void> _confirmClearAll() async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear data'),
          content: const Text('This will permanently remove all saved entries and reflections. If you would like to keep a copy, consider exporting your data first.'),
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
      await (_storage as dynamic).clearAllData();
      await _loadEntries();
      await _loadReflection();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data cleared')));
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
                  builder: (context) => WeeklyOverviewScreen(customCategories: _settings?.customCategories ?? []),
                ),
              );
            },
            tooltip: 'Weekly Overview',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              final result = await Navigator.of(context).push<AppSettings?>(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
              if (!mounted) return;
              if (result != null) {
                setState(() => _settings = result);
                // reload entries to reflect any changed behavior (if needed)
                await _loadEntries();
              }
            },
            tooltip: 'Settings',
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'export_json') {
                await _exportData('json');
              } else if (value == 'export_csv') {
                await _exportData('csv');
              } else if (value == 'clear_all') {
                await _confirmClearAll();
              } else if (value == 'logout') {
                final auth = Provider.of<AuthService>(context, listen: false);
                final navigator = Navigator.of(context);
                await auth.logout();
                if (!mounted) return;
                navigator.pushReplacementNamed('/');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'export_json', child: Text('Export JSON')),
              const PopupMenuItem(value: 'export_csv', child: Text('Export CSV')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'clear_all', child: Text('Clear data')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
          ),
        ],
      ),
      body: Padding(
        // Responsive horizontal padding: 20 on mobile, 40 on larger screens for better readability
        // Vertical padding remains 12 for consistent top/bottom spacing
        padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width > 600 ? 40 : 20, vertical: 12),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                // SingleChildScrollView allows content to scroll on smaller screens while maintaining full height on larger ones
                child: Column(
                  // CrossAxisAlignment.start aligns content to the left, creating a clean, readable layout
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

                    // Daily Focus Goal card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Daily Focus Goal', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                                // percentage text - calculated from today's totals and a 4h default goal
                                Builder(builder: (context) {
                                  final totalMinutes = todaysEntries.fold<int>(0, (s, e) => s + e.durationMinutes);
                                  const goalMinutes = 4 * 60;
                                  final pct = (totalMinutes / goalMinutes * 100).clamp(0, 100).round();
                                  return Text('$pct% Done', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.primary));
                                }),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Progress bar
                            Builder(builder: (context) {
                              final totalMinutes = todaysEntries.fold<int>(0, (s, e) => s + e.durationMinutes);
                              const goalMinutes = 4 * 60;
                              final progress = (totalMinutes / goalMinutes).clamp(0.0, 1.0);
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  LinearProgressIndicator(value: progress, minHeight: 8),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('${(totalMinutes ~/ 60)}h ${totalMinutes % 60}m logged today', style: Theme.of(context).textTheme.bodySmall),
                                      const Text('Goal: 4h', style: TextStyle(fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Optional insights (rule-based, non-AI, minimal language)
                    CardSurface(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Insights', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                              IconButton(
                                icon: Icon(_showInsights ? Icons.visibility_off : Icons.visibility, size: 20),
                                tooltip: _showInsights ? 'Hide insights' : 'Show insights',
                                onPressed: () => setState(() => _showInsights = !_showInsights),
                              ),
                            ],
                          ),
                          if (_showInsights) ...[
                            const SizedBox(height: 6),
                            Builder(builder: (context) {
                              final insights = _generateInsights();
                              if (insights.isEmpty) {
                                return Text('No notable insights for today yet. Keep studying!', style: Theme.of(context).textTheme.bodySmall);
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: insights.map((s) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text('• $s', style: Theme.of(context).textTheme.bodySmall),
                                )).toList(),
                              );
                            }),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Recent sessions (show up to 3 most recent)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('RECENT SESSIONS', style: Theme.of(context).textTheme.bodyMedium?.copyWith(letterSpacing: 1.0, fontWeight: FontWeight.w600)),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute(builder: (context) => WeeklyOverviewScreen(customCategories: _settings?.customCategories ?? [])));
                          },
                          child: const Text('See all'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (todaysEntries.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text('No recent sessions yet.', style: Theme.of(context).textTheme.bodyMedium),
                        ),
                      )
                    else
                      Column(
                        children: List.generate(
                          todaysEntries.length > 3 ? 3 : todaysEntries.length,
                          (i) {
                            final entry = List.of(todaysEntries)..sort((a,b)=>b.startTime.compareTo(a.startTime));
                            final e = entry[i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Card(
                                child: ListTile(
                                  leading: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).dividerColor,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.play_arrow, color: Colors.white),
                                  ),
                                  title: Text(e.activityName, style: Theme.of(context).textTheme.bodyLarge),
                                  subtitle: Text('${e.category.displayName} • ${e.durationMinutes}m', style: Theme.of(context).textTheme.bodySmall),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () => _openAddDialog(e),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Day summary
                    DaySummary(entries: todaysEntries, date: _selectedDate),
                    const SizedBox(height: 16),

                    // Baseline comparison
                    BaselineComparison(
                      todayEntries: todaysEntries,
                      date: _selectedDate,
                      allCategories: <ActivityCategory>[...ActivityCategory.builtInCategories, ...(_settings?.customCategories ?? [])],
                    ),
                    const SizedBox(height: 16),

                    // Category summary
                    CategorySummary(entries: todaysEntries),
                    const SizedBox(height: 16),

                    // Timeline
                    const SectionHeader(title: 'Timeline', showDivider: false),
                    const SizedBox(height: 8),
                    if (todaysEntries.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'No entries yet. You can tap the + button to log a time period.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      )
                    else
                      TimelineView(entries: todaysEntries, maxEntries: _settings?.entriesPerPage),

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
                                hintText: 'What supported me today? What challenged me today?',
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddDialog(),
        tooltip: 'Add entry',
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(onPressed: () {}, icon: const Icon(Icons.grid_view)),
                  IconButton(onPressed: () {}, icon: const Icon(Icons.menu_book)),
                ],
              ),
              Row(
                children: [
                  IconButton(onPressed: () {}, icon: const Icon(Icons.bar_chart)),
                  IconButton(onPressed: () {}, icon: const Icon(Icons.person)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
