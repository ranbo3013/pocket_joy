import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../config/design_tokens.dart';
import '../../config/routes.dart';
import '../../providers/config_provider.dart';
import '../../models/bag_state.dart';
import '../widgets/bag_widget.dart';

class SalarySetupPage extends StatefulWidget {
  const SalarySetupPage({super.key});

  @override
  State<SalarySetupPage> createState() => _SalarySetupPageState();
}

class _SalarySetupPageState extends State<SalarySetupPage> {
  final _salaryController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  int _workdays = 0;
  double _intervalMin = defaultIntervalMin.toDouble();
  double _intervalMax = defaultIntervalMax.toDouble();

  String? _salaryError;
  String? _intervalError;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Calculate default workdays for current month
    _workdays = _defaultWorkdaysThisMonth();
  }

  @override
  void dispose() {
    _salaryController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    final salary = double.tryParse(_salaryController.text);
    return salary != null &&
        ConfigProvider.validateSalary(salary) == null &&
        ConfigProvider.validateWorkdays(_workdays) == null &&
        ConfigProvider.validateInterval(_intervalMin.round(), _intervalMax.round()) == null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.xl),
                // Bag icon (decorative, small)
                const SizedBox(
                  width: 120,
                  height: 120,
                  child: BagWidget(state: BagState.idle),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  '先告诉口袋你的工资\n让它开始为你攒快乐吧',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headline,
                ),
                const SizedBox(height: AppSpacing.xl),

                // ─── Salary Input ──────────────────────────
                TextFormField(
                  controller: _salaryController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: '税后月薪',
                    hintText: '输入你的税后月薪',
                    errorText: _salaryError,
                    prefixIcon: const Icon(Icons.lock_outline,
                        color: AppColors.goldPrimary),
                  ),
                  style: AppTextStyles.body,
                  onChanged: (_) {
                    setState(() {
                      _salaryError = ConfigProvider.validateSalary(
                          double.tryParse(_salaryController.text));
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // ─── Workdays Stepper ──────────────────────
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.bgSecondary,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('本月工作天数', style: AppTextStyles.body),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            color: AppColors.textSecondary,
                            onPressed: _workdays > minWorkdays
                                ? () => setState(() => _workdays--)
                                : null,
                          ),
                          SizedBox(
                            width: 48,
                            child: Text(
                              '$_workdays',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.headline.copyWith(
                                fontSize: 22,
                                color: AppColors.goldPrimary,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            color: AppColors.textSecondary,
                            onPressed: _workdays < maxWorkdays
                                ? () => setState(() => _workdays++)
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (ConfigProvider.validateWorkdays(_workdays) != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      ConfigProvider.validateWorkdays(_workdays)!,
                      style: AppTextStyles.small.copyWith(
                          color: AppColors.danger),
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),

                // ─── Interval Range ────────────────────────
                Text('掉落间隔范围', style: AppTextStyles.body),
                const SizedBox(height: AppSpacing.sm),
                RangeSlider(
                  values: RangeValues(_intervalMin, _intervalMax),
                  min: minIntervalMinutes.toDouble(),
                  max: maxIntervalMinutes.toDouble(),
                  divisions: 100,
                  activeColor: AppColors.goldPrimary,
                  inactiveColor: AppColors.textMuted,
                  labels: RangeLabels(
                    '${_intervalMin.round()} 分钟',
                    '${_intervalMax.round()} 分钟',
                  ),
                  onChanged: (values) {
                    setState(() {
                      _intervalMin = values.start;
                      _intervalMax = values.end;
                      _intervalError = ConfigProvider.validateInterval(
                        _intervalMin.round(),
                        _intervalMax.round(),
                      );
                    });
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${_intervalMin.round()} 分钟',
                        style: AppTextStyles.small),
                    Text('${_intervalMax.round()} 分钟',
                        style: AppTextStyles.small),
                  ],
                ),
                if (_intervalError != null)
                  Text(_intervalError!,
                      style: AppTextStyles.small.copyWith(
                          color: AppColors.danger)),
                const SizedBox(height: AppSpacing.xl),

                // ─── Save Button ───────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isFormValid && !_isSaving ? _onSave : null,
                    child: _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.bgPrimary,
                            ),
                          )
                        : const Text('开始攒快乐'),
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

  Future<void> _onSave() async {
    setState(() => _isSaving = true);

    final salary = double.parse(_salaryController.text);
    final config = context.read<ConfigProvider>();
    final success = await config.saveSalary(salary, _workdays);
    await config.updateIntervalRange(_intervalMin.round(), _intervalMax.round());

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      // Navigate to home, replacing setup page
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存失败，请检查设备存储空间')),
      );
    }
  }

  int _defaultWorkdaysThisMonth() {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);
    int count = 0;
    for (var d = firstDay;
        d.isBefore(lastDay) || d == lastDay;
        d = d.add(const Duration(days: 1))) {
      if (d.weekday != DateTime.saturday && d.weekday != DateTime.sunday) {
        count++;
      }
    }
    return count;
  }
}
