import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> launchExternalUrl(BuildContext context, Uri uri, {String? errorMessage}) async {
  try {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage ?? 'Could not open link')),
      );
    }
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(errorMessage ?? 'Could not open link')),
    );
  }
}

Future<void> launchPhone(BuildContext context, String phoneDigits) async {
  final uri = Uri(scheme: 'tel', path: phoneDigits.replaceAll(RegExp(r'\s'), ''));
  await launchExternalUrl(context, uri, errorMessage: 'Could not start phone call');
}

Future<void> launchEmail(BuildContext context, String email) async {
  final uri = Uri(scheme: 'mailto', path: email);
  await launchExternalUrl(context, uri, errorMessage: 'Could not open email app');
}
