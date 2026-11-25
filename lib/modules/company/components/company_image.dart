import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';
import 'package:conecta_utsh/modules/company/models/company_model.dart';

class CompanyImage extends StatelessWidget {
  const CompanyImage({
    required this.company,
    required this.size,
    this.featured = false,
    this.circular = false,
    super.key,
  });

  final CompanyModel company;
  final double size;
  final bool featured;
  final bool circular;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final name = company.name?.trim();
    final initial = name == null || name.isEmpty
        ? 'E'
        : name.substring(0, 1).toUpperCase();
    final initialStyle = circular
        ? Theme.of(context).textTheme.headlineMedium
        : Theme.of(context).textTheme.titleMedium;
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: featured ? colors.onPrimary : colors.primaryContainer,
        shape: circular ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circular ? null : BorderRadius.circular(12),
      ),
      child: Text(
        initial,
        style: initialStyle?.copyWith(
          color: featured ? colors.primary : colors.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    final imageUrl = company.imageUrl?.trim();
    if (imageUrl == null || imageUrl.isEmpty) return _clip(fallback);

    return _clip(
      CachedNetworkImage(
        imageUrl: imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, _) => fallback,
        errorWidget: (_, _, _) => fallback,
      ),
    );
  }

  Widget _clip(Widget child) => circular
      ? ClipOval(child: child)
      : ClipRRect(borderRadius: BorderRadius.circular(12), child: child);
}
