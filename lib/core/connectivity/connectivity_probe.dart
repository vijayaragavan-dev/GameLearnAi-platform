import 'dart:async';
import 'package:flutter/foundation.dart';

/// Lightweight connectivity probe — used by offline UX layer.
/// Reuses existing app lifecycle patterns and does not pull in heavy packages.
class ConnectivityProbe {
  ConnectivityProbe({Duration timeout = const Duration(seconds: 3)})
      : _timeout = timeout;

  final Duration _timeout;

  Future<bool> reachable({Future<bool> Function()? check}) async {
    if (check != null) return await check();
    return true; // optimistic default; only flag offline on API failures
  }
}

/// Global flag consulted by screens to render truthful stale/offline state.
/// Set by the offline banner; reset by the API client on a successful request.
class OfflineState extends ChangeNotifier {
  bool _offline = false;
  bool get offline => _offline;

  void mark() {
    if (_offline) return;
    _offline = true;
    notifyListeners();
  }

  void clear() {
    if (!_offline) return;
    _offline = false;
    notifyListeners();
  }
}
