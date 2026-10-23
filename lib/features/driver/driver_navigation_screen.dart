// KANAWA - Navegação (Motorista)
// v2.0 — Telefone + Ligar + Chat + Bairro + Localização do passageiro
// Design: MBSoft · Benvindo Mersh

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_client.dart';
import '../../core/theme/kanawa_theme.dart';
import 'chat_screen.dart';

enum TripPhase { toPickup, atPickup, inTrip, completed }

class DriverNavigationScreen extends StatefulWidget {
  final Map<String, dynamic> trip;

  const DriverNavigationScreen({super.key, required this.trip});

  @override
  State<DriverNavigationScreen> createState() => _DriverNavigationScreenState();
}

class _DriverNavigationScreenState extends State<DriverNavigationScreen> {
  GoogleMapController? _mapController;
  TripPhase _phase = TripPhase.toPickup;
  bool _isProcessing = false;

  // ═══════════════════════════════════════════════════════════
  // HELPERS — extrair dados do passageiro
  // ═══════════════════════════════════════════════════════════
  String _getPassengerName() {
    if (widget.trip['passenger'] is Map) {
      final p = widget.trip['passenger'] as Map;
      return p['full_name']?.toString() ?? 'Passageiro';
    }
    return 'Passageiro';
  }

  String _getPassengerPhone() {
    if (widget.trip['passenger'] is Map) {
      final p = widget.trip['passenger'] as Map;
      return p['phone']?.toString() ?? '';
    }
    return '';
  }

  String _getPickupBairro() {
    final address = widget.trip['pickup_address']?.toString() ?? '';
    if (address.isEmpty || address == 'Localização atual') {
      return 'Bairro não especificado';
    }
    return address;
  }

