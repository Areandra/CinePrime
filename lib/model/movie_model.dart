class MovieModel {
  final String? id;
  final String? judul;
  final String? ringkasan;
  final String? gambarPoster;
  final String? gambarSampul;
  final int? tanggalRilis; // Disimpan dalam format Unix Timestamp (integer)
  final double? skorRating;
  final String? kategori;
  final String? urlTrailer;

  MovieModel({
    this.id,
    this.judul,
    this.ringkasan,
    this.gambarPoster,
    this.gambarSampul,
    this.tanggalRilis,
    this.skorRating,
    this.kategori,
    this.urlTrailer,
  });

  // Mengubah JSON dari API menjadi Objek Model (Digunakan saat READ)
  factory MovieModel.fromJson(Map<String, dynamic> json) {
    return MovieModel(
      id: json['id']?.toString(),
      judul: json['judul'],
      ringkasan: json['ringkasan'],
      gambarPoster: json['gambar_poster'],
      gambarSampul: json['gambar_sampul'],
      tanggalRilis: json['tanggal_rilis'] != null
          ? (json['tanggal_rilis'] is num
                ? (json['tanggal_rilis'] as num).toInt()
                : int.tryParse(json['tanggal_rilis'].toString()))
          : null,
      skorRating: json['skor_rating'] != null
          ? (json['skor_rating'] is num
                ? (json['skor_rating'] as num).toDouble()
                : double.tryParse(json['skor_rating'].toString()))
          : null,
      kategori: json['kategori'],
      urlTrailer: json['url_trailer'],
    );
  }

  // Mengubah Objek Model menjadi JSON (Digunakan saat CREATE & UPDATE)
  Map<String, dynamic> toJson() {
    return {
      'judul': judul,
      'ringkasan': ringkasan,
      'gambar_poster': gambarPoster,
      'gambar_sampul': gambarSampul,
      'tanggal_rilis': tanggalRilis,
      'skor_rating': skorRating,
      'kategori': kategori,
      'url_trailer': urlTrailer,
    };
  }
}
