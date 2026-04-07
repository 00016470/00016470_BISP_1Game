import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/constants.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(AppConstants.warningColor).withValues(alpha: 0.15),
      child: Row(
        children: [
          const Icon(Icons.wifi_off,
              size: 16, color: Color(AppConstants.warningColor)),
          const SizedBox(width: 8),
          Text(
            'NO INTERNET CONNECTION',
            style: GoogleFonts.orbitron(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(AppConstants.warningColor),
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    ).animate().slideY(begin: -1, end: 0, duration: 300.ms);
  }
}
