import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/constants.dart';
import '../../domain/entities/club.dart';

class ClubCard extends StatelessWidget {
  final Club club;
  final VoidCallback onTap;
  final int index;

  const ClubCard({
    super.key,
    required this.club,
    required this.onTap,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(AppConstants.cardColor),
          border: Border.all(
            color: const Color(AppConstants.primaryAccent).withOpacity(0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(AppConstants.primaryAccent).withOpacity(0.05),
              blurRadius: 20,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImage(),
            _buildInfo(),
          ],
        ),
      )
          .animate(delay: Duration(milliseconds: index * 100))
          .fadeIn(duration: 400.ms)
          .slideY(begin: 0.1, end: 0),
    );
  }

  Widget _buildImage() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Stack(
        children: [
          SizedBox(
            height: 160,
            width: double.infinity,
            child: club.imageUrl != null && club.imageUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: club.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: const Color(AppConstants.backgroundSecondary),
                      child: const Center(
                        child: Icon(Icons.videogame_asset,
                            size: 48, color: Colors.white24),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: const Color(AppConstants.backgroundSecondary),
                      child: const Center(
                        child: Icon(Icons.videogame_asset,
                            size: 48, color: Colors.white24),
                      ),
                    ),
                  )
                : Container(
                    color: const Color(AppConstants.backgroundSecondary),
                    child: const Center(
                      child: Icon(Icons.videogame_asset,
                          size: 48, color: Colors.white24),
                    ),
                  ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(AppConstants.backgroundPrimary)
                    .withOpacity(0.85),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      const Color(AppConstants.primaryAccent).withOpacity(0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded,
                      size: 14, color: Color(AppConstants.warningColor)),
                  const SizedBox(width: 4),
                  Text(
                    club.rating.toStringAsFixed(1),
                    style: GoogleFonts.orbitron(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!club.isActive)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Center(
                  child: Text(
                    'CLOSED',
                    style: GoogleFonts.orbitron(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(AppConstants.errorColor),
                      letterSpacing: 3,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  club.name,
                  style: GoogleFonts.orbitron(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      const Color(AppConstants.primaryAccent).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(AppConstants.primaryAccent)
                        .withOpacity(0.4),
                  ),
                ),
                child: Text(
                  '${club.pricePerHour.toStringAsFixed(0)} UZS/hr',
                  style: GoogleFonts.orbitron(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(AppConstants.primaryAccent),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 14,
                  color: Color(AppConstants.primaryAccent)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  club.location,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: Colors.white54),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.reviews_outlined,
                  size: 14, color: Colors.white38),
              const SizedBox(width: 4),
              Text(
                '${club.totalReviews} reviews',
                style:
                    GoogleFonts.inter(fontSize: 12, color: Colors.white38),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
