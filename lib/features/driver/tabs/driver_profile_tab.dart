// KANAWA - Aba de Perfil (Motorista)
// v2.0 — Perfil real + ganhos totais + veículo + alterar password + sobre

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/kanawa_theme.dart';
import '../../auth/login_screen.dart';
import '../about_driver_screen.dart';
import '../change_password_screen.dart';
import '../edit_driver_profile_screen.dart';

class DriverProfileTab extends StatefulWidget {
  final Map<String, dynamic>? driverProfile;
  final Map<String, dynamic>? vehicle;

  const DriverProfileTab({super.key, this.driverProfile, this.vehicle});

  @override
  State<DriverProfileTab> createState() => _DriverProfileTabState();
}

class _DriverProfileTabState extends State<DriverProfileTab> {
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _vehicle;
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _profile = widget.driverProfile;
    _vehicle = widget.vehicle;
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);

    try {
      final meRes = await ApiClient.get('/auth/me/', authenticated: true);
      final vehRes = await ApiClient.get(
        '/fleet/vehicles/my/',
        authenticated: true,
      );
      final statsRes = await ApiClient.get(
        '/trips/stats/',
        authenticated: true,
      );

      if (!mounted) return;

      if (meRes.success && meRes.data is Map) {
        _profile = Map<String, dynamic>.from(meRes.data as Map);
      }
      if (vehRes.success && vehRes.data is Map) {
        _vehicle = Map<String, dynamic>.from(vehRes.data as Map);
      }
      if (statsRes.success && statsRes.data is Map) {
        _stats = Map<String, dynamic>.from(statsRes.data as Map);
      }
      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('❌ Erro perfil: $e');
      if (mounted) setState(() => _isLoading = false);
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

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: KanawaColors.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Terminar sessão?',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            color: KanawaColors.textStrong,
          ),
        ),
        content: Text(
          'Vais precisar de fazer login de novo.',
          style: GoogleFonts.inter(
            color: KanawaColors.textMuted,
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.inter(
                color: KanawaColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Sair',
              style: GoogleFonts.inter(
                color: KanawaColors.red,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await ApiClient.clearTokens();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _openEditProfile() async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditDriverProfileScreen(profile: _profile ?? {}),
      ),
    );
    if (updated == true) _loadAll();
  }

  void _openChangePassword() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ChangePasswordScreen(),
      ),
    );
  }

  void _openAbout() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AboutDriverScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: KanawaColors.bgApp,
        body: Center(
          child: CircularProgressIndicator(color: KanawaColors.red),
        ),
      );
    }

    final name = _profile?['full_name']?.toString() ?? 'Motorista';
    final phone = _profile?['phone']?.toString() ?? '—';
    final email = _profile?['email']?.toString() ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'M';

    // Ganhos totais (all-time) — vamos usar os dados do mês como proxy
    // Para ter o total all-time, precisaríamos de um endpoint dedicado
    // Por enquanto, calculamos a partir do "month"
    final month = _stats?['month'] as Map? ?? {};
    final monthTotal = _toDouble(month['total']);
    final monthCount = _toInt(month['count']);

    return Scaffold(
      backgroundColor: KanawaColors.bgApp,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadAll,
          color: KanawaColors.red,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ═══ HEADER ═══
                Row(
                  children: [
                    Text(
                      'Perfil',
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: KanawaColors.textStrong,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _openEditProfile,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: KanawaColors.bgCard,
                          shape: BoxShape.circle,
                          border: Border.all(color: KanawaColors.border),
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          color: KanawaColors.textStrong,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ═══ CARD DO MOTORISTA ═══
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [KanawaColors.driver, Color(0xFF134E4A)],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: KanawaColors.driver.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.5),
                            width: 3,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            initial,
                            style: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: KanawaColors.driver,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.phone_rounded,
                                  color: Colors.white70,
                                  size: 13,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  phone,
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                            if (email.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.email_rounded,
                                    color: Colors.white70,
                                    size: 13,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      email,
                                      style: GoogleFonts.inter(
                                        fontSize: 11.5,
                                        color: Colors.white.withOpacity(0.85),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ═══ CARD GANHOS TOTAIS ═══
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [KanawaColors.success, Color(0xFF15803D)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: KanawaColors.success.withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.wallet_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'GANHOS ACUMULADOS',
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
                        _formatKz(monthTotal),
                        style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            '$monthCount viagens · últimos 30 dias',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ═══ SECÇÃO VEÍCULO ═══
                if (_vehicle != null) ...[
                  _sectionTitle('VEÍCULO'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: KanawaColors.bgCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: KanawaColors.border),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: KanawaColors.driver.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                _vehicle?['category'] == 'MOTA'
                                    ? Icons.two_wheeler_rounded
                                    : Icons.directions_car_rounded,
                                color: KanawaColors.driver,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_vehicle?['brand'] ?? ''} ${_vehicle?['model'] ?? ''}'
                                        .trim(),
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: KanawaColors.textStrong,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _vehicle?['plate']?.toString() ?? '—',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: KanawaColors.textMuted,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: (_vehicle?['is_approved'] == true
                                        ? KanawaColors.success
                                        : KanawaColors.warning)
                                    .withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _vehicle?['is_approved'] == true
                                    ? 'Aprovado'
                                    : 'Pendente',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: _vehicle?['is_approved'] == true
                                      ? KanawaColors.success
                                      : KanawaColors.warning,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Divider(color: KanawaColors.border, height: 1),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _vehicleStat(
                              'Categoria',
                              _vehicle?['category']?.toString() ?? '—',
                            ),
                            _vehicleStat(
                              'Estado',
                              _vehicle?['status']?.toString() ?? '—',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // ═══ SECÇÃO CONTA ═══
                _sectionTitle('CONTA'),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: KanawaColors.bgCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: KanawaColors.border),
                  ),
                  child: Column(
                    children: [
                      _menuItem(
                        icon: Icons.person_outline_rounded,
                        label: 'Editar perfil',
                        onTap: _openEditProfile,
                      ),
                      Divider(
                        color: KanawaColors.border,
                        height: 1,
                        indent: 56,
                      ),
                      _menuItem(
                        icon: Icons.lock_outline_rounded,
                        label: 'Alterar password',
                        onTap: _openChangePassword,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ═══ SECÇÃO SOBRE ═══
                _sectionTitle('SOBRE'),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: KanawaColors.bgCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: KanawaColors.border),
                  ),
                  child: _menuItem(
                    icon: Icons.info_outline_rounded,
                    label: 'Sobre o KANAWA',
                    trailing: 'v1.0.0',
                    onTap: _openAbout,
                  ),
                ),

                const SizedBox(height: 20),

                // ═══ LOGOUT ═══
                GestureDetector(
                  onTap: _handleLogout,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: KanawaColors.bgCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: KanawaColors.red.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.logout_rounded,
                          color: KanawaColors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Terminar sessão',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: KanawaColors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
          color: KanawaColors.textMuted,
        ),
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String label,
    String? trailing,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: KanawaColors.bgSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: KanawaColors.textMuted, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: KanawaColors.textStrong,
                ),
              ),
            ),
            if (trailing != null) ...[
              Text(
                trailing,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: KanawaColors.textMuted,
                ),
              ),
              const SizedBox(width: 6),
            ],
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: KanawaColors.textSubtle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _vehicleStat(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: KanawaColors.textSubtle,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: KanawaColors.textStrong,
            ),
          ),
        ],
      ),
    );
  }
}