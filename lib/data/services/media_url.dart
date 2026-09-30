import '../../core/constants/api_config.dart';

bool _isAnimatedMediaUrl(String url) {
  final uri = Uri.tryParse(url);
  final path = (uri?.path ?? url).toLowerCase();
  final nested = uri?.queryParameters['url']?.toLowerCase() ?? '';
  return path.endsWith('.gif') ||
      path.endsWith('.webp') ||
      path.endsWith('.apng') ||
      nested.endsWith('.gif') ||
      nested.endsWith('.webp') ||
      nested.contains('.gif');
}

/// Construit l'URL d'affichage d'un média signe.
///
/// Les GIF hébergés hors origine (ex. corpus-lsfb.be) n'envoient pas de
/// en-têtes CORS : sur le web ils échouent. On les passe par le proxy
/// backend `/api/media/proxy` qui renvoie le vrai fichier + cache disque.
String resolveSignMediaUrl(String? url) {
  if (url == null || url.trim().isEmpty) return '';
  final trimmed = url.trim();
  final uri = Uri.tryParse(trimmed);
  if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
    return trimmed;
  }

  if (uri.path.contains('/api/media/proxy')) return trimmed;

  final api = Uri.tryParse(ApiConfig.baseUrl);
  if (api != null && uri.host == api.host) return trimmed;

  if (_isAnimatedMediaUrl(trimmed) || uri.host.contains('corpus-lsfb')) {
    return Uri.parse(ApiConfig.baseUrl).replace(
      path: '/api/media/proxy',
      queryParameters: {'url': trimmed},
    ).toString();
  }
  return trimmed;
}
