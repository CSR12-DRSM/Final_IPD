import 'package:flutter/material.dart';
import '../core/theme.dart';

class BadgeLogo extends StatelessWidget {
  final double size;
  const BadgeLogo({super.key, this.size = 70});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.paleBlue,
        borderRadius: BorderRadius.circular(size * .28),
        border: Border.all(color: AppTheme.border),
      ),
      child: Icon(
        Icons.shield_outlined,
        size: size * .62,
        color: AppTheme.slate,
      ),
    );
  }
}
