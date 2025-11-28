class DisabilityType {
  static const visual = 'visual';
  static const hearing = 'hearing';
  static const physical = 'physical';
  static const cognitive = 'cognitive';

  static String label(String type) {
    switch (type) {
      case visual:
        return 'දෘශ්‍ය අබාධිත';
      case hearing:
        return 'ශ්‍රවණ අබාධිත';
      case physical:
        return 'ශාරීරික අබාධිත';
      case cognitive:
        return 'ඥානීය / බුද්ධිමය';
      default:
        return 'ශිෂ්‍ය';
    }
  }
}
