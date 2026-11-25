import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:conecta_utsh/modules/company/components/company_cards.dart';
import 'package:conecta_utsh/modules/company/models/company_model.dart';

class FeaturedCompaniesCarousel extends StatefulWidget {
  const FeaturedCompaniesCarousel({
    required this.companies,
    required this.onTap,
    super.key,
  });

  final List<CompanyModel> companies;
  final ValueChanged<CompanyModel> onTap;

  @override
  State<FeaturedCompaniesCarousel> createState() =>
      _FeaturedCompaniesCarouselState();
}

class _FeaturedCompaniesCarouselState extends State<FeaturedCompaniesCarousel>
    with SingleTickerProviderStateMixin {
  late final PageController _controller;
  late final AnimationController _entranceController;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideIn;
  Timer? _timer;
  int _currentPage = 0;
  bool _isInteracting = false;

  @override
  void initState() {
    super.initState();
    _controller = PageController(
      viewportFraction: .88,
      initialPage: widget.companies.length * 1000,
    );
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..forward();
    _fadeIn = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );
    _slideIn = Tween<Offset>(begin: const Offset(0, .08), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Curves.easeOutCubic,
          ),
        );
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.companies.length < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_isInteracting && _controller.hasClients) {
        final nextPage = (_controller.page?.round() ?? 0) + 1;
        _controller.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _pause() {
    _isInteracting = true;
    _timer?.cancel();
  }

  void _resumeAfterInteraction() {
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 5), () {
      _isInteracting = false;
      _startTimer();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _entranceController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.companies.isEmpty) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        SizedBox(
          height: 188,
          child: Listener(
            onPointerDown: (_) => _pause(),
            onPointerUp: (_) => _resumeAfterInteraction(),
            onPointerCancel: (_) => _resumeAfterInteraction(),
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (page) =>
                  setState(() => _currentPage = page % widget.companies.length),
              itemBuilder: (context, index) {
                final company =
                    widget.companies[index % widget.companies.length];
                return AnimatedBuilder(
                  animation: _controller,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 8,
                    ),
                    child: FeaturedCompanyCard(
                      company: company,
                      onTap: () => widget.onTap(company),
                    ),
                  ),
                  builder: (context, child) {
                    final page = _controller.hasClients
                        ? (_controller.page ??
                              _controller.initialPage.toDouble())
                        : _controller.initialPage.toDouble();
                    final distance = (page - index).abs().clamp(0.0, 1.0);
                    return Opacity(
                      opacity: 1 - distance * .22,
                      child: Transform.scale(
                        scale: 1 - distance * .08,
                        child: FadeTransition(
                          opacity: _fadeIn,
                          child: SlideTransition(
                            position: _slideIn,
                            child: child,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.companies.length, (index) {
            final selected = index == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: selected ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: selected ? colors.tertiary : colors.outline,
                borderRadius: BorderRadius.circular(5),
              ),
            );
          }),
        ),
      ],
    );
  }
}
