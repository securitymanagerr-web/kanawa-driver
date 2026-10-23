// KANAWA - Aba de Histórico (Motorista)
// v2.3 — Auto-refresh a cada 5s + pull-to-refresh

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/kanawa_theme.dart';

class DriverHistoryTab extends StatefulWidget {
  const DriverHistoryTab({super.key});

  @override
  State<DriverHistoryTab> createState() => _DriverHistoryTabState();
}

class _DriverHistoryTabState extends State<DriverHistoryTab> {
  String _filter = 'all';
  List<Map<String, dynamic>> _trips = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _loadHistory(); // primeira carga
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
      _loadHistory(silent: true);
    });
  }

  Future<void> _loadHistory({bool silent = false}) async {
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
      final response = await ApiClient.get(
        '/trips/history/?period=$_filter',
        authenticated: true,
      );

      if (!mounted) return;

      if (response.success && response.data is Map) {
        final results = (response.data['results'] as List?) ?? [];
        _trips = results
            .map((m) => Map<String, dynamic>.from(m as Map))
            .toList();
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = null;
          });
        }
      } else {
        if (mounted && !silent) {
          setState(() {
            _isLoading = false;
            _error = 'Erro ao carregar histórico';
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Erro: $e');
      if (mounted && !silent) {
        setState(() {
          _isLoading = false;
          _error = 'Erro de ligação';
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

  String _dateGroupLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(dateOnly).inDays;

    if (diff == 0) return 'HOJE';
    if (diff == 1) return 'ONTEM';
    if (diff < 7) return 'ESTA SEMANA';
    if (diff < 30) return 'ESTE MÊS';
    return 'MAIS ANTIGAS';
  }

  Map<String, List<Map<String, dynamic>>> _groupedTrips() {
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final trip in _trips) {
      String label = 'MAIS ANTIGAS';
      try {
        final raw = trip['completed_at']?.toString() ??
            trip['cancelled_at']?.toString() ??
            trip['requested_at']?.toString() ??
            '';
        final dt = DateTime.parse(raw).toLocal();
        label = _dateGroupLabel(dt);
      } catch (_) {}
      groups.putIfAbsent(label, () => []).add(trip);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KanawaColors.bgApp,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Histórico',
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
                    '${_trips.length} viagem(ns)',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: KanawaColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFilters(),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: KanawaColors.red,
                      ),
                    )
                  : _error != null
                      ? _buildError()
                      : _trips.isEmpty
                          ? _buildEmpty()
                          : RefreshIndicator(
                              onRefresh: () => _loadHistory(silent: true),
                              color: KanawaColors.red,
                              child: SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding:
                                    const EdgeInsets.fromLTRB(20, 0, 20, 20),
                                child: _buildGroupedList(),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    final filters = {
      'all': 'Todas',
      'today': 'Hoje',
      'week': 'Semana',
      'month': 'Mês',
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.entries.map((e) {
          final selected = _filter == e.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                if (_filter == e.key) return;
                setState(() => _filter = e.key);
                _loadHistory();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: selected ? KanawaColors.red : KanawaColors.bgCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? KanawaColors.red : KanawaColors.border,
                  ),
                ),
                child: Text(
                  e.value,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : KanawaColors.textMuted,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGroupedList() {
    final grouped = _groupedTrips();
    final orderedKeys = [
      'HOJE',
      'ONTEM',
      'ESTA SEMANA',
      'ESTE MÊS',
      'MAIS ANTIGAS',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: orderedKeys.where((k) => grouped.containsKey(k)).map((label) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  color: KanawaColors.textMuted,
                ),
              ),
            ),
            ...grouped[label]!.map((trip) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildTripCard(trip),
                )),
            const SizedBox(height: 8),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildTripCard(Map<String, dynamic> trip) {
    final passenger = trip['passenger_name']?.toString() ?? 'Passageiro';
    final pickup = trip['pickup_address']?.toString() ?? '—';
    final dropoff = trip['dropoff_address']?.toString() ?? '—';
    final earnings = _toDouble(trip['driver_earnings']);
    final km = _toDouble(trip['distance_km']);
    final min = _toInt(trip['duration_minutes']);
    final rating = _toInt(trip['rating']);
    final status = trip['status']?.toString() ?? 'COMPLETED';
    final isCancelled = status == 'CANCELLED';
    final reason = trip['cancellation_reason']?.toString() ?? '';

    final color = isCancelled ? KanawaColors.danger : KanawaColors.success;
    final bgSoft = isCancelled
        ? KanawaColors.danger.withOpacity(0.1)
        : KanawaColors.successSoft;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KanawaColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCancelled
              ? KanawaColors.danger.withOpacity(0.3)
              : KanawaColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: bgSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isCancelled
                      ? Icons.cancel_rounded
                      : Icons.check_circle_rounded,
                  color: color,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            passenger,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: KanawaColors.textStrong,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCancelled) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: KanawaColors.danger.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Cancelada',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: KanawaColors.danger,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (!isCancelled && rating > 0)
                      Row(
                        children: List.generate(
                          5,
                          (i) => Icon(
                            i < rating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 11,
                            color: i < rating
                                ? KanawaColors.warning
                                : KanawaColors.textSubtle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (!isCancelled)
                Text(
                  '+${_formatKz(earnings)}',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: KanawaColors.success,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(color: KanawaColors.border, height: 1),
          const SizedBox(height: 10),
          _routeLine(Icons.location_on_rounded, KanawaColors.success, pickup),
          const SizedBox(height: 6),
          _routeLine(Icons.flag_rounded, KanawaColors.red, dropoff),
          if (isCancelled && reason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: KanawaColors.danger.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: KanawaColors.danger,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Motivo: $reason',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: KanawaColors.danger,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.route_rounded,
                  size: 13, color: KanawaColors.textMuted),
              const SizedBox(width: 4),
              Text(
                '${km.toStringAsFixed(1)} km',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: KanawaColors.textMuted,
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.access_time_rounded,
                  size: 13, color: KanawaColors.textMuted),
              const SizedBox(width: 4),
              Text(
                '$min min',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: KanawaColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _routeLine(IconData icon, Color color, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: KanawaColors.textStrong,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: KanawaColors.bgSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history_rounded,
                color: KanawaColors.textMuted,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Sem viagens',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: KanawaColors.textStrong,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'As tuas viagens vão aparecer aqui',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: KanawaColors.textMuted,
              ),
            ),
          ],
        ),
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
              onPressed: () => _loadHistory(),
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