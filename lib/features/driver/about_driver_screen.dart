// KANAWA - Sobre o KANAWA (Motorista)
// v1.0 — Informações sobre a app + autor

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/kanawa_theme.dart';
import '../../shared/widgets/kanawa_logo_pin.dart';
import '../../shared/widgets/kanawa_signature.dart';

class AboutDriverScreen extends StatelessWidget {
  const AboutDriverScreen({super.key});

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
                    'Sobre o KANAWA',
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
                  children: [
                    const SizedBox(height: 20),
                    const KanawaLogoPin(size: 100, showShadow: true),
                    const SizedBox(height: 24),
                    Text(
                      'KANAWA',
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: KanawaColors.textStrong,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Versão 1.0.0',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: KanawaColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: KanawaColors.bgCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: KanawaColors.border),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Plataforma de transporte por aplicativo '
                            'desenvolvida para Angola 🇦🇴',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              height: 1.5,
                              color: KanawaColors.textStrong,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Divider(color: KanawaColors.border, height: 1),
                          const SizedBox(height: 20),
                          _infoRow(
                            icon: Icons.business_rounded,
                            label: 'Empresa',
                            value: 'MBSoft',
                          ),
                          const SizedBox(height: 12),
                          _infoRow(
                            icon: Icons.person_rounded,
                            label: 'Autor',
                            value: 'Benvindo Mersh',
                          ),
                          const SizedBox(height: 12),
                          _infoRow(
                            icon: Icons.calendar_today_rounded,
                            label: 'Ano',
                            value: '2026',
                          ),
                          const SizedBox(height: 12),
                          _infoRow(
                            icon: Icons.location_on_rounded,
                            label: 'Piloto',
                            value: 'Saurimo, Lunda Sul',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Feito com ❤️ em Angola',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: KanawaColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 40),
                    const KanawaSignature(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: KanawaColors.textMuted),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: KanawaColors.textMuted,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: KanawaColors.textStrong,
          ),
        ),
      ],
    );
  }
}