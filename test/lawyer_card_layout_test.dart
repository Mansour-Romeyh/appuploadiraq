import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dill_adala/widgets/lawyer_card.dart';
import 'package:dill_adala/models/lawyer.dart';
import 'package:dill_adala/i18n/localized.dart';

Lawyer _sample({required String photo}) => Lawyer(
      id: 'محامي كرار',
      name: const Localized(ar: 'المحامي كرار عباس'),
      title: const Localized(ar: 'المدير المفوض'),
      specialty: const Localized(ar: ''),
      experience: 10,
      cases: 200,
      bio: const Localized(ar: ''),
      education: const Localized(ar: ''),
      phone: '',
      email: '',
      available: true,
      nextAvailable: const Localized(ar: ''),
      photoUrl: photo,
    );

void main() {
  testWidgets('LawyerCard WITH photo lays out (no exception)', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ListView(children: [
          LawyerCard(lawyer: _sample(photo: '/files/director-karrar.jpeg'), onPress: () {}),
        ]),
      ),
    ));
    await tester.pump();
    final ex = tester.takeException();
    // ignore: avoid_print
    print('EXCEPTION (with photo) = $ex');
    expect(ex, isNull);
  });

  testWidgets('LawyerCard WITHOUT photo (initials) lays out', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ListView(children: [
          LawyerCard(lawyer: _sample(photo: ''), onPress: () {}),
        ]),
      ),
    ));
    await tester.pump();
    final ex = tester.takeException();
    // ignore: avoid_print
    print('EXCEPTION (initials) = $ex');
    expect(ex, isNull);
  });
}
