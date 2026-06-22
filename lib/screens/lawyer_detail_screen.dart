import 'package:flutter/material.dart';

import '../i18n/strings.dart';
import '../i18n/tr.dart';
import '../models/lawyer.dart';
import '../services/api_service.dart';
import '../services/content_service.dart';
import '../theme/app_colors.dart';
import '../widgets/lawyer_card.dart';
import 'tabs_shell.dart';

/// Lawyer profile page (ported from app/lawyer/[id].tsx): photo hero with stat
/// chips, a four-tab body (About / Availability / Experience / Education) and a
/// gold "book appointment" CTA.
class LawyerDetailScreen extends StatefulWidget {
  final String lawyerId;

  const LawyerDetailScreen({super.key, required this.lawyerId});

  @override
  State<LawyerDetailScreen> createState() => _LawyerDetailScreenState();
}

enum _Tab { about, availability, experience, education }

class _LawyerDetailScreenState extends State<LawyerDetailScreen> {
  _Tab _active = _Tab.about;

  /// Switch the shell to the Contact tab, then pop back to it.
  void _goToContact() {
    final switcher = TabSwitcher.of(context);
    if (switcher != null) {
      switcher.switchTo(switcher.contactIndex);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<List<Lawyer>>(
        future: ContentService.instance.team(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return _withBackButton(
              topPadding,
              const Center(
                child: CircularProgressIndicator(color: AppColors.gold),
              ),
            );
          }
          final lawyer = (snap.data ?? const <Lawyer>[])
              .where((l) => l.id == widget.lawyerId)
              .firstOrNull;
          if (lawyer == null) {
            return _withBackButton(
              topPadding,
              Center(
                child: Text(
                  t('team.notFound'),
                  style: const TextStyle(color: AppColors.foreground),
                ),
              ),
            );
          }
          return _content(context, lawyer, topPadding);
        },
      ),
    );
  }

  /// Minimal navy header with just a back button, for the loading / not-found
  /// states so the user is never stranded.
  Widget _withBackButton(double topPadding, Widget body) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: AppColors.navy,
          padding: EdgeInsets.only(
            top: topPadding + 8,
            left: 16,
            right: 16,
            bottom: 16,
          ),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: _backButton(),
          ),
        ),
        Expanded(child: body),
      ],
    );
  }

  Widget _backButton() {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Color(0x26FFFFFF),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.arrow_forward, size: 20, color: Colors.white),
      ),
    );
  }

  Widget _content(BuildContext context, Lawyer lawyer, double topPadding) {
    final resolvedName = tr(lawyer.name);
    final photoUri = resolveMedia(lawyer.photoUrl);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ─── Hero ───
        Container(
          color: AppColors.navy,
          padding: EdgeInsets.only(
            top: topPadding + 8,
            left: 16,
            right: 16,
            bottom: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _backButton(),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr(lawyer.specialty),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0x99FFFFFF),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          resolvedName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tr(lawyer.title),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  _heroAvatar(lawyer, resolvedName, photoUri),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _statChip(
                      Icons.people_outline,
                      '+${lawyer.cases}',
                      t('team.casesCompleted'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _statChip(
                      Icons.work_outline,
                      '${lawyer.experience} ${t('team.experienceUnit')}',
                      t('team.tabExperience'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ─── Tabs ───
        Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              _tab(_Tab.about, t('team.tabAbout')),
              _tab(_Tab.availability, t('team.tabAvailability')),
              _tab(_Tab.experience, t('team.tabExperience')),
              _tab(_Tab.education, t('team.tabEducation')),
            ],
          ),
        ),

        // ─── Tab body + CTA ───
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            children: [
              ..._tabBody(lawyer),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _goToContact,
                  icon: const Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: AppColors.navy,
                  ),
                  label: Text(
                    t('team.bookAppointment'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.navy,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _heroAvatar(Lawyer lawyer, String resolvedName, String photoUri) {
    final child = photoUri.isNotEmpty
        ? Image.network(
            photoUri,
            width: 96,
            height: 96,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _heroInitials(lawyer, resolvedName),
          )
        : _heroInitials(lawyer, resolvedName);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x40FFFFFF), width: 2),
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(18), child: child),
    );
  }

  Widget _heroInitials(Lawyer lawyer, String resolvedName) {
    return Container(
      width: 96,
      height: 96,
      color: lawyerAvatarColor(lawyer.id),
      alignment: Alignment.center,
      child: Text(
        lawyerInitials(resolvedName),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _statChip(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xD9FFFFFF)),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0x99FFFFFF)),
          ),
        ],
      ),
    );
  }

  Widget _tab(_Tab tab, String label) {
    final active = _active == tab;
    return GestureDetector(
      onTap: () => setState(() => _active = tab),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? AppColors.gold : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? AppColors.foreground : AppColors.mutedForeground,
          ),
        ),
      ),
    );
  }

  List<Widget> _tabBody(Lawyer lawyer) {
    switch (_active) {
      case _Tab.about:
        return [
          Text(
            tr(lawyer.bio),
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.mutedForeground,
              height: 24 / 14,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _infoCard(
                  Icons.workspace_premium_outlined,
                  t('team.infoSpecialty'),
                  tr(lawyer.specialty),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _infoCard(
                  Icons.work_outline,
                  t('team.infoCompletedCases'),
                  '+${lawyer.cases} ${t('team.casesUnit')}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _infoCard(
                  Icons.schedule,
                  t('team.infoNextAvailable'),
                  tr(lawyer.nextAvailable),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _infoCard(
                  Icons.how_to_reg_outlined,
                  t('team.infoStatus'),
                  lawyer.available
                      ? t('team.availableNow')
                      : t('team.notAvailable'),
                ),
              ),
            ],
          ),
        ];
      case _Tab.availability:
        return [
          _sectionCard(
            Icons.schedule,
            t('team.infoNextAvailable'),
            children: [
              Text(
                tr(lawyer.nextAvailable),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(height: 10),
              _availabilityBadge(lawyer.available),
            ],
          ),
        ];
      case _Tab.experience:
        return [
          _sectionCard(
            Icons.work_outline,
            tr(lawyer.title),
            children: [
              Text(
                '${lawyer.experience} ${t('team.experienceDescription', vars: {'specialty': tr(lawyer.specialty), 'cases': '${lawyer.cases}'})}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.mutedForeground,
                  height: 24 / 14,
                ),
              ),
            ],
          ),
        ];
      case _Tab.education:
        return [
          _sectionCard(
            Icons.menu_book_outlined,
            t('team.educationTitle'),
            children: [
              Text(
                tr(lawyer.education),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.mutedForeground,
                  height: 24 / 14,
                ),
              ),
            ],
          ),
        ];
    }
  }

  Widget _infoCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.goldLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 16, color: AppColors.gold),
          ),
          const SizedBox(height: 6),
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
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.foreground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(
    IconData icon,
    String title, {
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.gold),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.foreground,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _availabilityBadge(bool available) {
    final color = available ? AppColors.success : AppColors.destructive;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(0x26),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            available ? t('team.availableNow') : t('team.notAvailable'),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
