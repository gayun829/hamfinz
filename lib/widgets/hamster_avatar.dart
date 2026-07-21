import 'package:flutter/material.dart';

import '../data/hamster_data.dart';

class HamsterAvatar extends StatelessWidget {
  const HamsterAvatar({
    super.key,
    required this.hamsterId,
    this.size = 72,
  });

  final String hamsterId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final item = HamsterData.findById(hamsterId);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFBFDBFE), width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        item?.emoji ?? '🐹',
        style: TextStyle(fontSize: size * 0.45),
      ),
    );
  }
}
