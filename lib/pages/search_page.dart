import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

class ProfileModel {
  final String id;
  final String? username;
  final String language;
  final String wilaya;
  final String accountType;
  final String? phone;
  final String? avatarUrl;
  final String? shopType;
  final double? shopLat;
  final double? shopLng;
  final double ratingAvg;
  final int ratingCount;
  final DateTime createdAt;

  const ProfileModel({
    required this.id,
    this.username,
    required this.language,
    required this.wilaya,
    required this.accountType,
    this.phone,
    this.avatarUrl,
    this.shopType,
    this.shopLat,
    this.shopLng,
    this.ratingAvg = 0.0,
    this.ratingCount = 0,
    required this.createdAt,
  });

  bool get isShop => accountType == 'shop';
  bool get hasLocation => shopLat != null && shopLng != null;
  String get displayName => username ?? 'Utilisateur';

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      username: json['username'] as String?,
      language: json['language'] as String? ?? 'fr',
      wilaya: json['wilaya'] as String? ?? '',
      accountType: json['account_type'] as String? ?? 'user',
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      shopType: json['shop_type'] as String?,
      shopLat: (json['shop_lat'] as num?)?.toDouble(),
      shopLng: (json['shop_lng'] as num?)?.toDouble(),
      ratingAvg: (json['rating_avg'] as num?)?.toDouble() ?? 0.0,
      ratingCount: (json['rating_count'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
      highlightColor:
          isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF5F5F5),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class ListItemShimmer extends StatelessWidget {
  const ListItemShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
      highlightColor:
          isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF5F5F5),
      child: ListTile(
        leading: Container(
          width: 56,
          height: 56,
          decoration:
              const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        ),
        title: Container(height: 12, color: Colors.white),
        subtitle: Container(
            height: 10, margin: const EdgeInsets.only(top: 4), color: Colors.white),
      ),
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
              style: TextStyle(
                  fontSize: size * 0.75, color: Colors.grey)),
        ],
      ],
    );
  }
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
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
      final supabase = Supabase.instance.client;
      final data = await supabase
          .from('profiles')
          .select()
          .eq('account_type', 'shop')
          .gte('rating_count', 7)
          .order('rating_avg', ascending: false)
          .limit(10);
      final shops = (data as List)
          .map((j) => ProfileModel.fromJson(j as Map<String, dynamic>))
          .toList();
      setState(() {
        _topShops = shops.map((p) => {
          'id': p.id,
          'username': p.username,
          'avatar_url': p.avatarUrl,
          'account_type': p.accountType,
          'shop_type': p.shopType,
          'rating_avg': p.ratingAvg,
          'rating_count': p.ratingCount,
          'wilaya': p.wilaya,
        }).toList();
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
      final supabase = Supabase.instance.client;
      final data = await supabase
          .from('profiles')
          .select()
          .ilike('username', '%$query%')
          .limit(10);
      final results = (data as List)
          .map((j) => ProfileModel.fromJson(j as Map<String, dynamic>))
          .toList();
      setState(() {
        _results = results;
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
          final name = shop['username'] as String? ?? 'Boutique';
          final ratingAvg = double.tryParse(shop['rating_avg']?.toString() ?? '0') ?? 0.0;
          final ratingCount = shop['rating_count'] as int? ?? 0;
          final id = shop['id'] as String;

          return GestureDetector(
            onTap: () => context.push('/user/$id'),
            child: Container(
              width: 110,
              margin: const EdgeInsets.only(right: 12),
              // Safety net: scales the content down only if it would overflow
              // the fixed card; renders identically when it fits.
              child: LayoutBuilder(builder: (context, constraints) {
                return FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
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
                  ),
                );
              }),
            ).animate().fadeIn(delay: Duration(milliseconds: i * 60)),
          );
        },
      ),
    );
  }
}
