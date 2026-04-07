import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../config/constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/loading_shimmer.dart';
import '../../../../injection.dart';
import '../../domain/entities/admin_stats.dart';
import '../bloc/admin_bloc.dart';
import '../bloc/admin_event.dart';
import '../bloc/admin_state.dart';

const _kAdmin = Color(0xFFFFAB00);
const _kAdminDark = Color(0xFF1A1500);
const _kAdminCard = Color(0xFF1E1800);

// ═══════════════════════════════════════════════════════════════════════
// ADMIN SHELL — 6 TABS
// ═══════════════════════════════════════════════════════════════════════

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  late AdminBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = sl<AdminBloc>()..add(const AdminDashboardLoadRequested());
    _tab = TabController(length: 6, vsync: this);
    _tab.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tab.indexIsChanging) return;
    switch (_tab.index) {
      case 0:
        _bloc.add(const AdminDashboardLoadRequested());
        break;
      case 1:
        _bloc.add(const AdminClubsLoadRequested());
        break;
      case 4:
        _bloc.add(const AdminUsersLoadRequested());
        break;
      case 5:
        _bloc.add(const AdminPendingPaymentsLoadRequested());
        break;
    }
  }

  @override
  void dispose() {
    _tab.removeListener(_onTabChanged);
    _tab.dispose();
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        backgroundColor: const Color(AppConstants.backgroundPrimary),
        appBar: _buildAppBar(),
        body: TabBarView(
          controller: _tab,
          physics: const NeverScrollableScrollPhysics(),
          children: const [
            _OverviewTab(),
            _ClubsTab(),
            _SessionsTab(),
            _RevenueTab(),
            _GamersTab(),
            _PaymentsTab(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight + 66),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(AppConstants.backgroundSecondary),
          border: Border(bottom: BorderSide(color: _kAdmin, width: 1.5)),
        ),
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kAdmin.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border:
                        Border.all(color: _kAdmin.withValues(alpha: 0.5)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.admin_panel_settings_rounded,
                        color: _kAdmin, size: 16),
                    const SizedBox(width: 6),
                    Text('ADMIN PANEL',
                        style: GoogleFonts.orbitron(
                            color: _kAdmin,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5)),
                  ]),
                ),
                const Spacer(),
                BlocBuilder<AdminBloc, AdminState>(
                    builder: (context, state) {
                  if (state is AdminDashboardLoaded &&
                      state.stats.pendingUsers > 0) {
                    return _BadgeWidget(
                        '${state.stats.pendingUsers} pending',
                        Colors.red);
                  }
                  return const SizedBox();
                }),
              ]),
            ),
            TabBar(
              controller: _tab,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicator: const UnderlineTabIndicator(
                borderSide: BorderSide(color: _kAdmin, width: 2),
                insets: EdgeInsets.symmetric(horizontal: 8),
              ),
              labelColor: _kAdmin,
              unselectedLabelColor: Colors.white38,
              labelStyle: GoogleFonts.orbitron(
                  fontSize: 10, fontWeight: FontWeight.bold),
              unselectedLabelStyle: GoogleFonts.orbitron(fontSize: 10),
              dividerColor: Colors.transparent,
              tabs: [
                const Tab(
                    icon: Icon(Icons.dashboard_rounded, size: 18),
                    text: 'OVERVIEW'),
                const Tab(
                    icon: Icon(Icons.videogame_asset_rounded, size: 18),
                    text: 'CLUBS'),
                const Tab(
                    icon: Icon(Icons.timer_rounded, size: 18),
                    text: 'SESSIONS'),
                const Tab(
                    icon: Icon(Icons.bar_chart_rounded, size: 18),
                    text: 'REVENUE'),
                const Tab(
                    icon: Icon(Icons.people_rounded, size: 18),
                    text: 'GAMERS'),
                const Tab(
                    icon: Icon(Icons.payment_rounded, size: 18),
                    text: 'PAYMENTS'),
              ],
            ),
          ]),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ═══════════════════════════════════════════════════════════════════════

class _BadgeWidget extends StatelessWidget {
  final String text;
  final Color color;
  const _BadgeWidget(this.text, this.color);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(text,
          style: GoogleFonts.inter(
              color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}

Widget _sectionLabel(String text) => Text(text,
    style: GoogleFonts.orbitron(
        color: Colors.white38, fontSize: 10, letterSpacing: 1.5));

class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorRetry({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 40),
        const SizedBox(height: 12),
        Text(message,
            style: GoogleFonts.inter(color: Colors.white54),
            textAlign: TextAlign.center),
        const SizedBox(height: 16),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: _kAdmin, foregroundColor: Colors.black),
          onPressed: onRetry,
          child: const Text('RETRY'),
        ),
      ]),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip(this.icon, this.label, {this.color = Colors.white38});
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: color),
      const SizedBox(width: 3),
      Text(label, style: GoogleFonts.inter(color: color, fontSize: 11)),
    ]);
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool numeric;
  final bool required;
  final bool decimal;
  const _Field(this.controller, this.hint,
      {this.numeric = false, this.required = false, this.decimal = false});
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: numeric
          ? (decimal
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.number)
          : TextInputType.text,
      inputFormatters:
          numeric && !decimal ? [FilteringTextInputFormatter.digitsOnly] : null,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: Colors.white24, fontSize: 13),
        filled: true,
        fillColor: _kAdminDark,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.white12)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _kAdmin)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.white12)),
      ),
      validator: required
          ? (v) => (v == null || v.isEmpty) ? 'Required' : null
          : null,
    );
  }
}

class _HourPicker extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final ValueChanged<int> onChanged;
  const _HourPicker(
      {required this.label,
      required this.value,
      required this.onChanged,
      this.max = 23});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
          color: _kAdminDark,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white12)),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.inter(
                    color: Colors.white38, fontSize: 10)),
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap:
                        value > 0 ? () => onChanged(value - 1) : null,
                    child: Icon(Icons.remove_circle_outline,
                        color: value > 0 ? _kAdmin : Colors.white24,
                        size: 20),
                  ),
                  Text(
                      '${value.toString().padLeft(2, '0')}:00',
                      style: GoogleFonts.orbitron(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                  GestureDetector(
                    onTap: value < max
                        ? () => onChanged(value + 1)
                        : null,
                    child: Icon(Icons.add_circle_outline,
                        color:
                            value < max ? _kAdmin : Colors.white24,
                        size: 20),
                  ),
                ]),
          ]),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final int delayMs;
  const _StatTile(
      this.label, this.value, this.icon, this.color, this.delayMs);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: _kAdminCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.35))),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 22),
            Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: GoogleFonts.orbitron(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(label,
                      style: GoogleFonts.inter(
                          color: Colors.white38, fontSize: 10)),
                ]),
          ]),
    ).animate(delay: delayMs.ms).fadeIn().slideY(begin: 0.08);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// TAB 1 — OVERVIEW  (Dashboard)
