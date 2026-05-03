import 'package:flutter/material.dart';
import 'package:mobile_app/services/progress_api.dart';
import 'package:intl/intl.dart';

class ProgressReportScreen extends StatefulWidget {
  const ProgressReportScreen({super.key});

  @override
  State<ProgressReportScreen> createState() => _ProgressReportScreenState();
}

class _ProgressReportScreenState extends State<ProgressReportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _summary;
  Map<String, dynamic>? _history;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final summaryRes = await ProgressApi.fetchSummary();
      final historyRes = await ProgressApi.fetchHistory();

      setState(() {
        _summary = summaryRes['data'];
        _history = historyRes['data'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'My Progress',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorUI()
              : _buildMainUI(),
    );
  }

  Widget _buildErrorUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Failed to load progress', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildMainUI() {
    return Column(
      children: [
        _buildSummaryHeader(),
        _buildTabBar(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildLessonsTab(),
              _buildQuizzesTab(),
              _buildGamesTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryHeader() {
    final xp = _summary?['totalXp'] ?? 0;
    final lessons = _summary?['lessonsCompleted'] ?? 0;
    final quizzes = _summary?['quizzesCompleted'] ?? 0;
    final games = _summary?['gamesPlayed'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🏆', style: TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Text(
                '$xp Total XP',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Lessons', lessons.toString(), Icons.play_circle_fill),
              _buildStatItem('Quizzes', quizzes.toString(), Icons.quiz),
              _buildStatItem('Games', games.toString(), Icons.videogame_asset),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        labelColor: Colors.black,
        unselectedLabelColor: Colors.grey,
        tabs: const [
          Tab(text: 'Lessons'),
          Tab(text: 'Quizzes'),
          Tab(text: 'Games'),
        ],
      ),
    );
  }

  Widget _buildLessonsTab() {
    final items = _history?['lessons'] as List? ?? [];
    if (items.isEmpty) return _buildEmptyHistory('No lessons completed yet');

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final lesson = item['lessonId'];
        final date = DateTime.parse(item['completedAt']);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.withOpacity(0.1),
              child: const Icon(Icons.check_circle, color: Colors.green),
            ),
            title: Text(lesson?['title'] ?? 'Unknown Lesson', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Completed on ${DateFormat.yMMMd().add_jm().format(date)}'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
          ),
        );
      },
    );
  }

  Widget _buildQuizzesTab() {
    final items = _history?['quizzes'] as List? ?? [];
    if (items.isEmpty) return _buildEmptyHistory('No quizzes attempted yet');

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final score = item['correctCount'] ?? 0;
        final total = item['totalQuestions'] ?? 0;
        final date = DateTime.parse(item['createdAt']);
        final difficulty = item['difficultyLevel'] ?? 1;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.withOpacity(0.1),
              child: const Icon(Icons.quiz, color: Colors.blue),
            ),
            title: Text('Score: $score / $total', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Level $difficulty • ${DateFormat.yMMMd().format(date)}'),
            trailing: Text(
              '${((score / total) * 100).toInt()}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: score / total >= 0.8 ? Colors.green : (score / total >= 0.5 ? Colors.orange : Colors.red),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGamesTab() {
    final items = _history?['games'] as List? ?? [];
    if (items.isEmpty) return _buildEmptyHistory('No games played yet');

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final score = item['correctCount'] ?? 0;
        final total = item['totalQuestions'] ?? 0;
        final date = DateTime.parse(item['createdAt']);
        final disability = item['disabilityType'] ?? 'General';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange.withOpacity(0.1),
              child: const Icon(Icons.videogame_asset, color: Colors.orange),
            ),
            title: Text('Score: $score / $total', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${disability.toUpperCase()} • ${DateFormat.yMMMd().format(date)}'),
            trailing: Text(
              '+${item['xpGained'] ?? 0} XP',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyHistory(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
