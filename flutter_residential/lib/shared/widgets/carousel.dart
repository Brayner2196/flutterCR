import 'dart:async';
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

class CarouselWidget extends StatefulWidget {
  const CarouselWidget({
    super.key,
    required this.pages,
    this.height = 280,
    this.autoScrollInterval = const Duration(seconds: 4),
    this.pauseAfterInteraction = const Duration(seconds: 5),
    this.animationDuration = const Duration(milliseconds: 450),
    this.infinite = true,
    this.showDots = true,
    this.pagePadding = const EdgeInsets.symmetric(horizontal: 2),
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
  });

  final List<Widget> pages;
  final double height;
  final Duration autoScrollInterval;
  final Duration pauseAfterInteraction;
  final Duration animationDuration;
  final bool infinite;
  final bool showDots;
  final EdgeInsets pagePadding;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  State<CarouselWidget> createState() => _CarouselWidgetState();
}

class _CarouselWidgetState extends State<CarouselWidget> {
  static const _offsetInicial = 10000;

  late final PageController _pageController;
  Timer? _timer;
  int _paginaReal = 0;

  int get _totalPaginas => widget.pages.length;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: widget.infinite ? _offsetInicial : 0,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _iniciarAutoScroll());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _iniciarAutoScroll() {
    if (widget.autoScrollInterval == Duration.zero) return;
    _timer?.cancel();
    _timer = Timer.periodic(widget.autoScrollInterval, (_) {
      if (!mounted || !_pageController.hasClients) return;
      _pageController.nextPage(
        duration: widget.animationDuration,
        curve: Curves.easeInOut,
      );
    });
  }

  void _pausarYReanudar() {
    _timer?.cancel();
    Future.delayed(widget.pauseAfterInteraction, () {
      if (mounted) _iniciarAutoScroll();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.errorMessage != null) {
      return _ErrorCarousel(
        mensaje: widget.errorMessage!,
        onRetry: widget.onRetry ?? () {},
      );
    }

    if (_totalPaginas == 0) return const SizedBox.shrink();

    return Skeletonizer(
      enabled: widget.isLoading,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: widget.height,
            child: NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n is UserScrollNotification) _pausarYReanudar();
                return false;
              },
              child: PageView.builder(
                controller: _pageController,
                physics: widget.infinite
                    ? const BouncingScrollPhysics()
                    : const PageScrollPhysics(),
                onPageChanged: (idx) {
                  setState(() => _paginaReal = idx % _totalPaginas);
                },
                itemCount: widget.infinite ? null : _totalPaginas,
                itemBuilder: (context, idx) {
                  final pagina = idx % _totalPaginas;
                  return Padding(
                    padding: widget.pagePadding,
                    child: widget.pages[pagina],
                  );
                },
              ),
            ),
          ),
          if (widget.showDots && _totalPaginas > 1) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_totalPaginas, (i) {
                final activo = i == _paginaReal;
                return GestureDetector(
                  onTap: () {
                    _pausarYReanudar();
                    final actual =
                        _pageController.page?.round() ??
                        (widget.infinite ? _offsetInicial : 0);
                    final diff = i - _paginaReal;
                    _pageController.animateToPage(
                      actual + diff,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: activo ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: activo
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorCarousel extends StatelessWidget {
  const _ErrorCarousel({required this.mensaje, required this.onRetry});

  final String mensaje;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: cs.error, size: 18),
              const SizedBox(width: 6),
              const Text(
                'No se pudo cargar el contenido',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            mensaje,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
