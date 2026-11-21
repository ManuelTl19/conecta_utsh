import 'package:material_ui/material_ui.dart';

class CompanyLogo extends StatelessWidget {
  const CompanyLogo({required this.logoKey, this.size = 38, super.key});

  final String logoKey;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final icon = switch (logoKey) {
      'spotify' => Icons.music_note_rounded,
      'pinterest' => Icons.push_pin_rounded,
      'google' => Icons.travel_explore_rounded,
      'microsoft' => Icons.window_rounded,
      'adobe' => Icons.change_history_rounded,
      'amazon' => Icons.shopping_bag_outlined,
      'uber' => Icons.directions_car_filled_outlined,
      'airbnb' => Icons.house_rounded,
      'canva' => Icons.brush_rounded,
      'shell' => Icons.local_gas_station_rounded,
      _ => Icons.business_rounded,
    };

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(size * .28),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: size * .58, color: colors.primary),
    );
  }
}
