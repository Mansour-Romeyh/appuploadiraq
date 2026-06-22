// Office (lawyer workspace) data models.
// Ported from law-firm-app/lib/api.ts: IntakeParty, IntakeListItem,
// IntakeDoc, IntakeCreatePayload, OfferItem, OfferListItem, OfferDoc,
// OfferCreatePayload, CustomerHit, ItemHit, ItemGroupHit.

/// Format an amount with thousands separators — the Dart stand-in for the
/// reference app's `Number.toLocaleString()`. Keeps any decimal part as-is.
String groupThousands(num n) {
  final s = n.toString();
  final dot = s.indexOf('.');
  final intPart = dot == -1 ? s : s.substring(0, dot);
  final decPart = dot == -1 ? '' : s.substring(dot);
  final negative = intPart.startsWith('-');
  final digits = negative ? intPart.substring(1) : intPart;
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  return '${negative ? '-' : ''}$buf$decPart';
}

/// One client/defendant row. `client` is the linked Customer id when picked
/// from the list, and null when the lawyer typed a free-form name (unlinked).
class IntakeParty {
  final String? client;
  final String? customerFullName;
  final String? nationalId;

  const IntakeParty({this.client, this.customerFullName, this.nationalId});

  factory IntakeParty.fromJson(Map<String, dynamic> j) => IntakeParty(
    client: j['client'] as String?,
    customerFullName: j['customer_full_name'] as String?,
    nationalId: j['national_id'] as String?,
  );

  Map<String, dynamic> toJson() => {
    if (client != null) 'client': client,
    if (customerFullName != null) 'customer_full_name': customerFullName,
    if (nationalId != null && nationalId!.isNotEmpty) 'national_id': nationalId,
  };
}

class IntakeListItem {
  final String name;
  final String postingDate;
  final String? itemName;
  final String? clientNames;

  /// 0 = draft, 1 = submitted.
  final int docstatus;

  const IntakeListItem({
    required this.name,
    required this.postingDate,
    this.itemName,
    this.clientNames,
    required this.docstatus,
  });

  factory IntakeListItem.fromJson(Map<String, dynamic> j) => IntakeListItem(
    name: j['name'] as String? ?? '',
    postingDate: j['posting_date']?.toString() ?? '',
    itemName: j['item_name'] as String?,
    clientNames: j['client_names'] as String?,
    docstatus: (j['docstatus'] as num?)?.toInt() ?? 0,
  );
}

class IntakeDoc {
  final String name;
  final String postingDate;
  final int docstatus;
  final String? itemGroup;
  final String? item;
  final String? itemName;
  final String? intakeDescription;
  final String? managementDescription;
  final List<IntakeParty> clients;
  final List<IntakeParty> defendants;

  const IntakeDoc({
    required this.name,
    required this.postingDate,
    required this.docstatus,
    this.itemGroup,
    this.item,
    this.itemName,
    this.intakeDescription,
    this.managementDescription,
    required this.clients,
    required this.defendants,
  });

  factory IntakeDoc.fromJson(Map<String, dynamic> j) => IntakeDoc(
    name: j['name'] as String? ?? '',
    postingDate: j['posting_date']?.toString() ?? '',
    docstatus: (j['docstatus'] as num?)?.toInt() ?? 0,
    itemGroup: j['item_group'] as String?,
    item: j['item'] as String?,
    itemName: j['item_name'] as String?,
    intakeDescription: j['intake_description'] as String?,
    managementDescription: j['management_description'] as String?,
    clients: _parties(j['clients']),
    defendants: _parties(j['defendants']),
  );

  static List<IntakeParty> _parties(Object? raw) => ((raw as List?) ?? const [])
      .whereType<Map>()
      .map((e) => IntakeParty.fromJson(e.cast<String, dynamic>()))
      .toList();
}

class IntakeCreatePayload {
  final String? itemGroup;
  final String? item;
  final String? itemName;
  final List<IntakeParty> clients;
  final List<IntakeParty> defendants;
  final String? intakeDescription;
  final String? managementDescription;

  const IntakeCreatePayload({
    this.itemGroup,
    this.item,
    this.itemName,
    required this.clients,
    this.defendants = const [],
    this.intakeDescription,
    this.managementDescription,
  });

  Map<String, dynamic> toJson() => {
    if (itemGroup != null && itemGroup!.isNotEmpty) 'item_group': itemGroup,
    if (item != null && item!.isNotEmpty) 'item': item,
    if (itemName != null && itemName!.isNotEmpty) 'item_name': itemName,
    'clients': clients.map((c) => c.toJson()).toList(),
    'defendants': defendants.map((d) => d.toJson()).toList(),
    if (intakeDescription != null && intakeDescription!.isNotEmpty)
      'intake_description': intakeDescription,
    if (managementDescription != null && managementDescription!.isNotEmpty)
      'management_description': managementDescription,
  };
}

class OfferItem {
  final String itemCode;
  final String? itemName;
  final num qty;
  final num rate;

  /// Server-computed; present on fetched docs, omitted on create.
  final num? amount;

  const OfferItem({
    required this.itemCode,
    this.itemName,
    required this.qty,
    required this.rate,
    this.amount,
  });

