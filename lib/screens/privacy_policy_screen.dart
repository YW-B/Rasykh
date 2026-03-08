import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';
import '../theme/glass_widgets.dart';
import '../constants/urls.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepEmerald,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            children: [
              // App bar row
              Row(
                children: [
                  GlassButton(
                    onTap: () => Navigator.of(context).pop(),
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.arrow_back,
                      size: 20,
                      color: AppColors.emerald100.withValues(alpha: 0.70),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Privacy Policy',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GlassPanel(
                  borderRadius: 24,
                  padding: const EdgeInsets.all(20),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'سياسة الخصوصية',
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.start,
                          style: GoogleFonts.scheherazadeNew(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'يقوم تطبيق راسخ بتخزين تقدمك في الحفظ محلياً على جهازك. لا نقوم بجمع أو تخزين أي بيانات شخصية لك أو إرسالها إلى أي خوادم خارجية.',
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.start,
                          style: GoogleFonts.inter(
                            color: AppColors.emerald100.withValues(alpha: 0.8),
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'للاطلاع على سياسة الخصوصية كاملة، يرجى فتح الرابط التالي:',
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.start,
                          style: GoogleFonts.inter(
                            color: AppColors.emerald100.withValues(alpha: 0.8),
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () async {
                            final uri = Uri.parse(AppUrls.privacyPolicy);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          },
                          child: Text(
                            AppUrls.privacyPolicy,
                            textDirection: TextDirection.ltr,
                            textAlign: TextAlign.start,
                            style: GoogleFonts.inter(
                              color: AppColors.emerald400,
                              fontSize: 14,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.emerald400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
