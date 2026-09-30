/// Tampon d'épellation côté client : assemble lettres / space / del en phrase.
///
/// Utilisé si le serveur ne gère pas la session, ou pour des tests purs Dart.
class SpellingBuffer {
  SpellingBuffer({
    this.minHold = 2,
    this.cooldown = const Duration(milliseconds: 450),
    this.threshold = 0.55,
  });

  /// Nombre de frames stables avant de valider une lettre.
  final int minHold;

  /// Délai minimum avant de recommiter la même lettre.
  final Duration cooldown;

  /// Confiance minimale pour accepter une prédiction.
  final double threshold;

  final List<String> _chars = [];
  String? _pending;
  int _hold = 0;
  String? _lastCommitted;
  DateTime? _lastAt;

  String get text {
    final s = _chars.join();
    if (s.endsWith(' ')) return '${s.trimRight()} ';
    return s;
  }
  /// Met à jour le tampon avec une prédiction frame.
  /// Retourne la lettre réellement commitée, ou null.
  String? update(String? label, double confidence) {
    final accepted =
        label != null && label.isNotEmpty && confidence >= threshold && label.toLowerCase() != 'nothing';
    if (!accepted) {
      _pending = null;
      _hold = 0;
      return null;
    }

    if (label != _pending) {
      _pending = label;
      _hold = 1;
    } else {
      _hold++;
    }
    if (_hold < minHold) return null;

    final now = DateTime.now();
    final low = label.toLowerCase();
    if (_lastCommitted == label &&
        low != 'del' &&
        low != 'space' &&
        _lastAt != null &&
        now.difference(_lastAt!) < cooldown) {
      return null;
    }

    _apply(label);
    _lastCommitted = label;
    _lastAt = now;
    _pending = null;
    _hold = 0;
    return label;
  }

  void _apply(String label) {
    final low = label.toLowerCase();
    if (low == 'nothing') return;
    if (low == 'del') {
      if (_chars.isNotEmpty) _chars.removeLast();
      return;
    }
    if (low == 'space') {
      if (_chars.isEmpty || _chars.last == ' ') return;
      _chars.add(' ');
      return;
    }
    final letter = label.trim().toUpperCase();
    if (letter.isEmpty) return;
    _chars.add(letter[0]);
  }

  void reset() {
    _chars.clear();
    _pending = null;
    _hold = 0;
    _lastCommitted = null;
    _lastAt = null;
  }
}
