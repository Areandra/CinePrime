import 'package:flutter/material.dart';
import '../controller/movie_controller.dart';
import '../model/movie_model.dart';

class MovieFormView extends StatefulWidget {
  final MovieModel? movie;
  MovieFormView({this.movie});

  @override
  State<MovieFormView> createState() => _MovieFormViewState();
}

class _MovieFormViewState extends State<MovieFormView>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final MovieController _controller = MovieController();

  late TextEditingController _judulC, _ringkasanC, _kategoriC, _ratingC;
  late TextEditingController _posterC, _sampulC, _trailerC;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isSaving = false;
  double _ratingValue = 0;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _judulC = TextEditingController(text: widget.movie?.judul ?? "");
    _ringkasanC = TextEditingController(text: widget.movie?.ringkasan ?? "");
    _kategoriC = TextEditingController(text: widget.movie?.kategori ?? "");
    _ratingC = TextEditingController(
      text: widget.movie?.skorRating != null
          ? (widget.movie!.skorRating! <= 10
                    ? widget.movie!.skorRating
                    : (widget.movie!.skorRating! / 10))
                ?.toString()
          : "",
    );
    _posterC = TextEditingController(text: widget.movie?.gambarPoster ?? "");
    _sampulC = TextEditingController(text: widget.movie?.gambarSampul ?? "");
    _trailerC = TextEditingController(text: widget.movie?.urlTrailer ?? "");

    if (widget.movie?.skorRating != null) {
      _ratingValue =
          double.tryParse(
            (widget.movie!.skorRating! <= 10
                    ? widget.movie!.skorRating
                    : (widget.movie!.skorRating! / 10))
                .toString(),
          ) ??
          0;
    }

    if (widget.movie?.tanggalRilis != null) {
      _selectedDate = DateTime.fromMillisecondsSinceEpoch(
        widget.movie!.tanggalRilis! * 1000,
      );
    }

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
    _animationController.forward();
  }

  @override
  void dispose() {
    _judulC.dispose();
    _ringkasanC.dispose();
    _kategoriC.dispose();
    _ratingC.dispose();
    _posterC.dispose();
    _sampulC.dispose();
    _trailerC.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // ── Bangun MovieModel dari isian form ─────────────────────────────────────
  MovieModel _buildMovieFromForm() {
    return MovieModel(
      id: widget.movie?.id,
      judul: _judulC.text.trim(),
      ringkasan: _ringkasanC.text.trim(),
      kategori: _kategoriC.text.trim(),
      skorRating: _ratingValue,
      gambarPoster: _posterC.text.trim(),
      gambarSampul: _sampulC.text.trim(),
      tanggalRilis: _selectedDate != null
          ? (_selectedDate!.millisecondsSinceEpoch ~/ 1000)
          : null,
      urlTrailer: _trailerC.text.trim().isEmpty ? null : _trailerC.text.trim(),
    );
  }

  // ── Handler simpan: CREATE atau UPDATE lewat controller ───────────────────
  void _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final movie = _buildMovieFromForm();
    bool success;
    String successMsg;
    String errorMsg;

    if (widget.movie == null) {
      success = await _controller.createMovie(movie);
      successMsg = 'Film berhasil ditambahkan!';
      errorMsg = 'Gagal menambahkan film. Coba lagi.';
    } else {
      success = await _controller.updateMovie(widget.movie!.id!, movie);
      successMsg = 'Film berhasil diperbarui!';
      errorMsg = 'Gagal memperbarui film. Coba lagi.';
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      _showSnackBar(
        message: successMsg,
        icon: widget.movie == null ? Icons.check_circle : Icons.edit,
        isError: false,
      );
      Navigator.pop(context, true);
    } else {
      _showSnackBar(
        message: errorMsg,
        icon: Icons.error_outline,
        isError: true,
      );
    }
  }

  void _showSnackBar({
    required String message,
    required IconData icon,
    required bool isError,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: isError
            ? Colors.red.shade800
            : const Color(0xFF1F2229),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 100, 20, 40),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderSection(),
                  const SizedBox(height: 32),

                  // Judul
                  _buildPremiumInput(
                    controller: _judulC,
                    label: 'Movie Title',
                    hint: 'Enter movie title...',
                    icon: Icons.movie_creation,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Please enter movie title'
                        : null,
                  ),
                  const SizedBox(height: 20),

                  // Kategori
                  _buildPremiumInput(
                    controller: _kategoriC,
                    label: 'Category',
                    hint: 'Action, Comedy, Drama...',
                    icon: Icons.category,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Please enter category'
                        : null,
                  ),
                  const SizedBox(height: 20),

                  // Rating
                  _buildRatingSection(),
                  const SizedBox(height: 20),

                  // Ringkasan
                  _buildPremiumInput(
                    controller: _ringkasanC,
                    label: 'Synopsis',
                    hint: 'Write movie synopsis...',
                    icon: Icons.auto_stories,
                    maxLines: 5,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Please enter synopsis'
                        : null,
                  ),
                  const SizedBox(height: 20),

                  // URL Poster
                  _buildPremiumInput(
                    controller: _posterC,
                    label: 'Poster URL',
                    hint: 'https://example.com/poster.jpg',
                    icon: Icons.image,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Please enter poster URL'
                        : null,
                  ),
                  // Preview poster
                  if (_posterC.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _posterC.text,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 150,
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Text(
                                  'Invalid image URL',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // URL Sampul
                  _buildPremiumInput(
                    controller: _sampulC,
                    label: 'Cover/Backdrop URL',
                    hint: 'https://example.com/backdrop.jpg',
                    icon: Icons.wallpaper,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Please enter cover URL'
                        : null,
                  ),
                  // Preview sampul
                  if (_sampulC.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _sampulC.text,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 150,
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Text(
                                  'Invalid image URL',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Tanggal Rilis
                  _buildDatePicker(),
                  const SizedBox(height: 20),

                  // URL Trailer
                  _buildPremiumInput(
                    controller: _trailerC,
                    label: 'Trailer URL (Optional)',
                    hint: 'https://youtube.com/watch?v=...',
                    icon: Icons.play_circle,
                    validator: (v) {
                      if (v != null && v.trim().isNotEmpty) {
                        final uri = Uri.tryParse(v.trim());
                        if (uri == null || !uri.hasScheme) {
                          return 'Please enter a valid URL';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 40),

                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF0A0E17).withOpacity(0.95),
      elevation: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.amber, Colors.orange],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              widget.movie == null ? Icons.add : Icons.edit,
              size: 20,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            widget.movie == null ? 'Add Movie' : 'Edit Movie',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white70, size: 22),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.withOpacity(0.1),
            Colors.orange.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.amber, Colors.orange],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              widget.movie == null
                  ? Icons.add_photo_alternate
                  : Icons.edit_note,
              size: 32,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.movie == null ? 'Create New Movie' : 'Update Movie',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.movie == null
                      ? 'Add a new movie to your collection'
                      : 'Modify movie information',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: Colors.amber),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            height: 1.5,
          ),
          cursorColor: Colors.amber,
          validator: validator,
          onChanged: (value) {
            // Trigger rebuild untuk preview gambar
            if (controller == _posterC || controller == _sampulC) {
              setState(() {});
            }
          },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 14,
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.amber, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.red.withOpacity(0.5)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.star, size: 16, color: Colors.amber),
              ),
              const SizedBox(width: 8),
              const Text(
                'Rating',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _ratingValue = (index + 1).toDouble();
                        _ratingC.text = _ratingValue.toInt().toString();
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        index < _ratingValue ? Icons.star : Icons.star_border,
                        size: 36,
                        color: index < _ratingValue
                            ? Colors.amber
                            : Colors.white.withOpacity(0.2),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _ratingValue > 0
                      ? '${_ratingValue.toString()} / 5'
                      : 'Tap to rate',
                  style: TextStyle(
                    color: _ratingValue > 0
                        ? Colors.amber
                        : Colors.white.withOpacity(0.4),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              TextFormField(
                controller: _ratingC,
                style: const TextStyle(color: Colors.transparent, fontSize: 1),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
                validator: (v) {
                  if (v == null || v.isEmpty || int.tryParse(v) == null) {
                    return 'Please select a rating';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Release Date',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _selectedDate ?? DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              builder: (context, child) {
                return Theme(
                  data: ThemeData.dark().copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: Colors.amber,
                      onPrimary: Colors.black,
                      surface: Color(0xFF1F2229),
                      onSurface: Colors.white,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (date != null) {
              setState(() {
                _selectedDate = date;
              });
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.event,
                  color: _selectedDate != null
                      ? Colors.amber
                      : Colors.white.withOpacity(0.3),
                ),
                const SizedBox(width: 12),
                Text(
                  _selectedDate != null
                      ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                      : 'Select release date...',
                  style: TextStyle(
                    color: _selectedDate != null
                        ? Colors.white
                        : Colors.white.withOpacity(0.3),
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                _controller.deleteMovie(widget.movie!.id!);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.black,
                disabledBackgroundColor: Colors.amber.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: _isSaving ? 0 : 4,
                shadowColor: Colors.amber.withOpacity(0.4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [Icon(Icons.delete, size: 20)],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                disabledBackgroundColor: Colors.amber.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: _isSaving ? 0 : 4,
                shadowColor: Colors.amber.withOpacity(0.4),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.movie == null ? Icons.add : Icons.save,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.movie == null ? 'Add Movie' : 'Update Movie',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
