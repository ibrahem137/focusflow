import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../services/app_repository.dart';
import 'theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  final AppRepository repository;
  late final StreamSubscription<Map<String, dynamic>> _subscription;
  ThemeCubit({AppRepository? repository})
    : repository = repository ?? AppRepository(),
      super(const ThemeState(themeMode: ThemeMode.system)) {
    _subscription = this.repository.changes.listen((_) => _sync());
    if (this.repository.loaded) _sync();
  }
  void _sync() {
    final name = repository.settings['theme'];
    final mode = ThemeMode.values.firstWhere(
      (m) => m.name == name,
      orElse: () => ThemeMode.system,
    );
    if (!isClosed && state.themeMode != mode) emit(ThemeState(themeMode: mode));
  }

  Future<void> loadTheme() async {
    await repository.load();
    _sync();
  }

  Future<void> setTheme(ThemeMode mode) async {
    await repository.update(
      (d) => (d['settings'] as Map)['theme'] = mode.name,
      evaluate: false,
    );
  }

  Future<void> toggleTheme() =>
      setTheme(state.isDark ? ThemeMode.light : ThemeMode.dark);
  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
