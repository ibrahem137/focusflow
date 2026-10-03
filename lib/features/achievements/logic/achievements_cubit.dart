import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/services/app_repository.dart';

class AchievementsCubit extends Cubit<Map<String, DateTime>> {
  final AppRepository repository;
  late final StreamSubscription<Map<String, dynamic>> _subscription;
  AchievementsCubit(this.repository) : super(const {}) {
    _subscription = repository.changes.listen((_) => _sync());
    _sync();
  }
  void _sync() {
    final unlocked = Map<String, dynamic>.from(
      repository.data['achievements'] as Map,
    );
    final next = unlocked.map(
      (id, date) => MapEntry(id, DateTime.parse(date as String)),
    );
    if (!isClosed && !mapEquals(state, next)) emit(next);
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
