import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../shared/models/product_model.dart';
import '../../../../shared/widgets/loading_shimmer.dart';
import '../../../../shared/widgets/rating_stars.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final int index;

  const ProductCard({super.key, required this.product, required this.index});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => context.push('/product/${product.id}'),
      child: AnimatedContainer(
        duration: 150.ms,
        child: Card(
          elevation: 2,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImage(context),
              _buildInfo(context, isDark),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: index * 60), duration: 400.ms)
        .slideY(begin: 0.1, end: 0);
  }

  Widget _buildImage(BuildContext context) {
    return Hero(
      tag: 'product_${product.id}',
      child: AspectRatio(
        aspectRatio: 1 / 1.2,
        child: Stack(
          fit: StackFit.expand,
          children: [
            product.mainImage.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: product.mainImage,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const ShimmerBox(
                      width: double.infinity,
                      height: double.infinity,
                      borderRadius: 0,
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: primaryBlue.withOpacity(0.1),
                      child: const Icon(Icons.image_not_supported,
                          color: primaryBlue, size: 40),
                    ),
                  )
                : Container(
                    color: primaryBlue.withOpacity(0.1),
                    child: const Icon(Icons.image, color: primaryBlue, size: 40),
                  ),
            Positioned(
              top: 8,
              left: 8,
              child: _buildBadge(
                product.isRental ? 'Location' : 'Vente',
                product.isRental ? primaryPink : primaryBlue,
              ),
            ),
            if (product.isOriginal)
              Positioned(
                top: 8,
                right: 8,
                child: _buildBadge('Original', Colors.amber.shade700),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
            color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildInfo(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            FormatUtils.formatPrice(product.price, isRental: product.isRental),
            style: const TextStyle(
                color: primaryBlue,
                fontWeight: FontWeight.bold,
                fontSize: 14),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _conditionColor(product.condition).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  FormatUtils.conditionLabel(product.condition, 'fr'),
                  style: TextStyle(
                      fontSize: 10,
                      color: _conditionColor(product.condition),
                      fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.location_on, size: 11, color: textSecondary),
              Expanded(
                child: Text(
                  product.wilaya,
                  style:
                      const TextStyle(fontSize: 10, color: textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (product.owner != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.store, size: 11, color: textSecondary),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    product.owner!.fullName ?? 'Vendeur',
                    style:
                        const TextStyle(fontSize: 10, color: textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (product.owner!.ratingAvg > 0)
                  RatingStars(
                    rating: product.owner!.ratingAvg,
                    size: 10,
                    showCount: false,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _conditionColor(String condition) {
    switch (condition) {
      case 'new':
        return const Color(0xFF43A047);
      case 'good_used':
        return const Color(0xFF1565C0);
      default:
        return textSecondary;
    }
  }
}
