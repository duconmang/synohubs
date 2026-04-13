import 'dart:convert';
import 'dart:io';

/// TMDB API client for fetching movie/TV show poster and backdrop images.
///
/// Requires a free API key from https://www.themoviedb.org/settings/api
class TmdbService {
  static final TmdbService _instance = TmdbService._();
  static TmdbService get instance => _instance;
  TmdbService._();

  String? _apiKey;
  final Map<String, _TmdbResult?> _cache = {};

  void setApiKey(String key) => _apiKey = key;
  String? get apiKey => _apiKey;
  bool get isConfigured => _apiKey != null && _apiKey!.isNotEmpty;

  /// Get poster image URL (portrait, 500px wide) for a media file.
  Future<String?> getPosterUrl(String fileName) async {
    final result = await _getResult(fileName);
    return result?.posterUrl;
  }

  /// Get backdrop image URL (landscape, 1280px wide) for a media file.
  Future<String?> getBackdropUrl(String fileName) async {
    final result = await _getResult(fileName);
    return result?.backdropUrl;
  }

  /// Get the matched TMDB title for display purposes.
  Future<String?> getTmdbTitle(String fileName) async {
    final result = await _getResult(fileName);
    return result?.title;
  }

  /// Get rating (0-10) for the matched title.
  Future<double?> getRating(String fileName) async {
    final result = await _getResult(fileName);
    return result?.rating;
  }

  Future<_TmdbResult?> _getResult(String fileName) async {
    if (!isConfigured) return null;
    final query = parseMediaName(fileName);
    if (query.isEmpty) return null;
    if (_cache.containsKey(query)) return _cache[query];

    try {
      final result = await _searchTmdb(query);
      _cache[query] = result;
      return result;
    } catch (_) {
      _cache[query] = null;
      return null;
    }
  }

  /// Parse a media filename into a clean movie/show title for TMDB search.
  static String parseMediaName(String fileName) {
    var name = fileName;

    // Remove file extension
    final dotIdx = name.lastIndexOf('.');
    if (dotIdx > 0) {
      final ext = name.substring(dotIdx + 1).toLowerCase();
      if (ext.length <= 5) name = name.substring(0, dotIdx);
    }

    // Extract content before Season/Episode markers
    final seMatch = RegExp(
      r'[Ss]\d+\s*[Ee](?:[Pp][Ss]?\s*)?\d+',
    ).firstMatch(name);
    if (seMatch != null) {
      name = name.substring(0, seMatch.start);
    }
    // Also handle standalone "S01" at end
    name = name.replaceAll(RegExp(r'\b[Ss]eason\s*\d+\b'), '');
    name = name.replaceAll(RegExp(r'\b[Ss]\d+\s*$'), '');

    // Remove quality/source tags
    name = name.replaceAll(
      RegExp(
        r'\b(1080[pi]|720p|480p|2160p|4[Kk]|UHD|BluRay|Blu-Ray|WEB-DL|'
        r'WEBRip|WEB|HDRip|DVDRip|BRRip|HDTV|REMUX|x264|x265|h\.?264|'
        r'h\.?265|HEVC|AVC|AAC|DTS|AC3|FLAC|5\.1|7\.1|10bit|HDR|SDR|'
        r'IMAX|PROPER|REPACK|EXTENDED|UNRATED|DIRECTORS\.?CUT)\b',
        caseSensitive: false,
      ),
      '',
    );

    // Remove year in parentheses or standalone
    name = name.replaceAll(RegExp(r'\(\d{4}\)'), '');
    name = name.replaceAll(RegExp(r'\b(19|20)\d{2}\b'), '');

    // Replace dots, underscores, hyphens with spaces
    name = name.replaceAll(RegExp(r'[._\-]'), ' ');
    // Collapse whitespace and trim
    name = name.replaceAll(RegExp(r'\s+'), ' ').trim();
    // Remove trailing punctuation
    name = name.replaceAll(RegExp(r'[\s\-:]+$'), '').trim();

    return name;
  }

  Future<_TmdbResult?> _searchTmdb(String query) async {
    final uri = Uri.https('api.themoviedb.org', '/3/search/multi', {
      'api_key': _apiKey!,
      'query': query,
      'include_adult': 'false',
      'language': 'en-US',
      'page': '1',
    });

    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final request = await client.getUrl(uri);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) return null;

      final json = jsonDecode(body) as Map<String, dynamic>;
      final results = json['results'] as List? ?? [];
      if (results.isEmpty) return null;

      // Find best match: prefer movie/tv with a poster
      Map<String, dynamic>? best;
      for (final r in results) {
        final item = r as Map<String, dynamic>;
        final mediaType = item['media_type'] as String?;
        if (mediaType == 'movie' || mediaType == 'tv') {
          if (item['poster_path'] != null) {
            best = item;
            break;
          }
          best ??= item;
        }
      }
      best ??= results.first as Map<String, dynamic>;

      final posterPath = best['poster_path'] as String?;
      final backdropPath = best['backdrop_path'] as String?;

      return _TmdbResult(
        posterUrl: posterPath != null
            ? 'https://image.tmdb.org/t/p/w500$posterPath'
            : null,
        backdropUrl: backdropPath != null
            ? 'https://image.tmdb.org/t/p/w1280$backdropPath'
            : null,
        title: best['title'] as String? ?? best['name'] as String? ?? query,
        year: _extractYear(best),
        overview: best['overview'] as String? ?? '',
        rating: (best['vote_average'] as num?)?.toDouble() ?? 0,
      );
    } finally {
      client.close();
    }
  }

  String? _extractYear(Map<String, dynamic> item) {
    final date =
        item['release_date'] as String? ?? item['first_air_date'] as String?;
    if (date != null && date.length >= 4) return date.substring(0, 4);
    return null;
  }
}

class _TmdbResult {
  final String? posterUrl;
  final String? backdropUrl;
  final String title;
  final String? year;
  final String overview;
  final double rating;

  const _TmdbResult({
    this.posterUrl,
    this.backdropUrl,
    required this.title,
    this.year,
    this.overview = '',
    this.rating = 0,
  });
}
