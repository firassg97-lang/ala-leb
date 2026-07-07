import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lebesty/data/categories.dart';
const Color primaryBlue = Color(0xFF6BB8E8);
const Color primaryPink = Color(0xFFF28BA8);
const Color backgroundLight = Color(0xFFFFFFFF);
const Color backgroundDark = Color(0xFF121212);
const Color surfaceLight = Color(0xFFF8F9FA);
const Color surfaceDark = Color(0xFF1E1E1E);
const Color cardDark = Color(0xFF2A2A2A);
const Color textPrimary = Color(0xFF1A1A2E);
const Color textSecondary = Color(0xFF6B7280);
const Color dividerColor = Color(0xFFF0F0F0);
const Color errorColor = Color(0xFFE53935);
const Color successColor = Color(0xFF43A047);
const Color warningColor = Color(0xFFFFA726);
const LinearGradient brandGradient = LinearGradient(
  colors: [primaryBlue, primaryPink],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);
const LinearGradient brandGradientVertical = LinearGradient(
  colors: [primaryBlue, primaryPink],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
);

// ─── نموذج التصنيف (مستورد من ملف categories) ───

// ─── Helper: البحث عن CategoryItem بالـ id في شجرة التصنيفات ───
CategoryItem? _findCategoryById(List<CategoryItem> list, String id) {
  for (final item in list) {
    if (item.id == id) return item;
    final found = _findCategoryById(item.children, id);
    if (found != null) return found;
  }
  return null;
}

/// يُرجع [mainCat, subCat, itemCat] بحسب productType و ids المخزنة
List<CategoryItem?> _resolveCategoryPath({
  required String productType,
  required String? mainId,
  required String? subId,
  required String? itemId,
}) {
  final categories = productType == 'rental' ? rentalCategories : saleCategories;
  final mainCat = mainId != null ? _findCategoryById(categories, mainId) : null;
  final subCat = subId != null ? _findCategoryById(categories, subId) : null;
  final itemCat = itemId != null ? _findCategoryById(categories, itemId) : null;
  return [mainCat, subCat, itemCat];
}

class ProfileOwner {
  final String id;
  final String? fullName;
  final String? avatarUrl;
  final String accountType;
  final String? shopType;
  final double ratingAvg;
  final int ratingCount;

  const ProfileOwner({
    required this.id,
    this.fullName,
    this.avatarUrl,
    required this.accountType,
    this.shopType,
    this.ratingAvg = 0.0,
    this.ratingCount = 0,
  });

  factory ProfileOwner.fromJson(Map<String, dynamic> json) => ProfileOwner(
    id: json['id'] as String,
    fullName: json['username'] as String?,
    avatarUrl: json['avatar_url'] as String?,
    accountType: json['account_type'] as String? ?? 'user',
    shopType: json['shop_type'] as String?,
    ratingAvg: double.tryParse(json['rating_avg']?.toString() ?? '0') ?? 0.0,
    ratingCount: json['rating_count'] as int? ?? 0,
  );
}

class ProductModel {
  final String id;
  final String userId;
  final String productType;
  final String? categoryMain;
  final String? categorySub;
  final String? categoryItem;
  final String title;
  final String? description;
  final String? size;
  final String condition;
  final bool isOriginal;
  final double price;
  final List<String> imageUrls;
  final String? thumbnailUrl;
  final String wilaya;
  final DateTime publishedAt;
  final ProfileOwner? owner;

  const ProductModel({
    required this.id,
    required this.userId,
    required this.productType,
    this.categoryMain,
    this.categorySub,
    this.categoryItem,
    required this.title,
    this.description,
    this.size,
    required this.condition,
    this.isOriginal = false,
    required this.price,
    this.imageUrls = const [],
    this.thumbnailUrl,
    required this.wilaya,
    required this.publishedAt,
    this.owner,
  });

  bool get isRental => productType == 'rental';
  String get mainImage =>
      thumbnailUrl ?? (imageUrls.isNotEmpty ? imageUrls.first : '');

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final rawImages = json['images'];
    List<String> images = [];
    if (rawImages is List) {
      images = rawImages.map((e) => e.toString()).toList();
    }
    ProfileOwner? owner;
    if (json['profiles'] != null) {
      owner = ProfileOwner.fromJson(json['profiles'] as Map<String, dynamic>);
    }
    return ProductModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      productType: json['product_type'] as String? ?? 'sale',
      categoryMain: json['category_main'] as String?,
      categorySub: json['category_sub'] as String?,
      categoryItem: json['category_item'] as String?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      size: json['taille'] as String?,
      condition: json['condition'] as String? ?? 'used',
      isOriginal: json['is_original'] as bool? ?? false,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      imageUrls: images,
      thumbnailUrl: json['main_image_url'] as String?,
      wilaya: json['wilaya'] as String? ?? '',
      publishedAt: DateTime.parse(
          json['published_at'] as String? ?? DateTime.now().toIso8601String()),
      owner: owner,
    );
  }
}

class RatingStars extends StatelessWidget {
  final double rating;
  final int count;
  final double size;
  final bool showCount;