// ═══════════════════════════════════════════════════════════════════════

class _OverviewTab extends StatelessWidget {
  const _OverviewTab();
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminBloc, AdminState>(builder: (context, state) {
      if (state is AdminLoading || state is AdminInitial) {
        return const LoadingShimmer();
      }
      if (state is AdminError) {
        return _ErrorRetry(
            message: state.message,
            onRetry: () => context
                .read<AdminBloc>()
                .add(const AdminDashboardLoadRequested()));
      }
      if (state is AdminDashboardLoaded) {
        final s = state.stats;
        final fmt = NumberFormat('#,###');
        final totalRevenue30d =
            s.revenueByDay.fold<double>(0, (a, b) => a + b.revenue);
        final totalBookings30d =
            s.revenueByDay.fold<int>(0, (a, b) => a + b.bookingCount);
        return RefreshIndicator(
          color: _kAdmin,
          onRefresh: () async => context
              .read<AdminBloc>()
              .add(const AdminDashboardLoadRequested()),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Welcome banner ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        _kAdmin.withValues(alpha: 0.18),
                        _kAdminCard,
                      ]),
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: _kAdmin.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Icon(Icons.rocket_launch_rounded,
                                color: _kAdmin, size: 20),
                            const SizedBox(width: 8),
                            Text('Dashboard',
                                style: GoogleFonts.orbitron(
                                    color: _kAdmin,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                          ]),
                          const SizedBox(height: 6),
                          Text(
                              DateFormat('EEEE, d MMMM yyyy')
                                  .format(DateTime.now()),
                              style: GoogleFonts.inter(
                                  color: Colors.white54, fontSize: 12)),
                        ]),
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.05),

                  const SizedBox(height: 18),
                  _sectionLabel("TODAY'S SNAPSHOT"),
                  const SizedBox(height: 12),

                  // ── 4 Stat tiles ──
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount:
                        MediaQuery.of(context).size.width > 700 ? 4 : 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.6,
                    children: [
                      _StatTile(
                          'REVENUE TODAY',
                          '${fmt.format(s.totalRevenueToday)} UZS',
                          Icons.attach_money_rounded,
                          const Color(0xFF76FF03),
                          0),
                      _StatTile(
                          'ACTIVE BOOKINGS',
                          '${s.activeBookings}',
                          Icons.event_available_rounded,
                          _kAdmin,
                          60),
                      _StatTile(
                          'PENDING PAYMENTS',
                          '${s.pendingPayments}',
                          Icons.payment_rounded,
                          Colors.orange,
                          120),
                      _StatTile(
                          'TOTAL USERS',
                          '${s.totalUsers}',
                          Icons.people_rounded,
                          Colors.purple,
                          180),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── 30-day revenue chart ──
                  _sectionLabel('REVENUE  ·  LAST 30 DAYS'),
                  const SizedBox(height: 4),
                  Text('${fmt.format(totalRevenue30d)} UZS  ·  $totalBookings30d bookings',
                      style: GoogleFonts.inter(
                          color: Colors.white54, fontSize: 11)),
                  const SizedBox(height: 12),
                  Container(
                    height: 160,
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(8, 12, 8, 24),
                    decoration: BoxDecoration(
                        color: _kAdminCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: _kAdmin.withValues(alpha: 0.15))),
                    child: s.revenueByDay.isEmpty
                        ? Center(
                            child: Text('No data yet',
                                style: GoogleFonts.inter(
                                    color: Colors.white24, fontSize: 12)))
                        : CustomPaint(
                            size: Size.infinite,
                            painter:
                                _RevenueChartPainter(s.revenueByDay)),
                  ).animate(delay: 200.ms).fadeIn(),

                  const SizedBox(height: 24),

                  // ── Top clubs by revenue ──
                  _sectionLabel('TOP CLUBS BY REVENUE'),
                  const SizedBox(height: 12),
                  if (s.bookingsByClub.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                          color: _kAdminCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: _kAdmin.withValues(alpha: 0.1))),
                      child: Center(
                          child: Text('No clubs yet',
                              style: GoogleFonts.inter(
                                  color: Colors.white24, fontSize: 12))),
                    ),
                  ...s.bookingsByClub.asMap().entries.map((e) {
                    final i = e.key;
                    final c = e.value;
                    final maxRev = s.bookingsByClub
                        .map((x) => x.revenue)
                        .reduce((a, b) => a > b ? a : b);
                    final pct = maxRev > 0 ? c.revenue / maxRev : 0.0;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: _kAdminCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color:
                                  _kAdmin.withValues(alpha: 0.15))),
                      child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Container(
                                width: 24,
                                height: 24,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                    color:
                                        _kAdmin.withValues(alpha: 0.15),
                                    borderRadius:
                                        BorderRadius.circular(6)),
                                child: Text('${i + 1}',
                                    style: GoogleFonts.orbitron(
                                        color: _kAdmin,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: Text(c.clubName,
                                      style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight:
                                              FontWeight.w600))),
                              Text('${c.bookingCount} bookings',
                                  style: GoogleFonts.inter(
                                      color: Colors.white38,
                                      fontSize: 11)),
                            ]),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                  value: pct,
                                  backgroundColor: Colors.white12,
                                  valueColor:
                                      const AlwaysStoppedAnimation(
                                          _kAdmin),
                                  minHeight: 6),
                            ),
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                  '${fmt.format(c.revenue)} UZS',
                                  style: GoogleFonts.orbitron(
                                      color: _kAdmin,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ]),
                    ).animate(delay: (i * 50).ms).fadeIn();
                  }),

                  const SizedBox(height: 24),

                  // ── Quick stats row ──
                  _sectionLabel('30-DAY SUMMARY'),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                        child: _MiniStat(
                            Icons.calendar_month_rounded,
                            'Total Bookings',
                            '$totalBookings30d',
                            _kAdmin)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _MiniStat(
                            Icons.monetization_on_rounded,
                            'Total Revenue',
                            '${fmt.format(totalRevenue30d)} UZS',
                            const Color(0xFF76FF03))),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _MiniStat(
                            Icons.store_rounded,
                            'Active Clubs',
                            '${s.bookingsByClub.length}',
                            Colors.cyan)),
                  ]),
                  const SizedBox(height: 24),
                ]),
          ),
        );
      }
      return const SizedBox();
    });
  }
}

