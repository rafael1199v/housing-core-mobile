import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:housing_core/housing_core.dart';

String _makeJwt(Map<String, dynamic> payload) {
  String seg(Map<String, dynamic> m) =>
      base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  final header = seg({'alg': 'none', 'typ': 'JWT'});
  return '$header.${seg(payload)}.sig';
}

void main() {
  group('AppRole', () {
    test('fromWire parses known roles case-insensitively', () {
      expect(AppRole.fromWire('Student'), AppRole.student);
      expect(AppRole.fromWire('householder'), AppRole.householder);
      expect(AppRole.fromWire('ADMIN'), AppRole.admin);
      expect(AppRole.fromWire('nope'), isNull);
      expect(AppRole.fromWire(null), isNull);
    });

    test('fromWireList drops unknown values', () {
      expect(
        AppRole.fromWireList(['Student', 'bogus', 'Householder']),
        [AppRole.student, AppRole.householder],
      );
    });
  });

  group('RoleHierarchy.assignableFor (symmetric)', () {
    test('householder-only can acquire student', () {
      expect(
        RoleHierarchy.assignableFor([AppRole.householder]),
        [AppRole.student],
      );
    });

    test('student-only can acquire householder', () {
      expect(
        RoleHierarchy.assignableFor([AppRole.student]),
        [AppRole.householder],
      );
    });

    test('holding both leaves nothing assignable', () {
      expect(
        RoleHierarchy.assignableFor([AppRole.student, AppRole.householder]),
        isEmpty,
      );
    });

    test('admin is never self-assignable', () {
      expect(RoleHierarchy.assignableFor(const []), isNot(contains(AppRole.admin)));
    });
  });

  group('RoleHierarchy.defaultActive', () {
    test('householder preferred when both held', () {
      expect(
        RoleHierarchy.defaultActive([AppRole.student, AppRole.householder]),
        AppRole.householder,
      );
    });

    test('single role returns that role', () {
      expect(RoleHierarchy.defaultActive([AppRole.student]), AppRole.student);
    });

    test('empty returns null', () {
      expect(RoleHierarchy.defaultActive(const []), isNull);
    });
  });

  group('CurrentUserService.rolesFromToken', () {
    test('single string role', () {
      final jwt = _makeJwt({'sub': 'u1', 'role': 'Householder'});
      expect(CurrentUserService.rolesFromToken(jwt), ['Householder']);
    });

    test('array of roles', () {
      final jwt = _makeJwt({
        'role': ['Householder', 'Student'],
      });
      expect(
        CurrentUserService.rolesFromToken(jwt),
        ['Householder', 'Student'],
      );
    });

    test('missing role claim returns empty', () {
      final jwt = _makeJwt({'sub': 'u1'});
      expect(CurrentUserService.rolesFromToken(jwt), isEmpty);
    });

    test('malformed token returns empty', () {
      expect(CurrentUserService.rolesFromToken('not-a-jwt'), isEmpty);
    });
  });
}
