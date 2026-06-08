import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/design_tokens.dart';
import '../../models/achievement.dart';
import '../../providers/game_provider.dart';
import '../widgets/heatmap_calendar.dart';

/// Achievement page with two tabs: badges and calendar heatmap.
class AchievementPage extends StatelessWidget {
  const AchievementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('我的成就'),
          bottom: const TabBar(
            labelColor: AppColors.goldPrimary,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.goldPrimary,
            tabs: [
              Tab(text: '徽章'),
              Tab(text: '日历'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _BadgesTab(),
            _CalendarTab(),
          ],
        ),
      ),
    );
  }
}

// ─── Badges Tab ──────────────────────────────────────────────

class _BadgesTab extends StatelessWidget {
  const _BadgesTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, game, _) {
        // Filter out hidden locked achievements
        final visible = game.achievements
            .where((a) => a.isUnlocked || !a.isHidden)
            .toList();

        if (visible.isEmpty) {
          return const Center(
            child: Text(
              '暂无徽章',
              style: AppTextStyles.caption,
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 0.85,
          ),
          itemCount: visible.length,
          itemBuilder: (context, index) {
            final achievement = visible[index];
            return _BadgeCard(achievement: achievement);
          },
        );
      },
    );
  }
}

// ─── Badge Card ──────────────────────────────────────────────

class _BadgeCard extends StatelessWidget {
  final Achievement achievement;

  const _BadgeCard({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final unlocked = achievement.isUnlocked;

    return Card(
      color: unlocked ? AppColors.bgSecondary : const Color(0xFF1E1E24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: unlocked
            ? const BorderSide(color: AppColors.goldPrimary, width: 0.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Text(
              unlocked ? achievement.icon : '❓',
              style: TextStyle(fontSize: 48),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),

            // Name
            Text(
              achievement.name,
              style: AppTextStyles.small.copyWith(
                color: unlocked
                    ? AppColors.goldPrimary
                    : AppColors.textMuted,
                fontWeight:
                    unlocked ? FontWeight.w600 : FontWeight.w400,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            // Unlock date (only for unlocked)
            if (unlocked && achievement.unlockedAt != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${achievement.unlockedAt!.month.toString().padLeft(2, '0')}/${achievement.unlockedAt!.day.toString().padLeft(2, '0')}',
                style: AppTextStyles.small.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Calendar Tab ────────────────────────────────────────────

class _CalendarTab extends StatelessWidget {
  const _CalendarTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, game, _) {
        if (game.calendarDays.isEmpty) {
          return const Center(
            child: Text(
              '暂无日历数据',
              style: AppTextStyles.caption,
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: HeatmapCalendar(days: game.calendarDays),
        );
      },
    );
  }
}
