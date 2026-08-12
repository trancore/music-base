class InternetRadioStation {
  const InternetRadioStation({
    required this.id,
    required this.name,
    required this.streamUrl,
    this.description,
    this.genre,
  });

  final String id;
  final String name;
  final String streamUrl;
  final String? description;
  final String? genre;

  InternetRadioStation copyWith({
    String? name,
    String? streamUrl,
    String? description,
    String? genre,
  }) {
    return InternetRadioStation(
      id: id,
      name: name ?? this.name,
      streamUrl: streamUrl ?? this.streamUrl,
      description: description ?? this.description,
      genre: genre ?? this.genre,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'streamUrl': streamUrl,
    'description': description,
    'genre': genre,
  };

  static InternetRadioStation? fromJson(Object? value) {
    if (value is! Map) return null;
    final id = value['id'];
    final name = value['name'];
    final streamUrl = value['streamUrl'];
    if (id is! String || name is! String || streamUrl is! String) return null;
    return InternetRadioStation(
      id: id,
      name: name,
      streamUrl: streamUrl,
      description: value['description'] as String?,
      genre: value['genre'] as String?,
    );
  }
}
