import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/time_entry.dart';
import '../services/storage_service.dart';

class WeeklyOverviewScreen extends StatefulWidget {
  const WeeklyOverviewScreen({super.key});

  @override
  State<WeeklyOverviewScreen> createState() => _WeeklyOverviewScreenState();
}

class _WeeklyOverviewScreenState extends State<WeeklyOverviewScreen> {
  final StorageService _storage = StorageService();
  Map<ActivityCategory, int> _categoryTotals = {};
  // Energy totals for the 7-day window (per EnergyLevel)
  Map<EnergyLevel, int> _energyTotals = {};
  int _unspecifiedEnergy = 0; // minutes without an energy tag

  // Intent totals (intentional / unintentional)
  Map<IntentTag, int> _intentTotals = {};
  int _unspecifiedIntent = 0; // minutes without an intent tag

  bool _loading = true;
  DateTime _weekEndDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadWeeklyData();
  }

  /// Loads entries for the 7-day window ending on `_weekEndDate` and aggregates
  /// total minutes per category.
  ///
  /// Note: we deliberately use a simple 7-iteration loop instead of fancy date range
  /// utilities to keep the logic explicit and easy to reason about.
  Future<void> _loadWeeklyData() async {
    setState(() => _loading = true);

    final Map<ActivityCategory, int> totals = {};
    final Map<EnergyLevel, int> energyTotals = {};
    final Map<IntentTag, int> intentTotals = {};
    int unspecifiedEnergy = 0;
    int unspecifiedIntent = 0;

    // Initialize maps to 0 to ensure consistent ordering later
    for (var category in ActivityCategory.values) {
      totals[category] = 0;
    }
    for (var level in EnergyLevel.values) {
      energyTotals[level] = 0;
    }
    for (var i in IntentTag.values) {
      intentTotals[i] = 0;
    }

    // Helper to compute overlap minutes between an entry and a day window
    int overlapMinutes(DateTime start, DateTime end, DateTime dayStart, DateTime dayEnd) {
      final overlapStart = start.isAfter(dayStart) ? start : dayStart;
      final overlapEnd = end.isBefore(dayEnd) ? end : dayEnd;
      final diff = overlapEnd.difference(overlapStart).inMinutes;
      return diff > 0 ? diff : 0;
    }

    // Load entries for the last 7 days (inclusive of the end date)
    for (int i = 0; i < 7; i++) {
      final date = _weekEndDate.subtract(Duration(days: i));
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final entries = await _storage.loadEntries(date);
      final prevEntries = await _storage.loadEntries(date.subtract(const Duration(days: 1)));

      // Sum duration per category, energy, and intent using only the portion
      // of each entry that falls within the given day. We include entries stored
      // under the *previous* date as well, since older versions or manual
      // entries may store cross-midnight activities under the start date. This
      // ensures accurate per-day and per-week totals even when entries cross midnight.
      // Note: when loading entries we also normalize storage — if an entry's
      // `endTime` was earlier than its `startTime` we treat it as crossing
      // midnight and interpret the end time as the following day. This keeps
      // the per-day and per-week aggregates stable and predictable.
      for (var entry in [...entries, ...prevEntries]) {
        final minutes = overlapMinutes(entry.startTime, entry.endTime, dayStart, dayEnd);
        if (minutes <= 0) continue;

        totals[entry.category] = (totals[entry.category] ?? 0) + minutes;

        if (entry.energyLevel != null) {
          energyTotals[entry.energyLevel!] = (energyTotals[entry.energyLevel!] ?? 0) + minutes;
        } else {
          unspecifiedEnergy += minutes;
        }

        if (entry.intent != null) {
          intentTotals[entry.intent as IntentTag] = (intentTotals[entry.intent as IntentTag] ?? 0) + minutes;
        } else {
          unspecifiedIntent += minutes;
        }
      }
    }

    setState(() {
      _categoryTotals = totals;
      _energyTotals = energyTotals;
      _unspecifiedEnergy = unspecifiedEnergy;
      _intentTotals = intentTotals;
      _unspecifiedIntent = unspecifiedIntent;
      _loading = false;
    });
  }

  int get _totalMinutes {
    return _categoryTotals.values.fold(0, (sum, minutes) => sum + minutes);
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    return '${mins}m';
  }

  String _formatHours(int minutes) {
    return (minutes / 60).toStringAsFixed(1);
  }

  void _previousWeek() {
    setState(() {
      _weekEndDate = _weekEndDate.subtract(const Duration(days: 7));
      _loadWeeklyData();
    });
  }

  void _nextWeek() {
    setState(() {
      _weekEndDate = _weekEndDate.add(const Duration(days: 7));
      _loadWeeklyData();
    });
  }

  void _currentWeek() {
    setState(() {
      _weekEndDate = DateTime.now();
      _loadWeeklyData();
    });
  }

  bool get _isCurrentWeek {
    final now = DateTime.now();
    final diff = now.difference(_weekEndDate).inDays.abs();
    return diff < 7;
  }

  @override
  Widget build(BuildContext context) {
    final weekStartDate = _weekEndDate.subtract(const Duration(days: 6));
    
    // Sort categories by total time (descending)
    final sortedCategories = _categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: const Text('Week'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Week selector
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
                                onPressed: _previousWeek,
                                tooltip: 'Previous week',
                              ),
                              Expanded(
                                child: Text(
                                  '${DateFormat('MMM d').format(weekStartDate)} - ${DateFormat('MMM d, yyyy').format(_weekEndDate)}',
                                  style: Theme.of(context).textTheme.titleMedium,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_right),
                                onPressed: _isCurrentWeek ? null : _nextWeek,
                                tooltip: 'Next week',
                              ),
                            ],
                          ),
                          if (!_isCurrentWeek) ...[
                            const SizedBox(height: 8),
                            OutlinedButton(
                              onPressed: _currentWeek,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              child: const Text('Current Week'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Total time summary
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Time Tracked',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            _formatDuration(_totalMinutes),
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Category breakdown
                  Text(
                    'Time by Category',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),

                  if (_totalMinutes == 0)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'No entries for this week.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    )
                  else
                    ...sortedCategories.where((e) => e.value > 0).map((entry) {
                      final category = entry.key;
                      final minutes = entry.value;
                      final percentage = (_totalMinutes > 0) 
                          ? (minutes / _totalMinutes * 100) 
                          : 0.0;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      category.displayName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      _formatDuration(minutes),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: percentage / 100,
                                          minHeight: 12,
                                          backgroundColor: Colors.grey[200],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    SizedBox(
                                      width: 50,
                                      child: Text(
                                        '${percentage.toStringAsFixed(0)}%',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_formatHours(minutes)} hours',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),

                  const SizedBox(height: 8),

                  // Energy level breakdown
                  Text(
                    'Time by Energy level',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Builder(builder: (context) {
                    final total = _totalMinutes;
                    // Build a list of energy rows (level + minutes)
                    final energyList = _energyTotals.entries.toList()
                      ..sort((a, b) => b.value.compareTo(a.value));

                    if (total == 0) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text('No entries for this week.', style: Theme.of(context).textTheme.bodyMedium),
                        ),
                      );
                    }

                    return Column(
                      children: [
                        ...energyList.map((entry) {
                          final minutes = entry.value;
                          final percent = total > 0 ? (minutes / total * 100) : 0.0;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(entry.key.displayName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                        Text(_formatDuration(minutes), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(4),
                                            child: LinearProgressIndicator(value: percent / 100, minHeight: 12, backgroundColor: Colors.grey[200]),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        SizedBox(width: 50, child: Text('${percent.toStringAsFixed(0)}%', textAlign: TextAlign.right, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text('${_formatHours(minutes)} hours', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),

                        if (_unspecifiedEnergy > 0) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Unspecified', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                    Text(_formatDuration(_unspecifiedEnergy), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  }),

                  const SizedBox(height: 16),

                  // Intentional vs Unintentional breakdown
                  Text(
                    'Intentional vs Unintentional',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Builder(builder: (context) {
                    final total = _totalMinutes;
                    final intentional = _intentTotals[IntentTag.intentional] ?? 0;
                    final unintentional = _intentTotals[IntentTag.unintentional] ?? 0;

                    if (total == 0) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text('No entries for this week.', style: Theme.of(context).textTheme.bodyMedium),
                        ),
                      );
                    }

                    final intentionalPct = total > 0 ? (intentional / total * 100) : 0.0;
                    final unintentionalPct = total > 0 ? (unintentional / total * 100) : 0.0;
                    final unspecified = _unspecifiedIntent;
                    final unspecifiedPct = total > 0 ? (unspecified / total * 100) : 0.0;

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Intentional', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                      Text(_formatDuration(intentional), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: intentionalPct / 100, minHeight: 12, backgroundColor: Colors.grey[200]))),
                                      const SizedBox(width: 12),
                                      SizedBox(width: 50, child: Text('${intentionalPct.toStringAsFixed(0)}%', textAlign: TextAlign.right, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500))),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text('${_formatHours(intentional)} hours', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                ],
                              ),
                            ),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Unintentional', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                      Text(_formatDuration(unintentional), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: unintentionalPct / 100, minHeight: 12, backgroundColor: Colors.grey[200]))),
                                      const SizedBox(width: 12),
                                      SizedBox(width: 50, child: Text('${unintentionalPct.toStringAsFixed(0)}%', textAlign: TextAlign.right, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500))),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text('${_formatHours(unintentional)} hours', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                ],
                              ),
                            ),
                          ),
                        ),

                        if (unspecified > 0) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Unspecified', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                        Text(_formatDuration(unspecified), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: unspecifiedPct / 100, minHeight: 12, backgroundColor: Colors.grey[200]))),
                                        const SizedBox(width: 12),
                                        SizedBox(width: 50, child: Text('${unspecifiedPct.toStringAsFixed(0)}%', textAlign: TextAlign.right, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500))),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text('${_formatHours(unspecified)} hours', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  }),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
