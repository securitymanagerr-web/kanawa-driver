// KANAWA - Assinatura MBSoft · Benvindo Mersh

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class KanawaSignature extends StatelessWidget {
  const KanawaSignature({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'MBSoft · Benvindo Mersh',
      style: GoogleFonts.inter(
        fontSize: 10.5,
        fontWeight: FontWeight.w500,
        color: const Color(0xFFA1A1AA),
        letterSpacing: 0.3,
      ),
    );
  }
}