  factory OfferItem.fromJson(Map<String, dynamic> j) => OfferItem(
    itemCode: j['item_code'] as String? ?? '',
    itemName: j['item_name'] as String?,
    qty: (j['qty'] as num?) ?? 0,
    rate: (j['rate'] as num?) ?? 0,
    amount: j['amount'] as num?,
  );

  Map<String, dynamic> toJson() => {
    'item_code': itemCode,
    if (itemName != null) 'item_name': itemName,
    'qty': qty,
    'rate': rate,
  };

  OfferItem copyWith({num? qty, num? rate}) => OfferItem(
    itemCode: itemCode,
    itemName: itemName,
    qty: qty ?? this.qty,
    rate: rate ?? this.rate,
    amount: amount,
  );
}

class OfferListItem {
  final String name;
  final String customer;
  final String? customerName;

  /// Linked customer's full legal name (custom field on Customer). Preferred
  /// over `customer_name`, which holds only the first name.
  final String? customFullName;
  final String transactionDate;
  final num grandTotal;
  final String status;

  const OfferListItem({
    required this.name,
    required this.customer,
    this.customerName,
    this.customFullName,
    required this.transactionDate,
    required this.grandTotal,
    required this.status,
  });

  factory OfferListItem.fromJson(Map<String, dynamic> j) => OfferListItem(
    name: j['name'] as String? ?? '',
    customer: j['customer'] as String? ?? '',
    customerName: j['customer_name'] as String?,
    customFullName: j['custom_full_name'] as String?,
    transactionDate: j['transaction_date']?.toString() ?? '',
    grandTotal: (j['grand_total'] as num?) ?? 0,
    status: j['status'] as String? ?? '',
  );

  /// Label to show for the offer's customer: full name when available, then the
  /// first-name `customer_name`, falling back to the raw Customer id.
  String get customerDisplay {
    final full = customFullName?.trim();
    if (full != null && full.isNotEmpty) return full;
    final short = customerName?.trim();
    if (short != null && short.isNotEmpty) return short;
    return customer;
  }
}

class OfferDoc extends OfferListItem {
  final String? title;
  final String? deliveryDate;
  final String? project;
  final List<OfferItem> items;

  const OfferDoc({
    required super.name,
    required super.customer,
    super.customerName,
    super.customFullName,
    required super.transactionDate,
    required super.grandTotal,
    required super.status,
    this.title,
    this.deliveryDate,
    this.project,
    required this.items,
  });

  factory OfferDoc.fromJson(Map<String, dynamic> j) {
    final base = OfferListItem.fromJson(j);
    return OfferDoc(
      name: base.name,
      customer: base.customer,
      customerName: base.customerName,
      customFullName: base.customFullName,
      transactionDate: base.transactionDate,
      grandTotal: base.grandTotal,
      status: base.status,
      title: j['title'] as String?,
      deliveryDate: j['delivery_date']?.toString(),
      project: j['project'] as String?,
      items: ((j['items'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => OfferItem.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }
}

class OfferCreatePayload {
  final String customer;
  final String? title;
  final String? transactionDate;
  final String? deliveryDate;
  final String? project;
  final List<OfferItem> items;

  const OfferCreatePayload({
    required this.customer,
    this.title,
    this.transactionDate,
    this.deliveryDate,
    this.project,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
    'customer': customer,
    if (title != null && title!.isNotEmpty) 'title': title,
    if (transactionDate != null && transactionDate!.isNotEmpty)
      'transaction_date': transactionDate,
    if (deliveryDate != null && deliveryDate!.isNotEmpty)
      'delivery_date': deliveryDate,
    if (project != null && project!.isNotEmpty) 'project': project,
    'items': items.map((i) => i.toJson()).toList(),
  };
}

class CustomerHit {
  final String name;
  final String? customerName;

  /// Customer's full legal name (custom field on the Customer doctype).
  /// `customer_name` holds only the first name, so we prefer this when set.
  final String? customFullName;
  const CustomerHit({
    required this.name,
    this.customerName,
    this.customFullName,
  });

  factory CustomerHit.fromJson(Map<String, dynamic> j) => CustomerHit(
    name: j['name'] as String? ?? '',
    customerName: j['customer_name'] as String?,
    customFullName: j['custom_full_name'] as String?,
  );

  /// Label to show for this customer: full name when available, otherwise the
  /// first-name `customer_name`, falling back to the raw Customer id.
  String get displayName {
    final full = customFullName?.trim();
    if (full != null && full.isNotEmpty) return full;
    final short = customerName?.trim();
    if (short != null && short.isNotEmpty) return short;
    return name;
  }
}

class ItemHit {
  final String itemCode;
  final String? itemName;
  final num? standardRate;
  const ItemHit({required this.itemCode, this.itemName, this.standardRate});

  factory ItemHit.fromJson(Map<String, dynamic> j) => ItemHit(
    itemCode: j['item_code'] as String? ?? '',
    itemName: j['item_name'] as String?,
    standardRate: j['standard_rate'] as num?,
  );
}

class ItemGroupHit {
  final String name;
  const ItemGroupHit({required this.name});

  factory ItemGroupHit.fromJson(Map<String, dynamic> j) =>
      ItemGroupHit(name: j['name'] as String? ?? '');
}
