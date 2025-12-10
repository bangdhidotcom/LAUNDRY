class Layanan {
  final String id;
  final String nama;
  final int harga;
  final String satuan;
  final String deskripsi;

  Layanan({
    required this.id,
    required this.nama,
    required this.harga,
    required this.satuan,
    required this.deskripsi,
  });

  factory Layanan.fromJson(Map<String, dynamic> json) {
    return Layanan(
      id: json['id'],
      nama: json['nama'],
      harga: json['harga'],
      satuan: json['satuan'],
      deskripsi: json['deskripsi'],
    );
  }
}

class ItemPesanan {
  final String idLayanan;
  final String namaLayanan;
  final int jumlah;
  final int harga;

  ItemPesanan({
    required this.idLayanan,
    required this.namaLayanan,
    required this.jumlah,
    required this.harga,
  });

  Map<String, dynamic> toJson() => {
    'idLayanan': idLayanan,
    'namaLayanan': namaLayanan,
    'jumlah': jumlah,
    'harga': harga,
  };

  factory ItemPesanan.fromJson(Map<String, dynamic> json) {
    return ItemPesanan(
      idLayanan: json['idLayanan'],
      namaLayanan: json['namaLayanan'],
      jumlah: json['jumlah'],
      harga: json['harga'],
    );
  }
}

class Pesanan {
  final String id;
  final List<ItemPesanan> items;
  final int total;
  final String status;
  final String dibuatPada;
  final String? selesaiPada;
  final String alamatPenjemputan;
  final String tanggalPenjemputan;
  final String waktuPenjemputan;
  final String? catatan;
  final bool sudahDibayar;

  Pesanan({
    required this.id,
    required this.items,
    required this.total,
    required this.status,
    required this.dibuatPada,
    this.selesaiPada,
    required this.alamatPenjemputan,
    required this.tanggalPenjemputan,
    required this.waktuPenjemputan,
    this.catatan,
    required this.sudahDibayar,
  });

  factory Pesanan.fromJson(Map<String, dynamic> json) {
    var list = json['items'] as List;
    List<ItemPesanan> itemsList = list
        .map((i) => ItemPesanan.fromJson(i))
        .toList();

    return Pesanan(
      id: json['id'],
      items: itemsList,
      total: json['total'],
      status: json['status'],
      dibuatPada: json['dibuatPada'],
      selesaiPada: json['selesaiPada'],
      alamatPenjemputan: json['alamatPenjemputan'],
      tanggalPenjemputan: json['tanggalPenjemputan'],
      waktuPenjemputan: json['waktuPenjemputan'],
      catatan: json['catatan'],
      sudahDibayar: json['sudahDibayar'] ?? false,
    );
  }
}

class ProfilPelanggan {
  final String id;
  final String nama;
  final String telepon;
  final String alamat;
  final String? email;

  ProfilPelanggan({
    required this.id,
    required this.nama,
    required this.telepon,
    required this.alamat,
    this.email,
  });

  factory ProfilPelanggan.fromJson(Map<String, dynamic> json) {
    return ProfilPelanggan(
      id: json['id'],
      nama: json['nama'],
      telepon: json['telepon'],
      alamat: json['alamat'],
      email: json['email'],
    );
  }
}
