import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/theme/logic/theme_cubit.dart';
import '../../../core/services/app_repository.dart';
import '../../../core/services/support_email_service.dart';
import '../../focus/logic/focus_cubit.dart';
import '../logic/settings_cubit.dart';
import 'support_screen.dart';

class SettingsScreen extends StatelessWidget {
  final SupportEmailService? supportService;
  const SettingsScreen({super.key, this.supportService});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: BlocBuilder<SettingsCubit, Map<String, dynamic>>(
        builder: (context, s) {
          final settings = context.read<SettingsCubit>();
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _section(context, 'Appearance', [
                _SettingDropdown<String>(
                  key: ValueKey('theme-${s['theme']}'),
                  value: s['theme'] as String,
                  label: 'Theme',
                  items: const [
                    DropdownMenuItem(value: 'system', child: Text('System')),
                    DropdownMenuItem(value: 'light', child: Text('Light')),
                    DropdownMenuItem(value: 'dark', child: Text('Dark')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      context.read<ThemeCubit>().setTheme(
                        ThemeMode.values.firstWhere((m) => m.name == v),
                      );
                    }
                  },
                ),
              ]),
              _section(context, 'Focus', [
                _SettingDropdown<int>(
                  key: ValueKey('duration-${s['duration']}'),
                  value: s['duration'] as int,
                  label: 'Default duration',
                  items: <int>{15, 25, 45, 60, s['duration'] as int}
                      .map(
                        (m) => DropdownMenuItem(
                          value: m,
                          child: Text('$m minutes'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) async {
                    if (v == null) return;
                    final focus = context.read<FocusCubit>();
                    if (await settings.set('duration', v)) {
                      await focus.selectDuration(v);
                    }
                  },
                ),
                SwitchListTile(
                  title: const Text('Completion sound'),
                  subtitle: const Text(
                    'Uses your device'
                    "Uses your device's alert sound when the app is open.",
                  ),
                  value: s['sound'] == true,
                  onChanged: (v) => settings.set('sound', v),
                ),
                SwitchListTile(
                  title: const Text('Haptic feedback'),
                  value: s['haptics'] == true,
                  onChanged: (v) => settings.set('haptics', v),
                ),
              ]),
              _section(context, 'Notifications', [
                if (!settings.reminders.supported)
                  const ListTile(
                    leading: Icon(Icons.notifications_off_outlined),
                    title: Text('Reminders are available on Android and iOS.'),
                  ),
                SwitchListTile(
                  title: const Text('Daily focus reminder'),
                  value: s['daily'] == true,
                  onChanged: settings.reminders.supported
                      ? (v) => settings.set('daily', v)
                      : null,
                ),
                if (s['daily'] == true)
                  ListTile(
                    title: const Text('Reminder time'),
                    trailing: Text(
                      TimeOfDay(
                        hour: s['hour'] as int,
                        minute: s['minute'] as int,
                      ).format(context),
                    ),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(
                          hour: s['hour'] as int,
                          minute: s['minute'] as int,
                        ),
                      );
                      if (time != null) {
                        await settings.setTime(time.hour, time.minute);
                      }
                    },
                  ),
                SwitchListTile(
                  title: const Text('Streak reminder'),
                  subtitle: const Text(
                    'At 8:30 PM if yesterday was productive and today is still open.',
                  ),
                  value: s['streak'] == true,
                  onChanged: settings.reminders.supported
                      ? (v) => settings.set('streak', v)
                      : null,
                ),
              ]),
              _section(context, 'Data', [
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Your app data is stored locally. Individual resets keep earned badges, lifetime task milestones and reward records.',
                  ),
                ),
                for (final entry in const {
                  'tasks': 'Reset tasks',
                  'focus': 'Reset focus history',
                  'progress': 'Reset XP / progress',
                  'all': 'Reset all application data',
                }.entries)
                  ListTile(
                    title: Text(entry.value),
                    subtitle: Text(switch (entry.key) {
                      'tasks' => 'Removes tasks; keeps focus history and XP.',
                      'focus' => 'Removes focus history and active timer; keeps tasks and XP.',
                      'progress' =>
                        'Resets XP and level; keeps tasks and focus history.',
                      _ => 'Resets local data, settings and reminders. External copies remain.',
                    }),
                    trailing: const Icon(Icons.delete_outline_rounded),
                    onTap: () => _reset(context, entry.key, entry.value),
                  ),
              ]),
              _section(context, 'Support & Feedback', [
                _SupportTile(
                  request: SupportRequest.feedback,
                  service: supportService,
                  icon: Icons.feedback_outlined,
                  title: 'Send Feedback',
                  subtitle: 'Share ideas or suggest improvements',
                ),
                _SupportTile(
                  request: SupportRequest.problem,
                  service: supportService,
                  icon: Icons.bug_report_outlined,
                  title: 'Report a Problem',
                  subtitle: 'Tell us about an issue you encountered',
                ),
                _SupportTile(
                  request: SupportRequest.contact,
                  service: supportService,
                  icon: Icons.mail_outline_rounded,
                  title: 'Contact Us',
                  subtitle: 'Get in touch with us',
                ),
              ]),
              _section(context, 'About', [
                const _AppInfoTile(),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Privacy Policy'),
                  subtitle: const Text('Learn how FocusFlow handles your data'),
                  trailing: const Icon(Icons.open_in_new_rounded),
                  onTap: () => _openPrivacyPolicy(context),
                ),
                ListTile(
                  leading: const Icon(Icons.flutter_dash),
                  title: const Text('Developer'),
                  subtitle: const Text(
                    'Developed with Flutter by Ibrahem Alhuossien',
                  ),
                ),
              ]),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openPrivacyPolicy(BuildContext context) async {
    final uri = Uri.parse('https://focusflow-cf64f.web.app/privacy/');

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open the Privacy Policy. Please try again.',
            ),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open the Privacy Policy. Please try again.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _reset(BuildContext context, String scope, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('$title?'),
        content: Text(
          scope == 'all'
              ? 'Resets tasks, focus history, active timer, progress, badges, settings and local reminders. Email drafts, sent mail, clipboard copies and existing backups are outside this reset. This action cannot be undone.'
              : 'This action cannot be undone. Earned badges, lifetime task milestones and reward records are kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final repository = context.read<AppRepository>();
    final settings = context.read<SettingsCubit>();
    final focus = context.read<FocusCubit>();
    if (scope == 'focus') {
      if (await focus.resetHistory()) await settings.syncReminders();
    } else {
      if (scope == 'all') {
        settings.cancelPendingChanges();
      }
      final saved = scope == 'all'
          ? await focus.resetAllData()
          : await repository.reset(scope);
      if (scope == 'all' && saved) {
        if (context.mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    }
  }

  Widget _section(BuildContext context, String title, List<Widget> children) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(children: children),
              ),
            ),
          ],
        ),
      );
}

