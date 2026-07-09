import 'package:flutter/material.dart';

class ToastWidget {
  static void show(BuildContext context, String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: error
            ? const Color(0xFFD43F3F)
            : const Color(0xFF09131E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(24),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
