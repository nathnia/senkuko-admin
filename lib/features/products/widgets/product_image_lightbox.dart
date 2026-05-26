import 'package:flutter/material.dart';
import 'package:senkukoadmin/features/products/models/product_image_model.dart';

class ProductImageLightbox extends StatefulWidget {
  final List<ProductImageData> images;
  final int initialIndex;

  const ProductImageLightbox({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  static void show(
    BuildContext context, {
    required List<ProductImageData> images,
    required int initialIndex,
  }) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.transparent,
        barrierDismissible: true,
        pageBuilder: (_, __, ___) => ProductImageLightbox(
          images: images,
          initialIndex: initialIndex,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 220),
        reverseTransitionDuration: const Duration(milliseconds: 180),
      ),
    );
  }

  @override
  State<ProductImageLightbox> createState() => _ProductImageLightboxState();
}

class _ProductImageLightboxState extends State<ProductImageLightbox>
    with SingleTickerProviderStateMixin {
  late final PageController _pageC;
  late int _currentIndex;

  // For swipe-down-to-close gesture
  double _dragOffset = 0;
  bool _isDragging = false;

  // Background opacity fades as you drag down
  double get _bgOpacity => (1.0 - (_dragOffset.abs() / 300)).clamp(0.0, 1.0);

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageC = PageController(initialPage: widget.initialIndex);

  }

  @override
  void dispose() {
    _pageC.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onVerticalDragStart: (_) {
          setState(() => _isDragging = true);
        },
        onVerticalDragUpdate: (details) {
          setState(() => _dragOffset += details.delta.dy);
        },
        onVerticalDragEnd: (details) {
          // Close if dragged > 120px or fast fling
          if (_dragOffset.abs() > 120 ||
              details.primaryVelocity!.abs() > 800) {
            _close();
          } else {
            setState(() {
              _dragOffset = 0;
              _isDragging = false;
            });
          }
        },
        onTap: _close,
        child: AnimatedContainer(
          duration: _isDragging
              ? Duration.zero
              : const Duration(milliseconds: 200),
          color: Colors.black.withValues(alpha: _bgOpacity * 0.93),
          child: Transform.translate(
            offset: Offset(0, _dragOffset),
            child: SafeArea(
              child: Stack(
                children: [
                  // ── Image PageView ──────────────────────────────────────
                  GestureDetector(
                    onTap: () {}, // prevent tap-to-close on image area
                    child: PageView.builder(
                      controller: _pageC,
                      itemCount: widget.images.length,
                      onPageChanged: (i) => setState(() => _currentIndex = i),
                      itemBuilder: (_, i) {
                        final img = widget.images[i];
                        return InteractiveViewer(
                          minScale: 1.0,
                          maxScale: 4.0,
                          child: Center(
                            child: Hero(
                              tag: 'product_image_${img.id}_$i',
                              child: Image.network(
                                img.imageUrl,
                                fit: BoxFit.contain,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                          : null,
                                      color: Colors.white54,
                                      strokeWidth: 2,
                                    ),
                                  );
                                },
                                errorBuilder: (_, __, ___) => Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.broken_image_outlined,
                                      size: 48,
                                      color: Colors.white24,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Gagal memuat gambar',
                                      style: TextStyle(
                                        color: Colors.white38,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // ── Top bar: close + counter ────────────────────────────
                  Positioned(
                    top: 8,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Close button
                        GestureDetector(
                          onTap: _close,
                          child: Container(
                            margin: const EdgeInsets.only(left: 16),
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                        // Counter badge
                        if (widget.images.length > 1)
                          Container(
                            margin: const EdgeInsets.only(right: 16),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_currentIndex + 1} / ${widget.images.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // ── Bottom dot indicators ───────────────────────────────
                  if (widget.images.length > 1)
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(widget.images.length, (i) {
                          final isActive = i == _currentIndex;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: isActive ? 18 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}