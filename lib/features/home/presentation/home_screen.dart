import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../shared/models/product_model.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import 'widgets/filter_bottom_sheet.dart';
import 'widgets/native_ad_card.dart';
import 'widgets/product_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scrollCtrl = ScrollController();
  final List<ProductModel> _products = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _offset = 0;
  static const int _pageSize = 10;

  ProductFilter _filter = const ProductFilter();

  @override
  void initState() {
    super.initState();
    _loadMore();
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
      if (!_isLoading && _hasMore) _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      var query = SupabaseConfig.client
          .from('products')
          .select('*, profiles(id, full_name, avatar_url, account_type, shop_type, rating_avg, rating_count)');

      // Apply filters before ordering and ranging
      if (_filter.productType != 'all') {
        query = query.eq('product_type', _filter.productType);
      }
      if (_filter.originalOnly) {
        query = query.eq('is_original', true);
      }
      if (_filter.wilayas.isNotEmpty) {
        query = query.inFilter('wilaya', _filter.wilayas);
      }
      if (_filter.categoryItem != null) {
        query = query.eq('category_item', _filter.categoryItem!);
      } else if (_filter.categorySub != null) {
        query = query.eq('category_sub', _filter.categorySub!);
      } else if (_filter.categoryMain != null) {
        query = query.eq('category_main', _filter.categoryMain!);
      }

      final response = await query
          .order('published_at', ascending: false)
          .range(_offset, _offset + _pageSize - 1);
      final items = (response as List)
          .map((j) => ProductModel.fromJson(j as Map<String, dynamic>))
          .toList();

      setState(() {
        _products.addAll(items);
        _offset += items.length;
        _hasMore = items.length == _pageSize;
      });
    } catch (e) {
      debugPrint('Load products error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _products.clear();
      _offset = 0;
      _hasMore = true;
    });
    await _loadMore();
  }

  void _applyFilter(ProductFilter filter) {
    setState(() {
      _filter = filter;
      _products.clear();
      _offset = 0;
      _hasMore = true;
    });
    _loadMore();
  }

  void _openFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FilterBottomSheet(
        current: _filter,
        onApply: _applyFilter,
      ),
    );
  }

  List<dynamic> _buildFeedItems() {
    final items = <dynamic>[];
    for (int i = 0; i < _products.length; i++) {
      items.add(_products[i]);
      if ((i + 1) % 5 == 0) {
        items.add('ad');
      }
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final feedItems = _buildFeedItems();
    final crossAxisCount = AppSizes.gridCrossAxisCount(context);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: primaryBlue,
          child: CustomScrollView(
            controller: _scrollCtrl,
            slivers: [
              SliverAppBar(
                floating: true,
                snap: true,
                elevation: 0,
                backgroundColor:
                    Theme.of(context).scaffoldBackgroundColor,
                title: _buildLogo(context),
                actions: [
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.tune_rounded),
                        onPressed: _openFilter,
                        iconSize: 26,
                        constraints: const BoxConstraints(
                            minWidth: 48, minHeight: 48),
                      ),
                      if (_filter.wilayas.isNotEmpty ||
                          _filter.productType != 'all' ||
                          _filter.originalOnly ||
                          _filter.hasCategory)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: primaryPink,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              if (_products.isEmpty && _isLoading)
                SliverPadding(
                  padding: const EdgeInsets.all(8),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => const ProductCardShimmer(),
                      childCount: 6,
                    ),
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1 / 1.6,
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, index) {
                      if (index >= feedItems.length) {
                        return _isLoading
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: primaryBlue),
                                ),
                              )
                            : const SizedBox(height: 80);
                      }

                      final item = feedItems[index];
                      if (item == 'ad') {
                        return const NativeAdCard();
                      }

                      final product = item as ProductModel;
                      final isFirstInPair = index % 2 == 0;
                      final nextItem =
                          index + 1 < feedItems.length
                              ? feedItems[index + 1]
                              : null;

                      if (isFirstInPair) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: ProductCard(
                                  product: product,
                                  index: index,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (nextItem is ProductModel)
                                Expanded(
                                  child: ProductCard(
                                    product: nextItem,
                                    index: index + 1,
                                  ),
                                )
                              else
                                const Expanded(child: SizedBox()),
                            ],
                          ),
                        );
                      }
                      // Odd-indexed products are rendered as part of the previous even-index row
                      return const SizedBox.shrink();
                    },
                    childCount: feedItems.length + 1,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: brandGradient,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'assets/images/lebesty_logo.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Center(
                child: Text('LB',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        ShaderMask(
          shaderCallback: (bounds) => brandGradient.createShader(bounds),
          child: const Text(
            'Lebesty',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          ),
        ),
      ],
    );
  }
}
