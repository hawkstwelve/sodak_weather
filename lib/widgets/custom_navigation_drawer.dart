import 'dart:ui';
import 'package:flutter/material.dart';
import '../config/navigation_config.dart';
import '../constants/ui_constants.dart';

/// Modal-like navigation drawer:
/// - Flush LEFT, VERTICALLY CENTERED (content-height)
/// - Strong screen dim
/// - Single blur behind content (text stays crisp)
class CustomNavigationDrawer extends StatefulWidget {
  final int selectedIndex;
  final bool isOpen;
  final ValueChanged<int> onNavigationChanged;
  final VoidCallback? onClose;

  // Tuning
  final double panelWidth;
  final double scrimOpacity;      // screen dim
  final double blurSigma;         // background blur (behind content only)
  final double panelDarkOpacity;  // dark tint under content (modal-like)

  const CustomNavigationDrawer({
    super.key,
    required this.selectedIndex,
    required this.onNavigationChanged,
    required this.isOpen,
    this.onClose,
    this.panelWidth = 320,
    this.scrimOpacity = 0.45,     // darker dim like your modals
    this.blurSigma = 24,          // single blur pass
    this.panelDarkOpacity = 0.22, // neutral dark tint (less milky)
  });

  @override
  State<CustomNavigationDrawer> createState() => _CustomNavigationDrawerState();
}

class _CustomNavigationDrawerState extends State<CustomNavigationDrawer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(-0.08, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void didUpdateWidget(CustomNavigationDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen != oldWidget.isOpen) {
      if (widget.isOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safeLeft = MediaQuery.of(context).padding.left;

    return IgnorePointer(
      ignoring: !widget.isOpen,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: Stack(
          children: [
            // Screen-wide dim
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onClose,
                child: Container(color: Colors.black.withValues(alpha: widget.scrimOpacity)),
              ),
            ),

            // Flush-left + vertically centered (no SafeArea vertical shift)
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerLeft,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: RepaintBoundary(
                    child: Padding(
                      padding: EdgeInsets.only(left: safeLeft + 12),
                      child: _DrawerPanel(
                        width: widget.panelWidth,
                        blurSigma: widget.blurSigma,
                        panelDarkOpacity: widget.panelDarkOpacity,
                        selectedIndex: widget.selectedIndex,
                        onNavigationChanged: (i) {
                          widget.onNavigationChanged(i);
                          widget.onClose?.call();
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerPanel extends StatelessWidget {
  final double width;
  final double blurSigma;
  final double panelDarkOpacity;
  final int selectedIndex;
  final ValueChanged<int> onNavigationChanged;

  const _DrawerPanel({
    required this.width,
    required this.blurSigma,
    required this.panelDarkOpacity,
    required this.selectedIndex,
    required this.onNavigationChanged,
  });

  @override
  Widget build(BuildContext context) {
    final radius = UIConstants.borderRadiusStandard;

    return Container(
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        // IMPORTANT: No internal Stack/Positioned. Size is driven by content only.
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: RepaintBoundary(
            child: Container(
              // Dark neutral tint under content to match your modals
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: panelDarkOpacity),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25), // subtle glass edge
                  width: 1,
                ),
              ),
              // Optional subtle left-to-right dark scrim for label contrast
              foregroundDecoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color.fromRGBO(0, 0, 0, 0.12),
                    Color.fromRGBO(0, 0, 0, 0.04),
                    Color.fromRGBO(0, 0, 0, 0.00),
                  ],
                  stops: [0.0, 0.45, 0.80],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  UIConstants.spacingXXXLarge,
                  UIConstants.spacingXXLarge,
                  UIConstants.spacingXXXLarge,
                  UIConstants.spacingLarge,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min, // content-height
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Sodak Weather',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: UIConstants.spacingXLarge),
                    _NavList(
                      selectedIndex: selectedIndex,
                      onNavigationChanged: onNavigationChanged,
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

class _NavList extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onNavigationChanged;

  const _NavList({
    required this.selectedIndex,
    required this.onNavigationChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Cap height like a modal; still centers vertically due to parent Align
    final maxListHeight = MediaQuery.of(context).size.height * 0.6;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxListHeight),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: UIConstants.spacingSmall),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: NavigationConfig.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isSelected = index == selectedIndex;
            return _NavItem(
              title: item.title,
              icon: item.icon,
              isSelected: isSelected,
              onTap: () => onNavigationChanged(index),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = UIConstants.borderRadiusStandard;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: UIConstants.spacingTiny),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          splashColor: Theme.of(context).colorScheme.secondary
              .withValues(alpha: UIConstants.opacityVeryLow),
          highlightColor: Theme.of(context).colorScheme.secondary
              .withValues(alpha: UIConstants.opacityVeryLow),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(
              horizontal: UIConstants.spacingLarge,
              vertical: UIConstants.spacingStandard,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.14) // subtle glass pill
                  : Colors.transparent,
              border: isSelected
                  ? Border.all(
                      color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.60),
                      width: 1,
                    )
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isSelected
                      ? Theme.of(context).colorScheme.secondary
                      : Colors.white.withValues(alpha: 0.92), // modal-like frosted white
                ),
                const SizedBox(width: UIConstants.spacingLarge),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? Theme.of(context).colorScheme.secondary
                              : Colors.white.withValues(alpha: 0.92),
                        ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
