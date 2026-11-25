import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:resize/resize.dart';
import 'package:conecta_utsh/helpers/style.dart';
import 'package:conecta_utsh/modules/company/components/company_cards.dart';
import 'package:conecta_utsh/modules/company/models/company_model.dart';
import 'package:conecta_utsh/modules/company/providers/company_controller.dart';
import 'package:conecta_utsh/modules/company/screens/company_details_screen.dart';
import 'package:conecta_utsh/modules/company/screens/company_screen.dart';
import 'package:conecta_utsh/modules/favoritos/providers/favoritos_controller.dart';

class FavoritosScreen extends StatelessWidget {
  const FavoritosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final controller = context.watch<FavoritosController>();

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Regresar',
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Mis empresas favoritas',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _buildBody(context, controller, theme, colors),
    );
  }

  Widget _buildBody(
    BuildContext context,
    FavoritosController controller,
    ThemeData theme,
    ColorScheme colors,
  ) {
    if (controller.status == FavoritosLoadStatus.loading &&
        !controller.hasLoaded) {
      return Center(child: CircularProgressIndicator(color: colors.primary));
    }

    if (controller.status == FavoritosLoadStatus.error &&
        !controller.hasLoaded) {
      return _buildError(context, controller, theme, colors);
    }

    if (controller.items.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          await controller.recargar();
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: Style.getPaddingSymmetric(horizontal: 28, vertical: 36),
          children: [
            if (controller.status == FavoritosLoadStatus.error &&
                controller.error != null) ...[
              _RefreshError(message: controller.error!),
              SizedBox(height: 12.h),
            ],
            SizedBox(height: 90.h),
            Icon(
              Icons.favorite_border_rounded,
              size: 48,
              color: colors.onSurfaceVariant,
            ),
            SizedBox(height: 12.h),
            Text(
              'Aún no tienes empresas favoritas',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Explora el directorio y guarda las empresas que te interesen.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 18.h),
            Center(
              child: FilledButton(
                onPressed: () => _openCompanies(context),
                child: const Text('Explorar empresas'),
              ),
            ),
          ],
        ),
      );
    }

    final items = controller.items;
    final hasRefreshError =
        controller.status == FavoritosLoadStatus.error &&
        controller.error != null;

    return RefreshIndicator(
      onRefresh: () async {
        await controller.recargar();
      },
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        itemCount: items.length + (hasRefreshError ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (hasRefreshError && index == 0) {
            return _RefreshError(message: controller.error!);
          }
          final item = items[index - (hasRefreshError ? 1 : 0)];
          final company = item.empresa;
          return CompanyListCard(
            key: ValueKey(company.id),
            company: company,
            onTap: () => _openCompanyDetail(context, company),
          );
        },
      ),
    );
  }

  Widget _buildError(
    BuildContext context,
    FavoritosController controller,
    ThemeData theme,
    ColorScheme colors,
  ) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: Style.getPaddingSymmetric(horizontal: 28, vertical: 36),
    children: [
      SizedBox(height: 90.h),
      Icon(Icons.error_outline_rounded, color: colors.error, size: 42),
      SizedBox(height: 12.h),
      Text(
        'No se pudieron cargar tus favoritos.',
        textAlign: TextAlign.center,
        style: theme.textTheme.titleSmall?.copyWith(
          color: colors.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      if (controller.error != null) ...[
        SizedBox(height: 6.h),
        Text(
          controller.error!,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
      SizedBox(height: 12.h),
      Center(
        child: FilledButton.tonal(
          onPressed: controller.recargar,
          child: const Text('Reintentar'),
        ),
      ),
    ],
  );

  void _openCompanies(BuildContext context) {
    final favoritesController = context.read<FavoritosController>();
    final companyController = context.read<CompanyController>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MultiProvider(
          providers: [
            ChangeNotifierProvider<FavoritosController>.value(
              value: favoritesController,
            ),
            ChangeNotifierProvider<CompanyController>.value(
              value: companyController,
            ),
          ],
          child: CompaniesScreen(initialQuery: companyController.query),
        ),
      ),
    );
  }

  void _openCompanyDetail(BuildContext context, CompanyModel company) {
    final favoritesController = context.read<FavoritosController>();
    final companyController = context.read<CompanyController>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MultiProvider(
          providers: [
            ChangeNotifierProvider<FavoritosController>.value(
              value: favoritesController,
            ),
            ChangeNotifierProvider<CompanyController>.value(
              value: companyController,
            ),
          ],
          child: CompanyDetailScreen(company: company),
        ),
      ),
    );
  }
}

class _RefreshError extends StatelessWidget {
  const _RefreshError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: Style.getPaddingAll(12),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: Style.getCircularBorderRadius(12),
      ),
      child: Text(
        'No se pudo actualizar: $message',
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: colors.onErrorContainer),
      ),
    );
  }
}