// Mini stat card for 30-day summary row
class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _MiniStat(this.icon, this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: _kAdminCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 8),
            Text(value,
                style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(label,
                style: GoogleFonts.inter(
                    color: Colors.white38, fontSize: 9)),
          ]),
    ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.05);
  }
}

// Custom revenue chart painter — 30-day bar chart
class _RevenueChartPainter extends CustomPainter {
  final List<RevenueByDay> data;
  _RevenueChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final maxRev =
        data.map((e) => e.revenue).reduce((a, b) => a > b ? a : b);
    final effectiveMax = maxRev > 0 ? maxRev : 1.0;
    final barWidth = (size.width - (data.length - 1) * 2) / data.length;

    final barPaint = Paint()..color = _kAdmin;
    final zeroPaint = Paint()..color = Colors.white12;
    final gridPaint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 0.5;

    // Draw 3 horizontal grid lines
    for (int i = 1; i <= 3; i++) {
      final y = size.height * (1 - i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    for (int i = 0; i < data.length; i++) {
      final x = i * (barWidth + 2);
      final double h = data[i].revenue > 0
          ? (data[i].revenue / effectiveMax) * (size.height - 4)
          : 2.0;
      final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, size.height - h, barWidth, h),
          const Radius.circular(2));
      canvas.drawRRect(
          rect, data[i].revenue > 0 ? barPaint : zeroPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ═══════════════════════════════════════════════════════════════════════
// TAB 2 — CLUBS
// ═══════════════════════════════════════════════════════════════════════

class _ClubsTab extends StatelessWidget {
  const _ClubsTab();
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminBloc, AdminState>(
      listener: (context, state) {
        if (state is AdminClubActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message,
                  style: const TextStyle(color: Colors.black)),
              backgroundColor: _kAdmin));
          context
              .read<AdminBloc>()
              .add(const AdminClubsLoadRequested());
        }
      },
      builder: (context, state) {
        if (state is AdminLoading) return const LoadingShimmer();
        if (state is AdminClubsLoaded) {
          return _ClubsList(clubs: state.clubs);
        }
        return const _ClubsList(clubs: []);
      },
    );
  }
}

class _ClubsList extends StatelessWidget {
  final List<AdminClubItem> clubs;
  const _ClubsList({required this.clubs});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _kAdmin,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: Text('ADD CLUB',
            style: GoogleFonts.orbitron(
                fontSize: 10, fontWeight: FontWeight.bold)),
        onPressed: () => _showClubForm(context, null),
      ),
      body: clubs.isEmpty
          ? Center(
              child: Text('No clubs yet',
                  style: GoogleFonts.orbitron(
                      color: Colors.white38, fontSize: 14)))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: clubs.length,
              itemBuilder: (context, i) =>
                  _ClubCard(club: clubs[i], index: i),
            ),
    );
  }

  void _showClubForm(BuildContext context, AdminClubItem? club) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<AdminBloc>(),
        child: _ClubFormSheet(existing: club),
      ),
    );
  }
}

class _ClubCard extends StatelessWidget {
  final AdminClubItem club;
  final int index;
  const _ClubCard({required this.club, required this.index});
  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: _kAdminCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kAdmin.withValues(alpha: 0.2))),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: _kAdmin.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.videogame_asset_rounded,
                    color: _kAdmin, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(club.name,
                          style: GoogleFonts.orbitron(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold)),
                      Text(club.location,
                          style: GoogleFonts.inter(
                              color: Colors.white38, fontSize: 11)),
                    ]),
              ),
              IconButton(
                icon: const Icon(Icons.edit_rounded,
                    color: _kAdmin, size: 18),
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => BlocProvider.value(
                    value: context.read<AdminBloc>(),
                    child: _ClubFormSheet(existing: club),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 6, children: [
              _InfoChip(
                  Icons.computer_rounded, '${club.totalComputers} PCs'),
              _InfoChip(Icons.access_time_rounded,
                  '${club.openingHour}:00\u2013${club.closingHour}:00'),
              _InfoChip(Icons.attach_money_rounded,
                  '${fmt.format(club.pricePerHour)}/hr'),
              if (club.latitude != null)
                _InfoChip(Icons.map_rounded, 'Map linked',
                    color: const Color(0xFF76FF03)),
            ]),
          ]),
    ).animate(delay: (index * 50).ms).fadeIn();
  }
}

class _ClubFormSheet extends StatefulWidget {
  final AdminClubItem? existing;
  const _ClubFormSheet({this.existing});
  @override
  State<_ClubFormSheet> createState() => _ClubFormSheetState();
}

class _ClubFormSheetState extends State<_ClubFormSheet> {
  final _form = GlobalKey<FormState>();
  late final _name =
      TextEditingController(text: widget.existing?.name ?? '');
  late final _loc =
      TextEditingController(text: widget.existing?.location ?? '');
  late final _desc = TextEditingController();
  late final _price = TextEditingController(
      text: widget.existing != null
          ? '${widget.existing!.pricePerHour}'
          : '');
  late final _pcs = TextEditingController(
      text: widget.existing != null
          ? '${widget.existing!.totalComputers}'
          : '');
  late final _addr =
      TextEditingController(text: widget.existing?.address ?? '');
  late final _lat = TextEditingController(
      text: widget.existing?.latitude?.toString() ?? '');
  late final _lng = TextEditingController(
      text: widget.existing?.longitude?.toString() ?? '');
  late int _openHour = widget.existing?.openingHour ?? 0;
  late int _closeHour = widget.existing?.closingHour ?? 24;

