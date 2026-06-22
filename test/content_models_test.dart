import 'package:flutter_test/flutter_test.dart';

import 'package:dill_adala/i18n/lang.dart';
import 'package:dill_adala/models/lawyer.dart';
import 'package:dill_adala/models/legal_service.dart';
import 'package:dill_adala/models/news_item.dart';

/// Locks the shape returned by `law_firm.api.mobile.{get_team,get_services,
/// get_news}` to the app models. If the backend renames a key these fail
/// loudly instead of silently rendering blanks.
void main() {
  test('Lawyer.fromJson maps the get_team shape', () {
    final l = Lawyer.fromJson(const {
      'id': 'LTM-001',
      'name': {'ar': 'محمد', 'en': 'Mohammed', 'ku': 'محمد'},
      'title': {'ar': 'محامٍ', 'en': 'Lawyer'},
      'specialty': {'ar': 'جنائي', 'en': 'Criminal'},
      'experience': 22,
      'cases': 480,
      'bio': {'ar': 'نبذة', 'en': 'Bio'},
      'education': {'ar': 'بغداد', 'en': 'Baghdad'},
      'phone': '+964 770 123 4567',
      'email': 'm@x.iq',
      'available': true,
      'nextAvailable': {'ar': 'الأحد', 'en': 'Sunday'},
      'photoUrl': '/files/m.jpg',
    });

    expect(l.id, 'LTM-001');
    expect(l.name.resolve(Lang.en), 'Mohammed');
    expect(l.name.resolve(Lang.ku), 'محمد');
    expect(l.experience, 22);
    expect(l.cases, 480);
    expect(l.available, isTrue);
    expect(l.nextAvailable.resolve(Lang.en), 'Sunday');
    expect(l.photoUrl, '/files/m.jpg');
  });

  test(
    'LegalService.fromJson keeps icon/color as strings and parses bullets',
    () {
      final s = LegalService.fromJson(const {
        'id': 'LS-1',
        'title': {'ar': 'الجنائي', 'en': 'Criminal'},
        'description': {'ar': 'وصف', 'en': 'Desc'},
        'details': {'ar': 'تفاصيل', 'en': 'Details'},
        'bullets': [
          {'ar': 'أ', 'en': 'a'},
          {'ar': 'ب', 'en': 'b'},
        ],
        'icon': 'shield',
        'color': '#C0392B',
      });

      expect(s.icon, 'shield');
      expect(s.color, '#C0392B');
      expect(s.bullets, hasLength(2));
      expect(s.bullets.first.resolve(Lang.en), 'a');
      expect(s.title.resolve(Lang.en), 'Criminal');
    },
  );

  test('NewsItem.fromJson keeps category key and localizes label', () {
    final n = NewsItem.fromJson(const {
      'id': 'LN-1',
      'category': 'تشريعات',
      'categoryLabel': {'ar': 'تشريعات', 'en': 'Legislation'},
      'title': {'ar': 'عنوان', 'en': 'Title'},
      'summary': {'ar': 'ملخص', 'en': 'Summary'},
      'content': {'ar': 'محتوى', 'en': 'Content'},
      'date': '2024-11-15',
      'imageUrl': 'https://x/y.jpg',
    });

    expect(n.category, 'تشريعات'); // stable key, never localized
    expect(n.categoryLabel.resolve(Lang.en), 'Legislation');
    expect(n.title.resolve(Lang.en), 'Title');
    expect(n.date, '2024-11-15');
    expect(n.imageUrl, 'https://x/y.jpg');
  });
}
