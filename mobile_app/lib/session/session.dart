class Session {
  static String? token;
  static String? userId;
  static String? userName;
  static String? email;
  static String? disabilityType;

  static const String enableAllActivitiesKey =
      "enable_all_cognitive_activities";
  static bool enableAllCognitiveActivities = false;

  static String enableAllActivitiesKeyForCurrentUser() {
    final identifier =
        (userId?.trim().isNotEmpty == true)
            ? userId!.trim()
            : (email?.trim().isNotEmpty == true)
            ? email!.trim().toLowerCase()
            : "anonymous";
    return "${enableAllActivitiesKey}_$identifier";
  }
}
