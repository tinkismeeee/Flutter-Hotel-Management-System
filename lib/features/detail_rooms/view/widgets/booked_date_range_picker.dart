import 'package:flutter/material.dart';

import '../../../../core/models/booked_range_model.dart';
import '../../../../core/theme/colors.dart';

Future<DateTimeRange?> showBookedDateRangePicker({
  required BuildContext context,
  required DateTime firstDate,
  required DateTime lastDate,
  required List<BookedRangeModel> bookedRanges,
  DateTimeRange? initialDateRange,
}) {
  return showDialog<DateTimeRange>(
    context: context,
    builder: (_) => BookedDateRangePickerDialog(
      firstDate: firstDate,
      lastDate: lastDate,
      bookedRanges: bookedRanges,
      initialDateRange: initialDateRange,
    ),
  );
}

class BookedDateRangePickerDialog extends StatefulWidget {
  final DateTime firstDate;
  final DateTime lastDate;
  final List<BookedRangeModel> bookedRanges;
  final DateTimeRange? initialDateRange;

  const BookedDateRangePickerDialog({
    super.key,
    required this.firstDate,
    required this.lastDate,
    required this.bookedRanges,
    this.initialDateRange,
  });

  @override
  State<BookedDateRangePickerDialog> createState() =>
      _BookedDateRangePickerDialogState();
}

