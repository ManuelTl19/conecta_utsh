import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:conecta_utsh/modules/company/models/company_model.dart';
import 'package:conecta_utsh/modules/company/providers/company_controller.dart';
import 'package:conecta_utsh/modules/favoritos/providers/favoritos_controller.dart';
import 'package:conecta_utsh/modules/favoritos/services/favoritos_service.dart';
import 'package:conecta_utsh/utils/widgets/dialogs.dart';

class FavoritoButton extends StatelessWidget {
  const FavoritoButton({
    required this.company,
    this.inactiveColor,
    super.key,
  });

  final CompanyModel company;
  final Color? inactiveColor;

  @override
  Widget build(BuildContext context) {
    return Selector<
      FavoritosController,
      ({
        bool isStudent,
        FavoritosLoadStatus status,
        bool isFavorite,
        bool isPending,
      })
    >(
      selector: (_, controller) => (
        isStudent: controller.isStudent,
        status: controller.status,
        isFavorite: controller.isFavorite(company.id),
        isPending: controller.isPending(company.id),
      ),
      builder: (context, state, _) {
        if (!state.isStudent) return const SizedBox.shrink();
        final colors = Theme.of(context).colorScheme;
        final disabled = state.isPending ||
            state.status == FavoritosLoadStatus.initial ||
            state.status == FavoritosLoadStatus.loading;

        return IconButton(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          padding: EdgeInsets.zero,
          tooltip: state.isFavorite
              ? 'Quitar de favoritas'
              : 'Agregar a favoritas',
          onPressed: disabled ? null : () => _toggle(context),
          icon: state.isPending
              ? SizedBox(
                  width: 19,
                  height: 19,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: inactiveColor ?? colors.primary,
                  ),
                )
              : Icon(
                  state.isFavorite
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: state.isFavorite
                      ? inactiveColor == null
                            ? colors.primary
                            : colors.tertiary
                      : inactiveColor ?? colors.onSurfaceVariant,
                ),
        );
      },
    );
  }

  Future<void> _toggle(BuildContext context) async {
    final controller = context.read<FavoritosController>();
    try {
      final result = await controller.alternar(
        company,
        onCompanyUnavailable: () =>
            context.read<CompanyController>().refresh(),
      );
      if (!context.mounted) return;
      if (result == FavoritoToggleResult.added) {
        final companyName = company.name?.trim();
        await Dialogs.showSimpleDialog(
          context,
          title: 'Favorito agregado',
          message: companyName == null || companyName.isEmpty
              ? 'La empresa se agregó a tus favoritos.'
              : '$companyName se agregó a tus favoritos.',
          icon: Icons.bookmark_added_rounded,
          color: Theme.of(context).colorScheme.primary,
        );
      }
    } on FavoritosApiException catch (error) {
      if (!context.mounted || error.statusCode == 401) return;
      _showMessage(context, error.message);
    } on Exception catch (error) {
      if (!context.mounted) return;
      _showMessage(context, 'No se pudo actualizar el favorito: $error');
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
