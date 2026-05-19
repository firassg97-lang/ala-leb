import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../constants/app_colors.dart';
import '../services/supabase_service.dart';
import '../services/format_utils.dart';
import '../models/product_model.dart';
import '../providers/auth_provider.dart';
import '../widgets/rating_widget.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  final _pageCtrl = PageController();
  ProductModel? _product;
  bool _isLoading = true;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await SupabaseConfig.client
          .from('products')
          .select(
              '*, profiles(id, full_name, avatar_url, account_type, shop_type, rating_avg, rating_count, phone, latitude, longitude)')
          .eq('id', widget.productId)
          .single();
      setState(() {
        _product = ProductModel.fromJson(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  bool get _isOwner {
    final user = ref.read(currentUserProvider);
    return user?.id == _product?.ownerId;
  }

  Future<void> _openChat() async {
    final user = ref.read(currentUserProvider);
    if (user == null || _product == null) return;

    try {
      // Find or create conversation
      final existing = await SupabaseConfig.client
          .from('conversations')
          .select()
          .or('and(participant1_id.eq.${user.id},participant2_id.eq.${_product!.ownerId}),and(participant1_id.eq.${_product!.ownerId},participant2_id.eq.${user.id})')
          .maybeSingle();

      String conversationId;
      if (existing != null) {
        conversationId = existing['id'] as String;
      } else {
        final created = await SupabaseConfig.client
            .from('conversations')
            .insert({
              'participant1_id': user.id,
              'participant2_id': _product!.ownerId,
            })
            .select()
            .single();
        conversationId = created['id'] as String;
      }

      // Send product reply message
      await SupabaseConfig.client.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': user.id,
        'message_type': 'product_reply',
        'product_id': _product!.id,
        'product_title': _product!.title,
        'product_image_url': _product!.mainImage,
        'product_price': _product!.price,
      });

      if (mounted) {
        context.push('/chat/$conversationId', extra: {
          'otherUserId': _product!.ownerId,
          'otherUserName': _product!.owner?.fullName ?? 'Vendeur',
          'otherUserAvatar': _product!.owner?.avatarUrl,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: errorColor),
        );
      }
    }
  }

  void _showRatingSheet() {
    int stars = 5;
    final commentCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            top: 24,
            left: 24,
            right: 24,
          ),
          decoration: BoxDecoration(
            color: Theme.of(ctx).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              const Text('Évaluer',
                  style:
                      TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              InteractiveRatingStars(
                initialRating: stars,
                onRatingChanged: (r) => setS(() => stars = r),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Commentaire (optionnel)',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final user = ref.read(currentUserProvider);
                  if (user == null || _product == null) return;
                  try {
                    await SupabaseConfig.client.from('ratings').upsert({
                      'rater_id': user.id,
                      'rated_id': _product!.ownerId,
                      'stars': stars,
                      'comment': commentCtrl.text.trim().isEmpty
                          ? null
                          : commentCtrl.text.trim(),
                    });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Évaluation envoyée'),
                          backgroundColor: successColor),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(e.toString()),
                          backgroundColor: errorColor),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  backgroundColor: primaryBlue,
                ),
                child: const Text('Envoyer',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: primaryBlue)),
      );
    }
    if (_product == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Produit non trouvé')),
      );
    }

    final product = _product!;
    final images = product.imageUrls.isEmpty
        ? [product.thumbnailUrl ?? '']
        : product.imageUrls;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: MediaQuery.of(context).size.width * 1.2,
            pinned: true,
            leading: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new,
                    color: textPrimary, size: 18),
              ),
            ),
            actions: [
              if (_isOwner)
                GestureDetector(
                  onTap: () =>
                      context.push('/product/${product.id}/edit'),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Modifier',
                        style: TextStyle(
                            color: primaryBlue,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  PageView.builder(
                    controller: _pageCtrl,
                    itemCount: images.length,
                    onPageChanged: (i) =>
                        setState(() => _currentImageIndex = i),
                    itemBuilder: (_, i) {
                      final img = images[i];
                      return img.isNotEmpty
                          ? Hero(
                              tag: 'product_${product.id}',
                              child: CachedNetworkImage(
                                imageUrl: img,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                    color: Colors.grey[100]),
                              ),
                            )
                          : Container(
                              color: primaryBlue.withOpacity(0.1),
                              child: const Icon(Icons.image,
                                  size: 64, color: primaryBlue),
                            );
                    },
                  ),
                  if (images.length > 1)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: AnimatedSmoothIndicator(
                          activeIndex: _currentImageIndex,
                          count: images.length,
                          effect: ExpandingDotsEffect(
                            dotHeight: 8,
                            dotWidth: 8,
                            activeDotColor: primaryBlue,
                            dotColor: Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _Badge(
                        label: product.isRental ? 'Location' : 'Vente',
                        color: product.isRental ? primaryPink : primaryBlue,
                      ),
                      const SizedBox(width: 8),
                      _Badge(
                        label: FormatUtils.conditionLabel(product.condition, 'fr'),
                        color: _conditionColor(product.condition),
                      ),
                      if (product.isOriginal) ...[
                        const SizedBox(width: 8),
                        _Badge(label: 'Original', color: Colors.amber.shade700),
                      ],
                    ],
                  ).animate().fadeIn(),
                  const SizedBox(height: 12),
                  Text(product.title,
                          style: Theme.of(context).textTheme.headlineMedium)
                      .animate()
                      .fadeIn(delay: 50.ms),
                  const SizedBox(height: 8),
                  Text(
                    FormatUtils.formatPrice(product.price,
                        isRental: product.isRental),
                    style: const TextStyle(
                        color: primaryBlue,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  ).animate().fadeIn(delay: 100.ms),
                  if (product.size != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Taille: ',
                            style: TextStyle(color: textSecondary)),
                        Text(product.size!,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                  if (product.description != null) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text('Description',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(product.description!,
                        style: const TextStyle(height: 1.6)),
                  ],
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  if (product.owner != null) _buildOwnerCard(product),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: !_isOwner ? _buildBottomBar(product) : null,
    );
  }

  Widget _buildOwnerCard(ProductModel product) {
    final owner = product.owner!;
    return GestureDetector(
      onTap: () => context.push('/user/${owner.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: dividerColor),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage: owner.avatarUrl != null
                  ? CachedNetworkImageProvider(owner.avatarUrl!)
                  : null,
              child: owner.avatarUrl == null
                  ? const Icon(Icons.person, size: 28)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    owner.fullName ?? 'Vendeur',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (owner.ratingAvg > 0)
                    RatingStars(
                      rating: owner.ratingAvg,
                      count: owner.ratingCount,
                      size: 14,
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: textSecondary),
          ],
        ),
      ).animate().fadeIn(delay: 200.ms),
    );
  }

  Widget _buildBottomBar(ProductModel product) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _openChat,
                icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                label: const Text('Envoyer un message',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: _showRatingSheet,
                icon: const Icon(Icons.star_outline, color: warningColor),
              ),
            ),
          ],
        ),
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

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}
