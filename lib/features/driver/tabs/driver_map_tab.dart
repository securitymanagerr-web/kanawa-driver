// KANAWA - Aba do Mapa (Motorista)
// v3.1 — Múltiplas viagens + Bottom Sheet + Navegação + Notificações

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/kanawa_theme.dart';
import '../driver_trip_detail_screen.dart';
import '../notifications_screen.dart';
import '../widgets/notification_bell.dart';
import '../widgets/online_toggle.dart';

class DriverMapTab extends StatefulWidget {
  final bool isOnline;
  final LatLng currentLocation;
  final Function(bool) onStatusChanged;
  final Function(LatLng) onLocationChanged;
  final Map<String, dynamic>? driverProfile;
  final Map<String, dynamic>? vehicle;

  const DriverMapTab({
    super.key,
    required this.isOnline,
    required this.currentLocation,
    required this.onStatusChanged,
    required this.onLocationChanged,
    this.driverProfile,
    this.vehicle,
  });

  @override
  State<DriverMapTab> createState() => _DriverMapTabState();
}

class _DriverMapTabState extends State<DriverMapTab> {
  GoogleMapController? _mapController;
  LatLng _location = const LatLng(-9.6608, 20.3917);
  bool _locationReady = false;
  bool _isTogglingOnline = false;

  List<Map<String, dynamic>> _pendingTrips = [];
  Timer? _pollTimer;
  Timer? _locationTimer;

  @override
  void initState() {
    super.initState();
    _location = widget.currentLocation;
    _initializeLocation();
    if (widget.isOnline) _startTimers();
  }

