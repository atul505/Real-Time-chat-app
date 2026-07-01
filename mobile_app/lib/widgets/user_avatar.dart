import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';

/// Reusable avatar widget with gradient background, initial letter, optional online indicator, and image support
class UserAvatar extends StatelessWidget {
  final String name;
  final double radius;
  final bool showOnline;
  final bool isOnline;
  final String? imageUrl;

  const UserAvatar({
    super.key,
    required this.name,
    this.radius = 24,
    this.showOnline = false,
    this.isOnline = false,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.getAvatarGradient(name);
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Stack(
      children: [
        Container(
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: imageUrl != null ? Colors.grey[200] : null,
            gradient: imageUrl == null
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: colors,
                  )
                : null,
          ),
          clipBehavior: Clip.hardEdge,
          child: imageUrl != null && imageUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Center(
                    child: Text(
                      initial,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: radius * 0.75,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Center(
                    child: Text(
                      initial,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: radius * 0.75,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
              : Center(
                  child: Text(
                    initial,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: radius * 0.75,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
        ),
        if (showOnline && isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: radius * 0.55,
              height: radius * 0.55,
              decoration: BoxDecoration(
                color: AppTheme.online,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.surface, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}
