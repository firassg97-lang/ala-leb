import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../shared/models/profile_model.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../../../shared/widgets/rating_stars.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchCtrl = TextEditingController();
  List<ProfileModel> _results = [];
  List<Map<String, dynamic>> _topShops = [];
  bool _isSearching = false;
  bool _isLoadingShops = true;

  @override
  void initState() {
    super.initState();
    _loadTopShops();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTopShops() async {
    try {
      final data = await SupabaseConfig.client
          .from('profiles')
          .select()
          .eq('account_type', 'shop')
          .gte('rating_count', 7)
          .order('rating_avg', ascending: false)
          .limit(10);
      setState(() {
        _topShops = List<Map<String, dynamic>>.from(data as List);
        _isLoadingShops = false;
      });
    } catch (e) {
      setState(() => _isLoadingShops = false);
    }
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    try {
      final data = await SupabaseConfig.client
          .from('profiles')
          .select()
          .or('username.ilike.%$query%,shop_name.ilike.%$query%')
          .limit(10);
      setState(() {
        _results = (data as List)
            .map((j) => ProfileModel.fromJson(j as Map<String, dynamic>))
            .toList();
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = _searchCtrl.text.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recherche'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: hasQuery
                ? _buildSearchResults()
                : _buildDefaultContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchCtrl,
        autofocus: false,
        onChanged: _search,
        decoration: InputDecoration(
          hintText: 'Rechercher boutiques et utilisateurs...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _results = []);
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: dividerColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: dividerColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: primaryBlue, width: 2),
          ),
          filled: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return ListView.builder(
        itemCount: 5,
        itemBuilder: (_, i) => const ListItemShimmer(),
      );
    }

    if (_results.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 64, color: textSecondary),
            SizedBox(height: 16),
            Text('Aucun résultat trouvé', style: TextStyle(color: textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (_, i) {
        final profile = _results[i];
        return ListTile(
          leading: CircleAvatar(
            radius: 24,
            backgroundImage: profile.avatarUrl != null
                ? CachedNetworkImageProvider(profile.avatarUrl!)
                : null,
            child: profile.avatarUrl == null
                ? const Icon(Icons.person)
                : null,
          ),
          title: Text(profile.displayName),
          subtitle: Text(
            profile.isShop ? '🏪 Boutique • ${profile.wilaya}' : '👤 Utilisateur',
            style: const TextStyle(fontSize: 12, color: textSecondary),
          ),
          trailing: profile.isShop && profile.ratingAvg > 0
              ? RatingStars(
                  rating: profile.ratingAvg,
                  count: profile.ratingCount,
                  size: 14,
                )
              : null,
          onTap: () => context.push('/user/${profile.id}'),
        ).animate().fadeIn(delay: Duration(milliseconds: i * 50));
      },
    );
  }

  Widget _buildDefaultContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              '🏆 Top 10 Boutiques',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          _buildTopShopsSection(),
        ],
      ),
    );
  }

  Widget _buildTopShopsSection() {
    if (_isLoadingShops) {
      return SizedBox(
        height: 140,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 5,
          itemBuilder: (_, i) => Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ShimmerBox(width: 100, height: 140, borderRadius: 16),
          ),
        ),
      );
    }

    if (_topShops.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Aucune boutique disponible pour le moment',
          style: TextStyle(color: textSecondary),
        ),
      );
    }

    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _topShops.length,
        itemBuilder: (_, i) {
          final shop = _topShops[i];
          final avatar = shop['avatar_url'] as String?;
          final name = shop['full_name'] as String? ?? 'Boutique';
          final ratingAvg = (shop['rating_avg'] as num?)?.toDouble() ?? 0.0;
          final ratingCount = shop['rating_count'] as int? ?? 0;
          final id = shop['id'] as String;

          return GestureDetector(
            onTap: () => context.push('/user/$id'),
            child: Container(
              width: 110,
              margin: const EdgeInsets.only(right: 12),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: avatar != null
                        ? CachedNetworkImageProvider(avatar)
                        : null,
                    backgroundColor: primaryBlue.withOpacity(0.1),
                    child: avatar == null
                        ? const Icon(Icons.store, size: 36, color: primaryBlue)
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  RatingStars(
                    rating: ratingAvg,
                    count: ratingCount,
                    size: 12,
                    showCount: true,
                  ),
                ],
              ),
            ).animate().fadeIn(delay: Duration(milliseconds: i * 60)),
          );
        },
      ),
    );
  }
}
