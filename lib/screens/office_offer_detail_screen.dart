import 'package:flutter/material.dart';

import '../i18n/strings.dart';
import '../models/office.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';

/// Detail view for a single offer document
/// (ported from app/office/offer/[id].tsx).
class OfficeOfferDetailScreen extends StatefulWidget {
  final String name;

  const OfficeOfferDetailScreen({super.key, required this.name});

  @override
  State<OfficeOfferDetailScreen> createState() =>
      _OfficeOfferDetailScreenState();
}

class _OfficeOfferDetailScreenState extends State<OfficeOfferDetailScreen> {
  OfferDoc? _doc;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = AuthService.instance.user?.token;
    if (auth == null) {
      if (mounted) setState(() { _doc = null; _loading = false; });
      return;
    }
    if (mounted) setState(() => _loading = true);
    try {
      final doc = await ApiService.instance.lawyerGetOffer(widget.name, auth);
      if (!mounted) return;
      setState(() { _doc = doc; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _doc = null; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
      );
    }

    final topPadding = MediaQuery.of(context).padding.top;

    if (_doc == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: EdgeInsets.only(top: topPadding + 40),
            child: Text(
              t('office.loadFailed'),
              style: const TextStyle(color: AppColors.mutedForeground),
            ),
          ),
        ),
      );
    }

    final doc = _doc!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: topPadding + 16,
          left: 18,
          right: 18,
          bottom: 140,
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
                    doc.name,
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
            const SizedBox(height: 16),
            Text(
              doc.customerDisplay,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.foreground,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${doc.transactionDate} · ${doc.status}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.mutedForeground,
              ),
            ),
            const SizedBox(height: 12),
            for (final item in doc.items)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.gold),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.itemName ?? item.itemCode,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.foreground,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.qty} × ${groupThousands(item.rate)} = ${groupThousands(item.amount ?? 0)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  t('office.total'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.mutedForeground,
                  ),
                ),
                Text(
                  groupThousands(doc.grandTotal),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
