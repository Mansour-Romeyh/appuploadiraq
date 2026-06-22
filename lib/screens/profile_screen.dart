import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../i18n/strings.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';

/// Computes initials from a name: first letter of up to two words,
/// with '؟' as the fallback for an empty name.
String _initialsFor(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '؟';
  return parts.take(2).map((w) => w[0]).join();
}

/// Profile screen (ported from app/profile.tsx).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _confirming = false;
  bool _deleteConfirming = false;
  bool _deleting = false;

  Future<void> _handleSignOut() async {
    HapticFeedback.mediumImpact();
    // The AuthGate in main.dart swaps the home route to the login screen once
    // auth state clears — but this ProfileScreen is pushed on top of it, so the
    // login screen would stay hidden underneath until the user manually pressed
    // back. Pop back to the root so it's revealed immediately.
    await AuthService.instance.logout();
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _openPrivacy() async {
    HapticFeedback.selectionClick();
    await launchUrl(
      Uri.parse('$apiBaseUrl/privacy'),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _handleDelete() async {
    final token = AuthService.instance.user?.token;
    if (token == null) return;
    HapticFeedback.mediumImpact();
    setState(() => _deleting = true);
    try {
      await ApiService.instance.deleteAccount(token);
      await AuthService.instance.logout();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on ApiException {
      if (!mounted) return;
      setState(() {
        _deleting = false;
        _deleteConfirming = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('profile.deleteError'))),
      );
    }
  }

  Widget _legalSection({required bool showDelete}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t('profile.legalSection'),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.mutedForeground,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: cardShadow,
          ),
          child: Column(
            children: [
              _LinkRow(
                icon: Icons.privacy_tip_outlined,
                label: t('profile.privacyPolicy'),
                onTap: _openPrivacy,
              ),
              if (showDelete) ...[
                const _Divider(),
                _LinkRow(
                  icon: Icons.delete_outline,
                  label: t('profile.deleteAccount'),
                  destructive: true,
                  onTap: () => setState(() => _deleteConfirming = true),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _deleteConfirmCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.destructive.withAlpha(0x55)),
        boxShadow: cardShadow,
      ),
      child: Column(
        children: [
          Text(
            t('profile.deleteConfirm'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t('profile.deleteWarning'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.mutedForeground,
              height: 20 / 13,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.muted,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _deleting
                      ? null
                      : () => setState(() => _deleteConfirming = false),
                  child: Text(
                    t('cancel'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.foreground,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.destructive,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _deleting ? null : _handleDelete,
                  child: Text(
                    _deleting
                        ? t('profile.deleting')
                        : t('profile.deleteAccount'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListenableBuilder(
        listenable: LanguageService.instance,
        builder: (context, _) {
          final user = AuthService.instance.user;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                color: AppColors.navy,
                padding: EdgeInsets.only(
                  top: topPadding + 12,
                  left: 16,
                  right: 16,
                  bottom: 14,
                ),
                child: Row(
                  children: [
                    _HeaderCircleButton(
                      onTap: () => Navigator.of(context).maybePop(),
                      child: const Icon(
                        Icons.arrow_forward,
                        size: 22,
                        color: Colors.white,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        t('profile.title'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Avatar + identity
                      _Identity(user: user),
                      const SizedBox(height: 16),

                      if (user != null) ...[
                        _accountSection(user),
                        const SizedBox(height: 16),
                        if (_confirming) _confirmCard() else _signOutButton(),
                        const SizedBox(height: 16),
                        _legalSection(showDelete: user.token != null),
                        if (_deleteConfirming) ...[
                          const SizedBox(height: 12),
                          _deleteConfirmCard(),
                        ],
                      ] else ...[
                        _signInButton(),
                        const SizedBox(height: 16),
                        _legalSection(showDelete: false),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _accountSection(AuthUser user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t('profile.account'),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.mutedForeground,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: cardShadow,
          ),
          child: Column(
            children: [
              _InfoRow(
                icon: Icons.person_outline,
                label: t('profile.name'),
                value: user.name,
              ),
              const _Divider(),
              _InfoRow(
                icon: Icons.phone_outlined,
                label: t('profile.phone'),
                value: user.phone ?? t('profile.notProvided'),
                ltrValue: user.phone != null,
              ),
              const _Divider(),
              _InfoRow(
                icon: Icons.mail_outline,
                label: t('profile.email'),
                value: user.email ?? t('profile.notProvided'),
                ltrValue: user.email != null,
              ),
              const _Divider(),
              _InfoRow(
                icon: Icons.login,
                label: t('profile.loginMethod'),
                value: t('profile.method.${user.method.name}'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _signOutButton() {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: AppColors.destructive.withAlpha(0x66)),
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: () => setState(() => _confirming = true),
      icon: const Icon(Icons.logout, size: 18, color: AppColors.destructive),
      label: Text(
        t('profile.signOut'),
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.destructive,
        ),
      ),
    );
  }

  Widget _confirmCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.destructive.withAlpha(0x55)),
        boxShadow: cardShadow,
      ),
      child: Column(
        children: [
          Text(
            t('profile.signOutConfirm'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.foreground,
              height: 24 / 15,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.muted,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => setState(() => _confirming = false),
                  child: Text(
                    t('cancel'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.foreground,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.destructive,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _handleSignOut,
                  child: Text(
                    t('profile.signOut'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _signInButton() {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.gold,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: _handleSignOut,
      icon: const Icon(Icons.login, size: 18, color: AppColors.navy),
      label: Text(
        t('profile.signIn'),
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.navy,
        ),
      ),
    );
  }
}

class _HeaderCircleButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const _HeaderCircleButton({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Color(0x1FFFFFFF),
          shape: BoxShape.circle,
        ),
        child: child,
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  final AuthUser? user;

  const _Identity({required this.user});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: 96,
          height: 96,
          decoration: const BoxDecoration(
            color: AppColors.gold,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: user != null
              ? Text(
                  _initialsFor(user!.name),
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                )
              : const Icon(Icons.person, size: 40, color: AppColors.navy),
        ),
        const SizedBox(height: 10),
        Text(
          user != null ? user!.name : t('profile.guestTitle'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.foreground,
          ),
        ),
        const SizedBox(height: 10),
        if (user != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.gold.withAlpha(0x1f),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.gold.withAlpha(0x55)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  size: 13,
                  color: AppColors.gold,
                ),
                const SizedBox(width: 6),
                Text(
                  t('profile.registered'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gold,
                  ),
                ),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              t('profile.guestSubtitle'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.mutedForeground,
                height: 22 / 14,
              ),
            ),
          ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool ltrValue;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.ltrValue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.gold.withAlpha(0x18),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 16, color: AppColors.gold),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.mutedForeground,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                textDirection: ltrValue ? TextDirection.ltr : null,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.foreground,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 14),
      child: SizedBox(height: 1, child: ColoredBox(color: AppColors.border)),
    );
  }
}

class _LinkRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  const _LinkRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.destructive : AppColors.foreground;
    final tint = destructive ? AppColors.destructive : AppColors.gold;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: tint.withAlpha(0x18),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 16, color: tint),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            // chevron_left as the trailing affordance matches the RTL
            // convention adopted across the office screens.
            Icon(Icons.chevron_left,
                size: 22, color: AppColors.mutedForeground),
          ],
        ),
      ),
    );
  }
}
