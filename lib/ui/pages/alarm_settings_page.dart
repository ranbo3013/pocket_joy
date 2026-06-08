import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/design_tokens.dart';
import '../../models/alarm_config.dart';
import '../../repositories/alarm_repository.dart';
import 'alarm_edit_page.dart';

class AlarmSettingsPage extends StatefulWidget {
  const AlarmSettingsPage({super.key});

  @override
  State<AlarmSettingsPage> createState() => _AlarmSettingsPageState();
}

class _AlarmSettingsPageState extends State<AlarmSettingsPage> {
  AlarmConfig _config = const AlarmConfig();
  AlarmRepository? _repository;
  bool _loading = true;

  static const _weekdayLabels = ['一', '二', '三', '四', '五', '六', '日'];
  static const _breakIntervals = [30, 45, 60, 90, 120];
  static const _breakDurations = [3, 5, 10, 15];

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    _repository = AlarmRepository(prefs);
    setState(() {
      _config = _repository!.load();
      _loading = false;
    });
  }

  Future<void> _saveConfig(AlarmConfig config) async {
    setState(() => _config = config);
    await _repository?.save(config);
  }

  // ─── Time Pickers ──────────────────────────────────────────

  Future<void> _pickWorkStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _config.workStartTime,
      helpText: '上班时间',
      cancelText: '取消',
      confirmText: '确认',
    );
    if (time != null) {
      await _saveConfig(_config.copyWith(
        workStartHour: time.hour,
        workStartMinute: time.minute,
      ));
    }
  }

  Future<void> _pickWorkEndTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _config.workEndTime,
      helpText: '下班时间',
      cancelText: '取消',
      confirmText: '确认',
    );
    if (time != null) {
      await _saveConfig(_config.copyWith(
        workEndHour: time.hour,
        workEndMinute: time.minute,
      ));
    }
  }

  // ─── Number Pickers ────────────────────────────────────────

  void _pickBreakInterval() {
    _showNumberPicker<int>(
      title: '休息间隔',
      items: _breakIntervals,
      selected: _config.breakIntervalMinutes,
      formatter: (v) => '$v 分钟',
      onSelected: (v) => _saveConfig(_config.copyWith(breakIntervalMinutes: v)),
    );
  }

  void _pickBreakDuration() {
    _showNumberPicker<int>(
      title: '休息时长',
      items: _breakDurations,
      selected: _config.breakDurationMinutes,
      formatter: (v) => '$v 分钟',
      onSelected: (v) => _saveConfig(_config.copyWith(breakDurationMinutes: v)),
    );
  }

  void _showNumberPicker<T>({
    required String title,
    required List<T> items,
    required T selected,
    required String Function(T) formatter,
    required ValueChanged<T> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  title,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Divider(color: AppColors.textMuted, height: 1),
              ...items.map((item) {
                final isSelected = item == selected;
                return ListTile(
                  title: Text(
                    formatter(item),
                    style: AppTextStyles.body.copyWith(
                      color: isSelected
                          ? AppColors.goldPrimary
                          : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: AppColors.goldPrimary)
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    onSelected(item);
                  },
                );
              }),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        );
      },
    );
  }

  // ─── Custom Alarm Management ───────────────────────────────

  Future<void> _addCustomAlarm() async {
    final result = await Navigator.push<CustomAlarm>(
      context,
      MaterialPageRoute(
        builder: (_) => const AlarmEditPage(),
      ),
    );
    if (result != null) {
      await _saveConfig(
        _config.copyWith(customAlarms: [..._config.customAlarms, result]),
      );
    }
  }

  Future<void> _editCustomAlarm(int index) async {
    final result = await Navigator.push<CustomAlarm>(
      context,
      MaterialPageRoute(
        builder: (_) => AlarmEditPage(existingAlarm: _config.customAlarms[index]),
      ),
    );
    if (result != null) {
      final updated = List<CustomAlarm>.from(_config.customAlarms);
      updated[index] = result;
      await _saveConfig(_config.copyWith(customAlarms: updated));
    }
  }

  Future<void> _deleteCustomAlarm(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        title: const Text('删除闹钟', style: TextStyle(color: AppColors.danger)),
        content: Text(
          '确定要删除"${_config.customAlarms[index].title}"吗？',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final updated = List<CustomAlarm>.from(_config.customAlarms);
      updated.removeAt(index);
      await _saveConfig(_config.copyWith(customAlarms: updated));
    }
  }

  Future<void> _toggleCustomAlarm(int index, bool enabled) async {
    final updated = List<CustomAlarm>.from(_config.customAlarms);
    updated[index] = updated[index].copyWith(enabled: enabled);
    await _saveConfig(_config.copyWith(customAlarms: updated));
  }

  // ─── Helpers ───────────────────────────────────────────────

  String _formatTimeOfDay(TimeOfDay tod) {
    final h = tod.hour.toString().padLeft(2, '0');
    final m = tod.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatCustomAlarmSubtitle(CustomAlarm alarm) {
    final parts = <String>[];
    if (alarm.repeatCount > 1) {
      parts.add('重复${alarm.repeatCount}次');
    }
    if (alarm.intervalMinutes > 0 && alarm.repeatCount > 1) {
      parts.add('间隔${alarm.intervalMinutes}分钟');
    }
    return parts.join(' · ');
  }

  // ─── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.bgPrimary,
        appBar: AppBar(
          title: const Text('闹钟设置'),
          leading: IconButton(
            icon: SvgPicture.asset(
              'assets/icons/back.svg',
              width: 20,
              height: 20,
              colorFilter: const ColorFilter.mode(
                AppColors.textSecondary,
                BlendMode.srcIn,
              ),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: const Text('闹钟设置'),
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/icons/back.svg',
            width: 20,
            height: 20,
            colorFilter: const ColorFilter.mode(
              AppColors.textSecondary,
              BlendMode.srcIn,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Work Schedule ──────────────────────────────
              _SectionHeader(title: '工作时间'),
              _SettingsTile(
                title: '上班时间',
                subtitle: _formatTimeOfDay(_config.workStartTime),
                onTap: _pickWorkStartTime,
              ),
              _SettingsTile(
                title: '下班时间',
                subtitle: _formatTimeOfDay(_config.workEndTime),
                onTap: _pickWorkEndTime,
              ),
              _WorkDaysRow(
                workDays: _config.workDays,
                labels: _weekdayLabels,
                onChanged: (days) => _saveConfig(_config.copyWith(workDays: days)),
              ),
              const Divider(
                color: AppColors.textMuted,
                height: 1,
                indent: AppSpacing.lg,
                endIndent: AppSpacing.lg,
              ),

              // ─── Break Settings ─────────────────────────────
              _SectionHeader(title: '休息提醒'),
              _SettingsTile(
                title: '休息提醒',
                subtitle: _config.breakIntervalMinutes > 0
                    ? '每 ${_config.breakIntervalMinutes} 分钟提醒休息'
                    : '已关闭',
                trailing: Switch(
                  value: _config.breakIntervalMinutes > 0,
                  activeThumbColor: AppColors.goldPrimary,
                  onChanged: (enabled) {
                    _saveConfig(_config.copyWith(
                      breakIntervalMinutes: enabled ? 60 : 0,
                    ));
                  },
                ),
              ),
              _SettingsTile(
                title: '休息间隔',
                subtitle: '${_config.breakIntervalMinutes} 分钟',
                enabled: _config.breakIntervalMinutes > 0,
                onTap: _config.breakIntervalMinutes > 0 ? _pickBreakInterval : null,
              ),
              _SettingsTile(
                title: '休息时长',
                subtitle: '${_config.breakDurationMinutes} 分钟',
                enabled: _config.breakIntervalMinutes > 0,
                onTap: _config.breakIntervalMinutes > 0 ? _pickBreakDuration : null,
              ),
              _SettingsTile(
                title: '休息奖励',
                subtitle: '休息结束回来 +3 金币',
                trailing: Switch(
                  value: _config.breakRewardEnabled,
                  activeThumbColor: AppColors.goldPrimary,
                  onChanged: (v) =>
                      _saveConfig(_config.copyWith(breakRewardEnabled: v)),
                ),
              ),
              _SettingsTile(
                title: '早安金币',
                subtitle: '准时上班 +3 金币',
                trailing: Switch(
                  value: _config.morningRewardEnabled,
                  activeThumbColor: AppColors.goldPrimary,
                  onChanged: (v) =>
                      _saveConfig(_config.copyWith(morningRewardEnabled: v)),
                ),
              ),
              const Divider(
                color: AppColors.textMuted,
                height: 1,
                indent: AppSpacing.lg,
                endIndent: AppSpacing.lg,
              ),

              // ─── Custom Alarms ──────────────────────────────
              _SectionHeader(title: '自定义闹钟'),
              if (_config.customAlarms.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: Text(
                    '暂无自定义闹钟，点击下方按钮添加',
                    style: AppTextStyles.caption,
                  ),
                ),
              ..._config.customAlarms.asMap().entries.map((entry) {
                final index = entry.key;
                final alarm = entry.value;
                return _CustomAlarmTile(
                  alarm: alarm,
                  subtitle: _formatCustomAlarmSubtitle(alarm),
                  onTap: () => _editCustomAlarm(index),
                  onToggle: (enabled) => _toggleCustomAlarm(index, enabled),
                  onDelete: () => _deleteCustomAlarm(index),
                  onLongPress: () => _deleteCustomAlarm(index),
                );
              }),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _addCustomAlarm,
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('添加闹钟'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.goldPrimary,
                      side: const BorderSide(color: AppColors.goldPrimary),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Reusable Widgets ────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Text(
        title,
        style: AppTextStyles.small.copyWith(
          color: AppColors.textMuted,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;

  const _SettingsTile({
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = enabled ? null : AppColors.textMuted;
    return ListTile(
      title: Text(
        title,
        style: AppTextStyles.body.copyWith(color: textColor),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: AppTextStyles.small.copyWith(color: textColor),
            )
          : null,
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right, color: AppColors.textMuted)
              : null),
      onTap: enabled ? onTap : null,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      minLeadingWidth: 0,
    );
  }
}

class _WorkDaysRow extends StatelessWidget {
  final List<bool> workDays;
  final List<String> labels;
  final ValueChanged<List<bool>> onChanged;

  const _WorkDaysRow({
    required this.workDays,
    required this.labels,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (i) {
          final isSelected = workDays[i];
          return GestureDetector(
            onTap: () {
              final updated = List<bool>.from(workDays);
              updated[i] = !updated[i];
              onChanged(updated);
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.goldPrimary
                    : AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected
                      ? AppColors.goldPrimary
                      : AppColors.textMuted,
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                labels[i],
                style: AppTextStyles.small.copyWith(
                  color: isSelected
                      ? AppColors.bgPrimary
                      : AppColors.textSecondary,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _CustomAlarmTile extends StatelessWidget {
  final CustomAlarm alarm;
  final String subtitle;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;
  final VoidCallback onLongPress;

  const _CustomAlarmTile({
    required this.alarm,
    required this.subtitle,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final timeText =
        '${alarm.hour.toString().padLeft(2, '0')}:${alarm.minute.toString().padLeft(2, '0')}';

    return Dismissible(
      key: Key(alarm.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        color: AppColors.danger,
        child: const Icon(Icons.delete, color: AppColors.textPrimary),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false; // We handle deletion ourselves
      },
      child: ListTile(
        leading: Text(
          timeText,
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w600,
            color: alarm.enabled
                ? AppColors.goldPrimary
                : AppColors.textMuted,
          ),
        ),
        title: Text(
          alarm.title,
          style: AppTextStyles.body.copyWith(
            color: alarm.enabled
                ? AppColors.textPrimary
                : AppColors.textMuted,
          ),
        ),
        subtitle: subtitle.isNotEmpty
            ? Text(subtitle, style: AppTextStyles.small)
            : null,
        trailing: Switch(
          value: alarm.enabled,
          activeThumbColor: AppColors.goldPrimary,
          onChanged: onToggle,
        ),
        onTap: onTap,
        onLongPress: onLongPress,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        minLeadingWidth: 48,
      ),
    );
  }
}