  @override
  void didUpdateWidget(covariant DriverMapTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isOnline && widget.isOnline) {
      _startTimers();
    }
    if (oldWidget.isOnline && !widget.isOnline) {
      _stopTimers();
      setState(() => _pendingTrips = []);
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _locationTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════
  // LOCALIZAÇÃO
  // ═══════════════════════════════════════════════════════
  Future<void> _initializeLocation() async {
    if (kIsWeb) {
      setState(() => _locationReady = true);
      return;
    }

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _locationReady = true);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _locationReady = true);
        return;
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
      }

      if (!mounted || position == null) {
        setState(() => _locationReady = true);
        return;
      }

      setState(() {
        _location = LatLng(position!.latitude, position.longitude);
        _locationReady = true;
      });
      widget.onLocationChanged(_location);

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_location, 16),
      );
    } catch (e) {
      debugPrint('❌ Erro GPS: $e');
      if (mounted) setState(() => _locationReady = true);
    }
  }

  // ═══════════════════════════════════════════════════════
  // ONLINE / OFFLINE
  // ═══════════════════════════════════════════════════════
  Future<void> _toggleOnline() async {
    if (_isTogglingOnline) return;
    setState(() => _isTogglingOnline = true);

    if (!widget.isOnline) {
      final ok = await _goOnline();
      if (!mounted) return;
      if (ok) {
        widget.onStatusChanged(true);
        _startTimers();
        _showSnack('Estás online. A procurar viagens...');
      } else {
        _showSnack('Não foi possível ficar online', isError: true);
      }
    } else {
      widget.onStatusChanged(false);
      _stopTimers();
      setState(() => _pendingTrips = []);
      _showSnack('Estás offline');
    }
    setState(() => _isTogglingOnline = false);
  }

  Future<bool> _goOnline() async {
    try {
      final response = await ApiClient.post(
        '/auth/location/',
        body: {
          'latitude': _location.latitude.toStringAsFixed(7),
          'longitude': _location.longitude.toStringAsFixed(7),
        },
        authenticated: true,
      );
      return response.success;
    } catch (e) {
      debugPrint('❌ Erro: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════
  // TIMERS
  // ═══════════════════════════════════════════════════════
  void _startTimers() {
    _stopTimers();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _checkPendingTrips(),
    );
    _locationTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _updateLocation(),
    );
    _checkPendingTrips();
  }

  void _stopTimers() {
    _pollTimer?.cancel();
    _locationTimer?.cancel();
    _pollTimer = null;
    _locationTimer = null;
  }

  Future<void> _updateLocation() async {
    if (!widget.isOnline) return;
    try {
      await _initializeLocation();
      await ApiClient.post(
        '/auth/location/',
        body: {
          'latitude': _location.latitude.toStringAsFixed(7),
          'longitude': _location.longitude.toStringAsFixed(7),
        },
        authenticated: true,
      );
    } catch (e) {
      debugPrint('⚠️ Erro: $e');
    }
  }

  // ═══════════════════════════════════════════════════════
  // POLLING DE VIAGENS
  // ═══════════════════════════════════════════════════════
  Future<void> _checkPendingTrips() async {
    if (!widget.isOnline) return;

    try {
      final response = await ApiClient.get(
        '/trips/pending/',
        authenticated: true,
      );

      if (!mounted || !widget.isOnline) return;

      List<dynamic>? list;
      if (response.data is List) {
        list = response.data as List;
      } else if (response.data is Map && response.data['results'] is List) {
        list = response.data['results'] as List;
      }

      if (list != null) {
        final trips = list
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList();
        debugPrint('📥 ${trips.length} viagens pendentes');
        setState(() => _pendingTrips = trips);
      }
    } catch (e) {
      debugPrint('⚠️ Erro: $e');
    }
  }

  void _openTripDetail(Map<String, dynamic> trip) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => DriverTripDetailScreen(
              trip: trip,
              driverLocation: _location,
              onAccepted: () {
                _stopTimers();
                setState(() => _pendingTrips = []);
              },
            ),
          ),
        )
        .then((_) {
      if (widget.isOnline) _startTimers();
    });
  }

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const NotificationsScreen(),
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter(fontSize: 13)),
        backgroundColor: isError ? KanawaColors.danger : KanawaColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // MARCADORES
  // ═══════════════════════════════════════════════════════
  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};

    // Motorista
    if (_locationReady) {
      markers.add(
        Marker(
          markerId: const MarkerId('me'),
          position: _location,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      );
    }

    // Viagens pendentes (pickup de cada)
    for (int i = 0; i < _pendingTrips.length; i++) {
      final trip = _pendingTrips[i];
      final lat = double.tryParse(trip['pickup_latitude']?.toString() ?? '');
      final lng = double.tryParse(trip['pickup_longitude']?.toString() ?? '');
      if (lat != null && lng != null) {
        markers.add(
          Marker(
            markerId: MarkerId('trip_$i'),
            position: LatLng(lat, lng),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
            infoWindow: InfoWindow(
              title: trip['passenger']?['full_name']?.toString() ??
                  'Passageiro',
              snippet: trip['dropoff_address']?.toString() ?? '',
            ),
          ),
        );
      }
    }

    return markers;
  }

  // ═══════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KanawaColors.bgApp,
      body: Stack(
        children: [
          // Mapa
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _location,
                zoom: 15,
              ),
              onMapCreated: (c) => _mapController = c,
              myLocationEnabled: !kIsWeb,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: false,
              mapToolbarEnabled: false,
              markers: _buildMarkers(),
            ),
          ),

          // Header (Online/Offline + Notificações)
          Positioned(
            left: 16,
            right: 16,
            top: 16,
            child: SafeArea(child: _buildHeader()),
          ),

          // Lista de viagens (se houver)
          if (_pendingTrips.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 100,
              child: SafeArea(child: _buildTripList()),
            ),

          // Botão Online/Offline
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: SafeArea(
              child: OnlineToggle(
                isOnline: widget.isOnline,
                isLoading: _isTogglingOnline,
                onToggle: _toggleOnline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════
  Widget _buildHeader() {
    return Row(
      children: [
        // Pill Online/Offline + contador de viagens
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: KanawaColors.bgCard,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: widget.isOnline
                      ? KanawaColors.success
                      : KanawaColors.textMuted,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                widget.isOnline ? 'Online' : 'Offline',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: KanawaColors.textStrong,
                ),
              ),
              if (_pendingTrips.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: KanawaColors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_pendingTrips.length}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const Spacer(),
        // Sino de notificações
        NotificationBell(onTap: _openNotifications),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  // LISTA DE VIAGENS
  // ═══════════════════════════════════════════════════════
  Widget _buildTripList() {
    return Container(
      height: 200,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _pendingTrips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final trip = _pendingTrips[index];
          return _buildTripCard(trip);
        },
      ),
    );
  }

  Widget _buildTripCard(Map<String, dynamic> trip) {
    final passengerName = trip['passenger'] is Map
        ? (trip['passenger']['full_name']?.toString() ?? 'Passageiro')
        : 'Passageiro';
    final dropoff = trip['dropoff_address']?.toString() ?? '—';
    final pickup = trip['pickup_address']?.toString() ?? '—';
    final price = trip['price'];
    final priceKz = price is num
        ? price.round()
        : (double.tryParse(price?.toString() ?? '0')?.round() ?? 0);
    final distance = trip['distance_km']?.toString() ?? '0';

    return GestureDetector(
      onTap: () => _openTripDetail(trip),
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: KanawaColors.bgCard,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: KanawaColors.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'NOVA VIAGEM',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: KanawaColors.success,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '$priceKz Kz',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: KanawaColors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.person_rounded,
                  size: 16,
                  color: KanawaColors.textMuted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    passengerName,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: KanawaColors.textStrong,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  size: 14,
                  color: KanawaColors.success,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    pickup,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: KanawaColors.textMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.flag_rounded,
                  size: 14,
                  color: KanawaColors.red,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    dropoff,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: KanawaColors.textMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.route_rounded,
                  size: 13,
                  color: KanawaColors.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  '$distance km',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: KanawaColors.textMuted,
                  ),
                ),
                const Spacer(),
                Text(
                  'Ver detalhes →',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: KanawaColors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}