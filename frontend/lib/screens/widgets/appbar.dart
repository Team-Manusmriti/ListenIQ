import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AppHeader extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final String? chatTitle;
  final VoidCallback? onBackPressed;
  final VoidCallback? onMenuPressed;
  final VoidCallback? onDetailPressed;
  final VoidCallback? onProfilePressed;

  final List<Widget>? actions;
  final bool centerTitle;
  final double elevation;
  final Widget? titleWidget;
  final Widget? searchBar;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double height;
  final PreferredSizeWidget? bottom;
  final bool isTransparent;
  final EdgeInsetsGeometry? titlePadding;
  final bool isInChat;

  const AppHeader({
    super.key,
    this.title = 'ListenIQ',
    this.chatTitle,
    this.onBackPressed,
    this.onMenuPressed,
    this.onDetailPressed,
    this.onProfilePressed,
    this.actions,
    this.centerTitle = true,
    this.elevation = 0,
    this.titleWidget,
    this.searchBar,
    this.backgroundColor,
    this.foregroundColor,
    this.height = kToolbarHeight,
    this.bottom,
    this.isTransparent = false,
    this.titlePadding,
    this.isInChat = false,
  });

  @override
  State<AppHeader> createState() => _AppHeaderState();

  @override
  Size get preferredSize {
    final bottomHeight = bottom?.preferredSize.height ?? 0.0;
    return Size.fromHeight(height + bottomHeight);
  }
}

class _AppHeaderState extends State<AppHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (widget.isInChat) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(AppHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isInChat != oldWidget.isInChat) {
      if (widget.isInChat) {
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
    // Animated leading widget that changes between menu and back icon
    Widget leadingWidget = AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, child) {
        return Container(
          transform: Matrix4.rotationZ(_rotationAnimation.value),
          child: IconButton(
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Colors.purple),
              shape: MaterialStateProperty.all(const CircleBorder()),
            ),
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: widget.isInChat
                  ? Icon(
                      CupertinoIcons.back,
                      key: const ValueKey('back'),
                      color: Colors.white,
                      size: 24,
                    )
                  : Icon(
                      CupertinoIcons.line_horizontal_3,
                      key: const ValueKey('menu'),
                      color: Colors.white,
                      size: 24,
                    ),
            ),
            onPressed: widget.isInChat
                ? widget.onBackPressed
                : widget.onMenuPressed,
          ),
        );
      },
    );

    // Profile icon - always visible on the right
    Widget profileWidget = Container(
      margin: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: widget.onProfilePressed,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Colors.purple, Colors.purple.shade200],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Icon(CupertinoIcons.person, color: Colors.white, size: 18),
        ),
      ),
    );

    Widget titleContent;
    if (widget.searchBar != null) {
      titleContent = Padding(
        padding:
            widget.titlePadding ?? const EdgeInsets.symmetric(horizontal: 8.0),
        child: widget.searchBar!,
      );
    } else if (widget.titleWidget != null) {
      titleContent = widget.titleWidget!;
    } else {
      // Animated title switching between app title and chat title
      titleContent = AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Default app title
              AnimatedOpacity(
                opacity: widget.isInChat ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Transform.translate(
                  offset: Offset(0, widget.isInChat ? -10 : 0),
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: widget.foregroundColor ?? Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
              // Chat title
              AnimatedOpacity(
                opacity: widget.isInChat ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Transform.translate(
                  offset: Offset(0, widget.isInChat ? 0 : 10),
                  child: Text(
                    widget.chatTitle ?? '',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: widget.foregroundColor ?? Colors.white,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          );
        },
      );
    }

    return AppBar(
      elevation: widget.elevation,
      centerTitle: widget.searchBar != null ? false : widget.centerTitle,
      backgroundColor: widget.backgroundColor ?? const Color(0xFF1A1A1A),
      foregroundColor: widget.foregroundColor ?? Colors.white,
      leadingWidth: 48,
      leading: leadingWidget,
      title: titleContent,
      actions: [
        profileWidget,
        // Add any additional actions if provided
        if (widget.actions != null) ...widget.actions!,
      ],
      toolbarHeight: widget.height,
      automaticallyImplyLeading: false,
      shape: widget.elevation > 0
          ? const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            )
          : null,
      titleSpacing: 0.0,
      titleTextStyle: TextStyle(
        color: widget.foregroundColor ?? Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: widget.isTransparent
            ? Brightness.light
            : Brightness.light, // Changed to light for dark theme
        statusBarBrightness: widget.isTransparent
            ? Brightness.dark
            : Brightness.dark, // Changed for dark theme
      ),
      bottom: widget.bottom,
    );
  }
}
