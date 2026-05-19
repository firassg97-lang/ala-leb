import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

class NativeAdCard extends StatelessWidget {
  final bool isLoaded;

  const NativeAdCard({super.key, this.isLoaded = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: AppSizes.adCardHeight,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: isLoaded ? _buildAdContent(context, isDark) : _buildShimmer(isDark),
    );
  }

  Widget _buildShimmer(bool isDark) {
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
      highlightColor: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF5F5F5),
      child: Row(
        children: [
          Container(
            width: 140,
            color: Colors.white,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(height: 14, color: Colors.white, width: double.infinity),
                  const SizedBox(height: 8),
                  Container(height: 12, color: Colors.white, width: 120),
                  const SizedBox(height: 16),
                  Container(height: 12, color: Colors.white, width: 80),
                  const SizedBox(height: 8),
                  Container(height: 32, color: Colors.white, width: 100,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdContent(BuildContext context, bool isDark) {
    return Row(
      children: [
        Container(
          width: 140,
          height: AppSizes.adCardHeight,
          decoration: const BoxDecoration(
            gradient: brandGradient,
          ),
          child: const Center(
            child: Icon(Icons.shopping_bag, size: 48, color: Colors.white70),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Sponsorisé',
                    style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.white54 : textSecondary),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Découvrez nos meilleures offres',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  'Des collections exclusives à prix imbattables',
                  style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : textSecondary),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: brandGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Voir plus',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
