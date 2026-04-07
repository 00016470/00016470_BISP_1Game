import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
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
  YandexMapController? _mapController;
  bool _availableNow = false;
  ClubMapInfo? _selectedClub;
  Uint8List? _markerBytes;

  // Tashkent city center
  static const _tashkentCenter =
      Point(latitude: 41.2995, longitude: 69.2401);

  @override
  void initState() {
    super.initState();
    _generateMarkerIcon();
  }

  Future<void> _generateMarkerIcon() async {
    const size = 96.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Shadow
    final shadow = Paint()
      ..color = Colors.black26
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(const Offset(size / 2, 30), 22, shadow);

    // Main pin body
    final pin = Paint()..color = const Color(0xFF6C63FF);
    canvas.drawCircle(const Offset(size / 2, 28), 22, pin);

    // White border
    final border = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(const Offset(size / 2, 28), 22, border);

    // Pointer triangle
    final pointer = Path()
      ..moveTo(size / 2 - 12, 44)
      ..lineTo(size / 2, 68)
      ..lineTo(size / 2 + 12, 44)
      ..close();
    canvas.drawPath(pointer, pin);

    // Gamepad icon (white)
    final icon = Paint()..color = Colors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: const Offset(size / 2, 28), width: 20, height: 10),
        const Radius.circular(5),
      ),
      icon,
    );
    // D-pad dots
    canvas.drawCircle(const Offset(size / 2 - 5, 28), 2, Paint()..color = const Color(0xFF6C63FF));
    canvas.drawCircle(const Offset(size / 2 + 5, 28), 2, Paint()..color = const Color(0xFF6C63FF));

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    if (mounted) {
      setState(() {
        _markerBytes = byteData!.buffer.asUint8List();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PlacemarkMapObject> _buildPlacemarks(List<ClubMapInfo> clubs) {
    if (_markerBytes == null) return [];
    return clubs.where((c) => c.hasCoordinates).map((club) {
      return PlacemarkMapObject(
        mapId: MapObjectId('club_${club.id}'),
        point: Point(latitude: club.latitude!, longitude: club.longitude!),
        opacity: 1.0,
        icon: PlacemarkIcon.single(
          PlacemarkIconStyle(
            image: BitmapDescriptor.fromBytes(_markerBytes!),
            scale: 3,
          ),
        ),
        onTap: (_, __) => setState(() => _selectedClub = club),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext outerContext) {
    if (widget.isSingleClubMode) {
      return _buildSingleClubMap(outerContext);
    }
    return _buildAllClubsMap(outerContext);
  }

  Widget _buildSingleClubMap(BuildContext context) {
    final target = Point(
      latitude: widget.focusLatitude!,
      longitude: widget.focusLongitude!,
    );

    final placemarks = _markerBytes != null
        ? [
            PlacemarkMapObject(
              mapId: MapObjectId('focus_${widget.focusClubId}'),
              point: target,
              opacity: 1.0,
              icon: PlacemarkIcon.single(
                PlacemarkIconStyle(
                  image: BitmapDescriptor.fromBytes(_markerBytes!),
                  scale: 3,
                ),
              ),
            ),
          ]
        : <PlacemarkMapObject>[];

    return Scaffold(
      backgroundColor: const Color(AppConstants.backgroundPrimary),
      body: Stack(
        children: [
          YandexMap(
            onMapCreated: (controller) async {
              _mapController = controller;
              await controller.moveCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(target: target, zoom: 16),
                ),
              );
            },
            mapObjects: placemarks,
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            // Yandex Map (full screen)
            BlocBuilder<MapBloc, MapState>(
              builder: (context, state) {
                final clubs =
                    state is MapLoaded ? state.clubs : <ClubMapInfo>[];
                return YandexMap(
                  onMapCreated: (controller) async {
                    _mapController = controller;
                    await controller.moveCamera(
                      CameraUpdate.newCameraPosition(
                        CameraPosition(
                          target: _tashkentCenter,
                          zoom: 12,
                        ),
                      ),
                    );
                  },
                  mapObjects: _buildPlacemarks(clubs),
                );
              },
            ),

            // Top search bar
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back + search
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
                        Expanded(child: _SearchBar(controller: _searchController)),
                      ],
                    ),
                  ),
                  // Filter chips
                  BlocSelector<MapBloc, MapState, MapSortMode>(
                    selector: (state) =>
                        state is MapLoaded ? state.sortMode : MapSortMode.none,
                    builder: (context, sortMode) {
                      return _FilterRow(
                        availableNow: _availableNow,
                        sortMode: sortMode,
                        onChanged: (availableNow, sort) {
                          setState(() => _availableNow = availableNow);
                          context.read<MapBloc>().add(MapClubsLoadRequested(
                                availableNow: availableNow,
                                sortMode: sort,
                                search: _searchController.text.isEmpty
                                    ? null
                                    : _searchController.text,
                              ));
                        },
                      );
                    },
                  ),
                ],
              ),
            ),

            // Bottom sheet — club list
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
                          _mapController?.moveCamera(
                            CameraUpdate.newCameraPosition(
                              CameraPosition(
                                target: Point(
                                  latitude: club.latitude!,
                                  longitude: club.longitude!,
                                ),
                                zoom: 15,
                              ),
                            ),
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
          hintStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded,
              color: Color(AppConstants.primaryAccent), size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white38, size: 16),
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
      {required this.label, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onSelected(!selected),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
              ? const Color(AppConstants.primaryAccent).withValues(alpha: 0.1)
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
                Icon(Icons.star_rounded, color: Colors.amber, size: 12),
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
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 10),
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
