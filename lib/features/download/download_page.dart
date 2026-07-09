import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'dart:html' as html;

class DownloadPage extends StatelessWidget {
  const DownloadPage({super.key});

  void _downloadApk() {
    // Navigates the browser to download the local app-release.apk file
    html.window.open('/app-release.apk', '_blank');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.paper,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/mayvel_logo.png', width: 250),
              const SizedBox(height: 48),
              Container(
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.android,
                        size: 60, color: Color(0xFF3DDC84)),
                    const SizedBox(height: 16),
                    Text(
                      'Daily Task Tracker APK',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.ink,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Download and install the official Mayvel application directly to your Android device for the best offline and mobile experience.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.inkSoft,
                            height: 1.5,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.download_rounded),
                        label: const Text('Download APK'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        onPressed: _downloadApk,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(
                      'Note: You may need to allow "Install from Unknown Sources" in your device settings.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.inkSoft,
                            fontStyle: FontStyle.italic,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              TextButton(
                onPressed: () {
                  html.window.open('/', '_self');
                },
                child: const Text('Return to Web App Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
