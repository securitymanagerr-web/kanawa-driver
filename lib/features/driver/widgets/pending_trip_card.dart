// KANAWA - Card de viagem pendente
// v1.0

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/kanawa_theme.dart';

class PendingTripCard extends StatelessWidget {
  final String passengerName;
  final String pickupAddress;
  final String dropoffAddress;
  final String distanceToPickup;
  final String tripDistance;
  final int priceKz;
  final int etaMin;
  final bool isLoading;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const PendingTripCard({
    super.key,
    required this.passengerName,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.distanceToPickup,
    required this.tripDistance,
    required this.priceKz,
    required this.etaMin,
    required this.isLoading,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: KanawaColors.bgCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: KanawaColors.success.withOpacity(0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: KanawaColors.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.circle,
                      size: 8,
                      color: KanawaColors.success,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'NOVA VIAGEM',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: KanawaColors.success,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
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
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: KanawaColors.blueSoft,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    passengerName.isNotEmpty
                        ? passengerName[0].toUpperCase()
                        : 'P',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
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
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: KanawaColors.textStrong,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$distanceToPickup de ti',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: KanawaColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: KanawaColors.bgSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '~$etaMin min',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: KanawaColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: KanawaColors.border, height: 1),
          const SizedBox(height: 16),
          _routeRow(
            icon: Icons.location_on_rounded,
            color: KanawaColors.success,
            label: 'RECOLHA',
            value: pickupAddress,
          ),
          const SizedBox(height: 10),
          _routeRow(
            icon: Icons.flag_rounded,
            color: KanawaColors.red,
            label: 'DESTINO',
            value: dropoffAddress,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.route_rounded,
                size: 14,
                color: KanawaColors.textMuted,
              ),
              const SizedBox(width: 5),
              Text(
                'Viagem de $tripDistance',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: KanawaColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    onPressed: isLoading ? null : onReject,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: KanawaColors.border),
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
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KanawaColors.success,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: isLoading
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
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'ACEITAR',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
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
    );
  }

  Widget _routeRow({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: KanawaColors.textSubtle,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: KanawaColors.textStrong,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}