  // Image picker state
  Uint8List? _pickedImageBytes;
  String? _pickedImageName;
  String? _uploadedImageUrl;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _uploadedImageUrl = widget.existing?.imageUrl;
  }

  @override
  void dispose() {
    for (final c in [_name, _loc, _desc, _price, _pcs, _addr, _lat, _lng]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (xFile == null) return;
    final bytes = await xFile.readAsBytes();
    setState(() {
      _pickedImageBytes = bytes;
      _pickedImageName = xFile.name;
      _uploadedImageUrl = null; // clear old URL until upload
    });
  }

  Future<String?> _uploadPickedImage() async {
    if (_pickedImageBytes == null) return _uploadedImageUrl;
    setState(() => _uploading = true);
    try {
      final api = sl<ApiClient>();
      final formData = dio_pkg.FormData.fromMap({
        'file': dio_pkg.MultipartFile.fromBytes(
          _pickedImageBytes!,
          filename: _pickedImageName ?? 'image.jpg',
        ),
      });
      final resp = await api.dio.post('/uploads', data: formData);
      final url = resp.data['url'] as String;
      setState(() {
        _uploadedImageUrl = url;
        _uploading = false;
      });
      return url;
    } catch (e) {
      setState(() => _uploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image upload failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  Widget _buildImageSection() {
    final hasPickedImage = _pickedImageBytes != null;
    final hasExistingUrl = _uploadedImageUrl != null &&
        _uploadedImageUrl!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CLUB PHOTO',
            style: GoogleFonts.orbitron(
                color: Colors.white38,
                fontSize: 10,
                letterSpacing: 1)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _uploading ? null : _pickImage,
          child: Container(
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _kAdmin.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: _uploading
                ? const Center(
                    child: CircularProgressIndicator(color: _kAdmin))
                : hasPickedImage
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Image.memory(
                          _pickedImageBytes!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 160,
                        ),
                      )
                    : hasExistingUrl
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(11),
                            child: Image.network(
                              _uploadedImageUrl!.startsWith('http')
                                  ? _uploadedImageUrl!
                                  : '${AppConstants.baseUrl}$_uploadedImageUrl',
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 160,
                              errorBuilder: (_, __, ___) =>
                                  _buildImagePlaceholder(),
                            ),
                          )
                        : _buildImagePlaceholder(),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate_outlined,
              color: _kAdmin.withValues(alpha: 0.5), size: 40),
          const SizedBox(height: 8),
          Text('Tap to add photo',
              style: GoogleFonts.rajdhani(
                  color: Colors.white38, fontSize: 13)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Container(
      decoration: const BoxDecoration(
        color: Color(AppConstants.backgroundSecondary),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: _kAdmin, width: 1.5)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                    child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                            color: _kAdmin.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Text(isEdit ? 'EDIT CLUB' : 'ADD NEW CLUB',
                    style: GoogleFonts.orbitron(
                        color: _kAdmin,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5)),
                const SizedBox(height: 20),
                _buildImageSection(),
                _Field(_name, 'Club Name', required: true),
                const SizedBox(height: 12),
                _Field(_loc, 'Location / City', required: true),
                const SizedBox(height: 12),
                _Field(_desc, 'Description'),
                const SizedBox(height: 12),
                _Field(_addr, 'Address'),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                      child: _Field(_price, 'Price/hr (UZS)',
                          numeric: true, required: true)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _Field(_pcs, 'Computers',
                          numeric: true, required: true)),
                ]),
                const SizedBox(height: 16),
                Text('MAP COORDINATES',
                    style: GoogleFonts.orbitron(
                        color: Colors.white38,
                        fontSize: 10,
                        letterSpacing: 1)),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                      child: _Field(_lat, 'Latitude', decimal: true)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _Field(_lng, 'Longitude', decimal: true)),
                ]),
                const SizedBox(height: 16),
                Text('WORKING HOURS',
                    style: GoogleFonts.orbitron(
                        color: Colors.white38,
                        fontSize: 10,
                        letterSpacing: 1)),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                      child: _HourPicker(
                          label: 'Opens',
                          value: _openHour,
                          onChanged: (v) =>
                              setState(() => _openHour = v))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _HourPicker(
                          label: 'Closes',
                          value: _closeHour,
                          max: 24,
                          onChanged: (v) =>
                              setState(() => _closeHour = v))),
                ]),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kAdmin,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _submit,
                    child: Text(
                        isEdit ? 'SAVE CHANGES' : 'CREATE CLUB',
                        style: GoogleFonts.orbitron(
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                  ),
                ),
              ]),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;

    // Upload picked image first (if any)
    if (_pickedImageBytes != null) {
      final url = await _uploadPickedImage();
      if (url == null) return; // upload failed, snackbar shown
    }

    if (!mounted) return;
    final bloc = context.read<AdminBloc>();
    Navigator.of(context).pop();
    final lat = double.tryParse(_lat.text);
    final lng = double.tryParse(_lng.text);
    if (widget.existing != null) {
      final fields = <String, dynamic>{};
      if (_name.text.trim().isNotEmpty) {
        fields['name'] = _name.text.trim();
      }
      if (_loc.text.trim().isNotEmpty) {
        fields['location'] = _loc.text.trim();
      }
      if (_price.text.isNotEmpty) {
        fields['price_per_hour'] = int.parse(_price.text);
      }
      if (_pcs.text.isNotEmpty) {
        fields['total_computers'] = int.parse(_pcs.text);
      }
      if (_addr.text.trim().isNotEmpty) {
        fields['address'] = _addr.text.trim();
      }
      if (lat != null) fields['latitude'] = lat;
      if (lng != null) fields['longitude'] = lng;
      fields['opening_hour'] = _openHour;
      fields['closing_hour'] = _closeHour;
      if (_uploadedImageUrl != null) {
        fields['image_url'] = _uploadedImageUrl;
      }
      bloc.add(
          AdminUpdateClubRequested(widget.existing!.id, fields));
    } else {
      bloc.add(AdminCreateClubRequested(
        name: _name.text.trim(),
        location: _loc.text.trim(),
        description: _desc.text.trim(),
        pricePerHour: int.parse(_price.text),
        totalComputers: int.parse(_pcs.text),
        openingHour: _openHour,
        closingHour: _closeHour,
        address: _addr.text.trim().isEmpty
            ? null
            : _addr.text.trim(),
        latitude: lat,
        longitude: lng,
        imageUrl: _uploadedImageUrl,
      ));
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// TAB 3 — SESSIONS (live countdown timers)
// ═══════════════════════════════════════════════════════════════════════

class _SessionsTab extends StatefulWidget {
  const _SessionsTab();
  @override
  State<_SessionsTab> createState() => _SessionsTabState();
}

class _SessionsTabState extends State<_SessionsTab> {
  List<AdminClubItem>? _clubs;
  int? _selectedClubId;
  ClubSessions? _sessions;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminBloc, AdminState>(
      listener: (context, state) {
        if (state is AdminClubsLoaded) {
          setState(() => _clubs = state.clubs);
        }
        if (state is AdminClubSessionsLoaded) {
          setState(() => _sessions = state.sessions);
        }
      },
      builder: (context, state) {
        if (_clubs == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_clubs == null) {
              context
                  .read<AdminBloc>()
                  .add(const AdminClubsLoadRequested());
            }
          });
          return const LoadingShimmer();
        }
        return Column(children: [
          _ClubSelector(
              clubs: _clubs!,
              selected: _selectedClubId,
              onSelected: (id) {
                setState(() {
                  _selectedClubId = id;
                  _sessions = null;
                });
                context
                    .read<AdminBloc>()
                    .add(AdminClubSessionsLoadRequested(id));
              }),
          Expanded(child: _buildBody(state)),
        ]);
      },
    );
  }

  Widget _buildBody(AdminState state) {
    if (_selectedClubId == null) {
      return Center(
          child: Text('Select a club above',
              style: GoogleFonts.orbitron(
                  color: Colors.white38, fontSize: 14)));
    }
    if (state is AdminLoading && _sessions == null) {
      return const LoadingShimmer();
    }
    if (state is AdminError && _sessions == null) {
      return _ErrorRetry(
          message: state.message,
          onRetry: () => context.read<AdminBloc>().add(
              AdminClubSessionsLoadRequested(_selectedClubId!)));
    }
    if (_sessions != null) {
      return _SessionsBody(sessions: _sessions!);
    }
    return const LoadingShimmer();
  }
}

