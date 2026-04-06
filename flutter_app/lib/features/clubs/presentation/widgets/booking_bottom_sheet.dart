import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/constants.dart';
import '../../../../core/widgets/neon_button.dart';
import '../../../bookings/presentation/bloc/bookings_bloc.dart';
import '../../../bookings/presentation/bloc/bookings_event.dart';
import '../../../bookings/presentation/bloc/bookings_state.dart';
import '../../domain/entities/club.dart';
import '../../domain/entities/slot.dart';

class BookingBottomSheet extends StatefulWidget {
  final Club club;
  final Slot slot;

  const BookingBottomSheet({super.key, required this.club, required this.slot});

  static Future<bool?> show(
      BuildContext context, Club club, Slot slot) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<BookingsBloc>(),
        child: BookingBottomSheet(club: club, slot: slot),
      ),
    );
  }

  @override
  State<BookingBottomSheet> createState() => _BookingBottomSheetState();
}

class _BookingBottomSheetState extends State<BookingBottomSheet> {
  int _computersCount = 1;
  int _durationHours = 1;

  double get _totalPrice =>
      widget.club.pricePerHour * _computersCount * _durationHours;

  int get _maxComputers => widget.slot.availableComputers.clamp(1, 10);

  @override
  Widget build(BuildContext context) {
    return BlocListener<BookingsBloc, BookingsState>(
      listener: (context, state) {
        if (state is BookingCreated) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle,
                      color: Color(AppConstants.successColor)),
                  const SizedBox(width: 8),
                  Text('Booking confirmed!',
                      style: GoogleFonts.inter(color: Colors.white)),
                ],
              ),
              backgroundColor: const Color(AppConstants.backgroundSecondary),
            ),
          );
        } else if (state is BookingActionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message,
                  style: GoogleFonts.inter(color: Colors.white)),
              backgroundColor: const Color(AppConstants.errorColor),
            ),
          );
        }
      },
      child: Container(
        decoration: const BoxDecoration(
          color: Color(AppConstants.backgroundSecondary),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(
              color: Color(AppConstants.primaryAccent),
              width: 1,
            ),
          ),
        ),
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHandle(),
            const SizedBox(height: 16),
            _buildHeader(),
            const SizedBox(height: 20),
            _buildSlotInfo(),
            const SizedBox(height: 20),
            _buildComputersCounter(),
            const SizedBox(height: 16),
            _buildDurationCounter(),
            const SizedBox(height: 20),
            _buildPriceSummary(),
            const SizedBox(height: 20),
            _buildConfirmButton(),
          ],
        ),
      ).animate().slideY(begin: 1, end: 0, duration: 300.ms, curve: Curves.easeOut),
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: const Color(AppConstants.primaryAccent).withOpacity(0.4),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BOOK SLOT',
          style: GoogleFonts.orbitron(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(AppConstants.primaryAccent),
            letterSpacing: 2,
          ),
        ),
        Text(
          widget.club.name,
          style: GoogleFonts.inter(fontSize: 14, color: Colors.white54),
        ),
      ],
    );
  }

  Widget _buildSlotInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(AppConstants.backgroundPrimary),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(AppConstants.primaryAccent).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time,
              color: Color(AppConstants.primaryAccent), size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_fmt(widget.slot.startTime)} — ${_fmt(widget.slot.endTime)}',
                style: GoogleFonts.orbitron(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Text(
                '${widget.slot.availableComputers} computers available',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.white54),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComputersCounter() {
    return _CounterRow(
      label: 'COMPUTERS',
      value: _computersCount,
      min: 1,
      max: _maxComputers,
      onChanged: (v) => setState(() => _computersCount = v),
    );
  }

  Widget _buildDurationCounter() {
    return _CounterRow(
      label: 'HOURS',
      value: _durationHours,
      min: 1,
      max: 8,
      onChanged: (v) => setState(() => _durationHours = v),
    );
  }

  Widget _buildPriceSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(AppConstants.primaryAccent).withOpacity(0.1),
            const Color(AppConstants.primaryAccent).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(AppConstants.primaryAccent).withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'TOTAL PRICE',
            style: GoogleFonts.orbitron(
              fontSize: 12,
              color: Colors.white54,
              letterSpacing: 1,
            ),
          ),
          Text(
            '${_totalPrice.toStringAsFixed(0)} UZS',
            style: GoogleFonts.orbitron(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(AppConstants.primaryAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    return BlocBuilder<BookingsBloc, BookingsState>(
      builder: (context, state) {
        final isLoading = state is BookingCreating;
        return SizedBox(
          width: double.infinity,
          child: NeonButton(
            label: 'CONFIRM BOOKING',
            isLoading: isLoading,
            onPressed: isLoading ? null : _onConfirm,
            icon: Icons.check_circle_outline,
          ),
        );
      },
    );
  }

  void _onConfirm() {
    context.read<BookingsBloc>().add(
          BookingCreateRequested(
            clubSlot: widget.slot.id,
            computersCount: _computersCount,
            durationHours: _durationHours,
          ),
        );
  }

  String _fmt(String time) => time.length >= 5 ? time.substring(0, 5) : time;
}

class _CounterRow extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _CounterRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.orbitron(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
            letterSpacing: 1,
          ),
        ),
        Row(
          children: [
            _IconBtn(
              icon: Icons.remove,
              onTap: value > min ? () => onChanged(value - 1) : null,
            ),
            SizedBox(
              width: 48,
              child: Center(
                child: Text(
                  '$value',
                  style: GoogleFonts.orbitron(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(AppConstants.primaryAccent),
                  ),
                ),
              ),
            ),
            _IconBtn(
              icon: Icons.add,
              onTap: value < max ? () => onChanged(value + 1) : null,
            ),
          ],
        ),
      ],
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _IconBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled
              ? const Color(AppConstants.primaryAccent).withOpacity(0.15)
              : Colors.white10,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled
                ? const Color(AppConstants.primaryAccent).withOpacity(0.5)
                : Colors.white12,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled
              ? const Color(AppConstants.primaryAccent)
              : Colors.white24,
        ),
      ),
    );
  }
}
