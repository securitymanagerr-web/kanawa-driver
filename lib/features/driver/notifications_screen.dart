// KANAWA - Notificações (Motorista)
// v2.3 — Filtra notificações fantasma + navegação + som/vibração
// Design: MBSoft · Benvindo Mersh

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/api/api_client.dart';
import '../../core/services/local_notifications_service.dart';
import '../../core/theme/kanawa_theme.dart';
import 'driver_trip_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  Set<String> _availableTripIds = {};
  bool _isLoading = true;
  String? _error;
  Timer? _refreshTimer;
  bool _isOpeningTrip = false;

  // 🔔 Para detetar notificações novas
  final Set<String> _knownNotificationIds = {};
  bool _firstLoadDone = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      _loadNotifications(silent: true);
    });
  }

  Future<void> _loadNotifications({bool silent = false}) async {
    if (!mounted) return;

    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final results = await Future.wait<dynamic>([
        ApiClient.get('/notifications/', authenticated: true),
        ApiClient.get('/trips/pending/', authenticated: true),
      ]);

      if (!mounted) return;

      final notifRes = results[0] as dynamic;
      final pendingRes = results[1] as dynamic;

      // ─── 1. Recolher ids das viagens ainda pendentes ───
      final availableIds = <String>{};
      if (pendingRes.success) {
        final raw = pendingRes.data;
        List<dynamic>? list;
        if (raw is List) {
          list = raw;
        } else if (raw is Map && raw['results'] is List) {
          list = raw['results'] as List;
        }
        if (list != null) {
          for (final item in list) {
            if (item is Map && item['id'] != null) {
              availableIds.add(item['id'].toString());
            }
          }
        }
      }

      // ─── 2. Filtrar notificações ───
      if (notifRes.success) {
        final data = notifRes.data;
        List<dynamic>? list;

        if (data is List) {
          list = data;
        } else if (data is Map && data['results'] is List) {
          list = data['results'] as List;
        }

        if (list != null) {
          final all = list
              .map((m) => Map<String, dynamic>.from(m as Map))
              .toList();

          final filtered = all.where((n) {
            final type = n['type']?.toString() ?? '';
            if (type != 'NEW_TRIP_AVAILABLE') return true;

            final dataMap = n['data'];
            final tripId = (dataMap is Map)
                ? dataMap['trip_id']?.toString()
                : null;

            if (tripId == null || tripId.isEmpty) return false;

            return availableIds.contains(tripId);
          }).toList();

          // 🔔 Detetar notificações novas (só após primeira carga)
          if (_firstLoadDone) {
            for (final n in filtered) {
              final id = n['id']?.toString() ?? '';
              if (id.isEmpty) continue;
              if (_knownNotificationIds.contains(id)) continue;

              // Nova notificação → som + vibração
              final type = n['type']?.toString() ?? '';
              if (type == 'NEW_TRIP_AVAILABLE') {
                _playNewTripSound(n);
              } else if (type.startsWith('TRIP_')) {
                _playUpdateSound(n);
              }
            }
          }

          // Atualizar ids conhecidos
          _knownNotificationIds.clear();
          for (final n in filtered) {
            final id = n['id']?.toString() ?? '';
            if (id.isNotEmpty) _knownNotificationIds.add(id);
          }

          setState(() {
            _notifications = filtered;
            _availableTripIds = availableIds;
            _isLoading = false;
            _error = null;
          });

          if (!_firstLoadDone) _firstLoadDone = true;
        } else {
          setState(() {
            _notifications = [];
            _isLoading = false;
          });
        }
      } else {
        if (!silent) {
          setState(() {
            _isLoading = false;
            _error = 'Erro ao carregar notificações';
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Erro: $e');
      if (!silent && mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Erro de ligação';
        });
      }
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 🔔 SOM + VIBRAÇÃO
  // ═══════════════════════════════════════════════════════════
  Future<void> _playNewTripSound(Map<String, dynamic> notif) async {
    final title = notif['title']?.toString() ?? 'Nova viagem';
    final message = notif['message']?.toString() ?? '';

    await LocalNotificationsService.show(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      title: '🚗 $title',
      body: message.isNotEmpty ? message : 'Tens uma nova viagem disponível',
      payload: 'NEW_TRIP_AVAILABLE',
    );
  }

  Future<void> _playUpdateSound(Map<String, dynamic> notif) async {
    final title = notif['title']?.toString() ?? 'Atualização';
    final message = notif['message']?.toString() ?? '';

    await LocalNotificationsService.show(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      title: title,
      body: message,
      payload: notif['type']?.toString(),
    );
  }

  Future<void> _markAsRead(String id) async {
    try {
      await ApiClient.post(
        '/notifications/$id/read/',
        body: {},
        authenticated: true,
      );
      _loadNotifications(silent: true);
    } catch (e) {
      debugPrint('❌ Erro: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final res = await ApiClient.post(
        '/notifications/read-all/',
        body: {},
        authenticated: true,
      );

      if (res.success) {
        _loadNotifications(silent: true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Todas as notificações foram marcadas como lidas',
                style: GoogleFonts.inter(fontSize: 13),
              ),
              backgroundColor: KanawaColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Erro: $e');
    }
  }

  Future<void> _onNotificationTap(Map<String, dynamic> notif) async {
    final id = notif['id']?.toString() ?? '';
    final type = notif['type']?.toString() ?? '';
    final isRead = notif['is_read'] == true;

    if (!isRead && id.isNotEmpty) {
      await _markAsRead(id);
    }

    if (type == 'NEW_TRIP_AVAILABLE') {
      await _openTripFromNotification(notif);
    }
  }

  Future<void> _openTripFromNotification(Map<String, dynamic> notif) async {
    if (_isOpeningTrip) return;

    String? tripId;
    final data = notif['data'];
    if (data is Map) {
      tripId = data['trip_id']?.toString();
    }
    if (tripId == null || tripId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Viagem não encontrada nesta notificação',
              style: GoogleFonts.inter(fontSize: 13),
            ),
            backgroundColor: KanawaColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() => _isOpeningTrip = true);

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: KanawaColors.red),
        ),
      );
    }

    try {
      final results = await Future.wait<dynamic>([
        ApiClient.get('/trips/pending/', authenticated: true),
        _getDriverLocation(),
      ]);

      final pendingRes = results[0] as dynamic;
      final driverLoc = results[1] as LatLng;

      if (mounted) Navigator.of(context).pop();

      Map<String, dynamic>? tripData;

      if (pendingRes.success) {
        final raw = pendingRes.data;
        List<dynamic>? list;

        if (raw is List) {
          list = raw;
        } else if (raw is Map && raw['results'] is List) {
          list = raw['results'] as List;
        }

        if (list != null) {
          for (final item in list) {
            if (item is Map) {
              final m = Map<String, dynamic>.from(item);
              if (m['id']?.toString() == tripId) {
                tripData = m;
                break;
              }
            }
          }
        }
      }

      if (tripData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Esta viagem já não está disponível.\n'
                'Pode ter sido aceite por outro motorista.',
                style: GoogleFonts.inter(fontSize: 13),
              ),
              backgroundColor: KanawaColors.warning,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        setState(() => _isOpeningTrip = false);
        _loadNotifications(silent: true);
        return;
      }

      if (!mounted) return;

      Navigator.of(context).pop();

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DriverTripDetailScreen(
            trip: tripData!,
            driverLocation: driverLoc,
            onAccepted: () {
              _loadNotifications(silent: true);
            },
          ),
        ),
      );

      if (mounted) _loadNotifications(silent: true);
    } catch (e) {
      debugPrint('❌ Erro ao abrir viagem: $e');
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro ao abrir a viagem',
              style: GoogleFonts.inter(fontSize: 13),
            ),
            backgroundColor: KanawaColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isOpeningTrip = false);
    }
  }

  Future<LatLng> _getDriverLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 5));
      return LatLng(pos.latitude, pos.longitude);
    } catch (e) {
      debugPrint('⚠️ GPS falhou, fallback Saurimo: $e');
      return const LatLng(-9.6608, 20.3972);
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'TRIP_ACCEPTED':
        return Icons.check_circle_rounded;
      case 'TRIP_ARRIVED':
        return Icons.location_on_rounded;
      case 'TRIP_STARTED':
        return Icons.navigation_rounded;
      case 'TRIP_COMPLETED':
        return Icons.flag_rounded;
      case 'TRIP_CANCELLED':
        return Icons.cancel_rounded;
      case 'NEW_TRIP_AVAILABLE':
        return Icons.local_taxi_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'TRIP_ACCEPTED':
        return KanawaColors.blue;
      case 'TRIP_ARRIVED':
        return KanawaColors.warning;
      case 'TRIP_STARTED':
        return KanawaColors.success;
      case 'TRIP_COMPLETED':
        return KanawaColors.driver;
      case 'TRIP_CANCELLED':
        return KanawaColors.danger;
      case 'NEW_TRIP_AVAILABLE':
        return KanawaColors.red;
      default:
        return KanawaColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unread = _notifications.where((n) => n['is_read'] != true).length;

    return Scaffold(
      backgroundColor: KanawaColors.bgApp,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: KanawaColors.bgCard,
                        shape: BoxShape.circle,
                        border: Border.all(color: KanawaColors.border),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: KanawaColors.textStrong,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notificações',
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: KanawaColors.textStrong,
                          ),
                        ),
                        if (unread > 0)
                          Text(
                            '$unread não lida${unread > 1 ? "s" : ""}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: KanawaColors.red,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (unread > 0)
                    TextButton(
                      onPressed: _markAllAsRead,
                      child: Text(
                        'Marcar todas',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: KanawaColors.blue,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(color: KanawaColors.border, height: 1),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: KanawaColors.red,
                      ),
                    )
                  : _error != null
                      ? _buildError()
                      : _notifications.isEmpty
                          ? _buildEmpty()
                          : RefreshIndicator(
                              onRefresh: () => _loadNotifications(),
                              color: KanawaColors.red,
                              child: ListView.builder(
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(16),
                                itemCount: _notifications.length,
                                itemBuilder: (context, index) {
                                  return _buildNotificationItem(
                                    _notifications[index],
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notif) {
    final type = notif['type']?.toString() ?? 'SYSTEM';
    final title = notif['title']?.toString() ?? '';
    final message = notif['message']?.toString() ?? '';
    final timeAgo = notif['time_ago']?.toString() ?? '';
    final isRead = notif['is_read'] == true;

    final color = _colorForType(type);
    final icon = _iconForType(type);
    final isTripNotif = type == 'NEW_TRIP_AVAILABLE';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onNotificationTap(notif),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isRead ? KanawaColors.bgCard : color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isRead ? KanawaColors.border : color.withOpacity(0.3),
              width: isRead ? 1 : 1.5,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight:
                                  isRead ? FontWeight.w700 : FontWeight.w900,
                              color: KanawaColors.textStrong,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 6),
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: KanawaColors.textMuted,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          timeAgo,
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: KanawaColors.textSubtle,
                          ),
                        ),
                        if (isTripNotif) ...[
                          const Spacer(),
                          Text(
                            'Ver viagem',
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: color,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 13,
                            color: color,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
                Icons.notifications_none_rounded,
                color: KanawaColors.textMuted,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Sem notificações',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: KanawaColors.textStrong,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'As tuas notificações vão aparecer aqui',
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
              onPressed: () => _loadNotifications(),
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