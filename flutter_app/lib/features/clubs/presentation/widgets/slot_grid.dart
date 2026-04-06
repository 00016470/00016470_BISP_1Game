import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/constants.dart';
import '../../domain/entities/slot.dart';

class SlotGrid extends StatelessWidget {
  final List<Slot> slots;
  final Slot? selectedSlot;
  final ValueChanged<Slot> onSlotSelected;

  const SlotGrid({
    super.key,
    required this.slots,
    required this.onSlotSelected,
    this.selectedSlot,
  });

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            'No slots available for this date',
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 14),
          ),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.6,
      ),
      itemCount: slots.length,
      itemBuilder: (context, index) {
        final slot = slots[index];
        return _SlotTile(
          slot: slot,
          isSelected: selectedSlot?.id == slot.id,
          onTap: () {
            if (slot.isAvailable && !slot.isFull) onSlotSelected(slot);
          },
        );
      },
    );
  }
}

class _SlotTile extends StatelessWidget {
  final Slot slot;
  final bool isSelected;
  final VoidCallback onTap;

  const _SlotTile({
    required this.slot,
    required this.isSelected,
    required this.onTap,
  });

  Color get _tileColor {
    if (!slot.isAvailable || slot.isFull) {
      return const Color(AppConstants.errorColor).withOpacity(0.1);
    }
    if (isSelected) {
      return const Color(AppConstants.primaryAccent).withOpacity(0.2);
    }
    if (slot.isLowAvailability) {
      return const Color(AppConstants.warningColor).withOpacity(0.1);
    }
    return const Color(AppConstants.successColor).withOpacity(0.05);
  }

  Color get _borderColor {
    if (!slot.isAvailable || slot.isFull) {
      return const Color(AppConstants.errorColor).withOpacity(0.4);
    }
    if (isSelected) return const Color(AppConstants.primaryAccent);
    if (slot.isLowAvailability) {
      return const Color(AppConstants.warningColor).withOpacity(0.6);
    }
    return const Color(AppConstants.successColor).withOpacity(0.3);
  }

  Color get _textColor {
    if (!slot.isAvailable || slot.isFull) {
      return const Color(AppConstants.errorColor).withOpacity(0.6);
    }
    if (isSelected) return const Color(AppConstants.primaryAccent);
    if (slot.isLowAvailability) return const Color(AppConstants.warningColor);
    return const Color(AppConstants.successColor);
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = !slot.isAvailable || slot.isFull;
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _tileColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _borderColor, width: isSelected ? 1.5 : 1),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(AppConstants.primaryAccent)
                        .withOpacity(0.2),
                    blurRadius: 8,
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _formatTime(slot.startTime),
              style: GoogleFonts.orbitron(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: _textColor,
              ),
            ),
            Text(
              _formatTime(slot.endTime),
              style: GoogleFonts.inter(fontSize: 9, color: _textColor.withOpacity(0.8)),
            ),
            const SizedBox(height: 2),
            Text(
              isDisabled
                  ? 'FULL'
                  : '\${slot.availableComputers} PC',
              style: GoogleFonts.inter(
                fontSize: 9,
                color: _textColor.withOpacity(0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String time) {
    if (time.length >= 5) return time.substring(0, 5);
    return time;
  }
}
