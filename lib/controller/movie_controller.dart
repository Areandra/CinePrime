import 'dart:convert';
import 'package:rest_client/rest_client.dart' as rc;
import '../model/movie_model.dart';

class MovieController {
  // Base URL API asli dari Bapak Dosen
  static const String _baseUrl =
      'https://68ff8dfbe02b16d1753e765d.mockapi.io/film';

  // Header standar untuk komunikasi JSON
  static const Map<String, String> _headers = {
    "Content-Type": "application/json",
  };

  // Inisialisasi Client murni sesuai konstruktor v2.4.0 Anda
  final rc.Client _client = rc.Client();

  // 1. READ (Ambil Semua Data Film)
  Future<List<MovieModel>> getAllMovies() async {
    try {
      final response = await _client.execute(
        request: rc.Request(
          url: _baseUrl,
          method: rc.RequestMethod.get,
          headers: _headers,
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.body as List<dynamic>;
        return data
            .map((item) => MovieModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(
          'Gagal memuat data film. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Gagal terhubung ke server: $e');
    }
  }

  // 2. CREATE (Tambah Film Baru)
  Future<bool> createMovie(MovieModel movie) async {
    try {
      final response = await _client.execute(
        request: rc.Request(
          url: _baseUrl,
          method: rc.RequestMethod.post,
          headers: _headers,
          // Mengubah JSON Map menjadi String sesuai permintaan 'String? body'
          body: jsonEncode(movie.toJson()),
        ),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // 3. UPDATE (Ubah Data Film)
  Future<bool> updateMovie(String id, MovieModel movie) async {
    try {
      final response = await _client.execute(
        request: rc.Request(
          url: '$_baseUrl/$id',
          method: rc.RequestMethod.put,
          headers: _headers,
          body: jsonEncode(movie.toJson()),
        ),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // 4. DELETE (Hapus Film)
  Future<bool> deleteMovie(String id) async {
    try {
      final response = await _client.execute(
        request: rc.Request(
          url: '$_baseUrl/$id',
          method: rc.RequestMethod.delete,
          headers: _headers,
        ),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Future<List<String>> getCategories() async {
  //   try {
  //     // Panggil getAllMovies untuk mendapatkan semua data
  //     final List<MovieModel> movies = await getAllMovies();

  //     // Ambil semua kategori, masukkan ke dalam Set untuk menghapus duplikat
  //     final Set<String> categories = {};

  //     for (var movie in movies) {
  //       // Asumsi: di MovieModel ada properti 'category' atau 'genre'
  //       // Sesuaikan dengan nama field di model Anda (misalnya: movie.category)
  //       if (movie.kategori != null && movie.kategori!.isNotEmpty) {
  //         final category = movie.kategori!
  //             .split(',')
  //             .map((c) => c.trim())
  //             .where((c) => c.isNotEmpty);
  //         categories.addAll(category);
  //       }
  //     }

  //     // Kembalikan sebagai List
  //     return categories.toList();
  //   } catch (e) {
  //     // Jika gagal, kembalikan list kosong atau lempar error
  //     return [];
  //   }
  // }
}
