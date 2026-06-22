import 'package:flutter_test/flutter_test.dart';

import 'package:dill_adala/models/office.dart';

void main() {
  test('IntakeListItem parses', () {
    final it = IntakeListItem.fromJson({
      'name': 'INT-001',
      'posting_date': '2026-06-01',
      'item_name': 'قضية مدنية',
      'client_names': 'أحمد، سارة',
      'docstatus': 1,
    });
    expect(it.name, 'INT-001');
    expect(it.docstatus, 1);
    expect(it.clientNames, 'أحمد، سارة');
  });

  test('IntakeDoc parses with party rows', () {
    final doc = IntakeDoc.fromJson({
      'name': 'INT-002',
      'posting_date': '2026-06-02',
      'docstatus': 0,
      'item': 'ITEM-1',
      'clients': [
        {'client': 'CUST-1', 'customer_full_name': 'أحمد'},
        {'customer_full_name': 'سارة', 'national_id': '123'},
      ],
      'defendants': [],
    });
    expect(doc.clients, hasLength(2));
    expect(doc.clients[0].client, 'CUST-1');
    expect(doc.clients[1].nationalId, '123');
    expect(doc.defendants, isEmpty);
  });

  test('IntakeCreatePayload serializes only set fields', () {
    const payload = IntakeCreatePayload(
      itemGroup: 'G1',
      clients: [IntakeParty(customerFullName: 'أحمد')],
    );
    final json = payload.toJson();
    expect(json['item_group'], 'G1');
    expect(json.containsKey('item'), isFalse);
    expect((json['clients'] as List).first['customer_full_name'], 'أحمد');
  });

  test('IntakeParty serializes explicit null client (unlink)', () {
    const row = IntakeParty(client: null, customerFullName: 'typed name');
    expect(row.toJson(), {'customer_full_name': 'typed name'});
  });

  test('OfferDoc parses items and totals', () {
    final doc = OfferDoc.fromJson({
      'name': 'QTN-001',
      'customer': 'CUST-1',
      'customer_name': 'أحمد',
      'transaction_date': '2026-06-03',
      'grand_total': 1500000,
      'status': 'Draft',
      'items': [
        {'item_code': 'SRV-1', 'item_name': 'استشارة', 'qty': 2, 'rate': 750000, 'amount': 1500000},
      ],
    });
    expect(doc.items, hasLength(1));
    expect(doc.items.first.qty, 2);
    expect(doc.grandTotal, 1500000);
  });

  test('OfferCreatePayload serializes', () {
    const payload = OfferCreatePayload(
      customer: 'CUST-1',
      items: [OfferItem(itemCode: 'SRV-1', itemName: 'استشارة', qty: 1, rate: 100)],
    );
    final json = payload.toJson();
    expect(json['customer'], 'CUST-1');
    expect(json.containsKey('title'), isFalse);
    expect((json['items'] as List).first['item_code'], 'SRV-1');
  });

  test('groupThousands formats like toLocaleString', () {
    expect(groupThousands(0), '0');
    expect(groupThousands(1500000), '1,500,000');
    expect(groupThousands(999), '999');
    expect(groupThousands(1234.5), '1,234.5');
    expect(groupThousands(-1234567), '-1,234,567');
  });
}
