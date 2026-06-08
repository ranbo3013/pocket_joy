import 'package:flutter/material.dart';
import '../../config/design_tokens.dart';
import '../../models/achievement.dart';

/// A monthly work calendar heatmap showing daily coin earnings.
///
/// Displays the current month as a 7-column grid (Mon–Sun) with colored
/// circles indicating coin activity levels. Tapping a day shows a detail
/// popup with coins, work hours, and gold bars.
class HeatmapCalendar extends StatelessWidget {
  /// Date string (yyyy-MM-dd) → calendar day record.
  final Map<String, CalendarDay> days;

  /// Which month to display. Defaults to the current month.
  final DateTime month;

  HeatmapCalendar({
    super.key,
    required this.days,
    DateTime? month,
  }) : month = month ?? _currentMonth();

  static DateTime _currentMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  // ─── Date helpers ──────────────────────────────────────────

  int get _daysInMonth {
    // 0th day of next month = last day of this month
    return DateTime(month.year, month.month + 1, 0).day;
  }

  /// Monday = 0 … Sunday = 6 (Dart weekday: Mon=1 … Sun=7).
  int get _firstWeekday {
    return DateTime(month.year, month.month, 1).weekday - 1;
  }

  String _dateKey(int day) {
    return '${month.year}-${month.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
  }

  // ─── Display helpers ───────────────────────────────────────

  static const _dayHeaders = ['一', '二', '三', '四', '五', '六', '日'];

  static const _monthNames = [
    '', '1', '2', '3', '4', '5', '6',
    '7', '8', '9', '10', '11', '12',
  ];

  String _formatWorkTime(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return '$hours 小时 $minutes 分钟';
    }
    return '$minutes 分钟';
  }

  // ─── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final totalDays = _daysInMonth;
    final startOffset = _firstWeekday; // empty cells before day 1
    final totalSlots = startOffset + totalDays;
    final totalWeeks = (totalSlots / 7).ceil();

    // Build a flat list of day widgets (some null for empty slots)
    final cells = <Widget?>[];
    for (int i = 0; i < startOffset; i++) {
      cells.add(null); // placeholder for days before month start
    }
    for (int d = 1; d <= totalDays; d++) {
      final key = _dateKey(d);
      final day = days[key];
      cells.add(_DayCell(
        dayNumber: d,
        calendarDay: day,
        onTap: day != null
            ? () => _showDayDetail(context, day)
            : null,
      ));
    }
    // Pad to complete the last week
    while (cells.length < totalWeeks * 7) {
      cells.add(null);
    }

    // Chunk into weeks
    final weeks = <List<Widget?>>[];
    for (int w = 0; w < totalWeeks; w++) {
      final start = w * 7;
      weeks.add(cells.sublist(start, start + 7));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: [
          // Month header
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(
              '${month.year}年 ${_monthNames[month.month]}月',
              style: AppTextStyles.headline.copyWith(
                color: AppColors.goldPrimary,
              ),
            ),
          ),

          // Day-of-week headers
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: List.generate(7, (i) {
                final isWeekend = i >= 5; // Sat, Sun
                return Expanded(
                  child: Center(
                    child: Text(
                      _dayHeaders[i],
                      style: AppTextStyles.small.copyWith(
                        color: isWeekend
                            ? AppColors.textMuted
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Week rows
          ...List.generate(weeks.length, (w) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: w < weeks.length - 1 ? AppSpacing.sm : 0,
              ),
              child: Row(
                children: List.generate(7, (d) {
                  final cell = weeks[w][d];
                  return Expanded(
                    child: cell ?? const SizedBox.shrink(),
                  );
                }),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showDayDetail(BuildContext context, CalendarDay day) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.bgSecondary,
          title: Text(
            day.date,
            style: AppTextStyles.headline.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('金币', '${day.coins}', AppColors.goldPrimary),
              const SizedBox(height: AppSpacing.sm),
              _detailRow('工时', _formatWorkTime(day.workSeconds),
                  AppColors.accentTeal),
              const SizedBox(height: AppSpacing.sm),
              _detailRow('金条', '${day.goldBars}', AppColors.success),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('关闭'),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.caption),
        Text(
          value,
          style: AppTextStyles.body.copyWith(color: valueColor),
        ),
      ],
    );
  }
}

// ─── Day Cell ────────────────────────────────────────────────

class _DayCell extends StatelessWidget {
  final int dayNumber;
  final CalendarDay? calendarDay;
  final VoidCallback? onTap;

  const _DayCell({
    required this.dayNumber,
    this.calendarDay,
    this.onTap,
  });

  Color _cellColor() {
    if (calendarDay == null || calendarDay!.coins == 0) {
      return const Color(0xFF2A2A2F); // dark grey — no activity
    }
    if (calendarDay!.coins < 100) {
      return const Color(0xFF8B7A3A); // light gold
    }
    if (calendarDay!.coins < 300) {
      return const Color(0xFFC4A035); // medium gold
    }
    return AppColors.goldPrimary; // bright gold (300+)
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Colored circle
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _cellColor(),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 2),
            // Day number
            Text(
              '$dayNumber',
              style: AppTextStyles.small.copyWith(
                color: calendarDay != null
                    ? AppColors.textSecondary
                    : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
