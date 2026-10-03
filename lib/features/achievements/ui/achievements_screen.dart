import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../logic/achievement.dart';
import '../logic/achievements_cubit.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Achievements')),
    body: BlocBuilder<AchievementsCubit, Map<String, DateTime>>(
      builder: (context, unlocked) {
        final colors = Theme.of(context).colorScheme;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              '${unlocked.length} of ${Achievement.all.length} badges unlocked',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (unlocked.isEmpty)
              const Text('Start focusing to unlock your first achievement.'),
            const SizedBox(height: 16),
            for (final badge in Achievement.all)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  color: unlocked.containsKey(badge.id)
                      ? colors.primaryContainer
                      : colors.surfaceContainer,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Icon(
                      badge.icon,
                      color: unlocked.containsKey(badge.id)
                          ? colors.onPrimaryContainer
                          : colors.onSurfaceVariant,
                      size: 32,
                    ),
                    title: Text(badge.title),
                    subtitle: Text(
                      '${badge.description}\n${unlocked.containsKey(badge.id) ? 'Unlocked ${unlocked[badge.id]!.toLocal().toIso8601String().split('T').first}' : 'Locked'}',
                    ),
                    trailing: Icon(
                      unlocked.containsKey(badge.id)
                          ? Icons.check_circle_rounded
                          : Icons.lock_outline_rounded,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}