class _AppInfoTile extends StatefulWidget {
  const _AppInfoTile();

  @override
  State<_AppInfoTile> createState() => _AppInfoTileState();
}

class _AppInfoTileState extends State<_AppInfoTile> {
  String _version = '';

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.spa_rounded),
      title: Text(_version.isEmpty ? 'FocusFlow' : 'FocusFlow · $_version'),
      subtitle: const Text(
        'Protect your time. Finish meaningful work. Grow a little everyday.',
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();

      if (!mounted) return;

      setState(() {
        _version = '${info.version}+${info.buildNumber}';
      });
    } catch (_) {
      // The app remains usable even if package metadata is unavailable.
    }
  }
}

/// Controlled by persisted state, so a rejected write never leaves a false
/// selection in a FormField's independent internal state.
class _SettingDropdown<T> extends StatelessWidget {
  final T value;
  final String label;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  const _SettingDropdown({
    super.key,
    required this.value,
    required this.label,
    required this.items,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) => InputDecorator(
    decoration: InputDecoration(labelText: label),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        isDense: true,
        items: items,
        onChanged: onChanged,
      ),
    ),
  );
}

class _SupportTile extends StatefulWidget {
  final SupportRequest request;
  final SupportEmailService? service;
  final IconData icon;
  final String title;
  final String subtitle;
  const _SupportTile({
    required this.request,
    this.service,
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  @override
  State<_SupportTile> createState() => _SupportTileState();
}

class _SupportTileState extends State<_SupportTile> {
  bool _opening = false;
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(widget.icon, color: Theme.of(context).colorScheme.primary),
    title: Text(widget.title),
    subtitle: Text(widget.subtitle),
    onTap: _opening ? null : _open,
  );

  Future<void> _open() async {
    if (_opening) return;
    setState(() => _opening = true);
    Widget page(BuildContext _) => SupportScreen(
      request: widget.request,
      service: widget.service ?? SupportEmailService(),
    );
    try {
      await Navigator.of(context).push<void>(
        MediaQuery.disableAnimationsOf(context)
            ? PageRouteBuilder<void>(
                pageBuilder: (context, animation, secondary) => page(context),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              )
            : MaterialPageRoute<void>(builder: page),
      );
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }
}
