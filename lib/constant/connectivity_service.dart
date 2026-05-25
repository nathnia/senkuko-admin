// lib/constant/connectivity_service.dart

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ConnectivityService extends GetxController {
  final status = 'hidden'.obs; // 'hidden' | 'offline'

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  VoidCallback? onReconnect;

  bool get isOffline => status.value == 'offline';

  @override
  void onInit() {
    super.onInit();

    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    try {
      // Initial check
      final List<ConnectivityResult> result = await Connectivity().checkConnectivity();
      _updateConnectionStatus(result);

      // Listen to connectivity changes
      _subscription = Connectivity().onConnectivityChanged.listen(
        (List<ConnectivityResult> results) {
          _updateConnectionStatus(results);
        },
        onError: (error) {
          // print('Connectivity error: $error');
        },
      );
    } catch (e) {
      // print('Failed to check connectivity: $e');
      // Fallback: assume offline if plugin fails
      _goOffline();
    }
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final bool isOffline = results.every((r) => r == ConnectivityResult.none);

    if (isOffline) {
      _goOffline();
    } else {
      _goOnline();
    }
  }

  void _goOffline() {
    if (status.value != 'offline') {
      status.value = 'offline';
    }
  }

  void _goOnline() {
    if (status.value == 'offline') {
      status.value = 'hidden';
      onReconnect?.call();
    }
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}