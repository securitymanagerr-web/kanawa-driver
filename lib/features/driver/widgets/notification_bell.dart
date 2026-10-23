// KANAWA - Sino de notificações com badge (Motorista)
// v1.0 — Auto-refresh do contador de não lidas

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/kanawa_theme.dart';

class NotificationBell extends StatefulWidget {
  final VoidCallback onTap;

  const NotificationBell({super.key, required this.onTap});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  int _unreadCount = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadCount();
    _startPolling();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 8), (_) {
      _loadCount();
    });
  }

  Future<void> _loadCount() async {
    try {
      final res = await ApiClient.get(
        '/notifications/unread-count/',
        authenticated: true,
      );

      if (!mounted) return;

      if (res.success && res.data is Map) {
        final count = (res.data['unread_count'] as num?)?.toInt() ?? 0;
        if (count != _unreadCount) {
          setState(() => _unreadCount = count);
        }
      }
    } catch (e) {
      debugPrint('⚠️ Erro ao carregar contador: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: KanawaColors.bgCard,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: KanawaColors.textStrong,
              size: 22,
            ),
          ),
          if (_unreadCount > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 2,
                ),
                constraints: const BoxConstraints(minWidth: 18),
                decoration: BoxDecoration(
                  color: KanawaColors.red,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: KanawaColors.bgCard,
                    width: 2,
                  ),
                ),
                child: Text(
                  _unreadCount > 99 ? '99+' : '$_unreadCount',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}