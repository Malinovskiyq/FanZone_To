import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/user.dart';

class UserAvatar extends StatelessWidget {
  final User? user;
  final double size;
  final bool showBorder;

  const UserAvatar({
    super.key,
    this.user,
    this.size = 40,
    this.showBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final avatarUrl = user?.avatarFullUrl;
    final initials = user?.profile?.initials ??
        (user != null && user!.username.isNotEmpty ? user!.username[0].toUpperCase() : '?');

    Widget avatarContent;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      avatarContent = Image.network(
        avatarUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildInitials(initials),
      );
    } else {
      avatarContent = _buildInitials(initials);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: showBorder ? Border.all(color: AppTheme.brandPrimary, width: 2) : null,
      ),
      child: ClipOval(child: avatarContent),
    );
  }

  Widget _buildInitials(String text) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.brandPrimary, AppTheme.surfaceElevated],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.38,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
