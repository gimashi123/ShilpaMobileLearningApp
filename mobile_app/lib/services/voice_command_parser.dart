enum VoiceCommand {
  navigateHome,
  navigateLearn,
  navigateGames,
  navigateProfile,
  navigateQuiz, // New command for Quiz tab
  navigateBack,
  // Input Mode Commands
  setModeStandard,
  setModeDwell,
  setModeEyeGaze,
  setModeVoice,
  unknown,
}

class VoiceCommandParser {
  static VoiceCommand parse(String text) {
    text = text.toLowerCase().trim();

    // --- Input Mode Commands ---
    if (_containsAny(text, [
      'standard',
      'normal',
      'samanya',
      'touch',
      'සාමාන්‍ය',
    ])) {
      return VoiceCommand.setModeStandard;
    }
    if (_containsAny(text, [
      'dwell',
      'auto click',
      'obagena',
      'dwell mode',
      'ඔබගෙන',
    ])) {
      return VoiceCommand.setModeDwell;
    }
    if (_containsAny(text, ['eye', 'gaze', 'vision', 'as', 'ඇස්'])) {
      return VoiceCommand.setModeEyeGaze;
    }
    // "Voice" keyword might overlap, so check specific "mode" context or just prioritization
    if (_containsAny(text, [
      'voice mode',
      'katahanda',
      'katha',
      'input voice',
      'කටහඬ',
    ])) {
      return VoiceCommand.setModeVoice;
    }

    // --- Navigation Commands ---
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
    if (_containsAny(text, [
      'quiz',
      'prashna',
      'questions',
      'ප්‍රශ්න',
      'විභාග',
      'exam',
    ])) {
      return VoiceCommand.navigateQuiz;
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
