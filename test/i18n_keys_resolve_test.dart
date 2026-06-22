import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:dill_adala/i18n/strings.dart';

/// Guards every screen/widget migration: scans all of `lib/` (except the i18n
/// catalog itself) for `t('key')` / `.t('key')` usages and asserts each key
/// exists in the flattened catalog. A mistyped or invented key resolves
/// silently to the key string at runtime, so this test is the safety net.
void main() {
  test('all t() keys used in lib resolve to a catalog entry', () {
    final keyRe = RegExp('''\\bt\\(\\s*['"]([^'"]+)['"]''');
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart') && !f.path.contains('/i18n/'));

    final missing = <String>[];
    for (final f in files) {
      final src = f.readAsStringSync();
      for (final m in keyRe.allMatches(src)) {
        final key = m.group(1)!;
        // Skip runtime-interpolated keys (e.g. t('cases.status.$s')): the base
        // entries (cases.status.*, profile.method.*) exist and are verified by
        // the catalog tests; a static scan can't resolve the interpolated part.
        if (key.contains(r'$')) continue;
        if (!dict.containsKey(key)) missing.add('${f.path}: "$key"');
      }
    }

    expect(
      missing,
      isEmpty,
      reason: 'Unresolved i18n keys:\n${missing.join('\n')}',
    );
  });
}
