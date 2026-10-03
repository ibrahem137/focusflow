import 'dart:async';
import 'dart:convert';

import '../../../core/utils/event_id.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/services/app_repository.dart';
import '../../../core/constants/rewards.dart';
import '../data/models/focus_session.dart';
import 'focus_state.dart';

class FocusCubit extends Cubit<FocusState> {
  final AppRepository repository;
  final Duration tickDuration;
  final DateTime Function() clock;
  Timer? _timer;
  DateTime? _endsAt;
  String? _sessionId;
  bool _finishing = false;
  bool _resetting = false;
  Future<void>? _completion;
  late final StreamSubscription<Map<String, dynamic>> _subscription;
  FocusCubit({
    AppRepository? repository,
    this.tickDuration = const Duration(seconds: 1),
    DateTime Function()? clock,
  }) : repository = repository ?? AppRepository(),
       clock = clock ?? DateTime.now,
       super(FocusState.initial()) {
    _subscription = this.repository.changes.listen((_) => _syncHistory());
    if (this.repository.loaded) _syncHistory();
  }

  void refreshCalendar() => _syncHistory(force: true);

  String? _lastHistory;
  void _syncHistory({bool force = false}) {
    final snapshot = jsonEncode(repository.data['sessions']);
    if (!force && snapshot == _lastHistory) return;
    _lastHistory = snapshot;
    if (isClosed) return;
    final history = repository.sessions;
    emit(
      state.copyWith(
        sessionHistory: history,
        completedSessions: history.length,
        totalFocusMinutes: history.fold<int>(0, (n, s) => n + s.minutes),
      ),
    );
  }

  Future<void> loadFocusData() async {
    await repository.load();
    if (isClosed) return;
    _timer?.cancel();
    _endsAt = null;
    _sessionId = null;
    _syncHistory();
    final minutes = (repository.data['selectedMinutes'] as int).clamp(1, 180);
    final active = repository.data['active'] as Map?;
    emit(
      state.copyWith(
        selectedMinutes: minutes,
        remainingSeconds: minutes * 60,
        status: FocusStatus.ready,
      ),
    );
    if (active == null) return;
    _sessionId = active['id'] as String;
    final duration = (active['minutes'] as int).clamp(1, 180);
    final running = active['running'] == true;
    _endsAt = running ? DateTime.parse(active['endsAt'] as String) : null;
    emit(
      state.copyWith(
        selectedMinutes: duration,
        remainingSeconds: (active['remaining'] as int).clamp(0, duration * 60),
        status: running ? FocusStatus.running : FocusStatus.paused,
      ),
    );
    if (running) {
      await reconcile();
      if (state.isRunning) _schedule();
    }
  }

  void start() {
    if (state.isRunning || _finishing || _resetting || isClosed) return;
    if (state.status == FocusStatus.paused && state.remainingSeconds == 0) {
      unawaited(retryCompletion());
      return;
    }
    if (state.status != FocusStatus.paused || _sessionId == null) {
      _sessionId = newEventId();
      emit(state.copyWith(remainingSeconds: state.selectedMinutes * 60));
    }
    _endsAt = clock().add(Duration(seconds: state.remainingSeconds));
    emit(state.copyWith(status: FocusStatus.running));
    unawaited(_persistActive());
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer.periodic(tickDuration, (_) => unawaited(reconcile()));
  }

  /// Called on ticks and on lifecycle resume. Ticks never represent elapsed time.
  Future<void> reconcile() async {
    if (!state.isRunning || _endsAt == null || _resetting || isClosed) return;
    final remaining = (_endsAt!.difference(clock()).inMilliseconds / 1000)
        .ceil()
        .clamp(0, state.selectedMinutes * 60);
    if (remaining == 0) {
      _completion ??= _complete();
      await _completion;
      _completion = null;
    } else if (remaining != state.remainingSeconds) {
      emit(state.copyWith(remainingSeconds: remaining));
    }
  }

  void pause() {
    if (!state.isRunning || _finishing || _resetting) return;
    final remaining = ((_endsAt!.difference(clock()).inMilliseconds) / 1000)
        .ceil()
        .clamp(0, state.selectedMinutes * 60);
    if (remaining == 0) {
      unawaited(reconcile());
      return;
    }
    _timer?.cancel();
    _endsAt = null;
    emit(
      state.copyWith(remainingSeconds: remaining, status: FocusStatus.paused),
    );
    unawaited(_persistActive());
  }

  void toggle() => state.isRunning ? pause() : start();

  void reset() {
    if (_finishing || _resetting || isClosed) return;
    _timer?.cancel();
    _endsAt = null;
    _sessionId = null;
    emit(
      state.copyWith(
        remainingSeconds: state.selectedMinutes * 60,
        status: FocusStatus.ready,
      ),
    );
    unawaited(_persistActive());
  }

