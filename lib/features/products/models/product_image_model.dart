class ProductImageData {
  final String id;
  final String productId;
  final String imageUrl;
  final String publicId;
  final bool isPrimary;
  final DateTime createdAt;

  ProductImageData({
    this.id = '',
    required this.productId,
    required this.imageUrl,
    this.publicId = '',
    this.isPrimary = false,
    required this.createdAt,
  });

  factory ProductImageData.fromJson(Map<String, dynamic> json) {
    // list response uses "url", detail endpoint uses "image_url"
    final url = json['image_url']?.toString() ?? json['url']?.toString() ?? '';

    return ProductImageData(
      id: json['id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      imageUrl: url,
      publicId: json['public_id']?.toString() ?? '',
      isPrimary:
          json['is_primary'] == true ||
          json['is_primary'] ==
              1 // ← backend returns int 0/1
              ||
          json['isPrimary'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  ProductImageData copyWith({
    String? id,
    String? productId,
    String? imageUrl,
    String? publicId,
    bool? isPrimary,
    DateTime? createdAt,
  }) {
    return ProductImageData(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      imageUrl: imageUrl ?? this.imageUrl,
      publicId: publicId ?? this.publicId,
      isPrimary: isPrimary ?? this.isPrimary,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
