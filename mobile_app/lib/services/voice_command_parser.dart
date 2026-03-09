enum VoiceCommand {
  navigateHome,
  navigateLearn,
  navigateGames,
  navigateProfile,
  navigateQuiz, // New command for Quiz tab
  navigateBack,
  // Interaction Commands (Confirmation)
  select,
  confirm,
  // Specific Item Selection (Fusion / Voice-Only)
  selectById,
  selectByLabel,
  // Input Mode Commands
  setModeStandard,
  setModeDwell,
  setModeEyeGaze,
  setModeVoice,
  unknown,
}

class VoiceCommandParser {
  // Threshold for fuzzy matching (0.0 to 1.0)
  // 0.8 means 80% similarity required
  static const double _fuzzyThreshold = 0.75;

  /// Holds the parsed identifier (ID or Label) for selection commands
  static dynamic lastParsedData;

  static VoiceCommand parse(String text) {
    text = text.toLowerCase().trim();
    if (text.isEmpty) return VoiceCommand.unknown;
    lastParsedData = null;

    // 1. Check for Numeric IDs (High Priority)
    // Supports English digits and common Sinhala number sounds
    final idMatch = RegExp(r'(\d+)').firstMatch(text);
    if (idMatch != null) {
      lastParsedData = int.tryParse(idMatch.group(1)!);
      if (lastParsedData != null) return VoiceCommand.selectById;
    }

    // Sinhala phonetic numbers (1-5)
    if (text.contains('එක') || text.contains('eka')) {
      lastParsedData = 1;
      return VoiceCommand.selectById;
    }
    if (text.contains('දෙක') || text.contains('deka')) {
      lastParsedData = 2;
      return VoiceCommand.selectById;
    }
    if (text.contains('තුන') || text.contains('thuna')) {
      lastParsedData = 3;
      return VoiceCommand.selectById;
    }
    if (text.contains('හතර') || text.contains('hathara')) {
      lastParsedData = 4;
      return VoiceCommand.selectById;
    }
    if (text.contains('පහ') || text.contains('paha')) {
      lastParsedData = 5;
      return VoiceCommand.selectById;
    }

    // --- Input Mode Commands ---
    if (_matches(text, [
      'standard',
      'normal',
      'samanya',
      'touch',
      'සාමාන්‍ය',
      'ටච්',
      'නෝමල්',
    ])) {
      return VoiceCommand.setModeStandard;
    }
    if (_matches(text, [
      'dwell',
      'auto click',
      'obagena',
      'dwell mode',
      'ඔබගෙන',
      'ඩුවෙල්',
      'ඔටෝ',
    ])) {
      return VoiceCommand.setModeDwell;
    }
    if (_matches(text, [
      'eye',
      'gaze',
      'vision',
      'as',
      'ඇස්',
      'බලන්',
      'ගේස්',
    ])) {
      return VoiceCommand.setModeEyeGaze;
    }
    if (_matches(text, [
      'voice mode',
      'katahanda',
      'katha',
      'input voice',
      'කටහඬ',
      'වොයිස්',
    ])) {
      return VoiceCommand.setModeVoice;
    }

    // --- Navigation Commands ---
    if (_matches(text, [
      'home',
      'මුල් පිටුව',
      'gedara',
      'dashboard',
      'හොම්',
      'ප්‍රධාන',
    ])) {
      return VoiceCommand.navigateHome;
    }
    if (_matches(text, [
      'learn',
      'පාඩම්',
      'padam',
      'ඉගෙනීම',
      'ලර්න්',
      'පාඩම',
    ])) {
      return VoiceCommand.navigateLearn;
    }
    if (_matches(text, [
      'games',
      'සෙල්ලම්',
      'sallam',
      'ක්‍රීඩා',
      'ගේම්ස්',
      'සෙල්ලම',
    ])) {
      return VoiceCommand.navigateGames;
    }
    if (_matches(text, [
      'quiz',
      'prashna',
      'questions',
      'ප්‍රශ්න',
      'විභාග',
      'exam',
      'ක්විස්',
    ])) {
      return VoiceCommand.navigateQuiz;
    }
    if (_matches(text, [
      'profile',
      'පරිශීලක',
      'මම',
      'ප්‍රෝෆයිල්',
      'මා',
      'ගිණුම',
    ])) {
      return VoiceCommand.navigateProfile;
    }
    if (_matches(text, [
      'back',
      'පසුපසට',
      'pannata',
      'out',
      'අයින්',
      'පස්සට',
    ])) {
      return VoiceCommand.navigateBack;
    }

    // --- Interactive Selection (The "Fusion" Triggers) ---
    if (_matches(text, [
      'select',
      'click',
      'open',
      'go',
      'thama',
      'yanna',
      'එබුවා',
      'යන්න',
      'සෙලෙක්ට්',
      'යමු',
    ])) {
      return VoiceCommand.select;
    }
    if (_matches(text, [
      'confirm',
      'yes',
      'hari',
      'ehemayi',
      'ඕකේ',
      'හරි',
      'ඔව්',
      'කන්ෆර්ම්',
    ])) {
      return VoiceCommand.confirm;
    }

    // --- Fallback: Semantic Label Matching ---
    // If it's not a known command, it might be the name of a button
    lastParsedData = text;
    return VoiceCommand.selectByLabel;
  }

  /// Combined Exact + Fuzzy matcher
  static bool _matches(String input, List<String> keywords) {
    for (var keyword in keywords) {
      keyword = keyword.toLowerCase();

      // 1. Direct match
      if (input.contains(keyword)) return true;

      // 2. Fuzzy match for speech inaccuracies
      // We check each word in the input against the keyword
      List<String> inputWords = input.split(' ');
      for (var word in inputWords) {
        if (_calculateSimilarity(word, keyword) >= _fuzzyThreshold) {
          return true;
        }
      }
    }
    return false;
  }

  /// Levenshtein Distance similarity implementation
  static double _calculateSimilarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    int distance = _levenshtein(s1, s2);
    int maxLen = s1.length > s2.length ? s1.length : s2.length;
    return 1.0 - (distance / maxLen);
  }

  static int _levenshtein(String s1, String s2) {
    int n = s1.length;
    int m = s2.length;
    List<List<int>> d = List.generate(n + 1, (_) => List.filled(m + 1, 0));

    for (int i = 0; i <= n; i++) d[i][0] = i;
    for (int j = 0; j <= m; j++) d[0][j] = j;

    for (int i = 1; i <= n; i++) {
      for (int j = 1; j <= m; j++) {
        int cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        d[i][j] = [
          d[i - 1][j] + 1,
          d[i][j - 1] + 1,
          d[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }
    return d[n][m];
  }
}
