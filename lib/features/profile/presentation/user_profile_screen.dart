import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../shared/models/product_model.dart';
import '../../../shared/models/profile_model.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../../../shared/widgets/rating_stars.dart';
import '../../home/presentation/widgets/native_ad_card.dart';
import '../../home/presentation/widgets/product_card.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  final String userId;
  const UserProfileScreen({super.key, required this.userId});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  final _scrollCtrl = ScrollController();

  ProfileModel? _profile;
  final List<ProductModel> _products = [];
  bool _isLoadingProfile = true;
  bool _isLoadingProducts = true;
  bool _hasMore = true;
  int _offset = 0;

  // Rating state
  int? _myRating; // null = not rated yet
  int _selectedRating = 0; // live star selection
  bool _isEditingRating = false; // true when modifying existing rating
  bool _isSubmittingRating = false;

  @override
  void initState() {
    super.initState();
    _load();
    _scrollCtrl.addListener(_onScroll);
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

  // ─── Data loading ────────────────────────────────────────────────────────────

  Future<void> _load() async {
    try {
      final profileData = await SupabaseConfig.client
          .from('profiles')
          .select()
          .eq('id', widget.userId)
          .single();
      if (mounted) {
        setState(() {
          _profile = ProfileModel.fromJson(profileData);
          _isLoadingProfile = false;
        });
      }
      await Future.wait([_loadProducts(), _loadMyRating()]);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
          _isLoadingProducts = false;
        });
      }
    }
  }

  Future<void> _loadProducts() async {
    try {
      final data = await SupabaseConfig.client
          .from('products')
          .select(
              '*, profiles(id, full_name, avatar_url, account_type, shop_type, rating_avg, rating_count)')
          .eq('owner_id', widget.userId)
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

  Future<void> _loadMyRating() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;
    try {
      final data = await SupabaseConfig.client
          .from('ratings')
          .select()
          .eq('rater_id', currentUser.id)
          .eq('rated_id', widget.userId)
          .maybeSingle();
      if (data != null && mounted) {
        final score = data['score'] as int? ?? data['rating'] as int?;
        setState(() {
          _myRating = score;
          _selectedRating = score ?? 0;
        });
      }
    } catch (_) {}
  }

  // ─── Chat ────────────────────────────────────────────────────────────────────

  Future<void> _openChat() async {
    final user = ref.read(currentUserProvider);
    if (user == null || _profile == null) return;
    try {
      final existing = await SupabaseConfig.client
          .from('conversations')
          .select()
          .or('and(participant1_id.eq.${user.id},participant2_id.eq.${widget.userId}),and(participant1_id.eq.${widget.userId},participant2_id.eq.${user.id})')
          .maybeSingle();

      String convId;
      if (existing != null) {
        convId = existing['id'] as String;
      } else {
        final created = await SupabaseConfig.client
            .from('conversations')
            .insert({
              'participant1_id': user.id,
              'participant2_id': widget.userId,
            })
            .select()
            .single();
        convId = created['id'] as String;
      }
      if (mounted) {
        context.push('/chat/$convId', extra: {
          'otherUserId': widget.userId,
          'otherUserName': _profile?.displayName ?? 'Utilisateur',
          'otherUserAvatar': _profile?.avatarUrl,
        });
      }
    } catch (e) {
      debugPrint('Open chat error: $e');
    }
  }

  // ─── Maps ────────────────────────────────────────────────────────────────────

  void _openInMaps(double lat, double lng) {
    launchUrl(
        Uri.parse(
            'https://www.google.com/maps/search/?api=1&query=$lat,$lng'),
        mode: LaunchMode.externalApplication);
  }

  // ─── Rating ──────────────────────────────────────────────────────────────────

  Future<void> _submitRating() async {
    if (_selectedRating == 0) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isSubmittingRating = true);
    try {
      await SupabaseConfig.client.from('ratings').upsert(
        {
          'rater_id': user.id,
          'rated_id': widget.userId,
          'score': _selectedRating,
        },
        onConflict: 'rater_id,rated_id',
      );
      if (mounted) {
        setState(() {
          _myRating = _selectedRating;
          _isEditingRating = false;
          _isSubmittingRating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Évaluation soumise avec succès !'),
            backgroundColor: Colors.green));
      }
      // Refresh profile to get updated avg
      final profileData = await SupabaseConfig.client
          .from('profiles')
          .select()
          .eq('id', widget.userId)
          .single();
      if (mounted) {
        setState(() => _profile = ProfileModel.fromJson(profileData));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmittingRating = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: errorColor));
      }
    }
  }

  // ─── Feed builder ─────────────────────────────────────────────────────────────

  List<dynamic> _buildFeedItems() {
    final items = <dynamic>[];
    for (int i = 0; i < _products.length; i++) {
      items.add(_products[i]);
      if ((i + 1) % 5 == 0) items.add('ad');
    }
    return items;
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProfile) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: primaryBlue)),
      );
    }
    if (_profile == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Profil non trouvé')),
      );
    }

    final profile = _profile!;
    final feedItems = _buildFeedItems();
    final currentUser = ref.read(currentUserProvider);
    final isOwnProfile = currentUser?.id == widget.userId;
    final crossAxis = AppSizes.gridCrossAxisCount(context);

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollCtrl,
        slivers: [
          // ── App bar ──────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            floating: false,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            scrolledUnderElevation: 1,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 18),
              onPressed: () => context.pop(),
            ),
          ),

          // ── Profile info ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _buildProfileInfo(context, profile, isOwnProfile),
          ),

          // ── Products shimmer ─────────────────────────────────────────────
          if (_isLoadingProducts && _products.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.all(8),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => const ProductCardShimmer(),
                  childCount: 4,
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxis,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1 / 1.6,
                ),
              ),
            )

          // ── Empty state ──────────────────────────────────────────────────
          else if (!_isLoadingProducts && _products.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.inventory_2_outlined,
                        size: 64, color: textSecondary),
                    SizedBox(height: 16),
                    Text('Aucun article publié',
                        style: TextStyle(color: textSecondary)),
                  ],
                ),
              ),
            )

          // ── Products grid with ads ───────────────────────────────────────
          else
            SliverPadding(
              padding: const EdgeInsets.all(8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, index) {
                    if (index >= feedItems.length) return null;
                    final item = feedItems[index];
                    if (item == 'ad') {
                      return const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: NativeAdCard());
                    }
                    final product = item as ProductModel;
                    final nextItem = index + 1 < feedItems.length
                        ? feedItems[index + 1]
                        : null;
                    if (index % 2 == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                                child: ProductCard(
                                    product: product, index: index)),
                            const SizedBox(width: 8),
                            nextItem is ProductModel
                                ? Expanded(
                                    child: ProductCard(
                                        product: nextItem,
                                        index: index + 1))
                                : const Expanded(child: SizedBox()),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                  childCount: feedItems.length,
                ),
              ),
            ),

          // ── Pagination loader / end spacer ───────────────────────────────
          SliverToBoxAdapter(
            child: _isLoadingProducts && _products.isNotEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: primaryBlue)),
                  )
                : const SizedBox(height: 80),
          ),
        ],
      ),
    );
  }

  // ─── Profile info widget ─────────────────────────────────────────────────────

  Widget _buildProfileInfo(
      BuildContext context, ProfileModel profile, bool isOwnProfile) {
    final phone = profile.phone;
    final hasPhone = phone != null && phone.isNotEmpty && profile.phoneVisible;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Avatar (read-only) ─────────────────────────────────────────
          CircleAvatar(
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
          const SizedBox(height: 16),

          // ── Name ──────────────────────────────────────────────────────
          Text(
            profile.displayName,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          // ── Phone (respects owner's phoneVisible flag) ────────────────
          if (hasPhone) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.phone_outlined,
                    size: 16, color: textSecondary),
                const SizedBox(width: 6),
                Text(phone,
                    style: const TextStyle(
                        fontSize: 15, color: textPrimary)),
              ],
            ),
          ],

          // ── GPS button ────────────────────────────────────────────────
          if (profile.hasLocation) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () =>
                  _openInMaps(profile.latitude!, profile.longitude!),
              icon: const Icon(Icons.location_on_outlined,
                  size: 16, color: primaryBlue),
              label: const Text('Voir sur la carte',
                  style: TextStyle(color: primaryBlue, fontSize: 13)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: primaryBlue),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
              ),
            ),
          ],

          // ── Rating display ────────────────────────────────────────────
          if (profile.ratingAvg > 0) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star_rounded, color: warningColor, size: 18),
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

          // ── Interactive rating (visitor only, not own profile) ─────────
          if (!isOwnProfile) ...[
            const SizedBox(height: 16),
            _buildRatingSection(),
          ],

          // ── Message button ────────────────────────────────────────────
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openChat,
              icon: const Icon(Icons.chat_bubble_outline,
                  color: Colors.white, size: 18),
              label: const Text('Envoyer un message',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
        ],
      ),
    );
  }

  // ─── Rating section widget ───────────────────────────────────────────────────

  Widget _buildRatingSection() {
    final hasRated = _myRating != null && !_isEditingRating;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          if (hasRated) ...[
            // ── Already rated — show + edit option ───────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Votre note : ',
                    style: TextStyle(
                        color: textSecondary, fontSize: 13)),
                ...List.generate(
                  5,
                  (i) => Icon(
                    i < _myRating!
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: warningColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() {
                    _selectedRating = _myRating!;
                    _isEditingRating = true;
                  }),
                  child: const Text(
                    'Modifier',
                    style: TextStyle(
                        color: primaryBlue,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ] else ...[
            // ── Not yet rated (or editing) ───────────────────────────
            Text(
              _myRating != null
                  ? 'Modifier votre évaluation'
                  : 'Évaluer cette boutique',
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            // Interactive stars
            InteractiveRatingStars(
              initialRating: _selectedRating,
              size: 40,
              onRatingChanged: (r) => setState(() => _selectedRating = r),
            ),

            // Submit button — appears after a star is tapped
            if (_selectedRating > 0) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      _isSubmittingRating ? null : _submitRating,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding:
                        const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: _isSubmittingRating
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(
                          _myRating != null
                              ? 'Mettre à jour l\'évaluation'
                              : 'Évaluer cette boutique',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