  void prepareNextSession() {
    reset();
    unawaited(selectDuration(repository.settings['duration'] as int));
  }

  Future<void> stopForReset() async {
    if (_completion != null) await _completion;
    reset();
    await repository.flush();
  }

  Future<void> selectDuration(int minutes) async {
    if (state.isRunning ||
        state.status == FocusStatus.paused ||
        _finishing ||
        _resetting ||
        minutes < 1 ||
        minutes > 180) {
      return;
    }
    _timer?.cancel();
    _endsAt = null;
    _sessionId = null;
    emit(
      state.copyWith(
        selectedMinutes: minutes,
        remainingSeconds: minutes * 60,
        status: FocusStatus.ready,
      ),
    );
    await _persistActive();
  }

  int _activeRevision = 0;
  Future<bool> _persistActive() async {
    final revision = ++_activeRevision;
    final minutes = state.selectedMinutes;
    final active = _sessionId == null
        ? null
        : {
            'id': _sessionId,
            'minutes': minutes,
            'remaining': state.remainingSeconds,
            'running': state.isRunning,
            'endsAt': _endsAt?.toIso8601String(),
          };
    final saved = await repository.update((d) {
      d['selectedMinutes'] = minutes;
      d['active'] = active;
    }, evaluate: false);
    if (!saved && !isClosed && revision == _activeRevision) {
      _restorePersistedTimer();
    }
    return saved;
  }

  void _restorePersistedTimer() {
    _timer?.cancel();
    final active = repository.data['active'] as Map?;
    final minutes = (repository.data['selectedMinutes'] as int).clamp(1, 180);
    if (active == null) {
      _sessionId = null;
      _endsAt = null;
      emit(
        state.copyWith(
          selectedMinutes: minutes,
          remainingSeconds: minutes * 60,
          status: FocusStatus.ready,
        ),
      );
      return;
    }
    _sessionId = active['id'] as String;
    final running = active['running'] == true;
    _endsAt = running ? DateTime.parse(active['endsAt'] as String) : null;
    emit(
      state.copyWith(
        selectedMinutes: active['minutes'] as int,
        remainingSeconds: active['remaining'] as int,
        status: running ? FocusStatus.running : FocusStatus.paused,
      ),
    );
    if (running) _schedule();
  }

  Future<void> _complete() async {
    if (_finishing || _sessionId == null) return;
    _finishing = true;
    _timer?.cancel();
    final id = _sessionId!;
    final session = FocusSession(
      id: id,
      minutes: state.selectedMinutes,
      completedAt: (_endsAt ?? clock()).toLocal(),
    );
    final saved = await repository.update((d) {
      final history = d['sessions'] as List;
      final rewards = d['rewardIds'] as List;
      if (!rewards.contains('focus:$id')) {
        if (!history.any((s) => s['id'] == id)) {
          history.add(session.toJson());
          d['xp'] = (d['xp'] as int) + Rewards.focusXp(session.minutes);
        }
        rewards.add('focus:$id');
      }
      d['active'] = null;
    });
    if (!isClosed) {
      if (saved) {
        _endsAt = null;
        _sessionId = null;
        emit(
          state.copyWith(remainingSeconds: 0, status: FocusStatus.completed),
        );
      } else {
        // Keep the durable active session and stable ID for an explicit retry.
        emit(state.copyWith(remainingSeconds: 0, status: FocusStatus.paused));
      }
    }
    _finishing = false;
  }

  Future<void> retryCompletion() async {
    if (_sessionId == null ||
        state.remainingSeconds != 0 ||
        _resetting ||
        isClosed) {
      return;
    }
    _completion ??= _complete();
    await _completion;
    _completion = null;
  }

  Future<bool> resetHistory() => _resetStoredData('focus');
  Future<bool> resetAllData() => _resetStoredData('all');

  Future<bool> _resetStoredData(String scope) async {
    if (_resetting || isClosed) return false;
    _resetting = true;
    try {
      if (_completion != null) await _completion;
      _timer?.cancel();
      // Reload committed state even if later legacy/native cleanup failed.
      final saved = await repository.reset(scope);
      if (!isClosed) await loadFocusData();
      return saved;
    } finally {
      _resetting = false;
      if (!isClosed && state.isRunning) {
        await reconcile();
        if (state.isRunning) _schedule();
      }
    }
  }

  @override
  Future<void> close() async {
    _timer?.cancel();
    if (_completion != null) await _completion;
    await repository.flush();
    await _subscription.cancel();
    return super.close();
  }
}