  LatLng? _getLatLng(String latKey, String lngKey) {
    final lat = double.tryParse(widget.trip[latKey]?.toString() ?? '');
    final lng = double.tryParse(widget.trip[lngKey]?.toString() ?? '');
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  double _distanceKm(LatLng a, LatLng b) {
    const R = 6371.0;
    final lat1 = a.latitude * math.pi / 180;
    final lat2 = b.latitude * math.pi / 180;
    final dLat = (b.latitude - a.latitude) * math.pi / 180;
    final dLng = (b.longitude - a.longitude) * math.pi / 180;
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return R * 2 * math.asin(math.sqrt(h)) * 1.3;
  }

  // ═══════════════════════════════════════════════════════════
  // LIGAR AO PASSAGEIRO
  // ═══════════════════════════════════════════════════════════
  Future<void> _callPassenger() async {
    final phone = _getPassengerPhone();
    if (phone.isEmpty) {
      _showSnack('Número do passageiro não disponível', isError: true);
      return;
    }
    final clean = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri(scheme: 'tel', path: clean);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        _showSnack('Não foi possível abrir o discador', isError: true);
      }
    } catch (e) {
      if (mounted) _showSnack('Erro ao ligar', isError: true);
    }
  }

  // ═══════════════════════════════════════════════════════════
  // ABRIR CHAT
  // ═══════════════════════════════════════════════════════════
  void _openChat() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          otherName: _getPassengerName(),
          otherPhone: _getPassengerPhone(),
          otherLabel: 'Passageiro',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _markArrived() async {
    if (_isProcessing) return;
    setState(() {
      _phase = TripPhase.atPickup;
    });
  }

  Future<void> _startTrip() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final response = await ApiClient.post(
        '/trips/${widget.trip['id']}/start/',
        body: {},
        authenticated: true,
      );

      if (!mounted) return;

      if (response.success) {
        setState(() {
          _phase = TripPhase.inTrip;
          _isProcessing = false;
        });
        _showSnack('Viagem iniciada!');
      } else {
        setState(() => _isProcessing = false);
        _showSnack(response.errorMessage, isError: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showSnack('Erro ao iniciar', isError: true);
      }
    }
  }

  Future<void> _completeTrip() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final response = await ApiClient.post(
        '/trips/${widget.trip['id']}/complete/',
        body: {},
        authenticated: true,
      );

      if (!mounted) return;

      if (response.success) {
        setState(() {
          _phase = TripPhase.completed;
          _isProcessing = false;
        });
        _showSnack('Viagem concluída!');
      } else {
        setState(() => _isProcessing = false);
        _showSnack(response.errorMessage, isError: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showSnack('Erro ao concluir', isError: true);
      }
    }
  }

  Future<void> _cancelTrip() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => _CancelDialog(),
    );

    if (reason == null) return;

    try {
      await ApiClient.post(
        '/trips/${widget.trip['id']}/cancel/',
        body: {'reason': reason},
        authenticated: true,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) _showSnack('Erro ao cancelar', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter(fontSize: 13)),
        backgroundColor: isError ? KanawaColors.danger : KanawaColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pickup = _getLatLng('pickup_latitude', 'pickup_longitude');
    final dropoff = _getLatLng('dropoff_latitude', 'dropoff_longitude');
    final passengerName = _getPassengerName();
    final passengerPhone = _getPassengerPhone();
    final pickupAddress = _getPickupBairro();
    final dropoffAddress =
        widget.trip['dropoff_address']?.toString() ?? 'Destino';

    final kmToPickup = pickup != null
        ? _distanceKm(
            LatLng(
              double.tryParse(
                      widget.trip['pickup_latitude']?.toString() ?? '0') ??
                  0,
              double.tryParse(
                      widget.trip['pickup_longitude']?.toString() ?? '0') ??
                  0,
            ),
            pickup,
          )
        : 0.0;

    return Scaffold(
      backgroundColor: KanawaColors.bgApp,
      body: Column(
        children: [
          // ═══════════════════════════════════════════════════
          // MAPA
          // ═══════════════════════════════════════════════════
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                Positioned.fill(
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: pickup ?? const LatLng(-9.6608, 20.3917),
                      zoom: 15,
                    ),
                    onMapCreated: (c) {
                      _mapController = c;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (pickup != null && dropoff != null) {
                          final bounds = LatLngBounds(
                            southwest: LatLng(
                              math.min(pickup.latitude, dropoff.latitude),
                              math.min(pickup.longitude, dropoff.longitude),
                            ),
                            northeast: LatLng(
                              math.max(pickup.latitude, dropoff.latitude),
                              math.max(pickup.longitude, dropoff.longitude),
                            ),
                          );
                          _mapController?.animateCamera(
                            CameraUpdate.newLatLngBounds(bounds, 80),
                          );
                        }
                      });
                    },
                    markers: {
                      if (pickup != null)
                        Marker(
                          markerId: const MarkerId('pickup'),
                          position: pickup,
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueGreen,
                          ),
                          infoWindow: InfoWindow(title: pickupAddress),
                        ),
                      if (dropoff != null)
                        Marker(
                          markerId: const MarkerId('dropoff'),
                          position: dropoff,
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueRed,
                          ),
                          infoWindow: InfoWindow(title: dropoffAddress),
                        ),
                    },
                    polylines: {
                      if (pickup != null && dropoff != null)
                        Polyline(
                          polylineId: const PolylineId('route'),
                          points: [pickup, dropoff],
                          color: KanawaColors.blue,
                          width: 4,
                        ),
                    },
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    compassEnabled: false,
                    mapToolbarEnabled: false,
                  ),
                ),
                // Botão cancelar
                if (_phase != TripPhase.completed)
                  Positioned(
                    left: 16,
                    top: 16,
                    child: SafeArea(
                      child: GestureDetector(
                        onTap: _cancelTrip,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: KanawaColors.red,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Cancelar',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: KanawaColors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                // Pill distância até ao passageiro
                if (_phase == TripPhase.toPickup && pickup != null)
                  Positioned(
                    right: 16,
                    top: 16,
                    child: SafeArea(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: KanawaColors.success,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: KanawaColors.success.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.navigation_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${kmToPickup.toStringAsFixed(1)} km',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ═══════════════════════════════════════════════════
          // PAINEL INFERIOR
          // ═══════════════════════════════════════════════════
          Expanded(
            flex: 2,
            child: Container(
              decoration: const BoxDecoration(
                color: KanawaColors.bgCard,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Estado + distância
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _phaseColor().withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _phaseLabel(),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                              color: _phaseColor(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // ═══════════════════════════════════════════════
                    // HEADER — passageiro + telefone
                    // ═══════════════════════════════════════════════
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: KanawaColors.blueSoft,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              passengerName.isNotEmpty
                                  ? passengerName[0].toUpperCase()
                                  : 'P',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: KanawaColors.blue,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                passengerName,
                                style: GoogleFonts.inter(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: KanawaColors.textStrong,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                passengerPhone.isNotEmpty
                                    ? passengerPhone
                                    : 'Telefone não disponível',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: KanawaColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // ═══════════════════════════════════════════════
                    // BOTÕES LIGAR + CHAT
                    // ═══════════════════════════════════════════════
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: passengerPhone.isNotEmpty
                                ? _callPassenger
                                : null,
                            icon: const Icon(Icons.phone_rounded, size: 18),
                            label: Text(
                              'LIGAR',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: KanawaColors.success,
                              side: BorderSide(
                                color: KanawaColors.success.withOpacity(0.3),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _openChat,
                            icon: const Icon(Icons.chat_bubble_rounded,
                                size: 18),
                            label: Text(
                              'CHAT',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: KanawaColors.blue,
                              side: BorderSide(
                                color: KanawaColors.blue.withOpacity(0.3),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // ═══════════════════════════════════════════════
                    // BAIRRO DO PASSAGEIRO (CARD VERDE)
                    // ═══════════════════════════════════════════════
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            KanawaColors.success,
                            const Color(0xFF15803D),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: KanawaColors.success.withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
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
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.location_on_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'RECOLHA DO PASSAGEIRO',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            pickupAddress,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.route_rounded,
                                size: 14,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '${kmToPickup.toStringAsFixed(1)} km até ti',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withOpacity(0.85),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ═══════════════════════════════════════════════
                    // DESTINO (só em viagem)
                    // ═══════════════════════════════════════════════
                    if (_phase == TripPhase.inTrip)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: KanawaColors.bgSoft,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: KanawaColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: KanawaColors.blue,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.flag_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'DESTINO',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1,
                                      color: KanawaColors.blue,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    dropoffAddress,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: KanawaColors.textStrong,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 18),

                    // ═══════════════════════════════════════════════
                    // BOTÃO DE AÇÃO (Cheguei / Iniciar / Concluir)
                    // ═══════════════════════════════════════════════
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: _buildActionButton(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    switch (_phase) {
      case TripPhase.toPickup:
        return ElevatedButton(
          onPressed: _isProcessing ? null : _markArrived,
          style: _btnStyle(KanawaColors.blue),
          child: Text('CHEGUEI AO PASSAGEIRO', style: _btnText()),
        );
      case TripPhase.atPickup:
        return ElevatedButton(
          onPressed: _isProcessing ? null : _startTrip,
          style: _btnStyle(KanawaColors.success),
          child: _isProcessing
              ? const CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2.5)
              : Text('INICIAR VIAGEM', style: _btnText()),
        );
      case TripPhase.inTrip:
        return ElevatedButton(
          onPressed: _isProcessing ? null : _completeTrip,
          style: _btnStyle(KanawaColors.red),
          child: _isProcessing
              ? const CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2.5)
              : Text('CONCLUIR VIAGEM', style: _btnText()),
        );
      case TripPhase.completed:
        return ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: _btnStyle(KanawaColors.success),
          child: Text('VOLTAR AO MAPA', style: _btnText()),
        );
    }
  }

  ButtonStyle _btnStyle(Color color) => ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      );

  TextStyle _btnText() => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.5,
      );

  String _phaseLabel() {
    switch (_phase) {
      case TripPhase.toPickup:
        return 'A CAMINHO DO PASSAGEIRO';
      case TripPhase.atPickup:
        return 'NO PONTO DE RECOLHA';
      case TripPhase.inTrip:
        return 'EM VIAGEM';
      case TripPhase.completed:
        return 'CONCLUÍDA';
    }
  }

  Color _phaseColor() {
    switch (_phase) {
      case TripPhase.toPickup:
        return KanawaColors.blue;
      case TripPhase.atPickup:
        return KanawaColors.warning;
      case TripPhase.inTrip:
        return KanawaColors.red;
      case TripPhase.completed:
        return KanawaColors.success;
    }
  }
}

// ═══════════════════════════════════════════════════════════
// DIALOG DE CANCELAMENTO
// ═══════════════════════════════════════════════════════════
class _CancelDialog extends StatefulWidget {
  @override
  State<_CancelDialog> createState() => _CancelDialogState();
}

class _CancelDialogState extends State<_CancelDialog> {
  String _selectedReason = 'Passageiro não apareceu';

  final _reasons = [
    'Passageiro não apareceu',
    'Localização errada',
    'Emergência pessoal',
    'Problema no veículo',
    'Outro motivo',
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: KanawaColors.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Cancelar viagem?',
        style: GoogleFonts.inter(fontWeight: FontWeight.w900),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Escolhe o motivo:',
            style:
                GoogleFonts.inter(fontSize: 13, color: KanawaColors.textMuted),
          ),
          const SizedBox(height: 12),
          ..._reasons.map((r) => RadioListTile<String>(
                title: Text(r, style: GoogleFonts.inter(fontSize: 13)),
                value: r,
                groupValue: _selectedReason,
                activeColor: KanawaColors.red,
                onChanged: (v) => setState(() => _selectedReason = v!),
                contentPadding: EdgeInsets.zero,
                dense: true,
              )),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text('Voltar',
              style: GoogleFonts.inter(color: KanawaColors.textMuted)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_selectedReason),
          child: Text(
            'Confirmar',
            style: GoogleFonts.inter(
              color: KanawaColors.red,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}