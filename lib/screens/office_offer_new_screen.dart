import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../i18n/strings.dart';
import '../models/office.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/entity_picker_sheet.dart';
import '../widgets/office_field_decoration.dart';
import 'office_offer_detail_screen.dart';

/// New offer (Quotation) create form
/// (ported from app/office/offer/new.tsx).
class OfficeOfferNewScreen extends StatefulWidget {
  const OfficeOfferNewScreen({super.key});

  @override
  State<OfficeOfferNewScreen> createState() => _OfficeOfferNewScreenState();
}

class _OfficeOfferNewScreenState extends State<OfficeOfferNewScreen> {
  ({String id, String name})? _customer;
  final TextEditingController _title = TextEditingController();
  final List<OfferItem> _items = [];
  final List<int> _itemIds = [];
  int _nextItemId = 0;
  bool _saving = false;

  num get _total =>
      _items.fold<num>(0, (sum, it) => sum + it.qty * it.rate);

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _showError(String key) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(t(key))));
  }

  Future<void> _save() async {
    final auth = AuthService.instance.user?.token;
    if (auth == null) return;
    if (_customer == null) {
      _showError('office.customerRequired');
      return;
    }
    final clean =
        _items.where((it) => it.itemCode.isNotEmpty).toList();
    if (clean.isEmpty) {
      _showError('office.itemRequired');
      return;
    }
    setState(() => _saving = true);
    try {
      final name = await ApiService.instance.lawyerCreateOffer(
        OfferCreatePayload(
          customer: _customer!.id,
          title: _title.text,
          items: clean,
        ),
        auth,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OfficeOfferDetailScreen(name: name),
        ),
      );
    } catch (_) {
      if (mounted) _showError('office.saveFailed');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _openCustomerPicker() => showEntityPicker(
    context,
    title: t('office.customer'),
    cacheScope: 'customers',
    search: (q) async {
      final auth = AuthService.instance.user?.token;
      if (auth == null) return const [];
      final hits = await ApiService.instance.lawyerSearchCustomers(q, auth);
      return [
        for (final c in hits)
          PickerOption(
            id: c.name,
            label: c.displayName,
            sublabel: c.name,
          ),
      ];
    },
    onPick: (o) => setState(() {
      _customer = (id: o.id, name: o.label);
    }),
  );

  void _openItemPicker() => showEntityPicker(
    context,
    title: t('office.items'),
    cacheScope: 'offer-items',
    search: (q) async {
      final auth = AuthService.instance.user?.token;
      if (auth == null) return const [];
      final hits = await ApiService.instance.lawyerSearchItems(q, auth);
      return [
        for (final it in hits)
          PickerOption(
            id: it.itemCode,
            label: it.itemName ?? it.itemCode,
            sublabel: it.itemCode,
            meta: it.standardRate,
          ),
      ];
    },
    onPick: (o) => setState(() {
      _items.add(
        OfferItem(
          itemCode: o.id,
          itemName: o.label,
          qty: 1,
          rate: o.meta ?? 0,
        ),
      );
      _itemIds.add(_nextItemId++);
    }),
  );

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: topPadding + 16,
          left: 18,
          right: 18,
          bottom: 160 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0x26FFFFFF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    t('office.newOffer'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.foreground,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 14),
            // Customer picker
            PickerField(
              value: _customer?.name ?? '',
              placeholder: t('office.customer'),
              onTap: _openCustomerPicker,
            ),
            const SizedBox(height: 10),
            // Title field
            TextField(
              controller: _title,
              decoration: officeFieldDecoration(t('office.title')),
              style: const TextStyle(color: AppColors.foreground),
            ),
            const SizedBox(height: 18),
            // Items header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  t('office.items'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gold,
                  ),
                ),
                TextButton(
                  onPressed: _openItemPicker,
                  child: Text(
                    '+ ${t('office.addRow')}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.gold,
                    ),
                  ),
                ),
              ],
            ),
            // Item rows
            for (var i = 0; i < _items.length; i++)
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.gold),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _items[i].itemName ?? _items[i].itemCode,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.foreground,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            key: ValueKey('qty-${_itemIds[i]}'),
                            initialValue: '${_items[i].qty}',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[\d.]'),
                              ),
                            ],
                            onChanged: (v) => setState(
                              () => _items[i] = _items[i]
                                  .copyWith(qty: num.tryParse(v) ?? 0),
                            ),
                            decoration: officeFieldDecoration(t('office.qty')),
                            style:
                                const TextStyle(color: AppColors.foreground),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            key: ValueKey('rate-${_itemIds[i]}'),
                            initialValue: '${_items[i].rate}',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[\d.]'),
                              ),
                            ],
                            onChanged: (v) => setState(
                              () => _items[i] = _items[i]
                                  .copyWith(rate: num.tryParse(v) ?? 0),
                            ),
                            decoration:
                                officeFieldDecoration(t('office.rate')),
                            style:
                                const TextStyle(color: AppColors.foreground),
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        _items.removeAt(i);
                        _itemIds.removeAt(i);
                      }),
                      child: Text(
                        t('office.remove'),
                        style: const TextStyle(
                          color: AppColors.destructive,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  t('office.total'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mutedForeground,
                  ),
                ),
                Text(
                  groupThousands(_total),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                _saving ? t('office.saving') : t('office.save'),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
