import 'package:flutter/material.dart';
import '../../services/auth_api.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Get user data from static storage
    final user = AuthApi.currentUser;
    final name = user?['name'] ?? 'Student';
    final disabilityType = user?['disabilityType'] ?? 'Unknown';

    // Theme values
    const gradientColors = [Color(0xFF8EC5FC), Color(0xFFE0C3FC)];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine layout based on width
        // If width > 600, we use a horizontal "Side-by-Side" Card layout
        // Otherwise, we use the vertical stacked layout (safe for phones)
        final isWide = constraints.maxWidth > 600;

        // Card constraints
        final double maxWidth = isWide ? 700 : 400;
        final EdgeInsets padding = const EdgeInsets.all(24);

        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            physics: const BouncingScrollPhysics(),
            child: Container(
              constraints: BoxConstraints(maxWidth: maxWidth),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: isWide
                  ? _buildWideLayout(
                      name,
                      disabilityType,
                      gradientColors,
                      padding,
                    )
                  : _buildNarrowLayout(
                      name,
                      disabilityType,
                      gradientColors,
                      padding,
                    ),
            ),
          ),
        );
      },
    );
  }

  // ===== WIDE LAYOUT (Horizontal Card for Tablets) =====
  Widget _buildWideLayout(
    String name,
    String disabilityType,
    List<Color> gradientColors,
    EdgeInsets padding,
  ) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // LEFT: Image Section with Gradient Background
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  bottomLeft: Radius.circular(24),
                ),
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      size: 64,
                      color: gradientColors[1],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDisabilityBadge(disabilityType, true),
                ],
              ),
            ),
          ),

          // RIGHT: Info & Stats Section
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Welcome back,',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF333333),
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Divider(height: 1),
                  const SizedBox(height: 32),
                  // Horizontal Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatItem('Lessons', '12'),
                      _buildStatItem('Games', '5'),
                      _buildStatItem('Points', '350'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== NARROW LAYOUT (Vertical Stack for Phones) =====
  Widget _buildNarrowLayout(
    String name,
    String disabilityType,
    List<Color> gradientColors,
    EdgeInsets padding,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top: Profile Image area
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(top: 40, bottom: 30),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            gradient: LinearGradient(
              colors: gradientColors.map((c) => c.withOpacity(0.3)).toList(),
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_rounded,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF333333),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              _buildDisabilityBadge(disabilityType, false),
            ],
          ),
        ),

        // Bottom: Stats
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem('Lessons', '12'),
              Container(height: 40, width: 1, color: Colors.grey[200]),
              _buildStatItem('Games', '5'),
              Container(height: 40, width: 1, color: Colors.grey[200]),
              _buildStatItem('Points', '350'),
            ],
          ),
        ),
      ],
    );
  }

  // Helper Widgets
  Widget _buildDisabilityBadge(String type, bool isLightMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isLightMode
            ? Colors.white.withOpacity(0.25)
            : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLightMode
              ? Colors.white.withOpacity(0.6)
              : Colors.black.withOpacity(0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getDisabilityIcon(type),
            size: 16,
            color: isLightMode ? Colors.white : Colors.grey[800],
          ),
          const SizedBox(width: 8),
          Text(
            type.toUpperCase(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isLightMode ? Colors.white : Colors.grey[800],
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Color(0xFF6E4BC6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  IconData _getDisabilityIcon(String type) {
    switch (type.toLowerCase()) {
      case 'visual':
        return Icons.visibility;
      case 'hearing':
        return Icons.hearing;
      case 'physical':
        return Icons.accessible;
      case 'cognitive':
        return Icons.psychology;
      default:
        return Icons.star;
    }
  }
}
