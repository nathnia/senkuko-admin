// lib/constant/connectivity_banner.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/connectivity_service.dart';

class ConnectivityBanner extends StatelessWidget {
  const ConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final service = Get.find<ConnectivityService>();
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Obx(() {
      if (!service.isOffline) return const SizedBox.shrink();

      return Container(
        width: double.infinity,
        color: const Color(0xFF3A3A3A),
        padding: EdgeInsets.only(
          top: 9,
          bottom: bottomPadding > 0 ? bottomPadding : 9,
          left: 16,
          right: 16,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.signal_wifi_off_rounded,
              size: 12,
              color: Color(0xFFAAAAAA),
            ),
            SizedBox(width: 7),
            Text(
              'Tidak ada koneksi internet',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFFDDDDDD),
                fontWeight: FontWeight.w400,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      );
    });
  }
}