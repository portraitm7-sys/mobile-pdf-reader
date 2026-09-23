class PdfItem {
  const PdfItem({
    required this.id,
    required this.name,
    required this.path,
    required this.addedAt,
    required this.lastOpenedAt,
    required this.sizeBytes,
    this.lastPage = 1,
    this.isFavorite = false,
  });

  final String id;
  final String name;
  final String path;
  final DateTime addedAt;
  final DateTime lastOpenedAt;
  final int sizeBytes;
  final int lastPage;
  final bool isFavorite;

  PdfItem copyWith({
    String? id,
    String? name,
    String? path,
    DateTime? addedAt,
    DateTime? lastOpenedAt,
    int? sizeBytes,
    int? lastPage,
    bool? isFavorite,
  }) {
    return PdfItem(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      addedAt: addedAt ?? this.addedAt,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      lastPage: lastPage ?? this.lastPage,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'path': path,
        'addedAt': addedAt.toIso8601String(),
        'lastOpenedAt': lastOpenedAt.toIso8601String(),
        'sizeBytes': sizeBytes,
        'lastPage': lastPage,
        'isFavorite': isFavorite,
      };

  factory PdfItem.fromJson(Map<String, dynamic> json) {
    return PdfItem(
      id: json['id'] as String,
      name: json['name'] as String,
      path: json['path'] as String,
      addedAt: DateTime.parse(json['addedAt'] as String),
      lastOpenedAt: DateTime.parse(json['lastOpenedAt'] as String),
      sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
      lastPage: (json['lastPage'] as num?)?.toInt() ?? 1,
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }
}
