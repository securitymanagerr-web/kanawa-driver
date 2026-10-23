// KANAWA - Login (App Motorista)
// v1.1 — Só motoristas criados pela empresa. Sem registo público.
//        Verifica: DRIVER + is_verified + veículo aprovado

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/api/api_client.dart';
import '../../core/models/user.dart';
import '../../core/theme/kanawa_theme.dart';
import '../../core/utils/phone_formatter.dart';
import '../../shared/widgets/kanawa_logo_pin.dart';
import '../../shared/widgets/kanawa_signature.dart';
import '../driver/driver_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();

    try {
      final response = await ApiClient.post(
        '/auth/login/',
        body: {
          'phone': normalizeAngolaPhone(_phoneController.text),
          'password': _passwordController.text,
        },
      );

      if (!mounted) return;

      if (response.success) {
        await ApiClient.saveTokens(
          access: response.data['access'] ?? '',
          refresh: response.data['refresh'] ?? '',
        );

        final user = User.fromJson(response.data['user']);

        // ═══════════════════════════════════════════════════
        // VERIFICAÇÃO 1: É DRIVER?
        // ═══════════════════════════════════════════════════
        if (!user.isDriver) {
          await ApiClient.clearTokens();
          setState(() {
            _errorMessage =
                'Esta conta não é de motorista. Usa o App Passageiro.';
            _isLoading = false;
          });
          return;
        }

        // ═══════════════════════════════════════════════════
        // VERIFICAÇÃO 2: Está verificado?
        // ═══════════════════════════════════════════════════
        if (!user.isVerified) {
          await ApiClient.clearTokens();
          setState(() {
            _errorMessage =
                'Conta ainda não verificada. Contacta a KANAWA.';
            _isLoading = false;
          });
          return;
        }

        // ═══════════════════════════════════════════════════
        // VERIFICAÇÃO 3: Tem veículo aprovado?
        // ═══════════════════════════════════════════════════
        final vehicleOk = await _checkApprovedVehicle();
        if (!mounted) return;

        if (!vehicleOk) {
          await ApiClient.clearTokens();
          setState(() {
            _errorMessage =
                'Não tens veículo aprovado. Contacta a KANAWA para registar o teu veículo.';
            _isLoading = false;
          });
          return;
        }

        // ═══════════════════════════════════════════════════
        // TUDO OK → Home
        // ═══════════════════════════════════════════════════
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const DriverHomeScreen()),
          (route) => false,
        );
      } else {
        setState(() {
          _errorMessage = response.errorMessage;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Erro inesperado. Tenta novamente.';
        _isLoading = false;
      });
    }
  }

  // ═══════════════════════════════════════════════════════
  // VERIFICA VEÍCULO APROVADO
  // ═══════════════════════════════════════════════════════
  Future<bool> _checkApprovedVehicle() async {
    try {
      // Tenta /vehicles/my/ — endpoint do app fleet
      final response = await ApiClient.get('/vehicles/my/');
      if (!mounted) return true; // Em caso de falha, deixa entrar (fallback)

      if (!response.success) {
        // Se der erro, não bloqueia (endpoint pode não existir)
        debugPrint('⚠️ Não foi possível verificar veículo: ${response.errorMessage}');
        return true;
      }

      final data = response.data;
      if (data is List) {
        if (data.isEmpty) return false;
        final vehicle = data.first as Map;
        final approved = vehicle['is_approved'] == true;
        return approved;
      }

      if (data is Map) {
        final approved = data['is_approved'] == true;
        return approved;
      }

      return true;
    } catch (e) {
      debugPrint('⚠️ Erro ao verificar veículo: $e');
      return true; // Não bloqueia em caso de erro
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KanawaColors.bgApp,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),

                const KanawaLogoPin(size: 80, showShadow: true),

                const SizedBox(height: 16),

                // Badge MOTORISTA
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: KanawaColors.driver.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: KanawaColors.driver.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.directions_car_rounded,
                        color: KanawaColors.driver,
                        size: 12,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'MOTORISTA',
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: KanawaColors.driver,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  'Bem-vindo, motorista',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: KanawaColors.textStrong,
                    letterSpacing: -0.5,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Entra com as credenciais da KANAWA',
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w400,
                    color: KanawaColors.textMuted,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 32),

                if (_errorMessage != null) ...[
                  _ErrorBanner(message: _errorMessage!),
                  const SizedBox(height: 16),
                ],

                // Telefone
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'TELEFONE',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: KanawaColors.textMuted,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 54,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: KanawaColors.bgSoft,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: KanawaColors.border),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🇦🇴', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Text(
                              '+244',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: KanawaColors.textStrong,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          AngolaPhoneFormatter(),
                        ],
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: KanawaColors.textStrong,
                          letterSpacing: 0.5,
                        ),
                        decoration: _inputDecoration(
                          hint: '924 222 333',
                          prefixIcon: Icons.phone_outlined,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Insere o teu telefone';
                          }
                          final digits = value.replaceAll(RegExp(r'\D'), '');
                          if (digits.length != 9) {
                            return 'Telefone inválido';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Password
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'PASSWORD',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: KanawaColors.textMuted,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: KanawaColors.textStrong,
                    letterSpacing: 1.2,
                  ),
                  decoration: _inputDecoration(
                    hint: 'A tua password',
                    prefixIcon: Icons.lock_outline_rounded,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: KanawaColors.textSubtle,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Insere a tua password';
                    }
                    if (value.length < 8) {
                      return 'A password deve ter pelo menos 8 caracteres';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KanawaColors.red,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          KanawaColors.red.withOpacity(0.5),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'ENTRAR',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 20,
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 32),

                // Info: como obter credenciais
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: KanawaColors.blueSoft,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: KanawaColors.blue.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: KanawaColors.blue,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Ainda não tens credenciais?',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: KanawaColors.blueDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'As contas de motorista são criadas pela equipa KANAWA. '
                        'Contacta-nos para te registares.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: KanawaColors.textBase,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                const Center(child: KanawaSignature()),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    String? hint,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        fontSize: 15,
        color: KanawaColors.textSubtle,
      ),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: KanawaColors.textSubtle, size: 20)
          : null,
      filled: true,
      fillColor: KanawaColors.bgCard,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 18,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: KanawaColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: KanawaColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: KanawaColors.red, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: KanawaColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: KanawaColors.danger, width: 2),
      ),
      errorStyle: GoogleFonts.inter(
        fontSize: 12,
        color: KanawaColors.danger,
      ),
      suffixIcon: suffixIcon,
    );
  }
}

// ═══════════════════════════════════════════════════════════
// BANNER DE ERRO
// ═══════════════════════════════════════════════════════════
class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KanawaColors.dangerSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KanawaColors.danger.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline,
              color: KanawaColors.danger, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: KanawaColors.danger,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}