  const RatingStars({
    super.key,
    required this.rating,
    this.count = 0,
    this.size = 16,
    this.showCount = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (i) {
          if (i < rating.floor()) {
            return Icon(Icons.star, size: size, color: warningColor);
          } else if (i < rating && rating - i >= 0.5) {
            return Icon(Icons.star_half, size: size, color: warningColor);
          } else {
            return Icon(Icons.star_border, size: size, color: Colors.grey[300]);
          }
        }),
        if (showCount && count > 0) ...[
          const SizedBox(width: 4),
          Text('($count)',
              style: TextStyle(fontSize: size * 0.75, color: Colors.grey)),
        ],
      ],
    );
  }
}

class InteractiveRatingStars extends StatefulWidget {
  final int initialRating;
  final void Function(int) onRatingChanged;
  final double size;

  const InteractiveRatingStars({
    super.key,
    this.initialRating = 0,
    required this.onRatingChanged,
    this.size = 40,
  });

  @override
  State<InteractiveRatingStars> createState() => _InteractiveRatingStarsState();
}

class _InteractiveRatingStarsState extends State<InteractiveRatingStars> {
  late int _rating;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return GestureDetector(
          onTap: () {
            setState(() => _rating = i + 1);
            widget.onRatingChanged(i + 1);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(
              i < _rating ? Icons.star : Icons.star_border,
              size: widget.size,
              color: i < _rating ? warningColor : Colors.grey[400],
            ),
          ),
        );
      }),
    );
  }
}

const _ownerSelect =
    'profiles(id, username, avatar_url, account_type, shop_type, rating_avg, rating_count)';

String _formatPrice(double price, {bool isRental = false}) {
  final formatted = price == price.truncateToDouble()
      ? price.toInt().toString()
      : price.toStringAsFixed(2);
  return isRental ? '$formatted TND/jour' : '$formatted TND';
}

