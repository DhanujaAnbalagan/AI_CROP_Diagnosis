import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/reminder_model.dart';
import '../services/reminder_service.dart';
import '../services/notification_service.dart';
import '../widgets/reminder_card.dart';
import '../core/theme/app_colors.dart';

/// The Farmer Calendar screen showing a monthly calendar and
/// scheduled reminders for the selected date.
class FarmerCalendarScreen extends StatefulWidget {
  final VoidCallback onBack;

  const FarmerCalendarScreen({super.key, required this.onBack});

  @override
  State<FarmerCalendarScreen> createState() => _FarmerCalendarScreenState();
}

class _FarmerCalendarScreenState extends State<FarmerCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  List<ReminderModel> _selectedDayReminders = [];
  Map<DateTime, List<ReminderModel>> _allReminders = {};

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  // ─── Load all reminders ──────────────────────────────────────────────────

  Future<void> _loadAll() async {
    final all = await reminderService.getAll();
    final grouped = <DateTime, List<ReminderModel>>{};
    for (final r in all) {
      final key = _dayKey(r.scheduledDate);
      grouped.putIfAbsent(key, () => []).add(r);
    }
    if (!mounted) return;
    setState(() {
      _allReminders = grouped;
    });
    await _loadForDay(_selectedDay);
  }

  Future<void> _loadForDay(DateTime day) async {
    final reminders = await reminderService.getForDate(day);
    if (!mounted) return;
    setState(() => _selectedDayReminders = reminders);
  }

  /// Strips time component for map key.
  DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

  List<ReminderModel> _eventsForDay(DateTime day) {
    return _allReminders[_dayKey(day)] ?? [];
  }

  // ─── Reminder actions ────────────────────────────────────────────────────

  Future<void> _markComplete(ReminderModel reminder) async {
    await reminderService.markCompleted(reminder.id);
    await _loadAll();
  }

  Future<void> _delete(ReminderModel reminder) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Reminder'),
        content: Text('Delete "${reminder.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await reminderService.delete(reminder.id);
      await _loadAll();
    }
  }

  // ─── Add Reminder dialog ─────────────────────────────────────────────────

  Future<void> _showAddReminderDialog() async {
    // Ask for notification permission first
    await NotificationService().requestPermission();

    final titleCtrl = TextEditingController();
    final cropCtrl = TextEditingController();
    ReminderType selectedType = ReminderType.pesticide;
    TimeOfDay selectedTime = TimeOfDay.now();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.gray300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Text(
                'Add Reminder — ${DateFormat("d MMM yyyy").format(_selectedDay)}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),

              // Reminder type chips
              const Text('Type', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ReminderType.values.map((type) {
                    final selected = selectedType == type;
                    final color = Color(type.colorValue);
                    return GestureDetector(
                      onTap: () => setModalState(() => selectedType = type),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? color : color.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected ? color : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(type.icon, style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 6),
                            Text(
                              type.label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: selected ? Colors.white : color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Title field
              _InputField(controller: titleCtrl, hint: 'Reminder title (e.g. Spray pesticide on Wheat)'),
              const SizedBox(height: 12),

              // Crop name field
              _InputField(controller: cropCtrl, hint: 'Crop name (e.g. Wheat)'),
              const SizedBox(height: 12),

              // Time picker
              GestureDetector(
                onTap: () async {
                  final t = await showTimePicker(
                    context: ctx,
                    initialTime: selectedTime,
                    builder: (BuildContext context, Widget? child) {
                      return MediaQuery(
                        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
                        child: Localizations.override(
                          context: context,
                          locale: const Locale('en', 'US'),
                          child: child,
                        ),
                      );
                    },
                  );
                  if (t != null) setModalState(() => selectedTime = t);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.gray50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.gray300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.schedule_rounded, color: AppColors.primary, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        selectedTime.format(ctx),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                      const Spacer(),
                      const Text('Tap to change', style: TextStyle(fontSize: 12, color: AppColors.textHint)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    final title = titleCtrl.text.trim();
                    final crop = cropCtrl.text.trim();
                    if (title.isEmpty || crop.isEmpty) return;

                    final id = DateTime.now().millisecondsSinceEpoch.toString();
                    final timeStr = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';

                    final reminder = ReminderModel(
                      id: id,
                      title: title,
                      cropName: crop,
                      scheduledDate: _selectedDay,
                      scheduledTime: timeStr,
                      reminderType: selectedType,
                    );

                    await reminderService.upsert(reminder);

                    // Show immediate demo notification on mobile
                    await NotificationService().scheduleReminder(
                      notificationId: int.parse(id.substring(id.length - 8)),
                      title: '🌾 Reminder: $title',
                      body: 'Today: $title on ${crop} field.',
                      scheduledDateTime: _selectedDay,
                    );

                    if (ctx.mounted) Navigator.pop(ctx);
                    await _loadAll();
                  },
                  child: const Text('Save Reminder', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: widget.onBack,
        ),
        title: const Text(
          '🌾 Farmer Calendar',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'Add Reminder',
            onPressed: _showAddReminderDialog,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddReminderDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Reminder', style: TextStyle(fontWeight: FontWeight.w700)),
        elevation: 4,
      ),
      body: Column(
        children: [
          // ─── Monthly Calendar ───────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: TableCalendar<ReminderModel>(
              firstDay: DateTime.utc(2024, 1, 1),
              lastDay: DateTime.utc(2027, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
              eventLoader: _eventsForDay,
              calendarStyle: CalendarStyle(
                // Today
                todayDecoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
                // Selected
                selectedDecoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
                // Events marker
                markerDecoration: const BoxDecoration(
                  color: Color(0xFFFF9800),
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 3,
                outsideDaysVisible: false,
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
                leftChevronIcon: Icon(Icons.chevron_left_rounded, color: AppColors.primary),
                rightChevronIcon: Icon(Icons.chevron_right_rounded, color: AppColors.primary),
              ),
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
                weekendStyle: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.error,
                  fontSize: 12,
                ),
              ),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                _loadForDay(selectedDay);
              },
              onPageChanged: (focusedDay) {
                setState(() => _focusedDay = focusedDay);
              },
            ),
          ),

          // ─── Divider ────────────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  DateFormat('EEEE, d MMMM yyyy').format(_selectedDay),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_selectedDayReminders.length} reminder${_selectedDayReminders.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ─── Reminder list ───────────────────────────────────────────────
          Expanded(
            child: _selectedDayReminders.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: _selectedDayReminders.length,
                    itemBuilder: (context, i) {
                      final r = _selectedDayReminders[i];
                      return ReminderCard(
                        reminder: r,
                        onComplete: () => _markComplete(r),
                        onDelete: () => _delete(r),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.event_note_rounded,
                size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          const Text(
            'No reminders for this day',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap + to add a reminder',
            style: TextStyle(fontSize: 13, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}

/// Simple reusable text input field.
class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const _InputField({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
        filled: true,
        fillColor: AppColors.gray50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gray300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gray300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}
