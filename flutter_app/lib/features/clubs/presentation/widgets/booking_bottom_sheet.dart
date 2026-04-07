import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../config/constants.dart';
import '../../../../core/widgets/neon_button.dart';
import '../../../bookings/presentation/bloc/bookings_bloc.dart';
import '../../../bookings/presentation/bloc/bookings_event.dart';
import '../../../bookings/presentation/bloc/bookings_state.dart';
import '../../domain/entities/club.dart';
import '../../domain/entities/slot.dart';

enum _PayMethod { wallet, card, cash }

class BookingBottomSheet extends StatefulWidget {
  final Club club;
  final Slot slot;
  final DateTime selectedDate;

  const BookingBottomSheet({
    super.key,
    required this.club,
    required this.slot,
    required this.selectedDate,
  });

  static Future<bool?> show(
      BuildContext context, Club club, Slot slot, DateTime selectedDate) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<BookingsBloc>(),
        child: BookingBottomSheet(
            club: club, slot: slot, selectedDate: selectedDate),
      ),
    );
  }

  @override
  State<BookingBottomSheet> createState() => _BookingBottomSheetState();
}

class _BookingBottomSheetState extends State<BookingBottomSheet> {
  int _computersCount = 1;
  int _durationHours = 1;
  _PayMethod _payMethod = _PayMethod.wallet;
  String? _errorMessage;
  bool _isInsufficientBalance = false;

  // Card form fields
  final _cardNumber = TextEditingController();
  final _cardExpiry = TextEditingController();
  final _cardCvv = TextEditingController();
  final _cardHolder = TextEditingController();

  double get _totalPrice =>
      widget.club.pricePerHour * _computersCount * _durationHours;

  int get _maxComputers => widget.slot.availableComputers.clamp(1, 10);