class _ClubSelector extends StatelessWidget {
  final List<AdminClubItem> clubs;
  final int? selected;
  final ValueChanged<int> onSelected;
  const _ClubSelector(
      {required this.clubs, this.selected, required this.onSelected});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      color: _kAdminCard,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: clubs.length,
        itemBuilder: (context, i) {
          final c = clubs[i];
          final isSel = c.id == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(c.name),
              selected: isSel,
              selectedColor: _kAdmin,
              backgroundColor:
                  const Color(AppConstants.backgroundSecondary),
              labelStyle: GoogleFonts.inter(
                  color: isSel ? Colors.black : Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
              onSelected: (_) => onSelected(c.id),
            ),
          );
        },
      ),
    );
  }
}

class _SessionsBody extends StatefulWidget {
  final ClubSessions sessions;
  const _SessionsBody({required this.sessions});
  @override
  State<_SessionsBody> createState() => _SessionsBodyState();
}

class _SessionsBodyState extends State<_SessionsBody> {
  late Timer _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.sessions;
    return RefreshIndicator(
      color: _kAdmin,
      onRefresh: () async => context
          .read<AdminBloc>()
          .add(AdminClubSessionsLoadRequested(s.clubId)),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                    child: _StatTile(
                        'AVAILABLE',
                        '${s.availableComputers}/${s.totalComputers}',
                        Icons.computer,
                        const Color(0xFF76FF03),
                        0)),
                const SizedBox(width: 10),
                Expanded(
                    child: _StatTile(
                        'ACTIVE',
                        '${s.activeSessions.length}',
                        Icons.play_circle,
                        _kAdmin,
                        50)),
              ]),
              const SizedBox(height: 20),
              if (s.activeSessions.isNotEmpty) ...[
                _sectionLabel('ACTIVE SESSIONS'),
                const SizedBox(height: 10),
                ...s.activeSessions.asMap().entries.map((e) =>
                    _SessionRow(session: e.value, index: e.key)),
              ],
              if (s.upcomingSessions.isNotEmpty) ...[
                const SizedBox(height: 20),
                _sectionLabel('UPCOMING'),
                const SizedBox(height: 10),
                ...s.upcomingSessions.asMap().entries.map((e) =>
                    _SessionRow(
                        session: e.value,
                        index: e.key,
                        upcoming: true)),
              ],
              if (s.activeSessions.isEmpty &&
                  s.upcomingSessions.isEmpty)
                Center(
                    child: Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Text('No sessions right now',
                      style: GoogleFonts.orbitron(
                          color: Colors.white38, fontSize: 14)),
                )),
            ]),
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  final ClubSessionItem session;
  final int index;
  final bool upcoming;
  const _SessionRow(
      {required this.session,
      required this.index,
      this.upcoming = false});
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final remaining = session.endTime.difference(now);
    final mins = remaining.inMinutes;
    final isExpiring = !upcoming && mins <= 15 && mins > 0;
    final color = upcoming
        ? Colors.blue
        : (isExpiring ? Colors.orange : const Color(0xFF76FF03));
    final timeFmt = DateFormat('HH:mm');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: _kAdminCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10)),
          child: Center(
              child: Text('${session.computersBooked}',
                  style: GoogleFonts.orbitron(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.bold))),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(session.username,
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                Text(
                    '${timeFmt.format(session.startTime)} \u2013 ${timeFmt.format(session.endTime)}',
                    style: GoogleFonts.inter(
                        color: Colors.white38, fontSize: 11)),
              ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6)),
            child: Text(
                upcoming
                    ? 'UPCOMING'
                    : (mins <= 0 ? 'ENDING' : '${mins}m left'),
                style: GoogleFonts.inter(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
          ),
          if (session.totalPrice != null) ...[
            const SizedBox(height: 4),
            Text(
                '${NumberFormat('#,###').format(session.totalPrice!.toInt())} UZS',
                style: GoogleFonts.orbitron(
                    color: _kAdmin,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
          ],
        ]),
      ]),
    ).animate(delay: (index * 40).ms).fadeIn();
  }
}

// ═══════════════════════════════════════════════════════════════════════
// TAB 4 — REVENUE (multi-club select)
// ═══════════════════════════════════════════════════════════════════════

class _RevenueTab extends StatefulWidget {
  const _RevenueTab();
  @override
  State<_RevenueTab> createState() => _RevenueTabState();
}

class _RevenueTabState extends State<_RevenueTab> {
  List<AdminClubItem>? _clubs;
  final Set<int> _selectedClubIds = {};
  bool _allSelected = false;
  ClubRevenue? _revenue;

