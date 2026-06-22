import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';

enum AuthMethod { google, apple, phone }

class AuthUser {
  final String name;
  final String? phone;
  final String? email;
  final AuthMethod method;

  /// Frappe API credentials returned by verify_otp; sent as
  /// `Authorization: token apiKey:apiSecret` on authenticated calls.
  final String? apiKey;
  final String? apiSecret;

  /// True when the backend flagged this account as a lawyer (verify_otp → user.is_lawyer).
  /// Gates the Office tab.
  final bool isLawyer;

  const AuthUser({
    required this.name,
    this.phone,
    this.email,
    required this.method,
    this.apiKey,
    this.apiSecret,
    this.isLawyer = false,
  });

  /// A usable auth token only when both credentials are present (i.e. a real
  /// phone/OTP login, not a mock social login).
  AuthToken? get token => (apiKey != null && apiSecret != null)
      ? AuthToken(apiKey: apiKey!, apiSecret: apiSecret!)
      : null;

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    'email': email,
    'method': method.name,
    'isLawyer': isLawyer,
    'apiKey': apiKey,
    'apiSecret': apiSecret,
  };

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    name: json['name'] as String? ?? '',
    phone: json['phone'] as String?,
    email: json['email'] as String?,
    method: AuthMethod.values.firstWhere(
      (m) => m.name == json['method'],
      orElse: () => AuthMethod.phone,
    ),
    isLawyer: json['isLawyer'] == true,
    apiKey: json['apiKey'] as String?,
    apiSecret: json['apiSecret'] as String?,
  );
}

/// App-wide auth state persisted in SharedPreferences
/// (ported from context/AuthContext.tsx).
class AuthService extends ChangeNotifier {
  AuthService._();

  static final AuthService instance = AuthService._();

  static const _authKey = 'law_firm_auth_v1';
  static const _guestKey = 'law_firm_guest_v1';

  AuthUser? _user;
  bool _isGuest = false;
  bool _isReady = false;

  AuthUser? get user => _user;
  bool get isGuest => _isGuest;
  bool get isReady => _isReady;
  bool get hasAuth => _user != null || _isGuest;
  bool get isLawyer => _user?.isLawyer ?? false;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_authKey);
      if (stored != null) {
        _user = AuthUser.fromJson(jsonDecode(stored) as Map<String, dynamic>);
      } else if (prefs.getBool(_guestKey) ?? false) {
        _isGuest = true;
      }
    } finally {
      _isReady = true;
      notifyListeners();
    }
  }

  Future<void> login(AuthUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_authKey, jsonEncode(user.toJson()));
    await prefs.remove(_guestKey);
    _user = user;
    _isGuest = false;
    notifyListeners();
  }

  Future<void> continueAsGuest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_guestKey, true);
    await prefs.remove(_authKey);
    _isGuest = true;
    _user = null;
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authKey);
    await prefs.remove(_guestKey);
    _user = null;
    _isGuest = false;
    notifyListeners();
  }
}