  @override
  void dispose() {
    _cardNumber.dispose();
    _cardExpiry.dispose();
    _cardCvv.dispose();
    _cardHolder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BookingsBloc, BookingsState>(
      listener: (context, state) {
        if (state is BookingCreated) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(children: [
                const Icon(Icons.check_circle,
                    color: Color(AppConstants.successColor)),
                const SizedBox(width: 8),
                Text('Booking confirmed!',
                    style: GoogleFonts.inter(color: Colors.white)),
              ]),
              backgroundColor:
                  const Color(AppConstants.backgroundSecondary),
            ),
          );
        } else if (state is BookingActionError) {
          final msg = state.message;
          final insufficient =
              msg.toLowerCase().contains('insufficient');
          setState(() {
            _errorMessage = msg;
            _isInsufficientBalance = insufficient;
          });
        }
      },
      child: Container(
        decoration: const BoxDecoration(
          color: Color(AppConstants.backgroundSecondary),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(
                color: Color(AppConstants.primaryAccent), width: 1),
          ),
        ),
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHandle(),
              const SizedBox(height: 16),
              _buildHeader(),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                _buildErrorBanner(),
              ],
              const SizedBox(height: 20),
              _buildSlotInfo(),
              const SizedBox(height: 20),
              _buildComputersCounter(),
              const SizedBox(height: 16),
              _buildDurationCounter(),
              const SizedBox(height: 20),
              _buildPriceSummary(),
              const SizedBox(height: 20),
              _buildPaymentSelector(),
              if (_payMethod == _PayMethod.card) ...[
                const SizedBox(height: 16),
                _buildCardForm(),
              ],
              if (_payMethod == _PayMethod.cash) ...[
                const SizedBox(height: 12),
                _buildCashNote(),
              ],
              const SizedBox(height: 20),
              _buildConfirmButton(),
            ],
          ),
        ),
      ).animate().slideY(
          begin: 1, end: 0, duration: 300.ms, curve: Curves.easeOut),
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: const Color(AppConstants.primaryAccent)
              .withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final dateLabel = DateFormat('EEE, MMM d').format(widget.selectedDate);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('BOOK SLOT',
          style: GoogleFonts.orbitron(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(AppConstants.primaryAccent),
              letterSpacing: 2)),
      Text('${widget.club.name} · $dateLabel',
          style: GoogleFonts.inter(fontSize: 14, color: Colors.white54)),
    ]);
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.red, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _errorMessage!,
                  style: GoogleFonts.inter(
                      color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() {
                  _errorMessage = null;
                  _isInsufficientBalance = false;
                }),
                child: const Icon(Icons.close, color: Colors.red, size: 16),
              ),
            ],
          ),
          if (_isInsufficientBalance) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push('/wallet');
                },
                icon: const Icon(Icons.account_balance_wallet_rounded,
                    size: 16),
                label: Text('TOP UP WALLET',
                    style: GoogleFonts.orbitron(
                        fontSize: 11, fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                  backgroundColor: Colors.red.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ],
      ),
    ).animate().shakeX(hz: 3, amount: 4, duration: 400.ms);
  }

  Widget _buildSlotInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(AppConstants.backgroundPrimary),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(AppConstants.primaryAccent)
                .withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        const Icon(Icons.access_time,
            color: Color(AppConstants.primaryAccent), size: 20),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
              '${_fmt(widget.slot.startTime)} — ${_fmt(widget.slot.endTime)}',
              style: GoogleFonts.orbitron(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
          Text('${widget.slot.availableComputers} computers available',
              style:
                  GoogleFonts.inter(fontSize: 12, color: Colors.white54)),
        ]),
      ]),
    );
  }

  Widget _buildComputersCounter() => _CounterRow(
        label: 'COMPUTERS',
        value: _computersCount,
        min: 1,
        max: _maxComputers,
        onChanged: (v) => setState(() => _computersCount = v),
      );

  Widget _buildDurationCounter() => _CounterRow(
        label: 'HOURS',
        value: _durationHours,
        min: 1,
        max: 8,
        onChanged: (v) => setState(() => _durationHours = v),
      );

  Widget _buildPriceSummary() {
    final fmt = NumberFormat('#,###');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          const Color(AppConstants.primaryAccent).withValues(alpha: 0.1),
          const Color(AppConstants.primaryAccent).withValues(alpha: 0.05),
        ]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(AppConstants.primaryAccent)
                .withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('TOTAL PRICE',
                style: GoogleFonts.orbitron(
                    fontSize: 10,
                    color: Colors.white38,
                    letterSpacing: 1)),
            Text(
                '$_computersCount PC × $_durationHours hr × ${fmt.format(widget.club.pricePerHour)} UZS',
                style:
                    GoogleFonts.inter(fontSize: 11, color: Colors.white38)),
          ]),
          Text('${fmt.format(_totalPrice.toInt())} UZS',
              style: GoogleFonts.orbitron(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(AppConstants.primaryAccent))),
        ],
      ),
    );
  }

  Widget _buildPaymentSelector() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('PAYMENT METHOD',
          style: GoogleFonts.orbitron(
              fontSize: 10, color: Colors.white54, letterSpacing: 1.5)),
      const SizedBox(height: 10),
      Row(children: [
        _PayChip(
          label: 'WALLET',
          icon: Icons.account_balance_wallet_rounded,
          selected: _payMethod == _PayMethod.wallet,
          onTap: () => setState(() => _payMethod = _PayMethod.wallet),
        ),
        const SizedBox(width: 8),
        _PayChip(
          label: 'CARD',
          icon: Icons.credit_card_rounded,
          selected: _payMethod == _PayMethod.card,
          onTap: () => setState(() => _payMethod = _PayMethod.card),
        ),
        const SizedBox(width: 8),
        _PayChip(
          label: 'CASH',
          icon: Icons.payments_rounded,
          selected: _payMethod == _PayMethod.cash,
          onTap: () => setState(() => _payMethod = _PayMethod.cash),
        ),
      ]),
    ]);
  }

  Widget _buildCardForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(AppConstants.backgroundPrimary),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(AppConstants.primaryAccent)
                .withValues(alpha: 0.3)),
      ),
      child: Column(children: [
        _CardField(
          controller: _cardHolder,
          hint: 'Cardholder Name',
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 12),
        _CardField(
          controller: _cardNumber,
          hint: '0000  0000  0000  0000',
          icon: Icons.credit_card_rounded,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _CardNumberFormatter(),
          ],
          keyboardType: TextInputType.number,
          maxLength: 19,
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: _CardField(
              controller: _cardExpiry,
              hint: 'MM / YY',
              icon: Icons.calendar_today_rounded,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _ExpiryFormatter(),
              ],
              keyboardType: TextInputType.number,
              maxLength: 5,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _CardField(
              controller: _cardCvv,
              hint: 'CVV',
              icon: Icons.lock_outline_rounded,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              keyboardType: TextInputType.number,
              maxLength: 3,
              obscure: true,
            ),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          const Icon(Icons.lock_rounded, color: Colors.white38, size: 14),
          const SizedBox(width: 6),
          Text('Secured · Simulated payment only',
              style: GoogleFonts.inter(
                  color: Colors.white38, fontSize: 11)),
        ]),
      ]),
    );
  }

  Widget _buildCashNote() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.info_outline_rounded,
            color: Colors.orange, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Pay cash at the club. Booking is pending until validated by staff.',
            style: GoogleFonts.inter(
                color: Colors.orange, fontSize: 12),
          ),
        ),
      ]),
    );
  }

  Widget _buildConfirmButton() {
    return BlocBuilder<BookingsBloc, BookingsState>(
      builder: (context, state) {
        final isLoading = state is BookingCreating;
        return SizedBox(
          width: double.infinity,
          child: NeonButton(
            label: _payMethod == _PayMethod.cash
                ? 'CONFIRM (PAY AT CLUB)'
                : 'CONFIRM & PAY',
            isLoading: isLoading,
            onPressed: isLoading ? null : _onConfirm,
            icon: Icons.check_circle_outline,
          ),
        );
      },
    );
  }

  void _onConfirm() {
    setState(() {
      _errorMessage = null;
      _isInsufficientBalance = false;
    });
    final d = widget.selectedDate;
    String pad(int n) => n.toString().padLeft(2, '0');
    final dateStr = '${d.year}-${pad(d.month)}-${pad(d.day)}';
    final startIso = '${dateStr}T${widget.slot.startTime}:00Z';

    context.read<BookingsBloc>().add(BookingCreateRequested(
          clubId: widget.club.id,
          startTime: startIso,
          computersCount: _computersCount,
          durationHours: _durationHours,
          paymentMethod: _payMethod == _PayMethod.wallet
              ? 'WALLET'
              : _payMethod == _PayMethod.card
                  ? 'CARD'
                  : 'CASH',
        ));
  }

  String _fmt(String time) =>
      time.length >= 5 ? time.substring(0, 5) : time;
}

