import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../i18n/strings.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import '../theme/app_colors.dart';
import 'ai_screen.dart';
import 'contact_screen.dart';
import 'home_screen.dart';
import 'laws_screen.dart';
import 'office_hub_screen.dart';
import 'team_screen.dart';

/* Distinct elevated surface so the floating bar stands clear of the page bg */
const Color _barBg = Color(0xFF23232A);
const Color _barBorder = Color(0x47C9A84C);

class _TabDef {
  final IconData icon;
  final String label;
  final Widget page;

  /// When false the tab is hidden (bar item + page) for the current auth state.
  final bool Function() visible;

  const _TabDef(this.icon, this.label, this.page, this.visible);
}

/// The Office tab — which now hosts the Legal Cases entry alongside the
/// lawyer-only intake/offer cards — is shown to any signed-in user; guests
/// (user==null) don't see it.
bool _isLoggedIn() => AuthService.instance.user != null;

List<_TabDef> get _allTabDefs => [
  _TabDef(
    Icons.home_outlined,
    t('common.tab.home'),
    const HomeScreen(),
    () => true,
  ),
  _TabDef(
    Icons.people_outline,
    t('common.tab.team'),
    const TeamScreen(),
    () => true,
  ),
  _TabDef(
    Icons.menu_book_outlined,
    t('common.tab.laws'),
    const LawsScreen(),
    () => true,
  ),
  _TabDef(Icons.gavel, t('common.tab.ai'), const AiScreen(), () => true),
  _TabDef(
    Icons.phone_outlined,
    t('common.tab.contact'),
    const ContactScreen(),
    () => true,
  ),
  _TabDef(
    Icons.work_outline,
    t('common.tab.office'),
    const OfficeHubScreen(),
    _isLoggedIn,
  ),
];

/// Lets any descendant screen switch the active tab
/// (e.g. "احجز استشارة" buttons jump to the contact tab).
///
/// [contactIndex] is the live index of the Contact tab within the *active*
/// tab set; it shifts when the Office tab is hidden for guests, so descendants
/// must read it rather than hardcoding a position.
class TabSwitcher extends InheritedWidget {
  final ValueChanged<int> switchTo;
  final int contactIndex;

  const TabSwitcher({
    super.key,
    required this.switchTo,
    required this.contactIndex,
    required super.child,
  });

  static TabSwitcher? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TabSwitcher>();

  @override
  bool updateShouldNotify(TabSwitcher oldWidget) =>
      contactIndex != oldWidget.contactIndex;
}

/// Main shell: 6 tabs + floating pill tab bar
/// (ported from app/(tabs)/_layout.tsx).
class TabsShell extends StatefulWidget {
  const TabsShell({super.key});

  @override
  State<TabsShell> createState() => _TabsShellState();
}

class _TabsShellState extends State<TabsShell> {
  int _index = 0;

  void _onTab(int i) {
    if (i == _index) return;
    HapticFeedback.mediumImpact();
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      // Listen to LanguageService as well as AuthService: the tab pages are
      // const and none of them subscribe to language changes themselves, so a
      // switch only re-translates them if this shell rebuilds from above.
      body: ListenableBuilder(
        listenable: Listenable.merge([
          AuthService.instance,
          LanguageService.instance,
        ]),
        builder: (context, _) {
          // Active tabs depend on auth state (Office hidden for guests). Keep
          // the IndexedStack children and bar items index-aligned by deriving
          // both from this single filtered list.
          final tabs = _allTabDefs.where((d) => d.visible()).toList();

          // Clamp the selected index in case the active set shrank
          // (e.g. user was on Office, then logged out).
          if (_index >= tabs.length) _index = tabs.length - 1;

          final contactIndex = tabs.indexWhere((d) => d.page is ContactScreen);

          return TabSwitcher(
            switchTo: (i) => setState(() => _index = i),
            contactIndex: contactIndex,
            child: Stack(
              children: [
                // Keyed by language so the whole stack remounts on a switch,
                // forcing every const tab page to rebuild in the new language.
                // _index lives in State, so the active tab is preserved.
                KeyedSubtree(
                  key: ValueKey(LanguageService.instance.lang),
                  child: IndexedStack(
                    index: _index,
                    children: [for (final d in tabs) d.page],
                  ),
                ),
                PositionedDirectional(
                  start: 14,
                  end: 14,
                  bottom: bottomInset > 12 ? bottomInset : 12,
                  child: _FloatingTabBar(
                    tabs: tabs,
                    index: _index,
                    onTab: _onTab,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FloatingTabBar extends StatelessWidget {
  final List<_TabDef> tabs;
  final int index;
  final ValueChanged<int> onTab;

  const _FloatingTabBar({
    required this.tabs,
    required this.index,
    required this.onTab,
  });

  @override
  Widget build(BuildContext context) {
    const barHeight = 64.0;
    return Container(
      height: barHeight,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: _barBg,
        borderRadius: BorderRadius.circular(barHeight / 2),
        border: Border.all(color: _barBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x6B000000),
            offset: Offset(0, 8),
            blurRadius: 22,
          ),
        ],
      ),
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++)
            if (i == index)
              // Loose flex: the focused pill grows to show its label but is
              // capped so a long label (Kurdish/English) fades rather than
              // pushing the bar past the screen edge.
              Flexible(
                flex: 2,
                child: _FloatingTab(
                  def: tabs[i],
                  focused: true,
                  onPress: () => onTab(i),
                ),
              )
            else
              Expanded(
                child: _FloatingTab(
                  def: tabs[i],
                  focused: false,
                  onPress: () => onTab(i),
                ),
              ),
        ],
      ),
    );
  }
}

/// One animated tab cell — its flex grows on focus, physically pushing
/// the neighbouring cells aside so every icon glides to make room.
class _FloatingTab extends StatelessWidget {
  final _TabDef def;
  final bool focused;
  final VoidCallback onPress;

  const _FloatingTab({
    required this.def,
    required this.focused,
    required this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPress,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 340),
            curve: Curves.easeOutQuint,
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 9),
            decoration: BoxDecoration(
              color: focused ? AppColors.gold : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  def.icon,
                  size: 17,
                  color: focused ? AppColors.navy : const Color(0x8CF5F0E8),
                ),
                Flexible(
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 340),
                    curve: Curves.easeOutQuint,
                    child: focused
                        ? Padding(
                            padding: const EdgeInsetsDirectional.only(start: 5),
                            child: Text(
                              def.label,
                              maxLines: 1,
                              overflow: TextOverflow.fade,
                              softWrap: false,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.navy,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
