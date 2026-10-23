// KANAWA - Alterar Password (Motorista)
// v1.0 — POST /auth/change-password/

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/api/api_client.dart';
import '../../core/theme/kanawa_theme.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isSaving = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool _validatePassword(String password) {
    if (password.length < 8) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    if (!password.contains(RegExp(r'[a-z]'))) return false;
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    return true;
  }

  Future<void> _save() async {
    if (_isSaving) return;

    if (_currentController.text.isEmpty) {
      _showSnack('Introduz a password atual', isError: true);
      return;
    }
    if (!_validatePassword(_newController.text)) {
      _showSnack(
        'Password fraca. Usa 8+ caracteres com maiúsculas, minúsculas e números.',
        isError: true,
      );
      return;
    }
    if (_newController.text != _confirmController.text) {
      _showSnack('As passwords não coincidem', isError: true);
      return;
    }
    if (_currentController.text == _newController.text) {
      _showSnack('A nova password deve ser diferente da atual', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final body = {
        'current_password': _currentController.text,
        'new_password': _newController.text,
        'new_password_confirm': _confirmController.text,
      };

      final response = await ApiClient.post(
        '/auth/change-password/',
        body: body,
        authenticated: true,
      );

      if (!mounted) return;

      if (response.success) {
        _showSnack('Password alterada com sucesso!');
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) Navigator.of(context).pop();
        });
      } else {
        setState(() => _isSaving = false);
        _showSnack(response.errorMessage, isError: true);
      }
    } catch (e) {
      debugPrint('❌ Erro: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        _showSnack('Erro ao guardar', isError: true);
      }
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter(fontSize: 13)),
        backgroundColor: isError ? KanawaColors.danger : KanawaColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KanawaColors.bgApp,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
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
                  Text(
                    'Alterar password',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: KanawaColors.textStrong,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Protege a tua conta',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: KanawaColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _fieldLabel('PASSWORD ATUAL'),
                    const SizedBox(height: 8),
                    _passwordField(
                      controller: _currentController,
                      obscure: _obscureCurrent,
                      onToggle: () => setState(
                        () => _obscureCurrent = !_obscureCurrent,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _fieldLabel('NOVA PASSWORD'),
                    const SizedBox(height: 8),
                    _passwordField(
                      controller: _newController,
                      obscure: _obscureNew,
                      onToggle: () => setState(() => _obscureNew = !_obscureNew),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '8+ caracteres, com maiúscula, minúscula e número.',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: KanawaColors.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _fieldLabel('CONFIRMAR NOVA PASSWORD'),
                    const SizedBox(height: 8),
                    _passwordField(
                      controller: _confirmController,
                      obscure: _obscureConfirm,
                      onToggle: () => setState(
                        () => _obscureConfirm = !_obscureConfirm,
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: KanawaColors.red,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: KanawaColors.border,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                'ALTERAR PASSWORD',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
          color: KanawaColors.textMuted,
        ),
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: KanawaColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: KanawaColors.border),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.all(14),
            child: Icon(
              Icons.lock_outline_rounded,
              color: KanawaColors.textMuted,
              size: 20,
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscure,
              enabled: !_isSaving,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: KanawaColors.textStrong,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off : Icons.visibility,
              color: KanawaColors.textMuted,
              size: 20,
            ),
            onPressed: onToggle,
          ),
        ],
      ),
    );
  }
}