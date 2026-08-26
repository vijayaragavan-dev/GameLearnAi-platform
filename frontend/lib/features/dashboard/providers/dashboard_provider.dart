import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/dashboard_models.dart';
import '../../../core/providers.dart';

/// DASH-001 read state with explicit data/error so the UI never depends on
/// framework-specific async-transition semantics.
class DashboardState {
  const DashboardState({this.data, this.error, this.loading = false});

  final Dashboard? data;
  final Object? error;
  final bool loading;

  bool get showLoading => loading && data == null;

  DashboardState copyWith({
    Dashboard? data,
    bool clearData = false,
    Object? error,
    bool clearError = false,
    bool? loading,
  }) => DashboardState(
    data: clearData ? null : (data ?? this.data),
    error: clearError ? null : (error ?? this.error),
    loading: loading ?? this.loading,
  );
}

final dashboardProvider = NotifierProvider<DashboardController, DashboardState>(
  DashboardController.new,
);

class DashboardController extends Notifier<DashboardState> {
  @override
  DashboardState build() {
    Future<void>.microtask(load);
    return const DashboardState(loading: true);
  }

  Future<void> load() async {
    if (state.loading && state.data != null) return; // refresh handles reloads
    state = state.copyWith(loading: true, clearError: true);
    try {
      final d = await ref.read(intelligenceRepoProvider).dashboard();
      state = DashboardState(data: d);
    } catch (e) {
      state = state.copyWith(loading: false, error: e);
    }
  }

  /// Pull-to-refresh: re-fetch without blanking existing content.
  Future<void> refresh() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final fresh = await ref.read(intelligenceRepoProvider).dashboard();
      state = DashboardState(data: fresh);
    } catch (e) {
      state = state.copyWith(loading: false, error: e);
    }
  }
}
