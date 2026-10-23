// KANAWA - Aba de Ganhos (Motorista)
// v2.3 — Auto-refresh a cada 5s + pull-to-refresh

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/kanawa_theme.dart';

class DriverEarningsTab extends StatefulWidget {
  const DriverEarningsTab({super.key});

  @override
  State<DriverEarningsTab> createState() => _DriverEarningsTabState();
}

class _DriverEarningsTabState extends State<DriverEarningsTab> {
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _recentTrips = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _loadData(); // primeira carga
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _loadData(silent: true);
    });
  }

  Future<void> _loadData({bool silent = false}) async {
    if (!mounted) return;
    if (_isRefreshing) return;

    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    _isRefreshing = true;

    try {
      final statsRes = await ApiClient.get(
        '/trips/stats/',
        authenticated: true,
      );
      final historyRes = await ApiClient.get(
        '/trips/history/?period=all',
        authenticated: true,
      );

      if (!mounted) return;

      if (statsRes.success && statsRes.data is Map) {
        _stats = Map<String, dynamic>.from(statsRes.data as Map);
      }

      if (historyRes.success &&
          historyRes.data is Map &&
          historyRes.data['results'] is List) {
        _recentTrips = (historyRes.data['results'] as List)
            .where((m) => m['status'] == 'COMPLETED')
            .take(5)
            .map((m) => Map<String, dynamic>.from(m as Map))
            .toList();
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      debugPrint('❌ Erro: $e');
      if (mounted && !silent) {
        setState(() {
          _isLoading = false;
          _error = 'Erro ao carregar dados';
        });
      }
    } finally {
      _isRefreshing = false;
    }
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String _formatKz(num value) {
    if (value >= 1000) {
      final k = value ~/ 1000;
      final rest = value.toInt() % 1000;
      return '$k.${rest.toString().padLeft(3, '0')} Kz';
    }
    return '${value.toStringAsFixed(0)} Kz';
  }

  String _formatKzShort(double value) {
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    return value.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KanawaColors.bgApp,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadData(silent: true),
          color: KanawaColors.red,
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: KanawaColors.red),
                )
              : _error != null
                  ? _buildError()
                  : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Ganhos',
                                style: GoogleFonts.inter(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: KanawaColors.textStrong,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: KanawaColors.success.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: KanawaColors.success,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Ao vivo',
                                      style: GoogleFonts.inter(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        color: KanawaColors.success,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Resumo do teu trabalho',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: KanawaColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildBigCard(),
                          const SizedBox(height: 16),
                          _buildTwoSmallCards(),
                          const SizedBox(height: 24),
                          _buildChart(),
                          const SizedBox(height: 24),
                          _buildRecentTrips(),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _buildBigCard() {
    final today = _stats?['today'] as Map? ?? {};
    final total = _toDouble(today['total']);
    final count = _toInt(today['count']);
    final km = _toDouble(today['km']);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [KanawaColors.success, Color(0xFF15803D)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: KanawaColors.success.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'HOJE',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.trending_up_rounded,
                color: Colors.white70,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _formatKz(total),
            style: GoogleFonts.inter(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _miniStat(Icons.local_taxi_rounded, '$count viagens'),
              const SizedBox(width: 16),
              _miniStat(Icons.route_rounded, '${km.toStringAsFixed(1)} km'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white.withOpacity(0.85)),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildTwoSmallCards() {
    final week = _stats?['week'] as Map? ?? {};
    final month = _stats?['month'] as Map? ?? {};

    return Row(
      children: [
        Expanded(
          child: _smallCard(
            label: 'SEMANA',
            total: _toDouble(week['total']),
            count: _toInt(week['count']),
            color: KanawaColors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _smallCard(
            label: 'MÊS',
            total: _toDouble(month['total']),
            count: _toInt(month['count']),
            color: KanawaColors.warning,
          ),
        ),
      ],
    );
  }

  Widget _smallCard({
    required String label,
    required double total,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KanawaColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KanawaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  color: KanawaColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _formatKz(total),
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: KanawaColors.textStrong,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$count viagens',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: KanawaColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    final daily = (_stats?['daily_last_7'] as List?) ?? [];
    if (daily.isEmpty) return const SizedBox.shrink();

    double maxValue = 0;
    for (final d in daily) {
      final total = _toDouble(d['total']);
      if (total > maxValue) maxValue = total;
    }
    if (maxValue == 0) maxValue = 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KanawaColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KanawaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Últimos 7 dias',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: KanawaColors.textStrong,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: daily.map((d) {
                final total = _toDouble(d['total']);
                final ratio = total / maxValue;
                final barHeight = ratio * 90 + 6;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (total > 0)
                          Text(
                            _formatKzShort(total),
                            style: GoogleFonts.inter(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: KanawaColors.textMuted,
                            ),
                          ),
                        const SizedBox(height: 3),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          height: barHeight,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: total > 0
                                  ? [KanawaColors.success, const Color(0xFF15803D)]
                                  : [KanawaColors.bgSoft, KanawaColors.bgSoft],
                            ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          d['day_label']?.toString() ?? '',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: KanawaColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTrips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Últimas viagens',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: KanawaColors.textStrong,
              ),
            ),
            const Spacer(),
            if (_recentTrips.isNotEmpty)
              Text(
                '${_recentTrips.length}',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: KanawaColors.textMuted,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_recentTrips.isEmpty)
          _buildEmptyRecent()
        else
          ..._recentTrips.map((trip) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildTripItem(trip),
              )),
      ],
    );
  }

  Widget _buildTripItem(Map<String, dynamic> trip) {
    final passenger = trip['passenger_name']?.toString() ?? 'Passageiro';
    final dropoff = trip['dropoff_address']?.toString() ?? 'Destino';
    final earnings = _toDouble(trip['driver_earnings']);
    final date = trip['completed_at']?.toString() ?? '';

    String dateFormatted = '';
    try {
      final dt = DateTime.parse(date).toLocal();
      dateFormatted =
          '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} · ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {}

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: KanawaColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KanawaColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: KanawaColors.successSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: KanawaColors.success,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$passenger → $dropoff',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: KanawaColors.textStrong,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  dateFormatted,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: KanawaColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '+${_formatKz(earnings)}',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: KanawaColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyRecent() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: KanawaColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KanawaColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: KanawaColors.bgSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.directions_car_outlined,
              color: KanawaColors.textMuted,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Ainda sem viagens concluídas',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: KanawaColors.textStrong,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Os teus ganhos aparecem aqui depois da primeira viagem',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              color: KanawaColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                color: KanawaColors.danger, size: 48),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Erro',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: KanawaColors.textStrong,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _loadData(),
              style: ElevatedButton.styleFrom(
                backgroundColor: KanawaColors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}