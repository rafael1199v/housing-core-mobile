import 'package:flutter/foundation.dart';

class SessionNotifier extends ChangeNotifier {
  bool _isAuthenticated;
  bool get isAuthenticated => _isAuthenticated;

  SessionNotifier({bool isAuthenticated = false})
    : _isAuthenticated = isAuthenticated;

  void set(bool value) {
    if (_isAuthenticated == value) return;
    _isAuthenticated = value;
    notifyListeners();
  }

  void signedIn() => set(true);
  void signedOut() => set(false);
}
