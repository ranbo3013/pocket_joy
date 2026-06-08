import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../config/design_tokens.dart';
import '../../models/alarm_config.dart';

class AlarmEditPage extends StatefulWidget {
  /// If non-null, the page is in edit mode with fields pre-filled.
  final CustomAlarm? existingAlarm;

  const AlarmEditPage({super.key, this.existingAlarm});

  bool get isEditing => existingAlarm != null;

  @override
  State<AlarmEditPage> createState() => _AlarmEditPageState();
}

class _AlarmEditPageState extends State<AlarmEditPage> {
  static const _weekdayLabels = ['一', '二', '三', '四', '五', '六', '日'];
  static const _repeatCounts = [1, 2, 3, 5];
  static const _intervals = [1, 3, 5, 10, 15, 30];

  final _titleController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late int _hour;
  late int _minute;
  late int _repeatCount;
  late int _intervalMinutes;
  late bool _enabled;
  late List<bool> _workDays;

  @override
  void initState() {
    super.initState();
    final alarm = widget.existingAlarm;
    if (alarm != null) {
      _titleController.text = alarm.title;
      _hour = alarm.hour;
      _minute = alarm.minute;
      _repeatCount = alarm.repeatCount;
      _intervalMinutes = alarm.intervalMinutes;
      _enabled = alarm.enabled;
      _workDays = List<bool>.from(alarm.workDays);
    } else {
      _hour = 9;
      _minute = 0;
      _repeatCount = 1;
      _intervalMinutes = 5;
      _enabled = true;
      _workDays = const [true, true, true, true, true, false, false];
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  String get _appBarTitle => widget.isEditing ? '编辑闹钟' : '新建闹钟';

  // ─── Time Picker ───────────────────────────────────────────

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _hour, minute: _minute),
      helpText: '选择时间',
      cancelText: '取消',
      confirmText: '确认',
    );
    if (time != null) {
      setState(() {
        _hour = time.hour;
        _minute = time.minute;
      });
    }
  }

  String get _timeLabel {
    final h = _hour.toString().padLeft(2, '0');
    final m = _minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  // ─── Dropdown Pickers ──────────────────────────────────────

  void _pickRepeatCount() {
    _showDropdown<int>(
      title: '重复次数',
      items: _repeatCounts,
      selected: _repeatCount,
      formatter: (v) => '$v 次',
      onSelected: (v) => setState(() => _repeatCount = v),
    );
  }

  void _pickInterval() {
    _showDropdown<int>(
      title: '间隔时间',
      items: _intervals,
      selected: _intervalMinutes,
      formatter: (v) => '$v 分钟',
      onSelected: (v) => setState(() => _intervalMinutes = v),
    );
  }

  void _showDropdown<T>({
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
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
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

  // ─── Save ──────────────────────────────────────────────────

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final alarm = CustomAlarm(
      id: widget.existingAlarm?.id ??
          'alarm_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text.trim(),
      hour: _hour,
      minute: _minute,
      repeatCount: _repeatCount,
      intervalMinutes: _intervalMinutes,
      enabled: _enabled,
      workDays: _workDays,
    );
    Navigator.pop(context, alarm);
  }

  // ─── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: Text(_appBarTitle),
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
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(
              '保存',
              style: AppTextStyles.body.copyWith(
                color: AppColors.goldPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Title ────────────────────────────────────
                _SectionHeader(title: '名称'),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: TextFormField(
                    controller: _titleController,
                    style: AppTextStyles.body,
                    decoration: InputDecoration(
                      hintText: '闹钟标题',
                      hintStyle: AppTextStyles.body.copyWith(
                        color: AppColors.textMuted,
                      ),
                      filled: true,
                      fillColor: AppColors.bgSecondary,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.md,
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return '请输入闹钟标题';
                      return null;
                    },
                  ),
                ),
                const Divider(
                  color: AppColors.textMuted,
                  height: 1,
                  indent: AppSpacing.lg,
                  endIndent: AppSpacing.lg,
                ),

                // ─── Time ─────────────────────────────────────
                _SectionHeader(title: '时间'),
                _SettingsTile(
                  title: '提醒时间',
                  subtitle: _timeLabel,
                  onTap: _pickTime,
                ),
                const Divider(
                  color: AppColors.textMuted,
                  height: 1,
                  indent: AppSpacing.lg,
                  endIndent: AppSpacing.lg,
                ),

                // ─── Repeat ───────────────────────────────────
                _SectionHeader(title: '重复设置'),
                _SettingsTile(
                  title: '重复次数',
                  subtitle: '$_repeatCount 次',
                  onTap: _pickRepeatCount,
                ),
                _SettingsTile(
                  title: '间隔时间',
                  subtitle: '$_intervalMinutes 分钟',
                  onTap: _pickInterval,
                ),
                const Divider(
                  color: AppColors.textMuted,
                  height: 1,
                  indent: AppSpacing.lg,
                  endIndent: AppSpacing.lg,
                ),

                // ─── Work Days ────────────────────────────────
                _SectionHeader(title: '生效日'),
                _WorkDaysRow(
                  workDays: _workDays,
                  labels: _weekdayLabels,
                  onChanged: (days) => setState(() => _workDays = days),
                ),
                const Divider(
                  color: AppColors.textMuted,
                  height: 1,
                  indent: AppSpacing.lg,
                  endIndent: AppSpacing.lg,
                ),

                // ─── Enabled ──────────────────────────────────
                _SectionHeader(title: '状态'),
                _SettingsTile(
                  title: '启用',
                  trailing: Switch(
                    value: _enabled,
                    activeThumbColor: AppColors.goldPrimary,
                    onChanged: (v) => setState(() => _enabled = v),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Reusable Widgets (same pattern as alarm_settings_page) ──

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

  const _SettingsTile({
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title, style: AppTextStyles.body),
      subtitle: subtitle != null
          ? Text(subtitle!, style: AppTextStyles.small)
          : null,
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right, color: AppColors.textMuted)
              : null),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
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
                color: isSelected ? AppColors.goldPrimary : AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected ? AppColors.goldPrimary : AppColors.textMuted,
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
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
