import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dill_adala/widgets/entity_picker_sheet.dart';

void main() {
  setUp(EntityPickerSheet.clearCacheForTest);

  Future<void> open(
    WidgetTester tester,
    Future<List<PickerOption>> Function(String q) search, {
    void Function(PickerOption)? onPick,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showEntityPicker(
              context,
              title: 'Test',
              cacheScope: 'test',
              search: search,
              onPick: onPick ?? (_) {},
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('empty query loads default list immediately', (tester) async {
    var calls = <String>[];
    await open(tester, (q) async {
      calls.add(q);
      return [const PickerOption(id: '1', label: 'Alpha')];
    });
    expect(calls, ['']);
    expect(find.text('Alpha'), findsOneWidget);
  });

  testWidgets('typing debounces 250ms then searches', (tester) async {
    var calls = <String>[];
    await open(tester, (q) async {
      calls.add(q);
      return q.isEmpty
          ? [const PickerOption(id: '1', label: 'Alpha')]
          : [const PickerOption(id: '2', label: 'Beta')];
    });
    await tester.enterText(find.byType(TextField), 'b');
    await tester.pump(const Duration(milliseconds: 100));
    expect(calls, ['']); // not yet — still inside debounce window
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(calls, ['', 'b']);
    expect(find.text('Beta'), findsOneWidget);
  });

  testWidgets('cache hit skips the search call', (tester) async {
    var calls = 0;
    Future<List<PickerOption>> search(String q) async {
      calls++;
      return [const PickerOption(id: '1', label: 'Alpha')];
    }

    await open(tester, search);
    expect(calls, 1);
    // Close and reopen — same cacheScope → served from cache.
    await tester.tapAt(const Offset(10, 10)); // backdrop dismiss
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(find.text('Alpha'), findsOneWidget);
  });

  testWidgets('pick returns the option and closes', (tester) async {
    PickerOption? picked;
    await open(
      tester,
      (q) async => [const PickerOption(id: '7', label: 'Gamma', meta: 99)],
      onPick: (o) => picked = o,
    );
    await tester.tap(find.text('Gamma'));
    await tester.pumpAndSettle();
    expect(picked?.id, '7');
    expect(picked?.meta, 99);
    expect(find.text('Gamma'), findsNothing); // sheet closed
  });
}
