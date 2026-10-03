import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/services/app_repository.dart';
import 'progress_state.dart';

class ProgressCubit extends Cubit<ProgressState> {
  final AppRepository repository;
  late final StreamSubscription<Map<String, dynamic>> _subscription;
  ProgressCubit({AppRepository? repository})
    : repository = repository ?? AppRepository(),
      super(ProgressState.initial()) {
    _subscription = this.repository.changes.listen((_) => _sync());
    if (this.repository.loaded) _sync();
  }
  void _sync() {
    final xp = repository.data['xp'] as int;
    if (!isClosed && xp != state.totalXp) emit(state.copyWith(totalXp: xp));
  }

  Future<void> addXp(int amount) async {
    if (amount <= 0) return;
    await repository.update((d) => d['xp'] = (d['xp'] as int) + amount);
  }

  Future<void> loadProgress() async {
    await repository.load();
    _sync();
  }

  Future<void> resetProgress() async {
    await repository.reset('progress');
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    await repository.flush();
    return super.close();
  }
}
