import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../config/design_tokens.dart';
import '../../config/routes.dart';
import '../../providers/config_provider.dart';
import '../../providers/game_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
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
      body: Consumer<ConfigProvider>(
        builder: (context, config, _) {
          return SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Income & Work ────────────────────────
                  _SectionHeader(title: '收入与工作'),
                  _SettingsTile(
                    title: '修改税后月薪',
                    subtitle: '已设置',
                    trailing: const Icon(Icons.chevron_right,
                        color: AppColors.textMuted),
                    onTap: () => _showSalaryDialog(context, config),
                  ),
                  _SettingsTile(
                    title: '工作天数',
                    subtitle: '${config.workdays} 天',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, size: 20),
                          color: AppColors.textSecondary,
                          onPressed: config.workdays > minWorkdays
                              ? () => config.updateWorkdays(config.workdays - 1)
                              : null,
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, size: 20),
                          color: AppColors.textSecondary,
                          onPressed: config.workdays < maxWorkdays
                              ? () => config.updateWorkdays(config.workdays + 1)
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const Divider(
                      color: AppColors.textMuted, height: 1, indent: AppSpacing.lg, endIndent: AppSpacing.lg),

                  // ─── Drop Settings ────────────────────────
                  _SectionHeader(title: '掉落设置'),
                  _SettingsTile(
                    title: '随机间隔范围',
                    subtitle:
                        '${config.intervalMin} – ${config.intervalMax} 分钟',
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg),
                    child: RangeSlider(
                      values: RangeValues(
                        config.intervalMin.toDouble(),
                        config.intervalMax.toDouble(),
                      ),
                      min: minIntervalMinutes.toDouble(),
                      max: maxIntervalMinutes.toDouble(),
                      divisions: 100,
                      activeColor: AppColors.goldPrimary,
                      inactiveColor: AppColors.textMuted,
                      onChanged: (values) {
                        config.updateIntervalRange(
                          values.start.round(),
                          values.end.round(),
                        );
                      },
                    ),
                  ),
                  const Divider(
                      color: AppColors.textMuted, height: 1, indent: AppSpacing.lg, endIndent: AppSpacing.lg),

                  // ─── Preferences ──────────────────────────
                  _SectionHeader(title: '偏好'),
                  _SettingsTile(
                    title: '音效',
                    trailing: Switch(
                      value: config.soundEnabled,
                      activeThumbColor: AppColors.goldPrimary,
                      onChanged: (_) => config.toggleSound(),
                    ),
                  ),
                  _SettingsTile(
                    title: '震动',
                    trailing: Switch(
                      value: config.hapticEnabled,
                      activeThumbColor: AppColors.goldPrimary,
                      onChanged: (_) => config.toggleHaptic(),
                    ),
                  ),
                  _SettingsTile(
                    title: '通知',
                    trailing: Switch(
                      value: config.notificationsEnabled,
                      activeThumbColor: AppColors.goldPrimary,
                      onChanged: (_) => config.toggleNotifications(),
                    ),
                  ),
                  const Divider(
                      color: AppColors.textMuted, height: 1, indent: AppSpacing.lg, endIndent: AppSpacing.lg),

                  // ─── Data ─────────────────────────────────
                  _SectionHeader(title: '数据'),
                  _SettingsTile(
                    title: '清除本地数据',
                    subtitle: '清除后回到初始化页面',
                    trailing: SvgPicture.asset(
                      'assets/icons/trash.svg',
                      width: 24,
                      height: 24,
                      colorFilter: const ColorFilter.mode(
                        AppColors.danger,
                        BlendMode.srcIn,
                      ),
                    ),
                    titleColor: AppColors.danger,
                    onTap: () => _showClearDialog(context, config),
                  ),
                  const Divider(
                      color: AppColors.textMuted, height: 1, indent: AppSpacing.lg, endIndent: AppSpacing.lg),

                  // ─── About ────────────────────────────────
                  _SectionHeader(title: '关于'),
                  const _SettingsTile(
                    title: '版本',
                    subtitle: '1.0.0',
                  ),
                  const _SettingsTile(
                    title: 'PocketJoy',
                    subtitle: '口袋快乐 — 把上班时间变成快乐',
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Dialogs ─────────────────────────────────────────────

  void _showSalaryDialog(BuildContext context, ConfigProvider config) {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('修改税后月薪'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '税后月薪',
                hintText: '输入新的税后月薪',
              ),
              validator: (v) =>
                  ConfigProvider.validateSalary(double.tryParse(v ?? '')),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  // First confirmation
                  Navigator.of(ctx).pop();
                  final confirmed = await _showConfirmDialog(
                    context,
                    '确认修改月薪为 ${controller.text}？',
                  );
                  if (confirmed == true && context.mounted) {
                    final salary = double.parse(controller.text);
                    final success = await config.updateSalary(salary);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success ? '月薪已更新' : '保存失败，请重试'),
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('确认'),
            ),
          ],
        );
      },
    );
  }

  void _showClearDialog(BuildContext context, ConfigProvider config) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('清除本地数据',
              style: TextStyle(color: AppColors.danger)),
          content: const Text('此操作将清除所有本地数据，包括工资设置和金币统计。确定要继续吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                // Second confirmation
                final confirmed = await _showConfirmDialog(
                  context,
                  '数据清除后无法恢复，确认清除？',
                );
                if (confirmed == true) {
                  await config.clearAllData();
                  // Reset game state
                  if (context.mounted) {
                    context.read<GameProvider>().initialize();
                    Navigator.of(context)
                        .pushReplacementNamed(AppRoutes.setup);
                  }
                }
              },
              child: const Text('清除', style: TextStyle(color: AppColors.danger)),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _showConfirmDialog(BuildContext context, String message) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('确认'),
            ),
          ],
        );
      },
    );
  }
}

// ─── Reusable Settings Widgets ────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
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
  final Color? titleColor;

  const _SettingsTile({
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title,
          style: AppTextStyles.body.copyWith(color: titleColor)),
      subtitle: subtitle != null
          ? Text(subtitle!, style: AppTextStyles.small)
          : null,
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg),
      minLeadingWidth: 0,
    );
  }
}