  void _loadRevenue(BuildContext context) {
    final ids = _allSelected
        ? _clubs!.map((c) => c.id).toList()
        : _selectedClubIds.toList();
    if (ids.isEmpty) return;
    setState(() => _revenue = null);
    if (ids.length == 1) {
      context.read<AdminBloc>().add(AdminClubRevenueLoadRequested(ids.first));
    } else {
      context.read<AdminBloc>().add(AdminMultiClubRevenueLoadRequested(ids));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminBloc, AdminState>(
      listener: (context, state) {
        if (state is AdminClubsLoaded) {
          setState(() => _clubs = state.clubs);
        }
        if (state is AdminClubRevenueLoaded) {
          setState(() => _revenue = state.revenue);
        }
        if (state is AdminMultiClubRevenueLoaded) {
          setState(() => _revenue = state.combinedRevenue);
        }
      },
      builder: (context, state) {
        if (_clubs == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_clubs == null) {
              context
                  .read<AdminBloc>()
                  .add(const AdminClubsLoadRequested());
            }
          });
          return const LoadingShimmer();
        }
        return Column(children: [
          _MultiClubSelector(
            clubs: _clubs!,
            selectedIds: _selectedClubIds,
            allSelected: _allSelected,
            onAllToggled: () {
              setState(() {
                _allSelected = !_allSelected;
                if (_allSelected) _selectedClubIds.clear();
              });
              if (_allSelected) _loadRevenue(context);
            },
            onClubToggled: (id) {
              setState(() {
                _allSelected = false;
                if (_selectedClubIds.contains(id)) {
                  _selectedClubIds.remove(id);
                } else {
                  _selectedClubIds.add(id);
                }
              });
              if (_selectedClubIds.isNotEmpty) {
                _loadRevenue(context);
              } else {
                setState(() => _revenue = null);
              }
            },
          ),
          Expanded(child: _buildBody(state)),
        ]);
      },
    );
  }

  Widget _buildBody(AdminState state) {
    if (!_allSelected && _selectedClubIds.isEmpty) {
      return Center(
          child: Text('Select clubs to view revenue',
              style: GoogleFonts.orbitron(
                  color: Colors.white38, fontSize: 14)));
    }
    if (state is AdminLoading && _revenue == null) {
      return const LoadingShimmer();
    }
    if (state is AdminError && _revenue == null) {
      return _ErrorRetry(
          message: state.message,
          onRetry: () => _loadRevenue(context));
    }
    if (_revenue != null) {
      return _RevenueBody(
        revenue: _revenue!,
        onRefresh: () => _loadRevenue(context),
      );
    }
    return const LoadingShimmer();
  }
}

class _MultiClubSelector extends StatelessWidget {
  final List<AdminClubItem> clubs;
  final Set<int> selectedIds;
  final bool allSelected;
  final VoidCallback onAllToggled;
  final ValueChanged<int> onClubToggled;

  const _MultiClubSelector({
    required this.clubs,
    required this.selectedIds,
    required this.allSelected,
    required this.onAllToggled,
    required this.onClubToggled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      color: _kAdminCard,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: clubs.length + 1,
        itemBuilder: (context, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: const Text('All'),
                selected: allSelected,
                selectedColor: _kAdmin,
                backgroundColor:
                    const Color(AppConstants.backgroundSecondary),
                labelStyle: GoogleFonts.inter(
                    color: allSelected ? Colors.black : Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
                onSelected: (_) => onAllToggled(),
              ),
            );
          }
          final c = clubs[i - 1];
          final isSel = !allSelected && selectedIds.contains(c.id);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(c.name),
              selected: isSel,
              selectedColor: _kAdmin,
              checkmarkColor: Colors.black,
              backgroundColor:
                  const Color(AppConstants.backgroundSecondary),
              labelStyle: GoogleFonts.inter(
                  color: isSel ? Colors.black : Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
              onSelected: (_) => onClubToggled(c.id),
            ),
          );
        },
      ),
    );
  }
}

class _RevenueBody extends StatelessWidget {
  final ClubRevenue revenue;
  final VoidCallback? onRefresh;
  const _RevenueBody({required this.revenue, this.onRefresh});
  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###');
    return RefreshIndicator(
      color: _kAdmin,
      onRefresh: () async {
        if (onRefresh != null) onRefresh!();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    _kAdmin.withValues(alpha: 0.2),
                    _kAdmin.withValues(alpha: 0.05),
                  ]),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: _kAdmin.withValues(alpha: 0.4)),
                ),
                child: Column(children: [
                  Text(revenue.clubName.toUpperCase(),
                      style: GoogleFonts.orbitron(
                          color: _kAdmin,
                          fontSize: 11,
                          letterSpacing: 2)),
                  const SizedBox(height: 12),
                  Text(
                      '${fmt.format(revenue.totalRevenue)} UZS',
                      style: GoogleFonts.orbitron(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                      '${revenue.totalSessions} sessions  |  ${revenue.activeSessions} active',
                      style: GoogleFonts.inter(
                          color: Colors.white38, fontSize: 13)),
                ]),
              ).animate().fadeIn(),
              const SizedBox(height: 24),
              _sectionLabel('DAILY BREAKDOWN'),
              const SizedBox(height: 12),
              if (revenue.revenueByDay.isEmpty)
                Center(
                    child: Text('No data yet',
                        style: GoogleFonts.inter(
                            color: Colors.white38)))
              else
                ...revenue.revenueByDay.asMap().entries.map((entry) {
                  final i = entry.key;
                  final d = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                        color: _kAdminCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white12)),
                    child: Row(children: [
                      Expanded(
                        child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(d.date,
                                  style: GoogleFonts.orbitron(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                              Text('${d.bookingCount} bookings',
                                  style: GoogleFonts.inter(
                                      color: Colors.white38,
                                      fontSize: 11)),
                            ]),
                      ),
                      Text('${fmt.format(d.revenue)} UZS',
                          style: GoogleFonts.orbitron(
                              color: d.revenue > 0
                                  ? _kAdmin
                                  : Colors.white38,
                              fontSize: 13,
                              fontWeight: FontWeight.bold)),
                    ]),
                  ).animate(delay: (i * 30).ms).fadeIn();
                }),
              if (revenue.recentSessions.isNotEmpty) ...[
                const SizedBox(height: 24),
                _sectionLabel('RECENT SESSIONS'),
                const SizedBox(height: 12),
                ...revenue.recentSessions
                    .asMap()
                    .entries
                    .map((e) => _SessionRow(
                        session: e.value, index: e.key)),
              ],
            ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// TAB 5 — GAMERS (approval + detail view)
