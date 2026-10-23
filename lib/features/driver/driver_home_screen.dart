// KANAWA - Home do Motorista
// v2.0 — UI Completa com Bottom Navigation (Mapa, Ganhos, Histórico, Perfil)

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/api/api_client.dart';
import '../../core/theme/kanawa_theme.dart';
import '../auth/login_screen.dart';
import 'tabs/driver_map_tab.dart';
import 'tabs/driver_earnings_tab.dart';
import 'tabs/driver_history_tab.dart';
import 'tabs/driver_profile_tab.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  int _currentIndex = 0; // 0=Mapa, 1=Ganhos, 2=Histórico, 3=Perfil

  // Estado global (partilhado entre abas)
  bool _isOnline = false;
  LatLng _currentLocation = const LatLng(-9.6608, 20.3917);
  
  // Dados do motorista e veículo
  Map<String, dynamic>? _driverProfile;
  Map<String, dynamic>? _vehicle;

  @override
  void initState() {
    super.initState();
    _loadDriverData();
  }

  Future<void> _loadDriverData() async {
    try {
      final profileRes = await ApiClient.get('/auth/me/');
      if (profileRes.success) {
        _driverProfile = profileRes.data;
      }
      
      final vehicleRes = await ApiClient.get('/fleet/vehicles/my/');
      if (vehicleRes.success) {
        _vehicle = vehicleRes.data;
      }
      
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Erro ao carregar dados do motorista: $e');
    }
  }

  void _setOnlineStatus(bool status) {
    setState(() {
      _isOnline = status;
    });
  }

  void _updateLocation(LatLng loc) {
    _currentLocation = loc;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KanawaColors.bgApp,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          DriverMapTab(
            isOnline: _isOnline,
            currentLocation: _currentLocation,
            onStatusChanged: _setOnlineStatus,
            onLocationChanged: _updateLocation,
            driverProfile: _driverProfile,
            vehicle: _vehicle,
          ),
          const DriverEarningsTab(),
          const DriverHistoryTab(),
          DriverProfileTab(
            driverProfile: _driverProfile,
            vehicle: _vehicle,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: KanawaColors.bgCard,
        indicatorColor: KanawaColors.blue.withOpacity(0.1),
        elevation: 8,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map_rounded, color: KanawaColors.blue),
            label: 'Mapa',
          ),
          NavigationDestination(
            icon: Icon(Icons.wallet_outlined),
            selectedIcon: Icon(Icons.wallet_rounded, color: KanawaColors.blue),
            label: 'Ganhos',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded, color: KanawaColors.blue),
            label: 'Histórico',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded, color: KanawaColors.blue),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}