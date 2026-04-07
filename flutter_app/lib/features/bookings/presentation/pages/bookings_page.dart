import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/constants.dart';
import '../../../../core/widgets/error_widget.dart';
import '../bloc/bookings_bloc.dart';
import '../bloc/bookings_event.dart';
import '../bloc/bookings_state.dart';
import '../widgets/booking_card.dart';
import '../../domain/entities/booking.dart';

class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key});

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<BookingsBloc>().add(BookingsLoadRequested());
    _refreshTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      if (mounted) {
        context.read<BookingsBloc>().add(BookingsLoadRequested());
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppConstants.backgroundPrimary),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabs(),
            Expanded(
              child: BlocConsumer<BookingsBloc, BookingsState>(
                listener: (context, state) {
                  if (state is BookingActionError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message,
                            style: GoogleFonts.inter(color: Colors.white)),
                        backgroundColor:
                            const Color(AppConstants.errorColor),
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  if (state is BookingsLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: Color(AppConstants.primaryAccent)),
                    );
                  }
                  if (state is BookingsError) {
                    return AppErrorWidget(
                      message: state.message,
                      onRetry: () => context
                          .read<BookingsBloc>()
                          .add(BookingsLoadRequested()),
                    );
                  }
                  if (state is BookingsLoaded) {
                    return TabBarView(
                      controller: _tabController,
                      children: [
                        _buildBookingList(
                            state.upcomingBookings, 'upcoming'),
                        _buildBookingList(state.pastBookings, 'past'),
                      ],
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          const Icon(Icons.calendar_month_rounded,
              color: Color(AppConstants.primaryAccent), size: 28),
          const SizedBox(width: 12),
          Text(
            'MY BOOKINGS',
            style: GoogleFonts.orbitron(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(AppConstants.primaryAccent),
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh,
                color: Color(AppConstants.primaryAccent)),
            onPressed: () =>
                context.read<BookingsBloc>().add(BookingsLoadRequested()),
          ),
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(AppConstants.backgroundSecondary),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color:
                  const Color(AppConstants.primaryAccent).withValues(alpha: 0.2)),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color:
                const Color(AppConstants.primaryAccent).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(AppConstants.primaryAccent)),
          ),
          labelStyle: GoogleFonts.orbitron(
              fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle:
              GoogleFonts.orbitron(fontSize: 11),
          labelColor: const Color(AppConstants.primaryAccent),
          unselectedLabelColor: Colors.white38,
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: 'UPCOMING'),
            Tab(text: 'PAST'),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingList(List<Booking> bookings, String type) {
    if (bookings.isEmpty) {
      return EmptyStateWidget(
        message: type == 'upcoming'
            ? 'No upcoming bookings\nBook a gaming slot now!'
            : 'No past bookings yet',
        icon: type == 'upcoming'
            ? Icons.event_available_outlined
            : Icons.history,
      );
    }
    return RefreshIndicator(
      onRefresh: () async =>
          context.read<BookingsBloc>().add(BookingsLoadRequested()),
      color: const Color(AppConstants.primaryAccent),
      backgroundColor: const Color(AppConstants.backgroundSecondary),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 12, bottom: 16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          if (type == 'upcoming' && booking.isUpcoming) {
            return Slidable(
              endActionPane: ActionPane(
                motion: const DrawerMotion(),
                extentRatio: 0.3,
                children: [
                  SlidableAction(
                    onPressed: (_) => _confirmCancel(booking),
                    backgroundColor:
                        const Color(AppConstants.errorColor).withValues(alpha: 0.8),
                    foregroundColor: Colors.white,
                    icon: Icons.cancel_outlined,
                    label: 'Cancel',
                    borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(16)),
                  ),
                ],
              ),
              child: BookingCard(booking: booking, index: index),
            );
          }
          return BookingCard(booking: booking, index: index);
        },
      ),
    );
  }

  void _confirmCancel(Booking booking) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(AppConstants.backgroundSecondary),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'CANCEL BOOKING',
          style: GoogleFonts.orbitron(
            color: const Color(AppConstants.errorColor),
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        content: Text(
          'Are you sure you want to cancel this booking at ${booking.clubName}?',
          style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Keep',
                style: GoogleFonts.inter(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context
                  .read<BookingsBloc>()
                  .add(BookingCancelRequested(booking.id));
            },
            child: Text(
              'Cancel',
              style: GoogleFonts.orbitron(
                color: const Color(AppConstants.errorColor),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
