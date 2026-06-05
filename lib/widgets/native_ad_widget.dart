import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Placeholder native ad widget. Replace with actual NativeAd implementation
/// once you have your real AdMob native ad unit ID.
class NativeAdWidget extends StatelessWidget {
  const NativeAdWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height:  100,
      margin:  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width:  60,
            height: 60,
            decoration: BoxDecoration(
              color:        AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.campaign_rounded,
                color: AppColors.textMuted, size: 28),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment:  MainAxisAlignment.center,
              children: [
                Row(children: [
                  Text('Ad', style: TextStyle(
                      color: AppColors.textMuted, fontSize: 9,
                      fontWeight: FontWeight.bold)),
                  SizedBox(width: 4),
                  Text('Sponsored Content',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                ]),
                SizedBox(height: 4),
                Text('Advertisement loads here',
                    style: TextStyle(
                        color:      AppColors.textSecondary,
                        fontSize:   13,
                        fontWeight: FontWeight.w500)),
                SizedBox(height: 4),
                Text('Install now',
                    style: TextStyle(color: AppColors.accent, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
