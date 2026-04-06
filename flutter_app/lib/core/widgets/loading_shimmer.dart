import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/constants.dart';

class LoadingShimmer extends StatelessWidget {
  const LoadingShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(AppConstants.backgroundSecondary),
      highlightColor: const Color(AppConstants.surfaceColor),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (_, __) => const _ShimmerClubCard(),
      ),
    );
  }
}

class _ShimmerClubCard extends StatelessWidget {
  const _ShimmerClubCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
    );
  }
}

class SlotShimmer extends StatelessWidget {
  const SlotShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(AppConstants.backgroundSecondary),
      highlightColor: const Color(AppConstants.surfaceColor),
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.8,
        ),
        itemCount: 12,
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