String _conditionLabel(String condition) {
  const map = {'new': 'Nouveau', 'good_used': 'Bon état', 'used': 'Utilisé'};
  return map[condition] ?? condition;
}

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
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
      final data = await Supabase.instance.client
          .from('products')
          .select('*, $_ownerSelect')
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

  bool get _isOwner =>
      Supabase.instance.client.auth.currentUser?.id == _product?.userId;

  Future<void> _republish() async {
    if (_product == null) return;
    try {
      await Supabase.instance.client
          .from('products')
          .update({'published_at': DateTime.now().toIso8601String()})
          .eq('id', _product!.id);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Article republié'),
            backgroundColor: successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: errorColor),
        );
      }
    }
  }

  Future<void> _openChat() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null || _product == null) return;

    try {
      // Find or create conversation
      final existing = await supabase
          .from('conversations')
          .select()
          .or('and(participant1_id.eq.${user.id},participant2_id.eq.${_product!.userId}),and(participant1_id.eq.${_product!.userId},participant2_id.eq.${user.id})')
          .maybeSingle();

      String conversationId;
      if (existing != null) {
        conversationId = existing['id'] as String;
      } else {
        final created = await supabase
            .from('conversations')
            .insert({
          'participant1_id': user.id,
          'participant2_id': _product!.userId,
        })
            .select()
            .single();
        conversationId = created['id'] as String;
      }

      // Send product reply message
      await supabase.from('messages').insert({
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
          'otherUserId': _product!.userId,
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

  Future<void> _confirmAndReport() async {
    if (_product == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Signaler ce produit'),
        content:
            const Text('Voulez-vous signaler ce produit comme inapproprié ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Signaler', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;
    try {
      await supabase.from('reports').insert({
        'product_id': _product!.id,
        'reporter_id': user.id,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produit signalé, merci'),
          backgroundColor: successColor,
        ),
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;
      final alreadyReported = e.code == '23505';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(alreadyReported
              ? 'Vous avez déjà signalé ce produit'
              : e.message),
          backgroundColor: errorColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: errorColor),
      );
    }
  }

  Future<void> _confirmAndDelete() async {
    if (_product == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Supprimer l'article"),
        content: const Text(
            "Cette action est irréversible. L'article sera définitivement supprimé."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final supabase = Supabase.instance.client;
    try {
      // 1) جلب قائمة الصور من قاعدة البيانات
      final row = await supabase
          .from('products')
          .select('images')
          .eq('id', _product!.id)
          .single();
      final rawImages = row['images'];
      final List<String> imageUrls = (rawImages is List)
          ? rawImages.map((e) => e.toString()).toList()
          : <String>[];

      // 2) حذف ملفات الصور من Storage bucket 'products'
      final paths = imageUrls
          .map((url) {
            final idx = url.lastIndexOf('/');
            return idx >= 0 ? url.substring(idx + 1) : url;
          })
          .where((p) => p.isNotEmpty)
          .toList();
      if (paths.isNotEmpty) {
        await supabase.storage.from('products').remove(paths);
      }

      // 3) حذف صف المنتج
      await supabase.from('products').delete().eq('id', _product!.id);

      if (!mounted) return;
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Article supprimé'),
          backgroundColor: successColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: errorColor),
      );
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
                  final supabase = Supabase.instance.client;
                  final user = supabase.auth.currentUser;
                  if (user == null || _product == null) return;
                  try {
                    await supabase.from('ratings').upsert(
                      {
                        'rater_id': user.id,
                        'rated_id': _product!.userId,
                        'score': stars,
                      },
                      onConflict: 'rater_id,rated_id',
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Évaluation envoyée'),
                            backgroundColor: successColor),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(e.toString()),
                            backgroundColor: errorColor),
                      );
                    }
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
                  onTap: _confirmAndDelete,
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Supprimer',
                        style: TextStyle(
                            color: Colors.red,
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
                  // ── الشارات: نوع + حالة + أصلي ──
                  Row(
                    children: [
                      _Badge(
                        label: product.isRental ? 'Location' : 'Vente',
                        color: product.isRental ? primaryPink : primaryBlue,
                      ),
                      const SizedBox(width: 8),
                      _Badge(
                        label: _conditionLabel(product.condition),
                        color: _conditionColor(product.condition),
                      ),
                      if (product.isOriginal) ...[
                        const SizedBox(width: 8),
                        _Badge(label: 'Original', color: Colors.amber.shade700),
                      ],
                      if (!_isOwner) ...[
                        const Spacer(),
                        IconButton(
                          onPressed: _confirmAndReport,
                          tooltip: 'Signaler',
                          icon: const Icon(Icons.flag_outlined,
                              color: primaryPink),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
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
                    _formatPrice(product.price, isRental: product.isRental),
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

                  // ══════════════════════════════════════════
                  // ── قسم التصنيفات (التعديل الجديد) ──────
                  // ══════════════════════════════════════════
                  _buildCategorySection(product),

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
      bottomNavigationBar:
      _isOwner ? _buildOwnerBottomBar(product) : _buildBottomBar(product),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // ── Widget قسم التصنيف (جديد) ────────────────────────────────
  // ══════════════════════════════════════════════════════════════
  Widget _buildCategorySection(ProductModel product) {
    // لا نعرض القسم إذا لم يكن هناك أي تصنيف
    if (product.categoryMain == null &&
        product.categorySub == null &&
        product.categoryItem == null) {
      return const SizedBox.shrink();
    }

    final path = _resolveCategoryPath(
      productType: product.productType,
      mainId: product.categoryMain,
      subId: product.categorySub,
      itemId: product.categoryItem,
    );

    final mainCat = path[0];
    final subCat = path[1];
    final itemCat = path[2];

    // لا نعرض القسم إذا لم نجد أي تصنيف في القائمة
    if (mainCat == null && subCat == null && itemCat == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),
        // ── العنوان ──
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: (mainCat?.color ?? primaryBlue).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.category_outlined,
                size: 16,
                color: mainCat?.color ?? primaryBlue,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Catégorie',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Breadcrumb مرئي ──
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: (mainCat?.color ?? primaryBlue).withOpacity(0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: (mainCat?.color ?? primaryBlue).withOpacity(0.15),
              ),
            ),
            child: Builder(builder: (_) {
              // نعرض فقط المستوى الأول والأخير من التصنيفات الموجودة
              final cats =
                  [mainCat, subCat, itemCat].whereType<CategoryItem>().toList();
              if (cats.isEmpty) return const SizedBox.shrink();
              final firstCat = cats.first;
              final lastCat = cats.last;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _CategoryChip(
                    emoji: firstCat.emoji,
                    label: firstCat.labelFr,
                    color: firstCat.color,
                    isLeaf: cats.length == 1,
                  ),
                  if (cats.length >= 2) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(Icons.chevron_right,
                          size: 18,
                          color: firstCat.color.withOpacity(0.5)),
                    ),
                    _CategoryChip(
                      emoji: lastCat.emoji,
                      label: lastCat.labelFr,
                      color: lastCat.color,
                      isLeaf: true,
                      isSpecial: lastCat.isSpecial,
                    ),
                  ],
                ],
              );
            }),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 150.ms);
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

  Widget _buildOwnerBottomBar(ProductModel product) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push('/product/${product.id}/edit'),
                icon: const Icon(Icons.edit_outlined, color: primaryBlue),
                label: const Text('Modifier',
                    style: TextStyle(color: primaryBlue)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _republish,
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text('Republier',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
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

// ══════════════════════════════════════════════════════════════
// ── Widget الـ Chip الواحد في الـ Breadcrumb (جديد) ──────────
// ══════════════════════════════════════════════════════════════
class _CategoryChip extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  final bool isLeaf;
  final bool isSpecial;

  const _CategoryChip({
    required this.emoji,
    required this.label,
    required this.color,
    this.isLeaf = false,
    this.isSpecial = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: isLeaf ? color.withOpacity(0.13) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isLeaf ? Border.all(color: color.withOpacity(0.35)) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isLeaf ? FontWeight.w600 : FontWeight.w500,
                color: isLeaf ? color : textSecondary,
              ),
            ),
          ),
          // ★ للعناصر الخاصة
          if (isSpecial) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.amber.shade600,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('★',
                  style: TextStyle(fontSize: 9, color: Colors.white)),
            ),
          ],
        ],
      ),
    );
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
