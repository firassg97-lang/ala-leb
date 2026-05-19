import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../services/supabase_service.dart';
import '../models/product_model.dart';
import '../providers/auth_provider.dart';
import '../widgets/shimmer_grid.dart';
import '../widgets/product_card.dart';

class MyProfileScreen extends ConsumerStatefulWidget {
  const MyProfileScreen({super.key});

  @override
  ConsumerState<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends ConsumerState<MyProfileScreen> {
  final _scrollCtrl = ScrollController();
  final List<ProductModel> _products = [];
  bool _isLoadingProducts = true;
  bool _hasMore = true;
  int _offset = 0;

  bool _isUploadingAvatar = false;
  bool _phoneVisible = true;

  @override
  void initState() {
    super.initState();
    _loadPhoneVisibility();
    _loadProducts();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_products.isEmpty && !_isLoadingProducts && _offset == 0) {
      _loadProducts();
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 300) {
      if (!_isLoadingProducts && _hasMore) _loadProducts();
    }
  }

  // ─── Phone visibility ────────────────────────────────────────────────────────

  Future<void> _loadPhoneVisibility() async {
    try {
      final profile = ref.read(authNotifierProvider).valueOrNull;
      if (profile != null) {
        setState(() => _phoneVisible = profile.phoneVisible);
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() => _phoneVisible = prefs.getBool('phone_visible') ?? true);
      }
    } catch (_) {}
  }

  Future<void> _togglePhoneVisibility() async {
    final newValue = !_phoneVisible;
    setState(() => _phoneVisible = newValue);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('phone_visible', newValue);
    try {
      await ref
          .read(authNotifierProvider.notifier)
          .updateProfile({'phone_visible': newValue});
    } catch (_) {}
  }

  // ─── Products ────────────────────────────────────────────────────────────────

  Future<void> _loadProducts() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      if (mounted) setState(() => _isLoadingProducts = false);
      return;
    }
    if (_isLoadingProducts && _offset > 0) return;
    setState(() => _isLoadingProducts = true);
    try {
      final data = await SupabaseConfig.client
          .from('products')
          .select(
              '*, profiles(id, full_name, avatar_url, account_type, shop_type, rating_avg, rating_count)')
          .eq('owner_id', user.id)
          .order('published_at', ascending: false)
          .range(_offset, _offset + 9);
      final items = (data as List)
          .map((j) => ProductModel.fromJson(j as Map<String, dynamic>))
          .toList();
      if (mounted) {
        setState(() {
          _products.addAll(items);
          _offset += items.length;
          _hasMore = items.length == 10;
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingProducts = false);
    }
  }

  // ─── Avatar ──────────────────────────────────────────────────────────────────

  Future<void> _openImageSourceSheet() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.camera_alt_outlined, color: primaryBlue),
              ),
              title: const Text('Prendre une photo',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: primaryPink.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child:
                    const Icon(Icons.photo_library_outlined, color: primaryPink),
              ),
              title: const Text('Choisir depuis la galerie',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked == null || !mounted) return;

    setState(() => _isUploadingAvatar = true);
    try {
      // Compress to ~200 KB
      Uint8List? bytes = await FlutterImageCompress.compressWithFile(
        picked.path,
        quality: 80,
        minWidth: 400,
        minHeight: 400,
      );
      if (bytes == null || !mounted) return;

      // Reduce quality further if still > 200 KB
      if (bytes.lengthInBytes > 200 * 1024) {
        bytes = await FlutterImageCompress.compressWithList(bytes, quality: 60);
      }

      final user = ref.read(currentUserProvider)!;
      final path = '${user.id}/avatar.jpg';

      await SupabaseConfig.client.storage.from('avatars').uploadBinary(
            path,
            bytes,
            fileOptions:
                const FileOptions(contentType: 'image/jpeg', upsert: true),
          );

      final url =
          SupabaseConfig.client.storage.from('avatars').getPublicUrl(path);

      await ref
          .read(authNotifierProvider.notifier)
          .updateProfile({'avatar_url': url});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: errorColor));
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  // ─── Maps ────────────────────────────────────────────────────────────────────

  void _openInMaps(double lat, double lng) {
    launchUrl(
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng'),
        mode: LaunchMode.externalApplication);
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final crossAxis = AppSizes.gridCrossAxisCount(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ══════════════════════════════════════════════════════════════════
          // SECTION 1 — Profile header (white, always rendered)
          // ══════════════════════════════════════════════════════════════════
          Container(
            color: Colors.white,
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Settings gear ────────────────────────────────────────
                  Row(
                    children: [
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined),
                        onPressed: () => context.push('/settings'),
                        tooltip: 'Paramètres',
                      ),
                    ],
                  ),

                  // ── Profile content ───────────────────────────────────────
                  authState.when(
                    loading: () => _buildProfileShimmer(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (p) => p != null
                        ? _buildProfileInfo(p)
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),

          // Gap between sections
          const SizedBox(height: 8),

          // ══════════════════════════════════════════════════════════════════
          // SECTION 2 — Products (fills remaining height)
          // ══════════════════════════════════════════════════════════════════
          Expanded(
            child: _buildProductsSection(crossAxis),
          ),
        ],
      ),
    );
  }

  // ─── Products section ────────────────────────────────────────────────────────

  Widget _buildProductsSection(int crossAxis) {
    // Shimmer while first page loads
    if (_isLoadingProducts && _products.isEmpty) {
      return GridView.builder(
        padding: const EdgeInsets.all(8),
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxis,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1 / 1.6,
        ),
        itemCount: 4,
        itemBuilder: (_, __) => const ProductCardShimmer(),
      );
    }

    // Empty state
    if (!_isLoadingProducts && _products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_shopping_cart_outlined,
                    size: 48, color: primaryBlue),
              ),
              const SizedBox(height: 20),
              const Text(
                'Aucun article publié',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ajoutez votre premier article et commencez à vendre !',
                textAlign: TextAlign.center,
                style: TextStyle(color: textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.push('/add-product'),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Ajoutez votre premier article',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Products grid with pagination
    return CustomScrollView(
      controller: _scrollCtrl,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(8),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (_, i) => ProductCard(product: _products[i], index: i),
              childCount: _products.length,
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxis,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1 / 1.6,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _isLoadingProducts
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: primaryBlue)),
                )
              : const SizedBox(height: 80),
        ),
      ],
    );
  }

  // ─── Profile header shimmer ──────────────────────────────────────────────────

  Widget _buildProfileShimmer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
      child: Column(
        children: [
          ShimmerBox(width: 90, height: 90, borderRadius: 45),
          const SizedBox(height: 16),
          ShimmerBox(width: 160, height: 20, borderRadius: 8),
          const SizedBox(height: 10),
          ShimmerBox(width: 120, height: 14, borderRadius: 6),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ─── Profile info ─────────────────────────────────────────────────────────────

  Widget _buildProfileInfo(dynamic profile) {
    final phone = profile.phone as String?;
    final hasPhone = phone != null && phone.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        children: [
          // ── Avatar + camera badge ─────────────────────────────────────
          Stack(
            clipBehavior: Clip.none,
            children: [
              _isUploadingAvatar
                  ? Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey.shade200,
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                            color: primaryBlue, strokeWidth: 2),
                      ),
                    )
                  : CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: profile.avatarUrl != null
                          ? CachedNetworkImageProvider(profile.avatarUrl!)
                          : null,
                      child: profile.avatarUrl == null
                          ? Icon(
                              profile.isShop ? Icons.store : Icons.person,
                              size: 44,
                              color: Colors.grey.shade400,
                            )
                          : null,
                    ),

              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _isUploadingAvatar ? null : _openImageSourceSheet,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color:
                          _isUploadingAvatar ? Colors.grey : primaryBlue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt,
                        size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Username ──────────────────────────────────────────────────
          Text(
            profile.displayName,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          // ── Phone + eye toggle ────────────────────────────────────────
          if (hasPhone) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.phone_outlined,
                    size: 16, color: textSecondary),
                const SizedBox(width: 6),
                Text(
                  _phoneVisible ? phone : '••• ••• •••',
                  style:
                      const TextStyle(fontSize: 15, color: textPrimary),
                ),
                IconButton(
                  onPressed: _togglePhoneVisibility,
                  icon: Icon(
                    _phoneVisible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 18,
                    color: textSecondary,
                  ),
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],

          // ── GPS button ────────────────────────────────────────────────
          if (profile.hasLocation) ...[
            const SizedBox(height: 6),
            TextButton.icon(
              onPressed: () =>
                  _openInMaps(profile.latitude!, profile.longitude!),
              icon: const Icon(Icons.location_on_outlined,
                  size: 16, color: primaryBlue),
              label: const Text('Voir sur la carte',
                  style: TextStyle(color: primaryBlue, fontSize: 13)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
              ),
            ),
          ],

          // ── Rating ────────────────────────────────────────────────────
          if (profile.ratingCount > 0) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star_rounded,
                    color: warningColor, size: 18),
                const SizedBox(width: 4),
                Text(
                  profile.ratingAvg.toStringAsFixed(1),
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 4),
                Text(
                  '(${profile.ratingCount} avis)',
                  style: const TextStyle(
                      fontSize: 13, color: textSecondary),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
