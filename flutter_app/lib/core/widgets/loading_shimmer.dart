import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/constants.dart';

/// A loading shimmer widget that displays animated placeholder cards.
/// Used to indicate loading state while fetching club data.
/// Shows a list of 5 shimmering rectangular cards.
class LoadingShimmer extends StatelessWidget {
  /// Creates a LoadingShimmer widget.
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

/// A private widget representing a single shimmering club card placeholder.
/// Displays a white rectangular container with rounded corners.
class _ShimmerClubCard extends StatelessWidget {
  /// Creates a _ShimmerClubCard widget.
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

/// A loading shimmer widget for slot grids.
/// Used to indicate loading state while fetching slot availability.
/// Shows a grid of shimmering placeholder slots.
class SlotShimmer extends StatelessWidget {
  /// Creates a SlotShimmer widget.
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
