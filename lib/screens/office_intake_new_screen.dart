import 'package:flutter/material.dart';

import '../i18n/strings.dart';
import '../models/office.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/entity_picker_sheet.dart';
import '../widgets/office_field_decoration.dart';
import 'office_intake_detail_screen.dart';

/// One editable party row's controllers — kept outside build so TextFields
/// hold focus across rebuilds (the reference has the same concern).
class _PartyRowState {
  final TextEditingController name = TextEditingController(text: '');
  final TextEditingController nationalId = TextEditingController(text: '');
  String? client;

  void dispose() {
    name.dispose();
    nationalId.dispose();
  }

  IntakeParty toParty() => IntakeParty(
    client: client,
    customerFullName: name.text,
    nationalId: nationalId.text,
  );

  bool get isValid => name.text.trim().isNotEmpty || client != null;
}

/// New intake draft form (ported from app/office/intake/new.tsx).
class OfficeIntakeNewScreen extends StatefulWidget {
  const OfficeIntakeNewScreen({super.key});

  @override
  State<OfficeIntakeNewScreen> createState() => _OfficeIntakeNewScreenState();
}

class _OfficeIntakeNewScreenState extends State<OfficeIntakeNewScreen> {
  String _itemGroup = '';
  String _item = '';
  String _itemName = '';
  final List<_PartyRowState> _clients = [_PartyRowState()];
  final List<_PartyRowState> _defendants = [];
  final TextEditingController _description = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    for (final r in [..._clients, ..._defendants]) {
      r.dispose();
    }
    _description.dispose();
    super.dispose();
  }

  void _showError(String key) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(t(key))));
  }

  Future<void> _save() async {
    final auth = AuthService.instance.user?.token;
    if (auth == null) return;
    final cleanClients =
        _clients.where((r) => r.isValid).map((r) => r.toParty()).toList();
    if (cleanClients.isEmpty) {
      _showError('office.clientRequired');
      return;
    }
    setState(() => _saving = true);
    try {
      final name = await ApiService.instance.lawyerCreateIntake(
        IntakeCreatePayload(
          itemGroup: _itemGroup,
          item: _item,
          itemName: _itemName,
          clients: cleanClients,
          defendants: _defendants
              .where((r) => r.isValid)
              .map((r) => r.toParty())
              .toList(),
          intakeDescription: _description.text,
        ),
        auth,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OfficeIntakeDetailScreen(name: name),
        ),
      );
    } catch (_) {
      if (mounted) _showError('office.saveFailed');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _openGroupPicker() => showEntityPicker(
    context,
    title: t('office.itemGroup'),
    cacheScope: 'item-groups',
    search: (q) async {
      final auth = AuthService.instance.user?.token;
      if (auth == null) return const [];
      final hits = await ApiService.instance.lawyerSearchItemGroups(q, auth);
      return [for (final g in hits) PickerOption(id: g.name, label: g.name)];
    },
    onPick: (o) => setState(() {
      // A case belongs to a circuit — reset it when the circuit changes.
      if (o.id != _itemGroup) {
        _item = '';
        _itemName = '';
      }
      _itemGroup = o.id;
    }),
  );

  void _openItemPicker() => showEntityPicker(
    context,
    title: t('office.item'),
    cacheScope: 'items',
    cacheKey: _itemGroup,
    search: (q) async {
      final auth = AuthService.instance.user?.token;
      if (auth == null) return const [];
      final hits = await ApiService.instance.lawyerSearchItems(
        q,
        auth,
        itemGroup: _itemGroup.isEmpty ? null : _itemGroup,
      );
      return [
        for (final it in hits)
          PickerOption(
            id: it.itemCode,
            label: it.itemName ?? it.itemCode,
            sublabel: it.itemCode,
          ),
      ];
    },
    onPick: (o) => setState(() {
      _item = o.id;
      _itemName = o.label;
    }),
  );

  void _openPartyPicker(_PartyRowState row, String titleKey) =>
      showEntityPicker(
        context,
        title: t(titleKey),
        cacheScope: 'customers',
        search: (q) async {
          final auth = AuthService.instance.user?.token;
          if (auth == null) return const [];
          final hits =
              await ApiService.instance.lawyerSearchCustomers(q, auth);
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
          row.client = o.id;
          row.name.text = o.label;
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
                    t('office.newIntake'),
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
            PickerField(
              value: _itemGroup,
              placeholder: t('office.itemGroup'),
              onTap: _openGroupPicker,
            ),
            const SizedBox(height: 10),
            PickerField(
              value: _itemName.isNotEmpty ? _itemName : _item,
              placeholder: t('office.item'),
              onTap: _openItemPicker,
            ),
            _partySection(
              label: t('office.clients'),
              rows: _clients,
              titleKey: 'office.clients',
            ),
            _partySection(
              label: t('office.defendants'),
              rows: _defendants,
              titleKey: 'office.defendants',
            ),
            const SizedBox(height: 18),
            Text(
              t('office.intakeDescription'),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _description,
              maxLines: 4,
              decoration: officeFieldDecoration(t('office.intakeDescription')),
              style: const TextStyle(color: AppColors.foreground),
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

  Widget _partySection({
    required String label,
    required List<_PartyRowState> rows,
    required String titleKey,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gold,
                ),
              ),
              TextButton(
                onPressed: () => setState(() => rows.add(_PartyRowState())),
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
          for (var i = 0; i < rows.length; i++)
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.card,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _openPartyPicker(rows[i], titleKey),
                    icon: const Icon(
                      Icons.people_outline,
                      size: 15,
                      color: AppColors.gold,
                    ),
                    label: Text(
                      t('office.chooseFromList'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.goldLight,
                      side: const BorderSide(color: AppColors.gold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: rows[i].name,
                    // Typing a name unlinks the picked customer.
                    onChanged: (_) => rows[i].client = null,
                    decoration: officeFieldDecoration(t('office.fullName')),
                    style: const TextStyle(color: AppColors.foreground),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: rows[i].nationalId,
                    decoration: officeFieldDecoration(t('office.nationalId')),
                    style: const TextStyle(color: AppColors.foreground),
                  ),
                  TextButton(
                    onPressed: () {
                      final removed = rows[i];
                      setState(() => rows.removeAt(i));
                      WidgetsBinding.instance.addPostFrameCallback((_) => removed.dispose());
                    },
                    child: Text(
                      t('office.remove'),
                      style: const TextStyle(color: AppColors.destructive),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
