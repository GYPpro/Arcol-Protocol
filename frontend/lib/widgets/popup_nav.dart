import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';

class PopupNavOverlay extends ConsumerStatefulWidget {
  final Widget child;
  final VoidCallback? onLogout;

  const PopupNavOverlay({
    super.key,
    required this.child,
    this.onLogout,
  });

  @override
  ConsumerState<PopupNavOverlay> createState() => PopupNavOverlayState();
}

class PopupNavOverlayState extends ConsumerState<PopupNavOverlay> with SingleTickerProviderStateMixin {
  bool _isVisible = false;
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  final List<_NavItem> _navItems = [
    _NavItem(icon: Icons.dashboard, label: 'Dashboard', path: '/dashboard'),
    _NavItem(icon: Icons.timer, label: 'Time', path: '/time-management'),
    _NavItem(icon: Icons.trending_up, label: 'Assets', path: '/assets'),
    _NavItem(icon: Icons.dns, label: 'Routes', path: '/site-routes'),
    _NavItem(icon: Icons.monitor_heart, label: 'Monitor', path: '/server-monitor'),
    _NavItem(icon: Icons.rss_feed, label: 'RSS', path: '/rss'),
    _NavItem(icon: Icons.settings, label: 'Settings', path: '/settings'),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: -80, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void show() {
    if (!_isVisible) {
      setState(() => _isVisible = true);
      _controller.forward();
    }
  }

  void hide() {
    _controller.reverse().then((_) {
      if (mounted) setState(() => _isVisible = false);
    });
  }

  void _handleLogout() {
    hide();
    widget.onLogout?.call();
  }

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).matchedLocation;

    return Stack(
      children: [
        widget.child,
        // Hover trigger zone on left edge
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: 30,
          child: MouseRegion(
            onEnter: (_) => show(),
            onExit: (_) => hide(),
            child: Container(color: Colors.transparent),
          ),
        ),
        // Popup navigation
        if (_isVisible)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_slideAnimation.value, 0),
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: child,
                  ),
                );
              },
              child: MouseRegion(
                onEnter: (_) => show(),
                onExit: (_) => hide(),
                child: Container(
                  width: 200,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(2, 0),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // Logo
                      Row(
                        children: [
                          const SizedBox(width: 16),
                          Icon(
                            Icons.dashboard_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Arcol',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                      // Nav items
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          itemCount: _navItems.length,
                          itemBuilder: (context, index) {
                            final item = _navItems[index];
                            final isActive = currentPath == item.path;
                            return _NavButton(
                              item: item,
                              isActive: isActive,
                              onTap: () {
                                hide();
                                context.go(item.path);
                              },
                            );
                          },
                        ),
                      ),
                      // Logout
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: _LogoutButton(
                          onTap: _handleLogout,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String path;

  _NavItem({required this.icon, required this.label, required this.path});
}

class _NavButton extends StatefulWidget {
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: widget.isActive
                ? colorScheme.primaryContainer
                : _isHovered
                    ? colorScheme.surfaceContainerHighest
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      widget.item.icon,
                      size: 20,
                      color: widget.isActive
                          ? colorScheme.onPrimaryContainer
                          : _isHovered
                              ? colorScheme.onSurface
                              : colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 150),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.normal,
                        color: widget.isActive
                            ? colorScheme.onPrimaryContainer
                            : _isHovered
                                ? colorScheme.onSurface
                                : colorScheme.onSurfaceVariant,
                      ),
                      child: Text(widget.item.label),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatefulWidget {
  final VoidCallback onTap;

  const _LogoutButton({required this.onTap});

  @override
  State<_LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<_LogoutButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _isHovered ? Colors.red.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHovered ? Colors.red : Colors.red.withOpacity(0.3),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout, size: 18, color: _isHovered ? Colors.red : Colors.red.withOpacity(0.7)),
                  const SizedBox(width: 8),
                  Text(
                    'Logout',
                    style: TextStyle(
                      color: _isHovered ? Colors.red : Colors.red.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
