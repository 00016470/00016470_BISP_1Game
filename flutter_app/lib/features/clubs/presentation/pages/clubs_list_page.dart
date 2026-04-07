import 'package:go_router/go_router.dart';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/constants.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_shimmer.dart';
import '../bloc/clubs_bloc.dart';
import '../bloc/clubs_event.dart';
import '../bloc/clubs_state.dart';
import '../widgets/club_card.dart';

class ClubsListPage extends StatefulWidget {
  const ClubsListPage({super.key});

  @override
  State<ClubsListPage> createState() => _ClubsListPageState();
}

class _ClubsListPageState extends State<ClubsListPage> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<ClubsBloc>().add(ClubsLoadRequested());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppConstants.backgroundPrimary),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildSearchAndSort(),
            Expanded(
              child: BlocBuilder<ClubsBloc, ClubsState>(
                builder: (context, state) {
                  if (state is ClubsLoading) return const LoadingShimmer();
                  if (state is ClubsError) {
                    return AppErrorWidget(
                      message: state.message,
                      onRetry: () =>
                          context.read<ClubsBloc>().add(ClubsLoadRequested()),
                    );
                  }
                  if (state is ClubsLoaded) {
                    if (state.filteredClubs.isEmpty) {
                      return EmptyStateWidget(
                        message: state.searchQuery.isEmpty
                            ? 'No gaming clubs available'
                            : 'No clubs found for "${state.searchQuery}"',
                        icon: Icons.videogame_asset_off_outlined,
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () async {
                        context
                            .read<ClubsBloc>()
                            .add(ClubsLoadRequested());
                      },
                      color: const Color(AppConstants.primaryAccent),
                      backgroundColor:
                          const Color(AppConstants.backgroundSecondary),
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: state.filteredClubs.length,
                        itemBuilder: (context, index) {
                          final club = state.filteredClubs[index];
                          return ClubCard(
                            club: club,
                            index: index,
                            onTap: () =>
                                context.push('/clubs/${club.id}'),
                          );
                        },
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          const Icon(Icons.videogame_asset_rounded,
              color: Color(AppConstants.primaryAccent), size: 28),
          const SizedBox(width: 12),
          Text(
            '1GAME',
            style: GoogleFonts.orbitron(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(AppConstants.primaryAccent),
              letterSpacing: 2,
            ),
          ),
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }

  Widget _buildSearchAndSort() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
            onChanged: (v) =>
                context.read<ClubsBloc>().add(ClubsSearchChanged(v)),
            decoration: InputDecoration(
              hintText: 'Search clubs...',
              prefixIcon: const Icon(Icons.search,
                  color: Color(AppConstants.primaryAccent)),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white38),
                      onPressed: () {
                        _searchCtrl.clear();
                        context
                            .read<ClubsBloc>()
                            .add(ClubsSearchChanged(''));
                        setState(() {});
                      },
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 10),
          BlocBuilder<ClubsBloc, ClubsState>(
            builder: (context, state) {
              final sortType = state is ClubsLoaded
                  ? state.sortType
                  : ClubSortType.none;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _SortChip(
                      label: 'All',
                      isSelected: sortType == ClubSortType.none,
                      onTap: () => context
                          .read<ClubsBloc>()
                          .add(ClubsSortChanged(ClubSortType.none)),
                    ),
                    const SizedBox(width: 8),
                    _SortChip(
                      label: 'Top Rated',
                      icon: Icons.star_rounded,
                      isSelected: sortType == ClubSortType.byRating,
                      onTap: () => context
                          .read<ClubsBloc>()
                          .add(ClubsSortChanged(ClubSortType.byRating)),
                    ),
                    const SizedBox(width: 8),
                    _SortChip(
                      label: 'Cheapest',
                      icon: Icons.attach_money_rounded,
                      isSelected: sortType == ClubSortType.byPrice,
                      onTap: () => context
                          .read<ClubsBloc>()
                          .add(ClubsSortChanged(ClubSortType.byPrice)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SortChip({
    required this.label,
    this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(AppConstants.primaryAccent).withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(AppConstants.primaryAccent)
                : const Color(AppConstants.primaryAccent).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected
                    ? const Color(AppConstants.primaryAccent)
                    : Colors.white54,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? const Color(AppConstants.primaryAccent)
                    : Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
