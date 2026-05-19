import 'package:flutter/material.dart';
import '../controller/movie_controller.dart';
import '../model/movie_model.dart';
import 'detail_view.dart';

class MovieSearchView extends StatefulWidget {
  @override
  State<MovieSearchView> createState() => _MovieSearchViewState();
}

class _MovieSearchViewState extends State<MovieSearchView>
    with SingleTickerProviderStateMixin {
  final MovieController _controller = MovieController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<MovieModel> _allMovies = [];
  List<MovieModel> _searchResult = [];
  List<String> _recentSearches = [];
  bool _isSearching = false;
  bool _isLoading = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // ── Daftar kategori dengan ikon & warna ──────────────────────────────────
  final List<Map<String, dynamic>> _categoryMeta = [
    {
      'name': 'Action',
      'icon': Icons.local_fire_department,
      'color': Colors.red,
    },
    {'name': 'Comedy', 'icon': Icons.emoji_emotions, 'color': Colors.orange},
    {'name': 'Drama', 'icon': Icons.theater_comedy, 'color': Colors.purple},
    {'name': 'Sci-Fi', 'icon': Icons.rocket_launch, 'color': Colors.blue},
    {'name': 'Horror', 'icon': Icons.nightlight_round, 'color': Colors.grey},
    {'name': 'Romance', 'icon': Icons.favorite, 'color': Colors.pink},
  ];

  // Kategori dari API (dinamis)
  List<String> _apiCategories = [];
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _loadData();
    _animationController.forward();

    _searchFocusNode.addListener(() {
      setState(() {
        _isSearching = _searchFocusNode.hasFocus;
      });
    });
  }

  void _loadData() async {
    try {
      final data = await _controller.getAllMovies();
      // Ambil kategori unik dari data API
      final Set<String> cats = {};
      for (final m in data) {
        if (m.kategori != null && m.kategori!.isNotEmpty) {
          cats.add(m.kategori!);
        }
      }
      setState(() {
        _allMovies = data;
        _searchResult = [];
        _apiCategories = cats.toList()..sort();
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  // ── Logika pencarian: cocokkan judul ATAU kategori ────────────────────────
  void _onSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _searchResult = [];
      } else {
        final q = query.toLowerCase();
        _searchResult = _allMovies.where((m) {
          final judulMatch = (m.judul ?? '').toLowerCase().contains(q);
          final kategoriMatch = (m.kategori ?? '').toLowerCase().contains(q);
          return judulMatch || kategoriMatch;
        }).toList();

        // Simpan ke recent searches
        if (!_recentSearches.contains(query)) {
          _recentSearches.insert(0, query);
          if (_recentSearches.length > 5) _recentSearches.removeLast();
        }
      }
    });
  }

  // ── Klik kategori dari grid langsung filter ───────────────────────────────
  void _searchByCategory(String categoryName) {
    _searchController.text = categoryName;
    _onSearch(categoryName);
    _searchFocusNode.unfocus();
  }
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.amber,
                strokeWidth: 2,
              ),
            )
          : _searchController.text.isEmpty
          ? _buildSearchSuggestions()
          : _searchResult.isEmpty
          ? _buildEmptyState()
          : _buildSearchResults(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF0A0E17).withOpacity(0.95),
      elevation: 0,
      title: Container(
        height: 45,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: _isSearching
                ? Colors.amber.withOpacity(0.5)
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          onChanged: _onSearch,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          cursorColor: Colors.amber,
          decoration: InputDecoration(
            hintText: "Cari judul atau kategori film...",
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 16,
            ),
            prefixIcon: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                Icons.search,
                color: _isSearching
                    ? Colors.amber
                    : Colors.white.withOpacity(0.5),
                size: 22,
              ),
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white54,
                      size: 20,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      _onSearch('');
                      _searchFocusNode.unfocus();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSuggestions() {
    // Gabungkan kategori dari API dengan fallback ke _categoryMeta
    final List<Map<String, dynamic>> displayCategories = [];
    for (final meta in _categoryMeta) {
      displayCategories.add(meta);
    }
    // Tambah kategori dari API yang belum ada di _categoryMeta
    for (final cat in _apiCategories) {
      final alreadyExists = _categoryMeta.any(
        (m) => (m['name'] as String).toLowerCase() == cat.toLowerCase(),
      );
      if (!alreadyExists) {
        displayCategories.add({
          'name': cat,
          'icon': Icons.movie_outlined,
          'color': Colors.teal,
        });
      }
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 80), // Space for app bar
            // Popular Searches — dari kategori API
            if (_apiCategories.isNotEmpty) ...[
              _buildSectionHeader(
                icon: Icons.trending_up,
                title: 'Popular Searches',
                gradient: const [Colors.red, Colors.orange],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _apiCategories.map((cat) {
                  return _buildSuggestionChip(
                    cat,
                    isPopular: true,
                    onTap: () => _searchByCategory(cat),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
            ],

            // Recent Searches
            if (_recentSearches.isNotEmpty) ...[
              _buildSectionHeader(
                icon: Icons.history,
                title: 'Recent Searches',
                gradient: const [Colors.blue, Colors.purple],
                trailing: TextButton(
                  onPressed: () {
                    setState(() => _recentSearches.clear());
                  },
                  child: const Text(
                    'Clear All',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...List.generate(_recentSearches.length, (index) {
                return _buildRecentSearchItem(_recentSearches[index]);
              }),
              const SizedBox(height: 32),
            ],

            // Browse Categories
            _buildSectionHeader(
              icon: Icons.category,
              title: 'Browse Categories',
              gradient: const [Colors.green, Colors.teal],
            ),
            const SizedBox(height: 16),
            _buildCategoryGrid(displayCategories),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required List<Color> gradient,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradient),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const Spacer(),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildSuggestionChip(
    String label, {
    bool isPopular = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isPopular
              ? LinearGradient(
                  colors: [
                    Colors.amber.withOpacity(0.15),
                    Colors.orange.withOpacity(0.1),
                  ],
                )
              : null,
          color: isPopular ? null : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPopular
                ? Colors.amber.withOpacity(0.3)
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isPopular) ...[
              const Icon(
                Icons.local_fire_department,
                size: 16,
                color: Colors.amber,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isPopular ? Colors.amber : Colors.white70,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSearchItem(String search) {
    return GestureDetector(
      onTap: () {
        _searchController.text = search;
        _onSearch(search);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            Icon(Icons.history, size: 18, color: Colors.white.withOpacity(0.4)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                search,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _recentSearches.remove(search);
                });
              },
              child: Icon(
                Icons.close,
                size: 16,
                color: Colors.white.withOpacity(0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Category Grid — klik langsung filter ──────────────────────────────────
  Widget _buildCategoryGrid(List<Map<String, dynamic>> categories) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final name = category['name'] as String;
        final color = category['color'] as Color;
        final icon = category['icon'] as IconData;
        return GestureDetector(
          onTap: () => _searchByCategory(name),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: AnimatedOpacity(
        opacity: 1.0,
        duration: const Duration(milliseconds: 500),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Icon(
                Icons.movie_creation_outlined,
                size: 50,
                color: Colors.white.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Film Tidak Ditemukan',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coba kata kunci atau kategori lain',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                _searchController.clear();
                _onSearch('');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Clear Search',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Results Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.search,
                      size: 18,
                      color: Colors.amber,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Ditemukan ${_searchResult.length} film',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Results Grid
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.65,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    _buildMovieCard(_searchResult[index], index),
                childCount: _searchResult.length,
              ),
            ),
          ),

          // Bottom Padding
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildMovieCard(MovieModel movie, int index) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              MovieDetailView(movie: movie),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Hero(
                tag: 'search_${movie.id}_$index',
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          movie.gambarPoster!,
                          fit: BoxFit.cover,
                          frameBuilder:
                              (context, child, frame, wasSynchronouslyLoaded) {
                                if (wasSynchronouslyLoaded) return child;
                                return AnimatedOpacity(
                                  opacity: frame == null ? 0 : 1,
                                  duration: const Duration(milliseconds: 500),
                                  child: child,
                                );
                              },
                        ),
                        // Gradient overlay
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(20),
                                bottomRight: Radius.circular(20),
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withOpacity(0.8),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Rating badge
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.amber.withOpacity(0.5),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 12,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${movie.skorRating ?? '-'}',
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                movie.judul ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                movie.kategori ?? '',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
