import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../../../../config/constants.dart';
import '../../../../injection.dart';
import '../../domain/entities/club_map_info.dart';
import '../bloc/map_bloc.dart';
import '../bloc/map_event.dart';
import '../bloc/map_state.dart';

class ClubLocatorPage extends StatefulWidget {
  final int? focusClubId;
  final String? focusClubName;
  final double? focusLatitude;
  final double? focusLongitude;

  const ClubLocatorPage({
    super.key,
    this.focusClubId,
    this.focusClubName,
    this.focusLatitude,
    this.focusLongitude,
  });

  bool get isSingleClubMode =>
      focusLatitude != null && focusLongitude != null;

  @override
  State<ClubLocatorPage> createState() => _ClubLocatorPageState();
}

class _ClubLocatorPageState extends State<ClubLocatorPage> {
  final _searchController = TextEditingController();
  final _mapController = MapController();
  bool _availableNow = false;
  ClubMapInfo? _selectedClub;

  // Tashkent city center
  static const _tashkentCenter = LatLng(41.2995, 69.2401);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Marker> _buildMarkers(List<ClubMapInfo> clubs) {
    return clubs.where((c) => c.hasCoordinates).map((club) {
      final isSelected = _selectedClub?.id == club.id;
      return Marker(
        point: LatLng(club.latitude!, club.longitude!),
        width: 48,
        height: 58,
        child: GestureDetector(
          onTap: () => setState(() => _selectedClub = club),
          child: _MapPin(selected: isSelected),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isSingleClubMode) {
      return _buildSingleClubMap(context);
    }
    return _buildAllClubsMap(context);
  }

  Widget _buildSingleClubMap(BuildContext context) {
    final target = LatLng(widget.focusLatitude!, widget.focusLongitude!);

    return Scaffold(
      backgroundColor: const Color(AppConstants.backgroundPrimary),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: target,
              initialZoom: 16,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.gaming_club_tashkent',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: target,
                    width: 48,
                    height: 58,
                    child: const _MapPin(selected: true),
                  ),
                ],
              ),
            ],
          ),
          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  _GlassButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(AppConstants.backgroundSecondary)
                            .withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        widget.focusClubName ?? 'Club Location',
                        style: GoogleFonts.orbitron(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllClubsMap(BuildContext outerContext) {
    return BlocProvider(
      create: (_) =>
          sl<MapBloc>()..add(const MapClubsLoadRequested()),
      child: Builder(builder: (context) => Scaffold(
        backgroundColor: const Color(AppConstants.backgroundPrimary),
        body: Stack(
          children: [
            // OpenStreetMap (full screen)
            BlocBuilder<MapBloc, MapState>(
              builder: (context, state) {
                final clubs =
                    state is MapLoaded ? state.clubs : <ClubMapInfo>[];
                return FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _tashkentCenter,
                    initialZoom: 12,
                    onTap: (_, __) =>
                        setState(() => _selectedClub = null),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName:
                          'com.example.gaming_club_tashkent',
                    ),
                    MarkerLayer(markers: _buildMarkers(clubs)),
                  ],
                );
              },
            ),

            // Top search bar
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        _GlassButton(
                          icon: Icons.arrow_back_rounded,
                          onTap: () => context.pop(),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                            child: _SearchBar(
                                controller: _searchController)),
                      ],
                    ),
                  ),
                  BlocSelector<MapBloc, MapState, MapSortMode>(
                    selector: (state) =>
                        state is MapLoaded
                            ? state.sortMode
                            : MapSortMode.none,
                    builder: (context, sortMode) {
                      return _FilterRow(
                        availableNow: _availableNow,
                        sortMode: sortMode,
                        onChanged: (availableNow, sort) {
                          setState(() => _availableNow = availableNow);
                          context.read<MapBloc>().add(
                                MapClubsLoadRequested(
                                  availableNow: availableNow,
                                  sortMode: sort,
                                  search: _searchController.text.isEmpty
                                      ? null
                                      : _searchController.text,
                                ),
                              );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),

            // Bottom club list
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: BlocBuilder<MapBloc, MapState>(
                builder: (context, state) {
                  if (state is MapLoaded && state.clubs.isNotEmpty) {
                    return _ClubBottomSheet(
                      clubs: state.clubs,
                      selectedClub: _selectedClub,
                      onClubTap: (club) {
                        setState(() => _selectedClub = club);
                        if (club.hasCoordinates) {
                          _mapController.move(
                            LatLng(club.latitude!, club.longitude!),
                            15,
                          );
                        }
                      },
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),

            // Selected club info bubble
            if (_selectedClub != null)
              Positioned(
                left: 16,
                right: 16,
                bottom: 220,
                child: _ClubInfoBubble(
                  club: _selectedClub!,
                  onClose: () => setState(() => _selectedClub = null),
                ).animate().fadeIn().slideY(begin: 0.2),
              ),
          ],
        ),
      )),
    );
  }
}

// ── Custom map pin ────────────────────────────────────────────────────────────

class _MapPin extends StatelessWidget {
  final bool selected;
  const _MapPin({this.selected = false});

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? const Color(AppConstants.primaryAccent)
        : const Color(0xFF6C63FF);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: selected ? 12 : 6,
                spreadRadius: selected ? 2 : 0,
              ),
            ],
          ),
          child: Icon(
            Icons.sports_esports_rounded,
            color: Colors.white,
            size: selected ? 18 : 16,
          ),
        ),
        CustomPaint(
          size: const Size(12, 10),
          painter: _TrianglePainter(color),
        ),
      ],
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  const _TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TrianglePainter old) => old.color != color;
}

