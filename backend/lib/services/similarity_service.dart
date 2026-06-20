class SimilarityService {
  // Türkçe ve İngilizce stop word'ler — anlamsız kelimeler
  static const Set<String> _stopWords = {
    'bir', 've', 'bu', 'da', 'de', 'için', 'ile', 'olan',
 'şu', 'o', 'biz', 'siz', 'onlar', 'ben', 'sen', 'ama',
    'ya', 'ki', 'mi', 'mu', 'mı', 'mü', 'ne', 'hem', 'veya',
    'gibi', 'kadar', 'daha', 'en', 'çok', 'az', 'her', 'hiç',
    'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at',
    'to', 'for', 'of', 'with', 'by', 'from', 'is', 'are', 'was',
    'it', 'its', 'be', 'as', 'this', 'that', 'these',
  };

  /// Metni normalize eder: küçük harf, Türkçe karakter koruması, noktalama temizliği
  static String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll('İ', 'i')
        .replaceAll('I', 'ı')
        .replaceAll(RegExp(r'[^\wğüşıöçĞÜŞİÖÇ\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Metni anlamlı kelimelere böler, stop word'leri ve kısa kelimeleri atar
  static List<String> _tokenize(String text) {
    return _normalize(text)
        .split(' ')
        .where((w) => w.length > 2 && !_stopWords.contains(w))
        .toList();
  }

  /// TF (Term Frequency): kelime, metinde kaç kez geçiyor / toplam kelime sayısı
  static Map<String, double> _computeTF(List<String> tokens) {
    final tf = <String, double>{};
    if (tokens.isEmpty) return tf;

    for (final token in tokens) {
      tf[token] = (tf[token] ?? 0) + 1;
    }

    // Normalize: her sayıyı toplam kelime sayısına böl
    final total = tokens.length.toDouble();
    tf.updateAll((key, value) => value / total);
    return tf;
  }

  /// IDF (Inverse Document Frequency): kelime ne kadar nadir?
  /// Nadir kelimeler daha yüksek ağırlık alır.
  /// IDF = log(toplam belge / kelimeyi içeren belge sayısı + 1)
  static Map<String, double> _computeIDF(List<List<String>> allTokenLists) {
    final idf = <String, double>{};
    final docCount = allTokenLists.length.toDouble();

    // Her kelimenin kaç belgede geçtiğini say
    final docFrequency = <String, int>{};
    for (final tokens in allTokenLists) {
      for (final token in tokens.toSet()) {
        docFrequency[token] = (docFrequency[token] ?? 0) + 1;
      }
    }

    // IDF hesapla
    docFrequency.forEach((term, count) {
      idf[term] = _log2(docCount / (count + 1)) + 1;
    });

    return idf;
  }

  /// Basit log2 implementasyonu
  static double _log2(double x) {
    if (x <= 0) return 0;
    // log2(x) = ln(x) / ln(2)
    // Dart'ta dart:math import olmadığı için Newton yaklaşımı kullan
    return _ln(x) / _ln(2.0);
  }

  /// Doğal logaritma (Taylor serisi ile yaklaşım)
  static double _ln(double x) {
    if (x <= 0) return double.negativeInfinity;
    if (x == 1.0) return 0.0;

    // ln(x) hesaplamak için iteratif yaklaşım
    // y = (x - 1) / (x + 1), ln(x) ≈ 2 * (y + y^3/3 + y^5/5 + ...)
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

  /// TF-IDF vektörü oluşturur: her kelime için TF × IDF değeri
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

  /// Cosine Similarity: iki vektör arasındaki açının cosinüsü
  /// 1.0 = tamamen aynı yön (çok benzer), 0.0 = dik açı (hiç benzer değil)
  /// cos(θ) = (A · B) / (|A| × |B|)
  static double _cosineSimilarity(
    Map<String, double> vec1,
    Map<String, double> vec2,
  ) {
    if (vec1.isEmpty || vec2.isEmpty) return 0.0;

    // Nokta çarpım (dot product): A · B
    double dotProduct = 0.0;
    for (final term in vec1.keys) {
      if (vec2.containsKey(term)) {
        dotProduct += vec1[term]! * vec2[term]!;
      }
    }

    // Vektör büyüklükleri (magnitude): |A| ve |B|
    double mag1 = 0.0;
    for (final v in vec1.values) mag1 += v * v;
    mag1 = _sqrt(mag1);

    double mag2 = 0.0;
    for (final v in vec2.values) mag2 += v * v;
    mag2 = _sqrt(mag2);

    if (mag1 == 0 || mag2 == 0) return 0.0;
    return dotProduct / (mag1 * mag2);
  }

  /// Karekök (Newton-Raphson yöntemi)
  static double _sqrt(double x) {
    if (x < 0) return 0;
    if (x == 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 50; i++) {
      final next = (guess + x / guess) / 2;
      if ((next - guess).abs() < 1e-12) return next;
      guess = next;
    }
    return guess;
  }

  /// Shingle (n-gram) Jaccard benzerliği — Mevcut yaklaşım (yedek olarak tutuluyor)
  static double _jaccardSimilarity(String text1, String text2) {
    Set<String> createShingles(String text, {int size = 3}) {
      final words = _tokenize(text);
      final shingles = <String>{};
      for (int i = 0; i <= words.length - size; i++) {
        shingles.add(words.sublist(i, i + size).join(' '));
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

  /// Ana fonksiyon: TF-IDF Cosine + Jaccard hibrit benzerlik skoru
  ///
  /// Neden hibrit?
  /// - TF-IDF Cosine: kelime önemine göre içerik benzerliği (ağırlık: %70)
  /// - Jaccard: kelime sırası ve ifade benzerliği (ağırlık: %30)
  /// İkisini birleştirmek hem içerik hem yapı benzerliğini yakalar.
  static double calculateSimilarity(String text1, String text2) {
    final tokens1 = _tokenize(text1);
    final tokens2 = _tokenize(text2);

    // Her iki metin de çok kısaysa direkt Jaccard kullan
    if (tokens1.length < 4 || tokens2.length < 4) {
      return _jaccardSimilarity(text1, text2);
    }

    // IDF'i her iki metin üzerinden hesapla (corpus = bu 2 belge)
    final idf = _computeIDF([tokens1, tokens2]);

    // TF-IDF vektörleri
    final vec1 = _computeTFIDF(tokens1, idf);
    final vec2 = _computeTFIDF(tokens2, idf);

    // Cosine benzerliği
    final cosineSim = _cosineSimilarity(vec1, vec2);

    // Jaccard benzerliği (yapısal destek)
    final jaccardSim = _jaccardSimilarity(text1, text2);

    // Hibrit skor: %70 cosine + %30 jaccard
    return (cosineSim * 0.70) + (jaccardSim * 0.30);
  }

  /// Çoklu not karşılaştırması için optimize edilmiş versiyon.
  /// IDF'i tüm corpus üzerinden bir kez hesaplar — verimli.
  static double calculateSimilarityWithCorpus(
    String newText,
    String existingText,
    List<String> allCorpusTexts,
  ) {
    final allTokenLists = allCorpusTexts.map(_tokenize).toList();
    final newTokens = _tokenize(newText);
    final existingTokens = _tokenize(existingText);

    if (newTokens.length < 4 || existingTokens.length < 4) {
      return _jaccardSimilarity(newText, existingText);
    }

    // IDF'i tüm corpus üzerinden hesapla (daha doğru)
    final idf = _computeIDF([...allTokenLists, newTokens]);

    final vec1 = _computeTFIDF(newTokens, idf);
    final vec2 = _computeTFIDF(existingTokens, idf);

    final cosineSim = _cosineSimilarity(vec1, vec2);
    final jaccardSim = _jaccardSimilarity(newText, existingText);

    return (cosineSim * 0.70) + (jaccardSim * 0.30);
  }
}