// ── Payment method chip ──────────────────────────────────────────────────────

class _PayChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _PayChip(
      {required this.label,
      required this.icon,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? const Color(AppConstants.primaryAccent)
                  .withValues(alpha: 0.15)
              : const Color(AppConstants.backgroundPrimary),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? const Color(AppConstants.primaryAccent)
                : Colors.white12,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon,
              size: 14,
              color: selected
                  ? const Color(AppConstants.primaryAccent)
                  : Colors.white38),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.orbitron(
                  fontSize: 9,
                  color: selected
                      ? const Color(AppConstants.primaryAccent)
                      : Colors.white38,
                  fontWeight: selected
                      ? FontWeight.bold
                      : FontWeight.normal)),
        ]),
      ),
    );
  }
}

// ── Card form field ──────────────────────────────────────────────────────────

class _CardField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputType? keyboardType;
  final int? maxLength;
  final bool obscure;

  const _CardField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.inputFormatters,
    this.keyboardType,
    this.maxLength,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.inter(color: Colors.white24, fontSize: 13),
        prefixIcon:
            Icon(icon, size: 18, color: Colors.white38),
        counterText: '',
        filled: true,
        fillColor: const Color(AppConstants.backgroundSecondary),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
              color: Color(AppConstants.primaryAccent)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white12),
        ),
      ),
    );
  }
}

// ── Text formatters ──────────────────────────────────────────────────────────

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue next) {
    final digits = next.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 16; i++) {
      if (i > 0 && i % 4 == 0) buffer.write('  ');
      buffer.write(digits[i]);
    }
    final result = buffer.toString();
    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue next) {
    final digits = next.text.replaceAll('/', '');
    if (digits.length <= 2) return next.copyWith(text: digits);
    final result = '${digits.substring(0, 2)}/${digits.substring(2, digits.length.clamp(0, 4))}';
    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}

// ── Counter row ──────────────────────────────────────────────────────────────

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
        Text(label,
            style: GoogleFonts.orbitron(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
                letterSpacing: 1)),
        Row(children: [
          _IconBtn(
            icon: Icons.remove,
            onTap: value > min ? () => onChanged(value - 1) : null,
          ),
          SizedBox(
            width: 48,
            child: Center(
              child: Text('$value',
                  style: GoogleFonts.orbitron(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(AppConstants.primaryAccent))),
            ),
          ),
          _IconBtn(
            icon: Icons.add,
            onTap: value < max ? () => onChanged(value + 1) : null,
          ),
        ]),
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
              ? const Color(AppConstants.primaryAccent)
                  .withValues(alpha: 0.15)
              : Colors.white10,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled
                ? const Color(AppConstants.primaryAccent)
                    .withValues(alpha: 0.5)
                : Colors.white12,
          ),
        ),
        child: Icon(icon,
            size: 18,
            color: enabled
                ? const Color(AppConstants.primaryAccent)
                : Colors.white24),
      ),
    );
  }
}