// ═══════════════════════════════════════════════════════════════════════

class _GamersTab extends StatefulWidget {
  const _GamersTab();
  @override
  State<_GamersTab> createState() => _GamersTabState();
}

class _GamersTabState extends State<_GamersTab> {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminBloc, AdminState>(
      listener: (context, state) {
        if (state is AdminUserCreated ||
            state is AdminUserApproved ||
            state is AdminUserRejected ||
            state is AdminUserDeleted) {
          final msg = state is AdminUserApproved
              ? 'User approved'
              : (state is AdminUserRejected
                  ? 'User rejected'
                  : (state is AdminUserDeleted
                      ? 'User deleted'
                      : 'User created'));
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(msg,
                  style: const TextStyle(color: Colors.black)),
              backgroundColor: _kAdmin));
          context.read<AdminBloc>().add(
              const AdminUsersLoadRequested());
        }
      },
      builder: (context, state) {
        if (state is AdminLoading) return const LoadingShimmer();
        if (state is AdminUsersLoaded) {
          return _GamersBody(users: state.users);
        }
        if (state is AdminUserDetailLoaded) {
          return _UserDetailView(detail: state.detail);
        }
        return const SizedBox();
      },
    );
  }
}

class _GamersBody extends StatelessWidget {
  final List<AdminUserItem> users;
  const _GamersBody({required this.users});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _kAdmin,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.person_add_rounded),
        label: Text('ADD GAMER',
            style: GoogleFonts.orbitron(
                fontSize: 10, fontWeight: FontWeight.bold)),
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => BlocProvider.value(
            value: context.read<AdminBloc>(),
            child: const _UserFormSheet(),
          ),
        ),
      ),
      body: users.isEmpty
          ? Center(
              child: Text('No users yet',
                  style: GoogleFonts.orbitron(
                      color: Colors.white38, fontSize: 14)))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
              itemCount: users.length,
              itemBuilder: (context, i) =>
                  _GamerCard(user: users[i], index: i),
            ),
    );
  }
}

class _GamerCard extends StatelessWidget {
  final AdminUserItem user;
  final int index;
  const _GamerCard({required this.user, required this.index});
  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###');
    return GestureDetector(
      onTap: () => context
          .read<AdminBloc>()
          .add(AdminUserDetailLoadRequested(user.id)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: _kAdminCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: user.isApproved
                    ? _kAdmin.withValues(alpha: 0.15)
                    : Colors.red.withValues(alpha: 0.4))),
        child: Row(children: [
          CircleAvatar(
            radius: 22,
            backgroundColor:
                (user.isApproved ? _kAdmin : Colors.red)
                    .withValues(alpha: 0.15),
            child: Text(
                user.username.isNotEmpty
                    ? user.username[0].toUpperCase()
                    : '?',
                style: GoogleFonts.orbitron(
                    color:
                        user.isApproved ? _kAdmin : Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(user.username,
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    if (!user.isApproved) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color:
                                Colors.red.withValues(alpha: 0.2),
                            borderRadius:
                                BorderRadius.circular(4)),
                        child: Text('PENDING',
                            style: GoogleFonts.inter(
                                color: Colors.red,
                                fontSize: 9,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ]),
                  Text(user.email,
                      style: GoogleFonts.inter(
                          color: Colors.white38, fontSize: 11)),
                  const SizedBox(height: 4),
                  Row(children: [
                    _InfoChip(Icons.event_rounded,
                        '${user.bookingCount} bookings'),
                    const SizedBox(width: 8),
                    _InfoChip(
                        Icons.account_balance_wallet_rounded,
                        '${fmt.format(user.walletBalance)} UZS',
                        color: Colors.green),
                  ]),
                ]),
          ),
          if (!user.isApproved) ...[
            IconButton(
              icon: const Icon(Icons.check_circle,
                  color: Color(0xFF76FF03), size: 28),
              onPressed: () => context
                  .read<AdminBloc>()
                  .add(AdminApproveUserRequested(user.id)),
            ),
            IconButton(
              icon: const Icon(Icons.cancel,
                  color: Colors.red, size: 28),
              onPressed: () => context
                  .read<AdminBloc>()
                  .add(AdminRejectUserRequested(user.id)),
            ),
          ] else ...[
            IconButton(
              icon: Icon(Icons.delete_outline_rounded,
                  color: Colors.red.withValues(alpha: 0.7), size: 24),
              onPressed: () => _confirmDelete(context, user),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Colors.white24),
          ],
        ]),
      ),
    ).animate(delay: (index * 40).ms).fadeIn();
  }

  void _confirmDelete(BuildContext ctx, AdminUserItem u) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(AppConstants.backgroundSecondary),
        title: Text('Delete ${u.username}?',
            style: GoogleFonts.orbitron(color: Colors.white, fontSize: 14)),
        content: Text(
            'This will permanently remove this gamer and all their bookings, payments, and wallet data.',
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CANCEL',
                style: GoogleFonts.inter(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ctx.read<AdminBloc>().add(AdminDeleteUserRequested(u.id));
            },
            child: Text('DELETE',
                style: GoogleFonts.inter(
                    color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _UserDetailView extends StatelessWidget {
  final AdminUserDetail detail;
  const _UserDetailView({required this.detail});
  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => context
                  .read<AdminBloc>()
                  .add(const AdminUsersLoadRequested()),
              child: Row(children: [
                const Icon(Icons.arrow_back_ios,
                    color: _kAdmin, size: 16),
                Text('Back to Gamers',
                    style: GoogleFonts.inter(
                        color: _kAdmin, fontSize: 13)),
              ]),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: _kAdminCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: _kAdmin.withValues(alpha: 0.3))),
              child: Column(children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor:
                      _kAdmin.withValues(alpha: 0.15),
                  child: Text(
                      detail.username.isNotEmpty
                          ? detail.username[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.orbitron(
                          color: _kAdmin,
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                Text(detail.username,
                    style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                Text(detail.email,
                    style: GoogleFonts.inter(
                        color: Colors.white38, fontSize: 13)),
                if (detail.phone != null &&
                    detail.phone!.isNotEmpty)
                  Text(detail.phone!,
                      style: GoogleFonts.inter(
                          color: Colors.white38, fontSize: 12)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: (detail.isApproved
                              ? const Color(0xFF76FF03)
                              : Colors.red)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6)),
                  child: Text(
                      detail.isApproved
                          ? 'APPROVED'
                          : 'PENDING',
                      style: GoogleFonts.inter(
                          color: detail.isApproved
                              ? const Color(0xFF76FF03)
                              : Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceEvenly,
                    children: [
                      _detailStat('WALLET',
                          '${fmt.format(detail.walletBalance)} UZS'),
                      _detailStat('SPENT',
                          '${fmt.format(detail.totalSpent)} UZS'),
                      _detailStat(
                          'BOOKINGS', '${detail.bookingCount}'),
                    ]),
              ]),
            ),
            const SizedBox(height: 20),
            if (detail.bookings.isNotEmpty) ...[
              _sectionLabel('BOOKINGS'),
              const SizedBox(height: 10),
              ...detail.bookings.take(10).map((b) => _miniCard(
                  "${b['club_name'] ?? 'Club'} \u2013 ${b['status']}",
                  "${b['start_time']?.toString().substring(0, 16) ?? ''}  |  ${b['computers_booked'] ?? 1} PC(s)",
                  Icons.event_note_rounded)),
            ],
            if (detail.payments.isNotEmpty) ...[
              const SizedBox(height: 20),
              _sectionLabel('PAYMENTS'),
              const SizedBox(height: 10),
              ...detail.payments.take(10).map((p) => _miniCard(
                  '${fmt.format((p['amount'] as num?)?.toInt() ?? 0)} UZS',
                  "${p['method'] ?? ''} \u2013 ${p['status'] ?? ''}",
                  Icons.payment_rounded)),
            ],
            if (detail.transactions.isNotEmpty) ...[
              const SizedBox(height: 20),
              _sectionLabel('TRANSACTIONS'),
              const SizedBox(height: 10),
              ...detail.transactions.take(10).map((t) => _miniCard(
                  '${fmt.format((t['amount'] as num?)?.toInt() ?? 0)} UZS',
                  "${t['type'] ?? ''} \u2013 ${t['description'] ?? ''}",
                  Icons.swap_horiz_rounded)),
            ],
          ]),
    );
  }

  static Widget _detailStat(String label, String value) =>
      Column(children: [
        Text(value,
            style: GoogleFonts.orbitron(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold)),
        Text(label,
            style:
                GoogleFonts.inter(color: Colors.white38, fontSize: 9)),
      ]);

  static Widget _miniCard(
          String title, String subtitle, IconData icon) =>
      Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: _kAdminCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white12)),
        child: Row(children: [
          Icon(icon, color: _kAdmin, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                  Text(subtitle,
                      style: GoogleFonts.inter(
                          color: Colors.white38, fontSize: 11)),
                ]),
          ),
        ]),
      );
}

