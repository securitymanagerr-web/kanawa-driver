// KANAWA - Detalhe da viagem pendente (Motorista)
// v2.0 — Bairro + município + telefone do passageiro + Ligar + Chat

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_client.dart';
import '../../core/theme/kanawa_theme.dart';
import 'chat_screen.dart';
import 'driver_navigation_screen.dart';

class DriverTripDetailScreen extends StatefulWidget {
  final Map<String, dynamic> trip;
  final LatLng driverLocation;
  final VoidCallback onAccepted;

  const DriverTripDetailScreen({
    super.key,
    required this.trip,
    required this.driverLocation,
    required this.onAccepted,
  });

  @override
  State<DriverTripDetailScreen> createState() => _DriverTripDetailScreenState();
}

class _DriverTripDetailScreenState extends State<DriverTripDetailScreen> {
  GoogleMapController? _mapController;
  bool _isAccepting = false;

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
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

  int _etaMinutes(double km) {
    return (km / 28 * 60).ceil().clamp(1, 999);
  }

  // Extrai dados do passageiro
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

  // ═══════════════════════════════════════════════════════
  // LIGAR AO PASSAGEIRO
  // ═══════════════════════════════════════════════════════
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
      if (!ok && mounted) _showSnack('Não foi possível abrir o discador', isError: true);
    } catch (e) {
      if (mounted) _showSnack('Erro ao ligar', isError: true);
    }
  }

  // ═══════════════════════════════════════════════════════
  // ABRIR CHAT
  // ═══════════════════════════════════════════════════════
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

  Future<void> _acceptTrip() async {
    if (_isAccepting) return;
    setState(() => _isAccepting = true);

    try {
      final response = await ApiClient.post(
        '/trips/${widget.trip['id']}/accept/',
        body: {},
        authenticated: true,
      );

      if (!mounted) return;

      if (response.success) {
        widget.onAccepted();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => DriverNavigationScreen(trip: widget.trip),
          ),
        );
      } else {
        setState(() => _isAccepting = false);
        _showSnack(response.errorMessage, isError: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAccepting = false);
        _showSnack('Erro ao aceitar', isError: true);
      }
    }
  }

  void _rejectTrip() {
    widget.onAccepted();
    Navigator.of(context).pop();
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

    final toPickupKm =
        pickup != null ? _distanceKm(widget.driverLocation, pickup) : 0.0;
    final tripKm =
        pickup != null && dropoff != null ? _distanceKm(pickup, dropoff) : 0.0;
    final etaToPickup = _etaMinutes(toPickupKm);
    final etaTrip = _etaMinutes(tripKm);

    final passengerName = _getPassengerName();
    final passengerPhone = _getPassengerPhone();
    final price = widget.trip['price'];
    final priceKz = price is num
        ? price.round()
        : (double.tryParse(price?.toString() ?? '0')?.round() ?? 0);

    final bairro = _getPickupBairro();

    return Scaffold(
      backgroundColor: KanawaColors.bgApp,
      body: Column(
        children: [
          // MAPA
          SizedBox(
            height: 280,
            child: Stack(
              children: [
                Positioned.fill(
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: pickup ?? widget.driverLocation,
                      zoom: 14,
                    ),
                    onMapCreated: (c) {
                      _mapController = c;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (pickup != null && dropoff != null) {
                          final bounds = LatLngBounds(
                            southwest: LatLng(
                              math.min(
                                  math.min(widget.driverLocation.latitude,
                                      pickup.latitude),
                                  dropoff.latitude),
                              math.min(
                                  math.min(widget.driverLocation.longitude,
                                      pickup.longitude),
                                  dropoff.longitude),
                            ),
                            northeast: LatLng(
                              math.max(
                                  math.max(widget.driverLocation.latitude,
                                      pickup.latitude),
                                  dropoff.latitude),
                              math.max(
                                  math.max(widget.driverLocation.longitude,
                                      pickup.longitude),
                                  dropoff.longitude),
                            ),
                          );
                          _mapController?.animateCamera(
                            CameraUpdate.newLatLngBounds(bounds, 80),
                          );
                        }
                      });
                    },
                    markers: {
                      Marker(
                        markerId: const MarkerId('driver'),
                        position: widget.driverLocation,
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueAzure,
                        ),
                      ),
                      if (pickup != null)
                        Marker(
                          markerId: const MarkerId('pickup'),
                          position: pickup,
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueGreen,
                          ),
                        ),
                      if (dropoff != null)
                        Marker(
                          markerId: const MarkerId('dropoff'),
                          position: dropoff,
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueRed,
                          ),
                        ),
                    },
                    polylines: {
                      if (pickup != null && dropoff != null)
                        Polyline(
                          polylineId: const PolylineId('trip_route'),
                          points: [pickup, dropoff],
                          color: KanawaColors.blue,
                          width: 4,
                        ),
                      if (pickup != null)
                        Polyline(
                          polylineId: const PolylineId('to_pickup_route'),
                          points: [widget.driverLocation, pickup],
                          color: KanawaColors.success,
                          width: 4,
                          patterns: [
                            PatternItem.dash(10),
                            PatternItem.gap(6),
                          ],
                        ),
                    },
                    myLocationEnabled: false,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    compassEnabled: false,
                    mapToolbarEnabled: false,
                  ),
                ),
                Positioned(
                  left: 16,
                  top: 16,
                  child: SafeArea(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.arrow_back_rounded, size: 20),
                      ),
                    ),
                  ),
                ),
                // Pill de distância
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
                            '${toPickupKm.toStringAsFixed(1)} km',
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

          // PAINEL INFERIOR
          Expanded(
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
                    // HEADER — passageiro + telefone + preço
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
                        Text(
                          '$priceKz Kz',
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: KanawaColors.red,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // BOTÕES RÁPIDOS — LIGAR + CHAT
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
                            icon: const Icon(Icons.chat_bubble_rounded, size: 18),
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

                    const SizedBox(height: 20),

                    // ═══════════════════════════════════════════════════
                    // BAIRRO DO PASSAGEIRO (DESTAQUE)
                    // ═══════════════════════════════════════════════════
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
                            bairro,
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
                                '${toPickupKm.toStringAsFixed(1)} km · ~$etaToPickup min até ti',
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

                    // DESTINO
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: KanawaColors.bgSoft,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: KanawaColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
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
                                      'DESTINO DA VIAGEM',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1,
                                        color: KanawaColors.blue,
                                      ),
                                    ),
                                    Text(
                                      '${tripKm.toStringAsFixed(1)} km · ~$etaTrip min',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: KanawaColors.textStrong,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.flag_rounded,
                                size: 14,
                                color: KanawaColors.red,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.trip['dropoff_address']?.toString() ??
                                      'Destino',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: KanawaColors.textStrong,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // BOTÕES ACEITAR / REJEITAR
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: SizedBox(
                            height: 56,
                            child: OutlinedButton(
                              onPressed: _isAccepting ? null : _rejectTrip,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: KanawaColors.border,
                                ),
                                foregroundColor: KanawaColors.textMuted,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                'REJEITAR',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isAccepting ? null : _acceptTrip,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: KanawaColors.success,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: KanawaColors.border,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: _isAccepting
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'ACEITAR',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ],
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
}