
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../config/constants.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_shimmer.dart';
import '../../../../core/widgets/neon_button.dart';
import '../../../bookings/presentation/bloc/bookings_bloc.dart';
import '../bloc/clubs_bloc.dart';
import '../bloc/clubs_event.dart';
import '../bloc/clubs_state.dart';
import '../widgets/booking_bottom_sheet.dart';
import '../widgets/slot_grid.dart';
import '../../domain/entities/club.dart';
import '../../domain/entities/slot.dart';
import '../../domain/usecases/get_club_detail_usecase.dart';
import '../../domain/usecases/get_slots_usecase.dart';
import '../../../../injection.dart';

class ClubDetailPage extends StatefulWidget {
  final int clubId;

  const ClubDetailPage({super.key, required this.clubId});

  @override
  State<ClubDetailPage> createState() => _ClubDetailPageState();
}

class _ClubDetailPageState extends State<ClubDetailPage> {
  Club? _club;
  List<Slot> _slots = [];
  Slot? _selectedSlot;
  DateTime _selectedDate = DateTime.now();
  bool _loadingClub = true;
  bool _loadingSlots = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadClub();
  }

  Future<void> _loadClub() async {
    setState(() {
      _loadingClub = true;
      _error = null;
    });
    final result = await sl<GetClubDetailUseCase>()(
        ClubDetailParams(id: widget.clubId));
    result.fold(
      (f) => setState(() {
        _error = f.message;
        _loadingClub = false;
      }),
      (club) {
        setState(() {
          _club = club;
          _loadingClub = false;
        });
        _loadSlots();
      },
    );
  }

  Future<void> _loadSlots() async {
    setState(() {
      _loadingSlots = true;
      _selectedSlot = null;
    });
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final result = await sl<GetSlotsUseCase>()(
        SlotsParams(clubId: widget.clubId, date: dateStr));
    result.fold(
      (f) => setState(() => _loadingSlots = false),
      (slots) => setState(() {
        _slots = slots;
        _loadingSlots = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppConstants.backgroundPrimary),
      body: _loadingClub
          ? const Center(
              child: CircularProgressIndicator(
                  color: Color(AppConstants.primaryAccent)))
          : _error != null
              ? AppErrorWidget(message: _error!, onRetry: _loadClub)
              : _club == null
                  ? const SizedBox.shrink()
                  : CustomScrollView(
                      slivers: [
                        _buildSliverAppBar(),
                        SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildClubInfo(),
                              _buildDateSelector(),
                              _buildSlotsSection(),
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ],
                    ),
      floatingActionButton: _selectedSlot != null && _club != null
          ? _buildBookButton()
          : null,
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: const Color(AppConstants.backgroundPrimary),
      iconTheme:
          const IconThemeData(color: Color(AppConstants.primaryAccent)),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            _club!.imageUrl != null && _club!.imageUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: _club!.imageUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _placeholderImage(),
                  )
                : _placeholderImage(),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    const Color(AppConstants.backgroundPrimary),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      color: const Color(AppConstants.backgroundSecondary),
      child: const Center(
        child:
            Icon(Icons.videogame_asset, size: 64, color: Colors.white24),
      ),
    );
  }

  Widget _buildClubInfo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _club!.name,
                  style: GoogleFonts.orbitron(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(AppConstants.primaryAccent)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: const Color(AppConstants.primaryAccent)
                          .withOpacity(0.4)),
                ),
                child: Text(
                  '${_club!.pricePerHour.toStringAsFixed(0)} UZS/hr',
                  style: GoogleFonts.orbitron(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
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
                  size: 16, color: Color(AppConstants.primaryAccent)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(_club!.location,
                    style: GoogleFonts.inter(
                        fontSize: 13, color: Colors.white54)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.star_rounded,
                  size: 16, color: Color(AppConstants.warningColor)),
              const SizedBox(width: 4),
              Text(
                '${_club!.rating.toStringAsFixed(1)} · ${_club!.totalReviews} reviews',
                style:
                    GoogleFonts.inter(fontSize: 13, color: Colors.white54),
              ),
            ],
          ),
          if (_club!.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              _club!.description,
              style: GoogleFonts.inter(fontSize: 13, color: Colors.white38),
            ),
          ],
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }

  Widget _buildDateSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SELECT DATE',
            style: GoogleFonts.orbitron(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white54,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 72,
            child: Builder(builder: (context) {
              final today = DateTime.now();
              return ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 14,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final date = today.add(Duration(days: index));
                final isSelected = DateFormat('yyyy-MM-dd')
                        .format(date) ==
                    DateFormat('yyyy-MM-dd').format(_selectedDate);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = date;
                      _selectedSlot = null;
                    });
                    _loadSlots();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 52,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(AppConstants.primaryAccent)
                              .withOpacity(0.15)
                          : const Color(AppConstants.backgroundSecondary),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(AppConstants.primaryAccent)
                            : const Color(AppConstants.primaryAccent)
                                .withOpacity(0.15),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('EEE').format(date).toUpperCase(),
                          style: GoogleFonts.orbitron(
                            fontSize: 9,
                            color: isSelected
                                ? const Color(AppConstants.primaryAccent)
                                : Colors.white38,
                          ),
                        ),
                        Text(
                          DateFormat('d').format(date),
                          style: GoogleFonts.orbitron(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? const Color(AppConstants.primaryAccent)
                                : Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
          child: Row(
            children: [
              Text(
                'AVAILABLE SLOTS',
                style: GoogleFonts.orbitron(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white54,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              _LegendDot(
                  color: const Color(AppConstants.successColor),
                  label: 'Available'),
              const SizedBox(width: 12),
              _LegendDot(
                  color: const Color(AppConstants.warningColor),
                  label: 'Low'),
              const SizedBox(width: 12),
              _LegendDot(
                  color: const Color(AppConstants.errorColor), label: 'Full'),
            ],
          ),
        ),
        if (_loadingSlots)
          const SlotShimmer()
        else
          SlotGrid(
            slots: _slots,
            selectedSlot: _selectedSlot,
            onSlotSelected: (slot) => setState(() => _selectedSlot = slot),
          ),
      ],
    );
  }

  Widget _buildBookButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: NeonButton(
        label: 'BOOK NOW',
        onPressed: _onBookNow,
        icon: Icons.event_available_outlined,
        width: double.infinity,
      ),
    );
  }

  void _onBookNow() async {
    if (_selectedSlot == null || _club == null) return;
    final booked = await BookingBottomSheet.show(
        context, _club!, _selectedSlot!, _selectedDate);
    if (booked == true) {
      setState(() => _selectedSlot = null);
      _loadSlots();
    }
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.inter(fontSize: 10, color: Colors.white38)),
      ],
    );
  }
}
