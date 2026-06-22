import 'package:flutter_test/flutter_test.dart';

import 'package:dill_adala/i18n/lang.dart';
import 'package:dill_adala/i18n/strings.dart';

void main() {
  test('office keys resolve in all three languages', () {
    expect(translate('office.hubTitle', Lang.ar), 'مكتبي');
    expect(translate('office.hubTitle', Lang.en), 'My Office');
    expect(translate('office.hubTitle', Lang.ku), 'نووسینگەکەم');
    expect(translate('office.countOfMine', Lang.en, vars: {'n': 3}),
        '3 of mine');
    expect(translate('office.draft', Lang.en), 'Draft');
    expect(translate('office.submitted', Lang.en), 'Submitted');
    expect(translate('office.confirmSubmit', Lang.en),
        'Submit this intake? This cannot be undone.');
  });

  test('notifications keys resolve', () {
    expect(translate('notifications.screenTitle', Lang.ar), 'الإشعارات');
    expect(translate('notifications.screenTitle', Lang.en), 'Notifications');
    expect(translate('notifications.empty', Lang.ku),
        'هیچ ئاگادارکردنەوەیەک نییە ئێستا');
  });

  test('office tab label registered in common', () {
    expect(translate('common.tab.office', Lang.ar), 'مكتبي');
    expect(translate('common.tab.office', Lang.en), 'Office');
  });
}
