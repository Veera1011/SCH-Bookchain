import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

class ResponsiveNavigation extends StatelessWidget {
  final int selectedIndex;
  final List<NavigationDestination> destinations;
  final ValueChanged<int> onDestinationSelected;
  final Widget child;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget? title;
  final Widget? drawer;
  final Widget? floatingActionButton;

  const ResponsiveNavigation({
    super.key,
    required this.selectedIndex,
    required this.destinations,
    required this.onDestinationSelected,
    required this.child,
    this.leading,
    this.actions,
    this.title,
    this.drawer,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;
    final colorScheme = Theme.of(context).colorScheme;

    // Unified layout with adaptive drawer/rail simplified to just Drawer for cleaning up web
    return Scaffold(
      appBar: AppBar(
        leading: leading ?? (drawer != null ? Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_open_rounded, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ) : null),
        title: title ?? SvgPicture.asset(
          'assets/images/sch_logo.svg', 
          height: 28,
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        ),
        actions: actions?.where((a) {
          // Filter out notification icon if it's the bell
          if (a is IconButton && a.icon is Icon && (a.icon as Icon).icon == Icons.notifications_none_rounded) {
            return false;
          }
          if (a is Stack) return false; // Remove notification stack
          return true;
        }).map((a) => Theme(
          data: Theme.of(context).copyWith(
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          child: a,
        )).toList(),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primary,
                colorScheme.primary.withOpacity(0.9),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: isDesktop ? 2 : 4,
        centerTitle: !isDesktop,
      ),
      drawer: drawer,
      body: Row(
        children: [
          // On desktop, we could keep the drawer open or a very slim rail, 
          // but the user specifically asked to remove unnecessary things and keep drawer.
          Expanded(child: child),
        ],
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SalomonBottomBar(
          currentIndex: selectedIndex,
          onTap: onDestinationSelected,
          items: destinations.map((d) => SalomonBottomBarItem(
            icon: d.icon,
            title: Text(d.label),
            selectedColor: colorScheme.primary,
          )).toList(),
        ),
      ),
    );
  }
}