class _UserFormSheet extends StatefulWidget {
  const _UserFormSheet();
  @override
  State<_UserFormSheet> createState() => _UserFormSheetState();
}

class _UserFormSheetState extends State<_UserFormSheet> {
  final _form = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    for (final c in [_username, _email, _phone, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(AppConstants.backgroundSecondary),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: _kAdmin, width: 1.5)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _form,
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: _kAdmin.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text('ADD GAMER ACCOUNT',
                  style: GoogleFonts.orbitron(
                      color: _kAdmin,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5)),
              const SizedBox(height: 20),
              _Field(_username, 'Username', required: true),
              const SizedBox(height: 12),
              _Field(_email, 'Email', required: true),
              const SizedBox(height: 12),
              _Field(_phone, 'Phone (optional)'),
              const SizedBox(height: 12),
              _Field(_password, 'Password', required: true),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kAdmin,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _submit,
                  child: Text('CREATE ACCOUNT',
                      style: GoogleFonts.orbitron(
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ),
              ),
            ]),
      ),
    );
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    Navigator.of(context).pop();
    context.read<AdminBloc>().add(AdminCreateUserRequested(
          username: _username.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
          phone: _phone.text.trim(),
        ));
  }
}

// ═══════════════════════════════════════════════════════════════════════
// TAB 6 — PAYMENTS
// ═══════════════════════════════════════════════════════════════════════

class _PaymentsTab extends StatelessWidget {
  const _PaymentsTab();
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminBloc, AdminState>(
      listener: (context, state) {
        if (state is AdminPaymentValidated) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Payment validated',
                  style: TextStyle(color: Colors.black)),
              backgroundColor: _kAdmin));
          context.read<AdminBloc>().add(
              const AdminPendingPaymentsLoadRequested());
        }
      },
      builder: (context, state) {
        if (state is AdminLoading) return const LoadingShimmer();
        if (state is AdminPaymentsLoaded) {
          return _PaymentsList(payments: state.payments);
        }
        return const _PaymentsList(payments: []);
      },
    );
  }
}

class _PaymentsList extends StatelessWidget {
  final List<AdminPaymentItem> payments;
  const _PaymentsList({required this.payments});
  @override
  Widget build(BuildContext context) {
    if (payments.isEmpty) {
      return Center(
          child: Text('No pending payments',
              style: GoogleFonts.orbitron(
                  color: Colors.white38, fontSize: 14)));
    }
    return RefreshIndicator(
      color: _kAdmin,
      onRefresh: () async => context
          .read<AdminBloc>()
          .add(const AdminPendingPaymentsLoadRequested()),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: payments.length,
        itemBuilder: (context, i) {
          final p = payments[i];
          final fmt = NumberFormat('#,###');
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: _kAdminCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3))),
            child: Row(children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('@${p.username}',
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      Text('${p.clubName}  |  ${p.method}',
                          style: GoogleFonts.inter(
                              color: Colors.white38,
                              fontSize: 11)),
                      const SizedBox(height: 4),
                      Text(
                          '${fmt.format(p.amount.toInt())} UZS',
                          style: GoogleFonts.orbitron(
                              color: _kAdmin,
                              fontSize: 13,
                              fontWeight: FontWeight.bold)),
                    ]),
              ),
              if (p.status.toUpperCase() == 'PENDING')
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF76FF03),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                  ),
                  onPressed: () => context.read<AdminBloc>().add(
                      AdminPaymentValidateRequested(p.id)),
                  child: Text('VALIDATE',
                      style: GoogleFonts.orbitron(
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color:
                          Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6)),
                  child: Text(p.status.toUpperCase(),
                      style: GoogleFonts.inter(
                          color: Colors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
            ]),
          ).animate(delay: (i * 40).ms).fadeIn();
        },
      ),
    );
  }
}
