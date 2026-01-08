import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/time_entry.dart';
import '../services/storage_service.dart';

class AddEntryDialog extends StatefulWidget {
  final TimeEntry? entry;
  final DateTime selectedDate;

  const AddEntryDialog({super.key, this.entry, required this.selectedDate});

  @override
  State<AddEntryDialog> createState() => _AddEntryDialogState();
}

class _AddEntryDialogState extends State<AddEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _activityController;
  late ActivityCategory _selectedCategory;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late DateTime _selectedDate;
  EnergyLevel? _selectedEnergy; // optional energy tag for the activity
  IntentTag? _selectedIntent; // optional intent tag for the activity

  @override
  void initState() {
    super.initState();
    _activityController = TextEditingController(
      text: widget.entry?.activityName ?? '',
    );
    _selectedCategory = widget.entry?.category ?? ActivityCategory.other;
    _selectedDate = widget.entry?.startTime ?? widget.selectedDate;
    _startTime = widget.entry != null
        ? TimeOfDay.fromDateTime(widget.entry!.startTime)
        : TimeOfDay.now();
    _endTime = widget.entry != null
        ? TimeOfDay.fromDateTime(widget.entry!.endTime)
        : TimeOfDay.now();
    _selectedEnergy = widget.entry?.energyLevel; // default to existing value or null
    _selectedIntent = widget.entry?.intent; // default to existing value or null (IntentTag)
  }

  @override
  void dispose() {
    _activityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.entry == null ? 'Log time' : 'Edit entry',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),

              // Activity name field
              TextFormField(
                controller: _activityController,
                decoration: const InputDecoration(
                  labelText: 'Activity name',
                  hintText: 'e.g., Reading, Meeting, Exercise',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an activity name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category dropdown
              DropdownButtonFormField<ActivityCategory>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                ),
                items: ActivityCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCategory = value);
                  }
                },
              ),
              const SizedBox(height: 12),

              // Energy tag (optional)
              DropdownButtonFormField<EnergyLevel?>(
                initialValue: _selectedEnergy,
                decoration: const InputDecoration(
                  labelText: 'Energy (optional)',
                  helperText: 'How did this activity feel?',
                ),
                items: [
                  const DropdownMenuItem<EnergyLevel?>(value: null, child: Text('Not tagged')),
                  ...EnergyLevel.values.map((level) => DropdownMenuItem<EnergyLevel?>(
                        value: level,
                        child: Text(level.displayName),
                      )),
                ],
                onChanged: (value) {
                  setState(() => _selectedEnergy = value);
                },
              ),
              const SizedBox(height: 12),

              // Intent tag (optional)
              DropdownButtonFormField<IntentTag?>(
                initialValue: _selectedIntent,
                decoration: const InputDecoration(
                  labelText: 'Intent (optional)',
                  helperText: 'Mark whether the activity was intentional (optional)',
                ),
                items: [
                  const DropdownMenuItem<IntentTag?>(value: null, child: Text('Not tagged')),
                  ...IntentTag.values.map((intent) => DropdownMenuItem<IntentTag?>(
                        value: intent,
                        child: Text(intent.displayName),
                      )),
                ],
                onChanged: (value) {
                  setState(() => _selectedIntent = value);
                },
              ),
              const SizedBox(height: 16),

              // Date field
              TextFormField(
                readOnly: true,
                controller: TextEditingController(
                  text: DateFormat('MMM d, yyyy').format(_selectedDate),
                ),
                decoration: const InputDecoration(
                  labelText: 'Date',
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (!mounted) return;
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Start time field
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      readOnly: true,
                      controller: TextEditingController(
                        text: _startTime.format(context),
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Start time',
                      ),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _startTime,
                        );
                        if (!mounted) return;
                        if (picked != null) {
                          setState(() => _startTime = picked);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      readOnly: true,
                      controller: TextEditingController(
                        text: _endTime.format(context),
                      ),
                      decoration: const InputDecoration(
                        labelText: 'End time',
                      ),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _endTime,
                        );
                        if (!mounted) return;
                        if (picked != null) {
                          setState(() => _endTime = picked);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium!.color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async => await _saveEntry(),
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveEntry() async {
    if (_formKey.currentState!.validate()) {
      final startDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _startTime.hour,
        _startTime.minute,
      );
      var endDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _endTime.hour,
        _endTime.minute,
      );

      // If end appears before start, confirm whether it crosses midnight.
      //
      // Design note: we intentionally ask the user whether the entry crossed
      // midnight instead of unilaterally moving `endTime` forward. When the
      // user confirms the crossing we split the activity into two normalized
      // `TimeEntry` parts (first ending exactly at local midnight, second
      // starting at midnight). The dialog returns either a single
      // `TimeEntry` (for same-day entries) or a `List<TimeEntry>` containing
      // both parts. The caller is responsible for persisting each part under
      // the correct date key. This preserves per-day totals and weekly
      // aggregates without inventing ambiguous dates.
      if (endDateTime.isBefore(startDateTime)) {
        final crosses = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('End time earlier than start time'),
              content: const Text('The end time is before the start time. Did this activity cross midnight? If so, we can split it across days to reflect the correct minutes.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('No, I will adjust the times'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Yes, it crossed midnight'),
                ),
              ],
            );
          },
        );

        if (crosses != true) {
          // User chose to fix times; return to dialog without saving.
          return;
        }

        // User confirmed crossing midnight: split the entry into two parts.
        final actualEnd = endDateTime.add(const Duration(days: 1));
        final midnight = DateTime(startDateTime.year, startDateTime.month, startDateTime.day).add(const Duration(days: 1));

        final firstPart = TimeEntry(
          id: widget.entry?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
          startTime: startDateTime,
          endTime: midnight,
          activityName: _activityController.text.trim(),
          category: _selectedCategory,
          energyLevel: _selectedEnergy,
          intent: _selectedIntent,
        );

        final secondPart = TimeEntry(
          id: '${DateTime.now().millisecondsSinceEpoch}_2',
          startTime: midnight,
          endTime: actualEnd,
          activityName: _activityController.text.trim(),
          category: _selectedCategory,
          energyLevel: _selectedEnergy,
          intent: _selectedIntent,
        );

        // Check overlaps separately for both days.
        final existingFirst = await StorageService().loadEntries(_selectedDate);
        final overlappingFirst = existingFirst.where((e) {
          if (widget.entry != null && e.id == widget.entry!.id) return false;
          return firstPart.startTime.isBefore(e.endTime) && firstPart.endTime.isAfter(e.startTime);
        }).toList();

        final nextDate = _selectedDate.add(const Duration(days: 1));
        final existingSecond = await StorageService().loadEntries(nextDate);
        final overlappingSecond = existingSecond.where((e) {
          return secondPart.startTime.isBefore(e.endTime) && secondPart.endTime.isAfter(e.startTime);
        }).toList();

        final allOverlapping = [...overlappingFirst, ...overlappingSecond];
        if (allOverlapping.isNotEmpty) {
          if (!mounted) return;
          final proceed = await showDialog<bool>(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Overlapping entry detected'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('This entry (split across days) overlaps with existing entries. You can save anyway or review the times.'),
                      const SizedBox(height: 12),
                      ...allOverlapping.map((e) => Text('- ${e.activityName}: ${TimeOfDay.fromDateTime(e.startTime).format(context)} — ${TimeOfDay.fromDateTime(e.endTime).format(context)}')),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Review times'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Save anyway'),
                  ),
                ],
              );
            },
          );

          if (proceed != true) {
            return; // user chose to review
          }
        }

        // Return both parts to caller so they can be saved under their respective dates.
        // We return a List<TimeEntry> so the caller can persist each part under
        // the correct date key. This keeps per-day and per-week totals accurate.
        if (!mounted) return;
        Navigator.of(context).pop([firstPart, secondPart]);
        return;
      } // end crossing-midnight handling

      // Check overlaps for a single-day entry
      final existing = await StorageService().loadEntries(_selectedDate);
      final overlapping = existing.where((e) {
        if (widget.entry != null && e.id == widget.entry!.id) return false;
        return startDateTime.isBefore(e.endTime) && endDateTime.isAfter(e.startTime);
      }).toList();

      if (overlapping.isNotEmpty) {
        if (!mounted) return;
        final proceed = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Overlapping entry detected'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('This entry overlaps with existing entries. You can save anyway or review the times.'),
                    const SizedBox(height: 12),
                    ...overlapping.map((e) => Text('- ${e.activityName}: ${TimeOfDay.fromDateTime(e.startTime).format(context)} — ${TimeOfDay.fromDateTime(e.endTime).format(context)}')),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Review times'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Save anyway'),
                ),
              ],
            );
          },
        );

        if (proceed != true) {
          // User chose to review/adjust times.
          return;
        }
      }

      final entry = TimeEntry(
        id: widget.entry?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        startTime: startDateTime,
        endTime: endDateTime,
        activityName: _activityController.text.trim(),
        category: _selectedCategory,
        energyLevel: _selectedEnergy,
        intent: _selectedIntent,
      );

      if (!mounted) return;
      Navigator.of(context).pop(entry);
    }
  }
}
