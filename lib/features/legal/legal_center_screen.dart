import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/firebase_service.dart';

class LegalCenterScreen extends StatelessWidget {
  const LegalCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgSecondary,
        elevation: 0,
        title: const Text(
          'LEGAL & COMPLIANCE CENTER',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.accent, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIntroHeader(),
              const SizedBox(height: 20),
              const Text(
                'OFFICIAL POLICIES & AGREEMENTS',
                style: TextStyle(
                  color: AppColors.textAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              _buildPolicyTile(
                title: '1. Terms of Service (ToS)',
                subtitle: 'Platform usage rules, liabilities, and intellectual property.',
                icon: Icons.gavel_rounded,
                content: _termsOfServiceText,
              ),
              _buildPolicyTile(
                title: '2. Privacy Policy',
                subtitle: 'GDPR compliance, telemetry, device ID, & Firebase disclosure.',
                icon: Icons.privacy_tip_rounded,
                content: _privacyPolicyText,
              ),
              _buildPolicyTile(
                title: '3. AI Usage & Model Disclosure',
                subtitle: 'Use of Gemini Vision APIs and on-device temporal models.',
                icon: Icons.psychology_rounded,
                content: _aiUsageDisclosureText,
              ),
              _buildPolicyTile(
                title: '4. Forensic Verification Disclaimer',
                subtitle: 'Status of verification verdicts as statistical estimations.',
                icon: Icons.report_problem_rounded,
                content: _verificationDisclaimerText,
              ),
              _buildPolicyTile(
                title: '5. User Content & Abuse Policy',
                subtitle: 'Prohibitions on illegal content scanning and harassment.',
                icon: Icons.content_paste_search_rounded,
                content: _userContentPolicyText,
              ),
              _buildPolicyTile(
                title: '6. Copyright & DMCA Policy',
                subtitle: 'Procedures for requesting removal of infringing material.',
                icon: Icons.copyright_rounded,
                content: _copyrightPolicyText,
              ),
              _buildPolicyTile(
                title: '7. Contact & Grievance Registry',
                subtitle: 'Grievance Officer details and official support channels.',
                icon: Icons.contact_support_rounded,
                content: _contactGrievanceText,
              ),
              const SizedBox(height: 30),
              _buildBottomSupportCard(),
              const SizedBox(height: 20),
              _buildComplianceActionPanel(context),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComplianceActionPanel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lock_reset_rounded, color: AppColors.accent, size: 20),
              SizedBox(width: 8),
              Text(
                'GDPR / CCPA Privacy Control Center',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Exercise your right to be forgotten. You can purge your local search history or permanently delete your anonymous device profile below.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _confirmAndPurgeData(context),
                  icon: const Icon(Icons.delete_sweep_rounded, size: 16),
                  label: const Text('Purge Scans'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.divider),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _confirmAndDeleteAccount(context),
                  icon: const Icon(Icons.no_accounts_rounded, size: 16),
                  label: const Text('Delete Account'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger.withValues(alpha: 0.15),
                    foregroundColor: AppColors.danger,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: AppColors.danger, width: 0.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndPurgeData(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text('Purge Search History?', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'This will delete all locally saved scan results and reset your limit counts. Do you wish to proceed?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Purge All', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        if (Hive.isBoxOpen(AppConstants.boxChecks)) {
          await Hive.box<String>(AppConstants.boxChecks).clear();
        }
        if (Hive.isBoxOpen(AppConstants.boxClaimMemory)) {
          await Hive.box<String>(AppConstants.boxClaimMemory).clear();
        }
        
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
            'scanCountToday': 0,
            'lastScanDate': '',
          });
        }
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All search logs and caches have been purged.'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to purge data: $e'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  Future<void> _confirmAndDeleteAccount(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text('Delete Account Permanently?', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'This will purge your profile, streaks, and data from DeepTruth server systems. This action is irreversible. Proceed?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Account', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final uid = user.uid;
          
          // Clear cloud user document
          await FirebaseFirestore.instance.collection('users').doc(uid).delete();
          
          // Delete Firebase User identity
          await user.delete();
        }

        // Clear local storage boxes
        if (Hive.isBoxOpen(AppConstants.boxChecks)) {
          await Hive.box<String>(AppConstants.boxChecks).clear();
        }
        if (Hive.isBoxOpen(AppConstants.boxClaimMemory)) {
          await Hive.box<String>(AppConstants.boxClaimMemory).clear();
        }
        if (Hive.isBoxOpen(AppConstants.boxStreak)) {
          await Hive.box<String>(AppConstants.boxStreak).clear();
        }
        
        // Re-initialize a fresh anonymous session
        await FirebaseService.instance.initialize();

        if (context.mounted) {
          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppColors.bgCard,
              title: const Text('Identity Erased', style: TextStyle(color: AppColors.textPrimary)),
              content: const Text(
                'Your profile has been deleted and a fresh secure identity has been registered.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx); // Close dialog
                    Navigator.pop(context); // Exit compliance center
                  },
                  child: const Text('OK', style: TextStyle(color: AppColors.accent)),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Account deletion failed: $e. Try signing out and signing in again.'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  Widget _buildIntroHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: const Row(
        children: [
          Icon(Icons.shield_rounded, color: AppColors.accent, size: 36),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Global Security & Compliance Standards',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'DeepTruth operates in strict alignment with Google Play developer policies, GDPR rights, and AI platform compliance guidelines.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required String content,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.divider),
      ),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        collapsedIconColor: AppColors.textSecondary,
        iconColor: AppColors.accent,
        leading: Icon(icon, color: AppColors.accent, size: 22),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
        childrenPadding: const EdgeInsets.all(16),
        expandedAlignment: Alignment.topLeft,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgPrimary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.divider),
            ),
            child: Text(
              content,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.5,
                fontFamily: 'Courier', // Gives a premium developer/forensics feel
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSupportCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.accent.withValues(alpha: 0.1), AppColors.bgSecondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.mail_outline_rounded, color: AppColors.accent, size: 20),
              SizedBox(width: 8),
              Text(
                'Legal Grievance & Escalation Officer',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'For official DMCA takedowns, data deletion requests under GDPR, or platform abuse reporting, reach out to our dedicated grievance portal:',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.bgPrimary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'grievance@deeptruth.app',
              style: TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  POLICIES LEGAL TEXT TEMPLATES
  // ══════════════════════════════════════════════════════════════════

  static const String _termsOfServiceText = 
'''DEEPTRUTH TERMS OF SERVICE
Effective Date: June 12, 2026

1. ACCEPTANCE OF TERMS
By downloading, installing, or accessing the DeepTruth application ("Service"), you agree to be bound by these Terms. If you do not agree, uninstall the app immediately.

2. SERVICE SCOPE & AI VERDICT NATURE
DeepTruth is a forensic-consensus utility designed to evaluate digital media integrity. The verdicts generated ("TRUE", "FALSE", "MISLEADING") are computed statistical estimations based on available visual/OSINT metadata plugins and should not be construed as legally binding judgments or absolute truths.

3. ACCEPTABLE USE LICENSE
You are granted a limited, non-exclusive, non-transferable, revocable license to access the verification engine. You agree NOT to:
- Use the platform to harass, dox, or intimidate individuals.
- Submit materials containing CSAM, non-consensual pornography, or state-sponsored secrets.
- Attempt reverse engineering of on-device consensus or hashing models.

4. LIMITATION OF LIABILITY
DeepTruth, its founders, and affiliates shall not be liable for any direct, indirect, incidental, or consequential damages resulting from user reliance on verification reports or metadata verdicts.''';

  static const String _privacyPolicyText = 
'''DEEPTRUTH PRIVACY POLICY
Effective Date: June 12, 2026

1. DATA COLLECTION & TELEMETRY
DeepTruth collects non-personally identifiable telemetry to evaluate and train media trust algorithms. Collected information includes:
- Unique SHA-256 asset hashes (generated locally on your device).
- Diagnostic logs (Firebase Crashlytics).
- Anonymous installations and platform details.

2. GDPR & CCPA USER RIGHTS
If you are located in the European Union (EEA) or California:
- We do not store your IP address or link scans to your real-world identity.
- You have the right to request deletion of any cache records matching hashes you uploaded.
- You can request data erasure by contacting grievance@deeptruth.app.

3. FIREBASE & DATA LIFECYCLE
Asset hashes and verification consensus values are stored in a secure Google Cloud Firestore database ("Evidence Vault"). Media files uploaded for scanning are parsed in memory; binary image/video streams are discarded immediately after signature extraction.''';

  static const String _aiUsageDisclosureText = 
'''DEEPTRUTH AI & MODEL DISCLOSURE
Effective Date: June 12, 2026

1. TEMPORAL & VISION ANALYSIS LAYERS
DeepTruth utilizes advanced large-vision AI models (primarily Gemini 1.5 APIs) to parse text context and review image/video content frame-by-frame for deepfake features.

2. TRANSITIONAL FRAMEWORK WARNING
The current model implementation uses cloud-hosted generative AI pipelines to execute verification and semantic analysis. Over the course of the next twelve months, these cloud layers will be incrementally phased out and replaced by proprietary, local on-device neural nets to ensure absolute offline sovereignty and user privacy.''';

  static const String _verificationDisclaimerText = 
'''DEEPTRUTH FORENSIC VERDICT DISCLAIMER
Effective Date: June 12, 2026

1. NOT LEGAL ADVICE
The verification verdicts, trust scores, and evidence timelines produced by the DeepTruth app are for educational and research purposes only. 

2. LIMITS OF DETECTION
False positives and false negatives may occur due to:
- Highly complex diffusion models (AI generators).
- Deliberate stripping of EXIF and C2PA metadata by social media networks.
- Incomplete fact-checking records on Google Custom Search.
Users must exercise manual logical reasoning before sharing or reporting verification cards.''';

  static const String _userContentPolicyText = 
'''DEEPTRUTH USER CONTENT & ABUSE POLICY
Effective Date: June 12, 2026

1. PROHIBITED CONTENT TYPES
Users may not scan, upload, or process any of the following:
- Violent, graphic, or terroristic content.
- Copyrighted media scanned without fair-use justifications.
- Unauthorized recordings of private individuals.

2. SANCTION AND EXCLUSION
DeepTruth reserves the right to suspend API key access or black-list specific device tokens (anonymous UUIDs) if abuse patterns or rate limit violations are detected.''';

  static const String _copyrightPolicyText = 
'''DEEPTRUTH DMCA & COPYRIGHT POLICY
Effective Date: June 12, 2026

1. INFRINGEMENT CLAIMS
If you believe that a verification record or cached evidence entry in the Cloud Vault contains material that infringes your copyright, you may submit a formal takedown request under the Digital Millennium Copyright Act (DMCA).

2. REQUEST CONTENT
Send your request to grievance@deeptruth.app containing:
- The SHA-256 hash or report ID of the target entry.
- Direct proof of ownership of the intellectual property.
- Your official contact address and statement of good faith.''';

  static const String _contactGrievanceText = 
'''DEEPTRUTH CONTACT & GRIEVANCE REGISTRY
Effective Date: June 12, 2026

1. GRIEVANCE ESCALATION
Pursuant to international app distribution mandates and digital media guidelines, the designated grievance registry details are:

Email: grievance@deeptruth.app
Office: DeepTruth Lab Operations, New Delhi, India
Grievance Officer: Sanskardeep (Founder & Lead Engineer)

2. RESPONSE TIMELINE
We aim to reply to all formal regulatory complaints and data deletion requests within 72 hours of submission.''';
}
