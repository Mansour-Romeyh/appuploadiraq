import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:dill_adala/services/auth_service.dart';

void main() {
  test('AuthUser round-trips isLawyer through JSON', () {
    const user = AuthUser(
      name: 'Test Lawyer',
      phone: '+9647700000000',
      method: AuthMethod.phone,
      isLawyer: true,
      apiKey: 'k',
      apiSecret: 's',
    );
    final decoded = AuthUser.fromJson(
      jsonDecode(jsonEncode(user.toJson())) as Map<String, dynamic>,
    );
    expect(decoded.isLawyer, isTrue);
    expect(decoded.name, 'Test Lawyer');
    expect(decoded.apiKey, 'k');
    expect(decoded.apiSecret, 's');
    expect(decoded.token, isNotNull);
  });

  test('AuthUser defaults isLawyer to false (old persisted sessions)', () {
    final decoded = AuthUser.fromJson({
      'name': 'Old User',
      'method': 'phone',
    });
    expect(decoded.isLawyer, isFalse);
  });
}
