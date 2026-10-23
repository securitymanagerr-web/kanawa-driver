// KANAWA - Editar Perfil (Motorista)
// v1.0 — Nome, sobrenome e email via PATCH /auth/me/

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/api/api_client.dart';
import '../../core/theme/kanawa_theme.dart';

class EditDriverProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profile;

  const EditDriverProfileScreen({super.key, required this.profile});

  @override
  State<EditDriverProfileScreen> createState() =>
      _EditDriverProfileScreenState();
}

class _EditDriverProfileScreenState extends State<EditDriverProfileScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _firstNameController.text = widget.profile['first_name']?.toString() ?? '';
    _lastNameController.text = widget.profile['last_name']?.toString() ?? '';
    _emailController.text = widget.profile['email']?.toString() ?? '';
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;

    if (_firstNameController.text.trim().isEmpty) {
      _showSnack('O nome não pode estar vazio', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final body = {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
      };

      final response = await ApiClient.patch('/auth/me/', body: body);

      if (!mounted) return;

      if (response.success) {
        _showSnack('Perfil atualizado com sucesso!');
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) Navigator.of(context).pop(true);
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
                    'Editar perfil',
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
                    _fieldLabel('NOME'),
                    const SizedBox(height: 8),
                    _inputField(
                      controller: _firstNameController,
                      icon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: 20),
                    _fieldLabel('SOBRENOME'),
                    const SizedBox(height: 8),
                    _inputField(
                      controller: _lastNameController,
                      icon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: 20),
                    _fieldLabel('EMAIL'),
                    const SizedBox(height: 8),
                    _inputField(
                      controller: _emailController,
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
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
                                'GUARDAR ALTERAÇÕES',
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

  Widget _inputField({
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: KanawaColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: KanawaColors.border),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Icon(icon, color: KanawaColors.textMuted, size: 20),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
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
        ],
      ),
    );
  }
}