// ── Support widgets ───────────────────────────────────────────────────────────

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(AppConstants.backgroundSecondary)
              .withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  const _SearchBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: const Color(AppConstants.backgroundSecondary)
            .withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search clubs...',
          hintStyle:
              GoogleFonts.inter(color: Colors.white38, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded,
              color: Color(AppConstants.primaryAccent), size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear,
                      color: Colors.white38, size: 16),
                  onPressed: () {
                    controller.clear();
                    context
                        .read<MapBloc>()
                        .add(const MapSearchChanged(''));
                  },
                )
              : null,
        ),
        onChanged: (q) =>
            context.read<MapBloc>().add(MapSearchChanged(q)),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final bool availableNow;
  final MapSortMode sortMode;
  final void Function(bool availableNow, MapSortMode sort) onChanged;
  const _FilterRow(
      {required this.availableNow,
      required this.sortMode,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _FilterChip(
            label: 'Available Now',
            selected: availableNow,
            onSelected: (v) => onChanged(v, sortMode),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Top Rated',
            selected: sortMode == MapSortMode.topRated,
            onSelected: (_) => onChanged(
              availableNow,
              sortMode == MapSortMode.topRated
                  ? MapSortMode.none
                  : MapSortMode.topRated,
            ),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Cheapest',
            selected: sortMode == MapSortMode.cheapest,
            onSelected: (_) => onChanged(
              availableNow,
              sortMode == MapSortMode.cheapest
                  ? MapSortMode.none
                  : MapSortMode.cheapest,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  const _FilterChip(
      {required this.label,
      required this.selected,
      required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onSelected(!selected),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? const Color(AppConstants.primaryAccent)
              : const Color(AppConstants.backgroundSecondary)
                  .withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? const Color(AppConstants.primaryAccent)
                : Colors.white24,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: selected ? Colors.black : Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ClubBottomSheet extends StatelessWidget {
  final List<ClubMapInfo> clubs;
  final ClubMapInfo? selectedClub;
  final ValueChanged<ClubMapInfo> onClubTap;

  const _ClubBottomSheet({
    required this.clubs,
    this.selectedClub,
    required this.onClubTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: const Color(AppConstants.backgroundSecondary)
            .withValues(alpha: 0.97),
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(12),
              itemCount: clubs.length,
              itemBuilder: (context, i) => _ClubCard(
                club: clubs[i],
                isSelected: selectedClub?.id == clubs[i].id,
                onTap: () => onClubTap(clubs[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClubCard extends StatelessWidget {
  final ClubMapInfo club;
  final bool isSelected;
  final VoidCallback onTap;
  const _ClubCard(
      {required this.club, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###');
    final availColor = club.availableComputers == 0
        ? Colors.red
        : club.availableComputers < club.totalComputers * 0.3
            ? Colors.orange
            : const Color(0xFF76FF03);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 160,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(AppConstants.primaryAccent)
                  .withValues(alpha: 0.1)
              : const Color(AppConstants.backgroundPrimary),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(AppConstants.primaryAccent)
                : Colors.white24,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              club.name,
              style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.star_rounded, color: Colors.amber, size: 12),
                const SizedBox(width: 2),
                Text(club.rating.toStringAsFixed(1),
                    style: GoogleFonts.inter(
                        color: Colors.white70, fontSize: 11)),
              ],
            ),
            const Spacer(),
            Text(
              club.availabilityLabel,
              style: GoogleFonts.inter(
                  color: availColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
            Text(
              '${fmt.format(club.pricePerHour)} UZS/hr',
              style:
                  GoogleFonts.inter(color: Colors.white54, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClubInfoBubble extends StatelessWidget {
  final ClubMapInfo club;
  final VoidCallback onClose;
  const _ClubInfoBubble({required this.club, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(AppConstants.backgroundSecondary),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(AppConstants.primaryAccent)
                .withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(club.name,
                    style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(club.address ?? club.location,
                    style: GoogleFonts.inter(
                        color: Colors.white54, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Text('${fmt.format(club.pricePerHour)} UZS/hr',
                    style: GoogleFonts.inter(
                        color: const Color(AppConstants.primaryAccent),
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              ElevatedButton(
                onPressed: () => context.push('/clubs/${club.id}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(AppConstants.primaryAccent),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('BOOK',
                    style: GoogleFonts.orbitron(
                        fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white38, size: 16),
                onPressed: onClose,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