class _BookedDateRangePickerDialogState
    extends State<BookedDateRangePickerDialog> {
  late DateTime currentMonth;
  DateTime? selectedStart;
  DateTime? selectedEnd;

  @override
  void initState() {
    super.initState();
    selectedStart = widget.initialDateRange?.start;
    selectedEnd = widget.initialDateRange?.end;
    final initialMonth = selectedStart ?? widget.firstDate;
    currentMonth = DateTime(initialMonth.year, initialMonth.month);
  }

  bool get canGoPrevious {
    return currentMonth.isAfter(
      DateTime(widget.firstDate.year, widget.firstDate.month),
    );
  }

  bool get canGoNext {
    return currentMonth.isBefore(
      DateTime(widget.lastDate.year, widget.lastDate.month),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 410),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Select stay dates',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Row(
                children: [
                  Icon(Icons.circle, size: 9, color: AppColors.danger),
                  SizedBox(width: 7),
                  Text(
                    'Already booked',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SelectionSummary(start: selectedStart, end: selectedEnd),
              const SizedBox(height: 16),
              Row(
                children: [
                  IconButton(
                    onPressed: canGoPrevious ? () => changeMonth(-1) : null,
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Expanded(
                    child: Text(
                      localizations.formatMonthYear(currentMonth),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: canGoNext ? () => changeMonth(1) : null,
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
              const _WeekdayHeader(),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _MonthGrid(
                  key: ValueKey(currentMonth),
                  month: currentMonth,
                  firstDate: widget.firstDate,
                  lastDate: widget.lastDate,
                  bookedRanges: widget.bookedRanges,
                  selectedStart: selectedStart,
                  selectedEnd: selectedEnd,
                  canSelect: canSelect,
                  onSelected: selectDate,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: selectedStart != null && selectedEnd != null
                        ? () {
                            Navigator.of(context).pop(
                              DateTimeRange(
                                start: selectedStart!,
                                end: selectedEnd!,
                              ),
                            );
                          }
                        : null,
                    child: const Text('Confirm'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void changeMonth(int offset) {
    setState(() {
      currentMonth = DateTime(currentMonth.year, currentMonth.month + offset);
    });
  }

  bool canSelect(DateTime day) {
    if (day.isBefore(widget.firstDate) || day.isAfter(widget.lastDate)) {
      return false;
    }

    final start = selectedStart;
    if (start != null && selectedEnd == null && !day.isBefore(start)) {
      if (_sameDate(day, start)) return true;
      return !_overlapsBookedRange(start, day);
    }
    return !_isBooked(day);
  }

  void selectDate(DateTime day) {
    if (!canSelect(day)) return;

    setState(() {
      if (selectedStart == null ||
          selectedEnd != null ||
          day.isBefore(selectedStart!)) {
        selectedStart = day;
        selectedEnd = null;
      } else if (day.isAfter(selectedStart!)) {
        selectedEnd = day;
      }
    });
  }

  bool _isBooked(DateTime day) {
    return widget.bookedRanges.any((range) => range.contains(day));
  }

  bool _overlapsBookedRange(DateTime start, DateTime end) {
    return widget.bookedRanges.any((range) => range.overlaps(start, end));
  }
}

class _SelectionSummary extends StatelessWidget {
  final DateTime? start;
  final DateTime? end;

  const _SelectionSummary({required this.start, required this.end});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SelectionDate(label: 'Check-in', date: start),
          ),
          const Icon(Icons.arrow_forward_rounded, color: AppColors.textMuted),
          Expanded(
            child: _SelectionDate(
              label: 'Check-out',
              date: end,
              alignEnd: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectionDate extends StatelessWidget {
  final String label;
  final DateTime? date;
  final bool alignEnd;

  const _SelectionDate({
    required this.label,
    required this.date,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          date == null ? '--/--/----' : _formatDate(date!),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          _Weekday('Mon'),
          _Weekday('Tue'),
          _Weekday('Wed'),
          _Weekday('Thu'),
          _Weekday('Fri'),
          _Weekday('Sat'),
          _Weekday('Sun'),
        ],
      ),
    );
  }
}

class _Weekday extends StatelessWidget {
  final String label;

  const _Weekday(this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  final DateTime month;
  final DateTime firstDate;
  final DateTime lastDate;
  final List<BookedRangeModel> bookedRanges;
  final DateTime? selectedStart;
  final DateTime? selectedEnd;
  final bool Function(DateTime day) canSelect;
  final ValueChanged<DateTime> onSelected;

  const _MonthGrid({
    super.key,
    required this.month,
    required this.firstDate,
    required this.lastDate,
    required this.bookedRanges,
    required this.selectedStart,
    required this.selectedEnd,
    required this.canSelect,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final firstWeekdayOffset = DateTime(month.year, month.month, 1).weekday - 1;
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisExtent: 44,
      ),
      itemCount: 42,
      itemBuilder: (context, index) {
        final dayNumber = index - firstWeekdayOffset + 1;
        if (dayNumber < 1 || dayNumber > daysInMonth) {
          return const SizedBox.shrink();
        }
        final day = DateTime(month.year, month.month, dayNumber);
        final booked = bookedRanges.any((range) => range.contains(day));
        final enabled = canSelect(day);
        final isStart = selectedStart != null && _sameDate(day, selectedStart!);
        final isEnd = selectedEnd != null && _sameDate(day, selectedEnd!);
        final inRange =
            selectedStart != null &&
            selectedEnd != null &&
            day.isAfter(selectedStart!) &&
            day.isBefore(selectedEnd!);

        return _DayCell(
          day: day,
          booked: booked,
          enabled: enabled,
          selected: isStart || isEnd,
          inRange: inRange,
          onTap: () => onSelected(day),
        );
      },
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime day;
  final bool booked;
  final bool enabled;
  final bool selected;
  final bool inRange;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.booked,
    required this.enabled,
    required this.selected,
    required this.inRange,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = selected
        ? Colors.white
        : enabled
        ? AppColors.textPrimary
        : AppColors.textMuted.withValues(alpha: 0.45);

    return InkWell(
      onTap: enabled ? onTap : null,
      customBorder: const CircleBorder(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected
                  ? AppColors.primary
                  : inRange
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : Colors.transparent,
            ),
            alignment: Alignment.center,
            child: Text(
              '${day.day}',
              style: TextStyle(
                color: foreground,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
          if (booked)
            Positioned(
              bottom: 2,
              child: Container(
                key: ValueKey('booked-dot-${day.year}-${day.month}-${day.day}'),
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.danger,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}

bool _sameDate(DateTime first, DateTime second) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}
