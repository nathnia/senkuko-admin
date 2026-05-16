import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppBackButton extends StatelessWidget {
  final VoidCallback? onTap;

  const AppBackButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => Get.back(),

      child: const Icon(
        Icons.arrow_back_ios_new_rounded,
        size: 15,
        color: Colors.black87,
      ),
    );
  }
}
