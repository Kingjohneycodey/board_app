import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:board_app/core/theme/app_theme.dart';

class AppNotifications {
  static void showSuccess(BuildContext context, String message) {
    Flushbar(
      message: message,
      icon: const Icon(Icons.check_circle_outline, color: Colors.white),
      duration: const Duration(seconds: 3),
      backgroundColor: Colors.green,
      borderRadius: BorderRadius.circular(12),
      margin: const EdgeInsets.all(16),
      flushbarPosition: FlushbarPosition.TOP,
    ).show(context);
  }

  static void showError(BuildContext context, String message) {
    Flushbar(
      message: message,
      icon: const Icon(Icons.error_outline, color: Colors.white),
      duration: const Duration(seconds: 4),
      backgroundColor: Colors.redAccent,
      borderRadius: BorderRadius.circular(12),
      margin: const EdgeInsets.all(16),
      flushbarPosition: FlushbarPosition.TOP,
    ).show(context);
  }

  static void showInfo(BuildContext context, String message) {
    Flushbar(
      message: message,
      icon: const Icon(Icons.info_outline, color: Colors.white),
      duration: const Duration(seconds: 3),
      backgroundColor: AppTheme.primaryColor,
      borderRadius: BorderRadius.circular(12),
      margin: const EdgeInsets.all(16),
      flushbarPosition: FlushbarPosition.TOP,
    ).show(context);
  }
}
