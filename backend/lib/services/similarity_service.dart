class SimilarityService {
  static const Set<String> _stopWords = {
    'bir', 've', 'bu', 'da', 'de', 'için', 'ile', 'olan',
    'şu', 'o', 'biz', 'siz', 'onlar', 'ben', 'sen', 'ama',
    'ya', 'ki', 'mi', 'mu', 'mı', 'mü', 'ne', 'hem', 'veya',
    'gibi', 'kadar', 'daha', 'en', 'çok', 'az', 'her', 'hiç',
    'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at',
    'to', 'for', 'of', 'with', 'by', 'from', 'is', 'are', 'was',
    'it', 'its', 'be', 'as', 'this', 'that', 'these',
  };

  static String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll('İ', 'i')
        .replaceAll('I', 'ı')
        .replaceAll(RegExp(r'[^\wğüşıöçĞÜŞİÖÇ\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static List<String> _tokenize(String text) {
    return _normalize(text)
        .split(' ')
        .where((w) => w.length > 2 && !_stopWords.contains(w))
        .toList();
  }

  static Map<String, double> _computeTF(List<String> tokens) {
    final tf = <String, double>{};
    if (tokens.isEmpty) return tf;
    for (final token in tokens) {
      tf[token] = (tf[token] ?? 0) + 1;
    }
    final total = tokens.length.toDouble();
    tf.updateAll((key, value) => value / total);
    return tf;
  }

  static Map<String, double> _computeIDF(List<List<String>> allTokenLists) {
    final idf = <String, double>{};
    final docCount = allTokenLists.length.toDouble();
    final docFrequency = <String, int>{};
    for (final tokens in allTokenLists) {
      for (final token in tokens.toSet()) {
        docFrequency[token] = (docFrequency[token] ?? 0) + 1;
      }
    }
    docFrequency.forEach((term, count) {
      idf[term] = _log2(docCount / (count + 1)) + 1;
    });
    return idf;
  }

  static double _log2(double x) {
    if (x <= 0) return 0;
    return _ln(x) / _ln(2.0);
  }

  static double _ln(double x) {
    if (x <= 0) return double.negativeInfinity;
    if (x == 1.0) return 0.0;
    double y = (x - 1) / (x + 1);
    double result = 0;
    double term = y;
    for (int i = 0; i < 50; i++) {
      result += term / (2 * i + 1);
      term *= y * y;
      if (term.abs() < 1e-12) break;
    }
    return 2 * result;
  }

  static Map<String, double> _computeTFIDF(
    List<String> tokens,
    Map<String, double> idf,
  ) {
    final tf = _computeTF(tokens);
    final tfidf = <String, double>{};
    tf.forEach((term, tfValue) {
      tfidf[term] = tfValue * (idf[term] ?? 1.0);
    });
    return tfidf;
  }

  static double _cosineSimilarity(
    Map<String, double> vec1,
    Map<String, double> vec2,
  ) {
    if (vec1.isEmpty || vec2.isEmpty) return 0.0;
    double dotProduct = 0.0;
    for (final term in vec1.keys) {
      if (vec2.containsKey(term)) {
        dotProduct += vec1[term]! * vec2[term]!;
      }
    }
    double mag1 = 0.0;
    for (final v in vec1.values) mag1 += v * v;
    mag1 = _sqrt(mag1);

    double mag2 = 0.0;
    for (final v in vec2.values) mag2 += v * v;
    mag2 = _sqrt(mag2);

    if (mag1 == 0 || mag2 == 0) return 0.0;
    return dotProduct / (mag1 * mag2);
  }

  static double _sqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 50; i++) {
      final next = (guess + x / guess) / 2;
      if ((next - guess).abs() < 1e-12) return next;
      guess = next;
    }
    return guess;
  }

  // --- DÜZELTME 1: Shingle size 3 → 2 ---
  // 3-gram çok sıkı; birkaç satır silince ortak 3-gram sayısı dramatik düşer.
  // 2-gram daha toleranslı ve kısmi örtüşmeyi daha iyi yakalar.
  static double _jaccardSimilarity(String text1, String text2,
      {int shingleSize = 2}) {
    Set<String> createShingles(String text) {
      final words = _tokenize(text);
      final shingles = <String>{};
      for (int i = 0; i <= words.length - shingleSize; i++) {
        shingles.add(words.sublist(i, i + shingleSize).join(' '));
      }
      return shingles;
    }

    final set1 = createShingles(text1);
    final set2 = createShingles(text2);
    if (set1.isEmpty || set2.isEmpty) return 0.0;

    final intersection = set1.intersection(set2).length;
    final union = set1.union(set2).length;
    return intersection / union;
  }

  // --- DÜZELTME 2: Sadece TF (IDF'siz) cosine ---
  // 2 belgelik corpus'ta IDF gürültü yaratır. Saf TF cosine ile ortak
  // kelimelerin frekansını doğrudan karşılaştırmak çok daha güvenilir.
  static double _tfCosineSimilarity(String text1, String text2) {
    final tokens1 = _tokenize(text1);
    final tokens2 = _tokenize(text2);
    if (tokens1.isEmpty || tokens2.isEmpty) return 0.0;

    final tf1 = _computeTF(tokens1);
    final tf2 = _computeTF(tokens2);
    return _cosineSimilarity(tf1, tf2);
  }

  /// Corpus büyüklüğüne göre adaptif hibrit benzerlik
  static double calculateSimilarity(String text1, String text2) {
    final tokens1 = _tokenize(text1);
    final tokens2 = _tokenize(text2);

    if (tokens1.length < 4 || tokens2.length < 4) {
      return _jaccardSimilarity(text1, text2);
    }

    // Az belgede IDF'siz cosine + daha hassas 2-gram Jaccard
    final cosineSim = _tfCosineSimilarity(text1, text2);
    final jaccardSim = _jaccardSimilarity(text1, text2);
    return (cosineSim * 0.60) + (jaccardSim * 0.40);
  }

  /// --- ANA DÜZELTME ---
  /// Corpus belgesi 5'ten azsa TF-IDF yerine TF cosine kullan.
  /// Corpus büyüdükçe TF-IDF'e kademeli geçiş yap.
  static double calculateSimilarityWithCorpus(
    String newText,
    String existingText,
    List<String> allCorpusTexts,
  ) {
    final newTokens = _tokenize(newText);
    final existingTokens = _tokenize(existingText);

    if (newTokens.length < 4 || existingTokens.length < 4) {
      return _jaccardSimilarity(newText, existingText);
    }

    final jaccardSim = _jaccardSimilarity(newText, existingText);

    // Corpus çok küçükse (< 5 belge): saf TF cosine
    // IDF bu durumda ayırt edici değil, aksine ortak kelimelere
    // düşük ağırlık vererek benzerliği yapay olarak düşürür.
    if (allCorpusTexts.length < 5) {
      final cosineSim = _tfCosineSimilarity(newText, existingText);
      return (cosineSim * 0.60) + (jaccardSim * 0.40);
    }

    // Corpus yeterliyse TF-IDF cosine kullan (orijinal mantık, düzgün çalışır)
    final allTokenLists = allCorpusTexts.map(_tokenize).toList();
    final idf = _computeIDF([...allTokenLists, newTokens]);

    final vec1 = _computeTFIDF(newTokens, idf);
    final vec2 = _computeTFIDF(existingTokens, idf);
    final cosineSim = _cosineSimilarity(vec1, vec2);

    return (cosineSim * 0.70) + (jaccardSim * 0.30);
  }
}