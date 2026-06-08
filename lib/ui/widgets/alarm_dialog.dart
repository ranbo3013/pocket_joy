import 'package:flutter/material.dart';
import '../../config/design_tokens.dart';

class AlarmDialog extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String primaryLabel;
  final String? secondaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback? onSecondary;

  const AlarmDialog({
    super.key,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.primaryLabel,
    this.secondaryLabel,
    required this.onPrimary,
    this.onSecondary,
  });

  /// 🌅 上班提醒
  factory AlarmDialog.workStart({required VoidCallback onStart}) {
    return AlarmDialog(
      emoji: '🌅',
      title: '早上好，准备开工了',
      subtitle: '新的一天，口袋已准备好',
      primaryLabel: '开始工作',
      onPrimary: onStart,
    );
  }

  /// ☕ 休息提醒
  factory AlarmDialog.breakReminder({
    required int minutes,
    required VoidCallback onBreak,
    VoidCallback? onSnooze,
  }) {
    return AlarmDialog(
      emoji: '☕',
      title: '该休息一下了',
      subtitle: '你已经连续工作 $minutes 分钟',
      primaryLabel: '起身走走 🌿',
      secondaryLabel: '再等 5 分钟',
      onPrimary: onBreak,
      onSecondary: onSnooze,
    );
  }

  /// 🌙 下班打卡
  factory AlarmDialog.endOfWorkday({
    required String summary,
    required VoidCallback onClockOut,
  }) {
    return AlarmDialog(
      emoji: '🌙',
      title: '今天辛苦了',
      subtitle: summary,
      primaryLabel: '打卡下班',
      onPrimary: onClockOut,
    );
  }

  /// ⏰ 加班提醒
  factory AlarmDialog.overtime({required VoidCallback onDismiss}) {
    return AlarmDialog(
      emoji: '⏰',
      title: '还在加班？',
      subtitle: '已经超过下班时间了，该休息了',
      primaryLabel: '知道了',
      onPrimary: onDismiss,
    );
  }

  /// 🔔 自定义闹钟
  factory AlarmDialog.custom({
    required String alarmTitle,
    int? repeatInfo,
    required VoidCallback onDismiss,
  }) {
    final hasRepeat = repeatInfo != null;
    return AlarmDialog(
      emoji: hasRepeat ? '🔔🔔' : '🔔',
      title: alarmTitle,
      subtitle: hasRepeat ? '第 $repeatInfo 次提醒' : '闹钟提醒',
      primaryLabel: '知道了',
      onPrimary: onDismiss,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.8, end: 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return Transform.scale(scale: value, child: child);
        },
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.goldPrimary, width: 1),
          ),
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 56),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.goldPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.goldPrimary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    onPrimary();
                  },
                  child: Text(
                    primaryLabel,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              if (secondaryLabel != null && onSecondary != null) ...[
                const SizedBox(height: 12),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    textStyle: const TextStyle(fontSize: 14),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    onSecondary?.call();
                  },
                  child: Text(secondaryLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─── Convenience static show methods ─────────────────────

  static Future<void> showWorkStart(
    BuildContext context, {
    required VoidCallback onStart,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlarmDialog.workStart(onStart: onStart),
    );
  }

  static Future<void> showBreakReminder(
    BuildContext context, {
    required int minutes,
    required VoidCallback onBreak,
    VoidCallback? onSnooze,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlarmDialog.breakReminder(
        minutes: minutes,
        onBreak: onBreak,
        onSnooze: onSnooze,
      ),
    );
  }

  static Future<void> showEndOfWorkday(
    BuildContext context, {
    required String summary,
    required VoidCallback onClockOut,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlarmDialog.endOfWorkday(
        summary: summary,
        onClockOut: onClockOut,
      ),
    );
  }

  static Future<void> showOvertime(
    BuildContext context, {
    required VoidCallback onDismiss,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlarmDialog.overtime(onDismiss: onDismiss),
    );
  }

  static Future<void> showCustom(
    BuildContext context, {
    required String alarmTitle,
    int? repeatInfo,
    required VoidCallback onDismiss,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlarmDialog.custom(
        alarmTitle: alarmTitle,
        repeatInfo: repeatInfo,
        onDismiss: onDismiss,
      ),
    );
  }
}
