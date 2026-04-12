import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';

class BackHeaderWidget extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final PreferredSizeWidget? bottom;

  const BackHeaderWidget({
    super.key,
    required this.title,
    this.bottom,
  });

  static const double _headerHeight = 65.0;

  @override
  Widget build(BuildContext context) {
    final headerRow = Container(
      height: _headerHeight,
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (bottom == null) return headerRow;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        headerRow,
        ColoredBox(
          color: AppColors.primary,
          child: bottom!,
        ),
      ],
    );
  }

  @override
  Size get preferredSize {
    final bottomHeight = bottom?.preferredSize.height ?? 0.0;
    return Size.fromHeight(_headerHeight + bottomHeight);
  }
}
