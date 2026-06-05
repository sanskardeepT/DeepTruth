class NewsItem {
  final String id;
  final String title;
  final String description;
  final String url;
  final String? imageUrl;
  final String source;
  final DateTime publishedAt;
  final String category;
  final String? aiSummary;
  final int? truthScore;

  const NewsItem({
    required this.id,
    required this.title,
    required this.description,
    required this.url,
    this.imageUrl,
    required this.source,
    required this.publishedAt,
    required this.category,
    this.aiSummary,
    this.truthScore,
  });

  factory NewsItem.fromNewsApiJson(Map<String, dynamic> json) {
    final sourceMap = json['source'] as Map<String, dynamic>? ?? {};
    return NewsItem(
      id:          json['url'] as String? ?? DateTime.now().toIso8601String(),
      title:       json['title']       as String? ?? 'Untitled',
      description: json['description'] as String? ?? '',
      url:         json['url']         as String? ?? '',
      imageUrl:    json['urlToImage']  as String?,
      source:      sourceMap['name']   as String? ?? 'Unknown',
      publishedAt: DateTime.tryParse(json['publishedAt']?.toString() ?? '') ?? DateTime.now(),
      category:    json['category']    as String? ?? 'general',
    );
  }

  factory NewsItem.fromGNewsJson(Map<String, dynamic> json) {
    final sourceMap = json['source'] as Map<String, dynamic>? ?? {};
    return NewsItem(
      id:          json['url'] as String? ?? DateTime.now().toIso8601String(),
      title:       json['title']       as String? ?? 'Untitled',
      description: json['description'] as String? ?? '',
      url:         json['url']         as String? ?? '',
      imageUrl:    json['image']       as String?,
      source:      sourceMap['name']   as String? ?? 'Unknown',
      publishedAt: DateTime.tryParse(json['publishedAt']?.toString() ?? '') ?? DateTime.now(),
      category:    'general',
    );
  }

  NewsItem copyWith({String? aiSummary, int? truthScore}) {
    return NewsItem(
      id:          id,
      title:       title,
      description: description,
      url:         url,
      imageUrl:    imageUrl,
      source:      source,
      publishedAt: publishedAt,
      category:    category,
      aiSummary:   aiSummary ?? this.aiSummary,
      truthScore:  truthScore ?? this.truthScore,
    );
  }

  Map<String, dynamic> toJson() => {
    'id':          id,
    'title':       title,
    'description': description,
    'url':         url,
    'imageUrl':    imageUrl,
    'source':      source,
    'publishedAt': publishedAt.toIso8601String(),
    'category':    category,
    'aiSummary':   aiSummary,
    'truthScore':  truthScore,
  };

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    return NewsItem(
      id:          json['id']          as String? ?? '',
      title:       json['title']       as String? ?? 'Untitled',
      description: json['description'] as String? ?? '',
      url:         json['url']         as String? ?? '',
      imageUrl:    json['imageUrl']    as String?,
      source:      json['source']      as String? ?? 'Unknown',
      publishedAt: DateTime.tryParse(json['publishedAt']?.toString() ?? '') ?? DateTime.now(),
      category:    json['category']    as String? ?? 'general',
      aiSummary:   json['aiSummary']   as String?,
      truthScore:  (json['truthScore'] as num?)?.toInt(),
    );
  }
}
