import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../config/constants.dart';
import '../../../../core/widgets/loading_shimmer.dart';
import '../../../../injection.dart';
import '../../domain/entities/admin_stats.dart';
import '../bloc/admin_bloc.dart';
import '../bloc/admin_event.dart';
import '../bloc/admin_state.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<AdminBloc>()..add(const AdminDashboardLoadRequested()),
      child: const _AdminDashboardContent(),
    );
  }
}

class _AdminDashboardContent extends StatelessWidget {
  const _AdminDashboardContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppConstants.backgroundPrimary),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'ADMIN DASHBOARD',
          style: GoogleFonts.orbitron(
            color: const Color(AppConstants.primaryAccent),
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.payment_rounded,
                color: Color(AppConstants.primaryAccent)),
            onPressed: () => context.push('/admin/payments'),
            tooltip: 'Pending Payments',
          ),
        ],
      ),
      body: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, state) {
          if (state is AdminLoading || state is AdminInitial) {
            return const LoadingShimmer();
          }
          if (state is AdminError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message,
                      style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context
                        .read<AdminBloc>()
                        .add(const AdminDashboardLoadRequested()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (state is AdminDashboardLoaded) {
            return RefreshIndicator(
              color: const Color(AppConstants.primaryAccent),
              onRefresh: () async {
                context
                    .read<AdminBloc>()
                    .add(const AdminDashboardLoadRequested());
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatsGrid(stats: state.stats).animate().fadeIn(),
                    const SizedBox(height: 24),
                    _RevenueChart(days: state.stats.revenueByDay)
                        .animate()
                        .fadeIn(delay: 200.ms),
                    const SizedBox(height: 24),
                    _ClubsBarChart(clubs: state.stats.bookingsByClub)
                        .animate()
                        .fadeIn(delay: 300.ms),
                  ],
                ),
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final AdminStats stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###');
    final cards = [
      _StatCard(
        label: 'Revenue Today',
        value: '${fmt.format(stats.totalRevenueToday)} UZS',
        icon: Icons.attach_money_rounded,
        color: const Color(0xFF76FF03),
        delay: 0,
      ),
      _StatCard(
        label: 'Active Bookings',
        value: stats.activeBookings.toString(),
        icon: Icons.event_available_rounded,
        color: const Color(AppConstants.primaryAccent),
        delay: 80,
      ),
      _StatCard(
        label: 'Pending Payments',
        value: stats.pendingPayments.toString(),
        icon: Icons.pending_actions_rounded,
        color: Colors.orange,
        delay: 160,
      ),
      _StatCard(
        label: 'Total Users',
        value: stats.totalUsers.toString(),
        icon: Icons.people_rounded,
        color: Colors.purple,
        delay: 240,
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: cards,
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final int delay;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(AppConstants.backgroundSecondary),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(label,
                  style: GoogleFonts.inter(
                      color: Colors.white54, fontSize: 11)),
            ],
          ),
        ],
      ),
    ).animate(delay: delay.ms).fadeIn().slideY(begin: 0.1);
  }
}

class _RevenueChart extends StatelessWidget {
  final List<RevenueByDay> days;
  const _RevenueChart({required this.days});

  @override
  Widget build(BuildContext context) {
    final last14 = days.length > 14 ? days.sublist(days.length - 14) : days;
    final maxY = last14.isEmpty
        ? 1.0
        : last14.map((d) => d.revenue).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(AppConstants.backgroundSecondary),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('REVENUE — LAST 14 DAYS',
              style: GoogleFonts.orbitron(
                  color: Colors.white54, fontSize: 10, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: Colors.white12,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 48,
                      getTitlesWidget: (v, _) => Text(
                        '${(v / 1000).toStringAsFixed(0)}K',
                        style: GoogleFonts.inter(
                            color: Colors.white38, fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 2,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= last14.length) {
                          return const SizedBox();
                        }
                        final date = last14[idx].date;
                        final parts = date.split('-');
                        return Text(
                          parts.length == 3 ? '${parts[2]}/${parts[1]}' : '',
                          style: GoogleFonts.inter(
                              color: Colors.white38, fontSize: 9),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (last14.length - 1).toDouble(),
                minY: 0,
                maxY: maxY * 1.2,
                lineBarsData: [
                  LineChartBarData(
                    spots: last14.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value.revenue);
                    }).toList(),
                    isCurved: true,
                    color: const Color(AppConstants.primaryAccent),
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(AppConstants.primaryAccent)
                          .withValues(alpha: 0.1),
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
}

class _ClubsBarChart extends StatelessWidget {
  final List<BookingsByClub> clubs;
  const _ClubsBarChart({required this.clubs});

  @override
  Widget build(BuildContext context) {
    final sorted = [...clubs]
      ..sort((a, b) => b.bookingCount.compareTo(a.bookingCount));
    final top = sorted.take(6).toList();
    final maxY = top.isEmpty
        ? 1.0
        : top.map((c) => c.bookingCount.toDouble()).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(AppConstants.backgroundSecondary),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('BOOKINGS BY CLUB',
              style: GoogleFonts.orbitron(
                  color: Colors.white54, fontSize: 10, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY * 1.3,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= top.length) {
                          return const SizedBox();
                        }
                        final name = top[idx].clubName;
                        final short = name.split(' ').first;
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            short,
                            style: GoogleFonts.inter(
                                color: Colors.white54, fontSize: 9),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (v, _) => Text(
                        v.toInt().toString(),
                        style: GoogleFonts.inter(
                            color: Colors.white38, fontSize: 10),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: top.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value.bookingCount.toDouble(),
                        color: const Color(AppConstants.primaryAccent),
                        width: 18,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
