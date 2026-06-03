import 'package:flutter/material.dart';

/// PocketJoy V1.0 Design Tokens
/// Reference: PRD §9

// ─── Colors ───────────────────────────────────────────────

abstract class AppColors {
  /// 主背景色
  static const bgPrimary = Color(0xFF0D0D0D);

  /// 卡片/面板背景
  static const bgSecondary = Color(0xFF1A1A1F);

  /// 金币/金条/口袋主色
  static const goldPrimary = Color(0xFFD4A843);

  /// 光晕/呼吸光效 (20% 透明度用于光晕叠加)
  static const goldGlow = Color(0xFFF0D060);

  /// 辅助光（柔和蓝绿）
  static const accentTeal = Color(0xFF5BC0BE);

  /// 主要文字
  static const textPrimary = Color(0xFFF5F5F5);

  /// 次要文字
  static const textSecondary = Color(0xFFA0A0B0);

  /// 占位/禁用文字
  static const textMuted = Color(0xFF606070);

  /// 危险操作（清除数据）
  static const danger = Color(0xFFE05555);

  /// 金条达成高亮
  static const success = Color(0xFFFFD700);

  /// 光晕透明度
  static const glowOpacityGold = 0.12;
  static const glowOpacityTeal = 0.07;
}

// ─── Typography ───────────────────────────────────────────

abstract class AppTextStyles {
  /// 金币数量大字 — 36sp / Bold / 44 行高
  static const display = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 44 / 36,
    color: AppColors.textPrimary,
  );

  /// 页面标题 — 24sp / SemiBold / 32 行高
  static const headline = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 32 / 24,
    color: AppColors.textPrimary,
  );

  /// 正文/设置项 — 16sp / Regular / 24 行高
  static const body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
    color: AppColors.textPrimary,
  );

  /// 辅助说明/情绪文案 — 14sp / Regular / 20 行高
  static const caption = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
    color: AppColors.textSecondary,
  );

  /// 占位文字 — 12sp / Regular / 18 行高
  static const small = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 18 / 12,
    color: AppColors.textMuted,
  );
}

// ─── Spacing ───────────────────────────────────────────────

abstract class AppSpacing {
  /// 紧凑间距 4px
  static const xs = 4.0;

  /// 组件内间距 8px
  static const sm = 8.0;

  /// 区块间距 16px
  static const md = 16.0;

  /// 页面边距 24px
  static const lg = 24.0;

  /// 大区块分隔 32px
  static const xl = 32.0;
}

// ─── Border Radius ────────────────────────────────────────

abstract class AppRadius {
  /// 按钮/小卡片
  static const sm = 8.0;

  /// 面板/弹窗
  static const md = 12.0;

  /// 大口袋容器
  static const lg = 16.0;
}
