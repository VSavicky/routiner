import 'package:flutter/material.dart';
import '../../domain/services/challenges_service.dart';

class ChallengeDetailScreen extends StatefulWidget {
  final Map<String, dynamic> challenge;
  final VoidCallback? onJoinChanged;

  const ChallengeDetailScreen({
    super.key,
    required this.challenge,
    this.onJoinChanged,
  });

  @override
  State<ChallengeDetailScreen> createState() => _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends State<ChallengeDetailScreen> {
  bool _isJoined = false;
  bool _isLoading = true;
  final ChallengesService _challengesService = ChallengesService();

  @override
  void initState() {
    super.initState();
    _checkJoinedStatus();
  }

  Future<void> _checkJoinedStatus() async {
    final String challengeId = widget.challenge['id'] as String? ?? 
                               widget.challenge['title'] as String;
    final bool joined = await _challengesService.isJoined(challengeId);
    setState(() {
      _isJoined = joined;
      _isLoading = false;
    });
  }

  Future<void> _toggleJoin() async {
    final String challengeId = widget.challenge['id'] as String? ?? 
                              widget.challenge['title'] as String;
    
    if (_isJoined) {
      await _challengesService.leaveChallenge(challengeId);
      setState(() {
        _isJoined = false;
      });
    } else {
      await _challengesService.joinChallenge(widget.challenge);
      if (mounted) {
        setState(() {
          _isJoined = true;
        });
      }
    }
    
    // Уведомляем о изменении
    widget.onJoinChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final participants = widget.challenge['participants'] as int;
    final tasks = widget.challenge['tasks'] as List<dynamic>;
    final endTime = widget.challenge['endTime'] as DateTime?;
    final challengeColor = widget.challenge['color'] as Color;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              challengeColor,
              challengeColor.withOpacity(0.7),
            ],
            stops: const [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    // Back button
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          size: 18,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      
                      // Challenge icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            widget.challenge['icon'] as String,
                            style: const TextStyle(fontSize: 40),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Title
                      Text(
                        widget.challenge['title'] as String,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Time left
                      if (endTime != null)
                        Text(
                          _formatTimeLeft(endTime.difference(DateTime.now())),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      
                      const SizedBox(height: 24),
                      
                      // Participants avatars - наезжают друг на друга (по центру)
                      Center(
                        child: SizedBox(
                          width: 160,
                          height: 52,
                          child: Stack(
                            children: [
                              for (int i = 0; i < 4 && i < participants; i++)
                                Positioned(
                                  left: i * 20.0, // Намного ближе друг к другу (наезд)
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: challengeColor,
                                        width: 2,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(24),
                                      child: Image.network(
                                        'https://i.pravatar.cc/150?img=${10 + i}',
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: Colors.grey[300],
                                            child: Icon(
                                              Icons.person,
                                              size: 22,
                                              color: Colors.grey[600],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                            if (participants > 4)
                              Positioned(
                                left: 80, // Корректируем позицию бейджа
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: challengeColor,
                                      width: 2,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '+${participants - 4}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: challengeColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Description
                      Text(
                        widget.challenge['description'] as String,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Join button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _toggleJoin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: challengeColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: Text(
                            _isJoined ? 'Leave the Challenge' : 'Join the Challenge',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Tasks title
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Tasks',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Tasks as white cards on gradient
                      for (int i = 0; i < tasks.length; i++)
                        _buildTaskCard(tasks[i] as Map<String, dynamic>, challengeColor),
                      
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimeLeft(Duration duration) {
    if (duration.isNegative) return 'Ended';
    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);
    
    if (days > 0) return '$days days ${hours}h left';
    if (hours > 0) return '$hours hours ${minutes}m left';
    return '$minutes minutes left';
  }

  Widget _buildTaskCard(Map<String, dynamic> task, Color challengeColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EDF5)),
      ),
      child: Row(
        children: [
          // Task icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: challengeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                task['icon'] as String,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Task info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task['name'] as String,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  task['progress'] as String,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          // Participants mini avatars - ФИКС
          SizedBox(
            width: 70,
            height: 32,
            child: Stack(
              children: [
                for (int i = 0; i < 2; i++)
                  Positioned(
                    right: i * 18.0,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          'https://i.pravatar.cc/150?img=${20 + i}',
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.person,
                              size: 16,
                              color: Colors.grey[600],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  right: 36,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: challengeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '+3',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: challengeColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
