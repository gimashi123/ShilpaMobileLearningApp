enum VoiceCommand {
  navigateHome,
  navigateLearn,
  navigateGames,
  navigateProfile,
  navigateBack,
  unknown,
}

class VoiceCommandParser {
  static VoiceCommand parse(String text) {
    text = text.toLowerCase().trim();

    // Sinhala & English Keywords mapping
    if (_containsAny(text, [
      'home',
      'මුල් පිටුව',
      'gedara',
      'dashboard',
      'හොම්',
    ])) {
      return VoiceCommand.navigateHome;
    }
    if (_containsAny(text, ['learn', 'පාඩම්', 'padam', 'ඉගෙනීම', 'ලර්න්'])) {
      return VoiceCommand.navigateLearn;
    }
    if (_containsAny(text, [
      'games',
      'සෙල්ලම්',
      'sallam',
      'ක්‍රීඩා',
      'ගේම්ස්',
    ])) {
      return VoiceCommand.navigateGames;
    }
    if (_containsAny(text, ['profile', 'පරිශීලක', 'මම', 'ප්‍රෝෆයිල්', 'මා'])) {
      return VoiceCommand.navigateProfile;
    }
    if (_containsAny(text, ['back', 'පසුපසට', 'pannata', 'out', 'අයින්'])) {
      return VoiceCommand.navigateBack;
    }

    return VoiceCommand.unknown;
  }

  static bool _containsAny(String text, List<String> keywords) {
    for (var keyword in keywords) {
      if (text.contains(keyword.toLowerCase())) {
        return true;
      }
    }
    return false;
  }
}
