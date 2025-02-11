class SearchFilters {
  SearchFilters({
    this.categories = const [],
    this.priceRange,
    this.rating,
    this.distance,
    this.sortBy = 'relevance',
    this.openNow = false,
  });

  final List<String> categories;
  final String? priceRange;
  final double? rating;
  final double? distance;
  final String sortBy;
  final bool openNow;

  SearchFilters copyWith({
    List<String>? categories,
    String? priceRange,
    double? rating,
    double? distance,
    String? sortBy,
    bool? openNow,
  }) {
    return SearchFilters(
      categories: categories ?? this.categories,
      priceRange: priceRange ?? this.priceRange,
      rating: rating ?? this.rating,
      distance: distance ?? this.distance,
      sortBy: sortBy ?? this.sortBy,
      openNow: openNow ?? this.openNow,
    );
  }

  Map<String, dynamic> toJson() => {
        'categories': categories,
        'priceRange': priceRange,
        'rating': rating,
        'distance': distance,
        'sortBy': sortBy,
        'openNow': openNow,
      };

  factory SearchFilters.fromJson(Map<String, dynamic> json) => SearchFilters(
        categories: List<String>.from(json['categories'] as List? ?? []),
        priceRange: json['priceRange'] as String?,
        rating: json['rating'] as double?,
        distance: json['distance'] as double?,
        sortBy: json['sortBy'] as String? ?? 'relevance',
        openNow: json['openNow'] as bool? ?? false,
      );
}
