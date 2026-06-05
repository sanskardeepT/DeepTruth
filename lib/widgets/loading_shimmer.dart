import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../core/constants/app_colors.dart';

class LoadingShimmer extends StatelessWidget {
  final double height;
  final double? width;
  final BorderRadius? borderRadius;

  const LoadingShimmer({
    super.key,
    required this.height,
    this.width,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor:  AppColors.bgCard,
      highlightColor: AppColors.bgCardHover,
      child: Container(
        height: height,
        width:  width ?? double.infinity,
        decoration: BoxDecoration(
          color:        AppColors.bgCard,
          borderRadius: borderRadius ?? BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class NewsCardShimmer extends StatelessWidget {
  const NewsCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LoadingShimmer(height: 180),
          const SizedBox(height: 8),
          const LoadingShimmer(height: 20),
          const SizedBox(height: 6),
          const LoadingShimmer(height: 14),
          const SizedBox(height: 4),
          LoadingShimmer(height: 14, width: MediaQuery.sizeOf(context).width * 0.6),
        ],
      ),
    );
  }
}

class CheckResultShimmer extends StatelessWidget {
  const CheckResultShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const LoadingShimmer(height: 160, borderRadius: BorderRadius.all(Radius.circular(20))),
          const SizedBox(height: 16),
          const LoadingShimmer(height: 80),
          const SizedBox(height: 12),
          const LoadingShimmer(height: 120),
        ],
      ),
    );
  }
}

class ListShimmer extends StatelessWidget {
  final int count;
  const ListShimmer({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics:    const NeverScrollableScrollPhysics(),
      itemCount:  count,
      itemBuilder: (_, __) => const NewsCardShimmer(),
    );
  }
}
