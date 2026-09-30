// ignore: file_names
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ---------------------------------------------------------------------------
/// COURSE QUIZ
/// ---------------------------------------------------------------------------
///
/// Reusable quiz screen for every course.
///
/// Expected question shape:
///
/// {
///   "id": "aws_a_0001",
///   "topic": "AWS Cloud Concepts & Fundamentals",
///   "difficulty": "advanced",
///   "type": "single",
///   "question": "...",
///   "options": ["A", "B", "C", "D"],
///   "correctAnswer": 3,
///   "explanation": "..."
/// }
///
/// Example:
///
/// Navigator.of(context).push(
///   MaterialPageRoute(
///     builder: (_) => CourseQuizPage(
///       courseId: course.id,
///       courseName: course.name,
///       courseColor: course.color,
///       questions: course.quizQuestions,
///       adBanner: const ResponsiveAdShell(),
///     ),
///   ),
/// );
///
/// `adBanner` is deliberately injected instead of importing your ad file here.
/// This avoids circular imports and lets this single quiz file work anywhere
/// in your project. Pass `const ResponsiveAdShell()` from your courses file.
///
/// The screen:
/// - randomly selects up to 100 unique questions
/// - supports All / Beginner / Intermediate / Advance
/// - supports 15s / 30s / 45s / 1m / 2m per question
/// - has Next only (no previous button)
/// - auto-advances when time expires
/// - pauses and hides the active question while offline
/// - resumes the same question/time when internet returns
/// - shows final score, result review, restart and save-result actions
/// - persists saved attempts and best score with SharedPreferences
/// - keeps the supplied ad widget fixed above the scrollable quiz content
class CourseQuizPage extends StatefulWidget {
  final String courseId;
  final String courseName;
  final Color courseColor;
  final List<Map<String, dynamic>>? questions;
  final Widget adBanner;

  final VoidCallback? onHelp;

  const CourseQuizPage({
    super.key,
    required this.courseId,
    required this.courseName,
    required this.courseColor,
    required this.questions,
    required this.adBanner,
    this.onHelp,
  });

  @override
  State<CourseQuizPage> createState() => _CourseQuizPageState();
}

enum QuizDifficulty {
  all('All', null),
  beginner('Beginner', 'beginner'),
  intermediate('Intermediate', 'intermediate'),
  advance('Advance', 'advanced');

  final String label;
  final String? dataValue;

  const QuizDifficulty(this.label, this.dataValue);
}

enum QuizStage { setup, playing, finished }

class _CourseQuizPageState extends State<CourseQuizPage>
    with WidgetsBindingObserver {
  static const int _maximumQuestions = 100;
  static const List<int> _timeChoices = [15, 30, 45, 60, 120];

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  QuizDifficulty _difficulty = QuizDifficulty.all;
  QuizStage _stage = QuizStage.setup;

  int _secondsPerQuestion = 30;
  int _secondsLeft = 30;
  int _currentIndex = 0;

  bool _isOnline = true;
  bool _checkingConnection = true;
  bool _submitting = false;

  Timer? _timer;

  List<_QuizQuestion> _sessionQuestions = <_QuizQuestion>[];
  final Map<String, int?> _answers = <String, int?>{};

  int _bestScore = 0;
  int _bestTotal = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listenToConnectivity();
    _loadBestScore();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Do not allow the countdown to keep running while the app is not active.
    if (state == AppLifecycleState.resumed) {
      if (_stage == QuizStage.playing && _isOnline) {
        _startTimer();
      }
    } else {
      _timer?.cancel();
    }
  }

  String get _storagePrefix => 'course_quiz_${widget.courseId}';

  String get _bestScoreKey => '${_storagePrefix}_best_score';

  String get _bestTotalKey => '${_storagePrefix}_best_total';

  String get _savedResultsKey => '${_storagePrefix}_saved_results';

  List<_QuizQuestion> get _validQuestions {
    final source = widget.questions;
    if (source == null || source.isEmpty) return const <_QuizQuestion>[];

    final result = <_QuizQuestion>[];
    final seenIds = <String>{};

    for (var i = 0; i < source.length; i++) {
      final parsed = _QuizQuestion.tryParse(source[i], fallbackIndex: i);
      if (parsed == null) continue;

      // A malformed source should never cause duplicate session identities.
      if (seenIds.add(parsed.id)) {
        result.add(parsed);
      }
    }

    return result;
  }

  List<_QuizQuestion> get _filteredQuestions {
    final questions = _validQuestions;
    final wanted = _difficulty.dataValue;

    if (wanted == null) return questions;

    return questions
        .where((question) => question.difficulty == wanted)
        .toList(growable: false);
  }

  _QuizQuestion? get _currentQuestion {
    if (_sessionQuestions.isEmpty ||
        _currentIndex < 0 ||
        _currentIndex >= _sessionQuestions.length) {
      return null;
    }
    return _sessionQuestions[_currentIndex];
  }

  int get _answeredCount =>
      _answers.values.where((answer) => answer != null).length;

  int get _correctCount {
    var correct = 0;

    for (final question in _sessionQuestions) {
      if (_answers[question.id] == question.correctAnswer) {
        correct++;
      }
    }

    return correct;
  }

  double get _scorePercent {
    if (_sessionQuestions.isEmpty) return 0;
    return (_correctCount / _sessionQuestions.length) * 100;
  }

  Future<void> _listenToConnectivity() async {
    final connectivity = Connectivity();

    try {
      final initial = await connectivity.checkConnectivity();
      if (!mounted) return;

      _applyConnectivity(initial);

      _connectivitySubscription = connectivity.onConnectivityChanged.listen(
        _applyConnectivity,
        onError: (_) {
          if (!mounted) return;
          setState(() {
            _checkingConnection = false;
            _isOnline = false;
          });
          _timer?.cancel();
        },
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _checkingConnection = false;
        _isOnline = false;
      });

      // No subscription was created; dispose handles null safely.
    }
  }

  void _applyConnectivity(List<ConnectivityResult> results) {
    if (!mounted) return;

    // connectivity_plus reports `none` when no network transport is available.
    // This is a connectivity gate, not an HTTP reachability probe.
    final online =
        results.isNotEmpty && !results.contains(ConnectivityResult.none);

    final wasOnline = _isOnline;

    setState(() {
      _checkingConnection = false;
      _isOnline = online;
    });

    if (!online) {
      _timer?.cancel();
      return;
    }

    if (!wasOnline && _stage == QuizStage.playing) {
      _startTimer();
    }
  }

  Future<void> _loadBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      _bestScore = prefs.getInt(_bestScoreKey) ?? 0;
      _bestTotal = prefs.getInt(_bestTotalKey) ?? 0;
    });
  }

  Future<void> _updateBestScoreIfNeeded() async {
    final currentCorrect = _correctCount;
    final currentTotal = _sessionQuestions.length;

    final oldPercent = _bestTotal == 0 ? -1.0 : _bestScore / _bestTotal;
    final newPercent = currentTotal == 0 ? 0.0 : currentCorrect / currentTotal;

    if (newPercent <= oldPercent) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_bestScoreKey, currentCorrect);
    await prefs.setInt(_bestTotalKey, currentTotal);

    if (!mounted) return;

    setState(() {
      _bestScore = currentCorrect;
      _bestTotal = currentTotal;
    });
  }

  void _startQuiz() {
    if (!_isOnline || _checkingConnection) return;

    final available = List<_QuizQuestion>.from(_filteredQuestions);

    if (available.isEmpty) {
      _showMessage(
        'No ${_difficulty == QuizDifficulty.all ? '' : '${_difficulty.label.toLowerCase()} '}'
        'questions are available for ${widget.courseName}.',
      );
      return;
    }

    available.shuffle(Random.secure());

    final count = min(_maximumQuestions, available.length);

    setState(() {
      _sessionQuestions = available.take(count).toList(growable: false);
      _answers.clear();
      _currentIndex = 0;
      _secondsLeft = _secondsPerQuestion;
      _stage = QuizStage.playing;
      _submitting = false;
    });

    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();

    if (_stage != QuizStage.playing || !_isOnline) return;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted ||
          _stage != QuizStage.playing ||
          !_isOnline ||
          _currentQuestion == null) {
        timer.cancel();
        return;
      }

      if (_secondsLeft <= 1) {
        timer.cancel();

        setState(() {
          _secondsLeft = 0;
        });

        _advanceAfterTimeout();
        return;
      }

      setState(() {
        _secondsLeft--;
      });
    });
  }

  void _selectAnswer(int optionIndex) {
    if (!_isOnline || _stage != QuizStage.playing) return;

    final question = _currentQuestion;
    if (question == null) return;

    setState(() {
      _answers[question.id] = optionIndex;
    });
  }

  void _nextQuestion() {
    if (!_isOnline || _stage != QuizStage.playing) return;

    if (_currentIndex >= _sessionQuestions.length - 1) {
      _confirmSubmit();
      return;
    }

    _timer?.cancel();

    setState(() {
      _currentIndex++;
      _secondsLeft = _secondsPerQuestion;
    });

    _startTimer();
  }

  void _advanceAfterTimeout() {
    final question = _currentQuestion;
    if (question == null) return;

    // Explicitly record timeout as unanswered.
    _answers.putIfAbsent(question.id, () => null);

    if (_currentIndex >= _sessionQuestions.length - 1) {
      _finishQuiz();
      return;
    }

    setState(() {
      _currentIndex++;
      _secondsLeft = _secondsPerQuestion;
    });

    _startTimer();
  }

  Future<void> _confirmSubmit() async {
    final unanswered =
        _sessionQuestions.length - _answers.values.whereType<int>().length;

    final submit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Submit quiz?'),
          content: Text(
            unanswered == 0
                ? 'You have reached the final question. Submit your answers?'
                : 'You have $unanswered unanswered '
                    '${unanswered == 1 ? 'question' : 'questions'}. '
                    'Submit anyway?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Continue'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );

    if (submit == true) {
      await _finishQuiz();
    }
  }

  Future<void> _finishQuiz() async {
    if (_submitting || _stage == QuizStage.finished) return;

    _timer?.cancel();

    setState(() {
      _submitting = true;
      _stage = QuizStage.finished;
    });

    await _updateBestScoreIfNeeded();

    if (!mounted) return;

    setState(() {
      _submitting = false;
    });
  }

  void _restartQuiz() {
    _timer?.cancel();

    setState(() {
      _stage = QuizStage.setup;
      _sessionQuestions = <_QuizQuestion>[];
      _answers.clear();
      _currentIndex = 0;
      _secondsLeft = _secondsPerQuestion;
      _submitting = false;
    });
  }

  Future<void> _saveCurrentResult() async {
    if (_stage != QuizStage.finished || _sessionQuestions.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_savedResultsKey) ?? <String>[];

    final attempt = _SavedQuizAttempt(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      courseId: widget.courseId,
      courseName: widget.courseName,
      difficulty: _difficulty.label,
      secondsPerQuestion: _secondsPerQuestion,
      completedAt: DateTime.now(),
      correct: _correctCount,
      total: _sessionQuestions.length,
      questions: _sessionQuestions,
      answers: Map<String, int?>.from(_answers),
    );

    // Newest result first.
    saved.insert(0, jsonEncode(attempt.toJson()));

    await prefs.setStringList(_savedResultsKey, saved);

    if (!mounted) return;

    _showMessage('Quiz result saved. You can revisit it from Saved Results.');
  }

  Future<List<_SavedQuizAttempt>> _loadSavedResults() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_savedResultsKey) ?? <String>[];
    final attempts = <_SavedQuizAttempt>[];

    for (final item in raw) {
      try {
        final decoded = jsonDecode(item);
        if (decoded is Map<String, dynamic>) {
          final attempt = _SavedQuizAttempt.tryParse(decoded);
          if (attempt != null) attempts.add(attempt);
        } else if (decoded is Map) {
          final attempt = _SavedQuizAttempt.tryParse(
            Map<String, dynamic>.from(decoded),
          );
          if (attempt != null) attempts.add(attempt);
        }
      } catch (_) {
        // Ignore one corrupt local record instead of breaking the whole screen.
      }
    }

    attempts.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return attempts;
  }

  Future<void> _openSavedResults() async {
    final results = await _loadSavedResults();
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _SavedResultsPage(
          courseName: widget.courseName,
          courseColor: widget.courseColor,
          initialResults: results,
          onDelete: _deleteSavedResult,
        ),
      ),
    );
  }

  Future<void> _deleteSavedResult(String resultId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_savedResultsKey) ?? <String>[];

    raw.removeWhere((item) {
      try {
        final decoded = jsonDecode(item);
        return decoded is Map && decoded['id']?.toString() == resultId;
      } catch (_) {
        return false;
      }
    });

    await prefs.setStringList(_savedResultsKey, raw);
  }

  void _openBestScore() {
    final hasBest = _bestTotal > 0;
    final percent =
        hasBest ? ((_bestScore / _bestTotal) * 100).toStringAsFixed(1) : '0.0';

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.emoji_events_rounded, color: widget.courseColor),
              const SizedBox(width: 10),
              const Text('Best Score'),
            ],
          ),
          content: Text(
            hasBest
                ? '$_bestScore / $_bestTotal ($percent%)\n\n'
                    'Course: ${widget.courseName}'
                : 'You have not completed a ${widget.courseName} quiz yet.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _openHelp() {
    if (widget.onHelp != null) {
      widget.onHelp!();
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.courseName} Quiz Help',
                  style: Theme.of(sheetContext).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 18),
                const _HelpRow(
                  icon: Icons.shuffle_rounded,
                  title: 'Random questions',
                  text:
                      'Each attempt uses up to 100 randomly selected questions from the chosen difficulty.',
                ),
                const _HelpRow(
                  icon: Icons.timer_outlined,
                  title: 'Question timer',
                  text:
                      'Choose 15 seconds, 30 seconds, 45 seconds, 1 minute or 2 minutes per question.',
                ),
                const _HelpRow(
                  icon: Icons.arrow_forward_rounded,
                  title: 'Forward only',
                  text:
                      'Use Next to continue. Previous navigation is intentionally unavailable.',
                ),
                const _HelpRow(
                  icon: Icons.wifi_off_rounded,
                  title: 'Offline protection',
                  text:
                      'When network connectivity is lost, the timer pauses and the active question is hidden until connectivity returns.',
                ),
                const _HelpRow(
                  icon: Icons.bookmark_added_outlined,
                  title: 'Saved results',
                  text:
                      'After finishing, save an attempt so you can later review your answer, the correct answer and the explanation.',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openCurrentResult() {
    if (_sessionQuestions.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizResultReviewPage(
          title: '${widget.courseName} Result',
          courseColor: widget.courseColor,
          questions: _sessionQuestions,
          answers: Map<String, int?>.from(_answers),
          correct: _correctCount,
          total: _sessionQuestions.length,
        ),
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasQuestions = _validQuestions.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.courseName} Quiz',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Saved results',
            onPressed: _openSavedResults,
            icon: const Icon(Icons.folder_copy_outlined),
          ),
          IconButton(
            tooltip: 'Help',
            onPressed: _openHelp,
            icon: const Icon(Icons.help_outline_rounded),
          ),
          IconButton(
            tooltip: 'Best score',
            onPressed: _openBestScore,
            icon: const Icon(Icons.emoji_events_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          // Fixed: this widget is outside the scrollable Expanded body.
          widget.adBanner,
          Expanded(
            child: !hasQuestions
                ? const _EmptyCourses()
                : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _buildStage(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStage() {
    switch (_stage) {
      case QuizStage.setup:
        return _buildSetup();
      case QuizStage.playing:
        return _buildPlaying();
      case QuizStage.finished:
        return _buildFinished();
    }
  }

  Widget _buildSetup() {
    final theme = Theme.of(context);
    final available = _filteredQuestions.length;
    final selectedCount = min(_maximumQuestions, available);

    return SingleChildScrollView(
      key: const ValueKey('quiz-setup'),
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _QuizHeroCard(
                courseName: widget.courseName,
                courseColor: widget.courseColor,
                questionCount: selectedCount,
              ),
              const SizedBox(height: 20),
              Text(
                'Difficulty',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: QuizDifficulty.values.map((difficulty) {
                  final selected = _difficulty == difficulty;

                  return ChoiceChip(
                    label: Text(difficulty.label),
                    selected: selected,
                    selectedColor: widget.courseColor.withValues(alpha: 0.20),
                    onSelected: (_) {
                      setState(() {
                        _difficulty = difficulty;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Text(
                'Time per question',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _timeChoices.map((seconds) {
                  return ChoiceChip(
                    label: Text(_formatDurationChoice(seconds)),
                    selected: _secondsPerQuestion == seconds,
                    selectedColor: widget.courseColor.withValues(alpha: 0.20),
                    onSelected: (_) {
                      setState(() {
                        _secondsPerQuestion = seconds;
                        _secondsLeft = seconds;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              _InfoPanel(
                icon: Icons.info_outline_rounded,
                color: widget.courseColor,
                text: available == 0
                    ? 'There are no questions in the selected difficulty.'
                    : available > _maximumQuestions
                        ? 'A fresh random set of $_maximumQuestions questions will be selected from $available available questions.'
                        : 'This section has $available available '
                            '${available == 1 ? 'question' : 'questions'}. '
                            'All will be used for this attempt.',
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: available == 0 ||
                        !_isOnline ||
                        _checkingConnection
                    ? null
                    : _startQuiz,
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(
                  _checkingConnection
                      ? 'Checking connection...'
                      : !_isOnline
                          ? 'Waiting for internet...'
                          : 'Start $selectedCount Question Quiz',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: widget.courseColor,
                  foregroundColor: _foregroundFor(widget.courseColor),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              if (_checkingConnection || !_isOnline) ...[
                const SizedBox(height: 18),
                const _OfflinePanel(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaying() {
    final question = _currentQuestion;

    if (question == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_checkingConnection || !_isOnline) {
      return const _OfflineGate(
        key: ValueKey('offline-gate'),
      );
    }

    final theme = Theme.of(context);
    final selectedAnswer = _answers[question.id];
    final progress = (_currentIndex + 1) / _sessionQuestions.length;
    final timerProgress =
        _secondsPerQuestion == 0 ? 0.0 : _secondsLeft / _secondsPerQuestion;

    return Column(
      key: ValueKey('question-${question.id}'),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Question ${_currentIndex + 1} of ${_sessionQuestions.length}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      _TimerBadge(
                        secondsLeft: _secondsLeft,
                        color: widget.courseColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    borderRadius: BorderRadius.circular(99),
                    color: widget.courseColor,
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: timerProgress.clamp(0.0, 1.0),
                    minHeight: 3,
                    borderRadius: BorderRadius.circular(99),
                    color: _secondsLeft <= 5
                        ? theme.colorScheme.error
                        : widget.courseColor.withValues(alpha: 0.65),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _SmallTag(
                          label: question.topic,
                          icon: Icons.category_outlined,
                        ),
                        _SmallTag(
                          label: _displayDifficulty(question.difficulty),
                          icon: Icons.signal_cellular_alt_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          question.question,
                          style: theme.textTheme.titleLarge?.copyWith(
                            height: 1.45,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...List.generate(question.options.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _AnswerOption(
                          index: index,
                          text: question.options[index],
                          selected: selectedAnswer == index,
                          color: widget.courseColor,
                          onTap: () => _selectAnswer(index),
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _nextQuestion,
                      icon: Icon(
                        _currentIndex == _sessionQuestions.length - 1
                            ? Icons.check_circle_outline_rounded
                            : Icons.arrow_forward_rounded,
                      ),
                      label: Text(
                        _currentIndex == _sessionQuestions.length - 1
                            ? 'Submit'
                            : 'Next',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: widget.courseColor,
                        foregroundColor: _foregroundFor(widget.courseColor),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      selectedAnswer == null
                          ? 'You can continue without selecting an answer.'
                          : 'Answer selected. You can change it before tapping Next.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinished() {
    final theme = Theme.of(context);
    final percent = _scorePercent;
    final message = _congratulationMessage(percent);

    return SingleChildScrollView(
      key: const ValueKey('quiz-finished'),
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    children: [
                      Container(
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          color: widget.courseColor.withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.emoji_events_rounded,
                          size: 44,
                          color: widget.courseColor,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'You scored $_correctCount out of '
                        '${_sessionQuestions.length}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${percent.toStringAsFixed(1)}%',
                        style: theme.textTheme.displaySmall?.copyWith(
                          color: widget.courseColor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: _sessionQuestions.isEmpty
                            ? 0
                            : _correctCount / _sessionQuestions.length,
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(99),
                        color: widget.courseColor,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Answered: $_answeredCount / '
                        '${_sessionQuestions.length}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _submitting ? null : _openCurrentResult,
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('View Result'),
                style: FilledButton.styleFrom(
                  backgroundColor: widget.courseColor,
                  foregroundColor: _foregroundFor(widget.courseColor),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _submitting ? null : _saveCurrentResult,
                icon: const Icon(Icons.save_alt_rounded),
                label: const Text('Save Result'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _submitting ? null : _restartQuiz,
                icon: const Icon(Icons.restart_alt_rounded),
                label: const Text('Restart'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Public helper for opening the quiz from a CourseCard or any other page.
Future<void> openCourseQuiz(
  BuildContext context, {
  required String courseId,
  required String courseName,
  required Color courseColor,
  required List<Map<String, dynamic>>? questions,
  required Widget adBanner,
  VoidCallback? onHelp,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => CourseQuizPage(
        courseId: courseId,
        courseName: courseName,
        courseColor: courseColor,
        questions: questions,
        adBanner: adBanner,
        onHelp: onHelp,
      ),
    ),
  );
}

/// ---------------------------------------------------------------------------
/// RESULT REVIEW
/// ---------------------------------------------------------------------------

class QuizResultReviewPage extends StatelessWidget {
  final String title;
  final Color courseColor;
  // ignore: library_private_types_in_public_api
  final List<_QuizQuestion> questions;
  final Map<String, int?> answers;
  final int correct;
  final int total;

  const QuizResultReviewPage({
    super.key,
    required this.title,
    required this.courseColor,
    required this.questions,
    required this.answers,
    required this.correct,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = total == 0 ? 0.0 : (correct / total) * 100;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: _ResultSummaryCard(
                correct: correct,
                total: total,
                percent: percent,
                color: courseColor,
              ),
            ),
          ),
          const SizedBox(height: 18),
          ...List.generate(questions.length, (index) {
            final question = questions[index];
            final answer = answers[question.id];
            final isCorrect = answer == question.correctAnswer;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                    leading: CircleAvatar(
                      backgroundColor: isCorrect
                          ? Colors.green.withValues(alpha: 0.12)
                          : theme.colorScheme.error.withValues(alpha: 0.12),
                      child: Icon(
                        isCorrect
                            ? Icons.check_rounded
                            : Icons.close_rounded,
                        color: isCorrect
                            ? Colors.green
                            : theme.colorScheme.error,
                      ),
                    ),
                    title: Text(
                      '${index + 1}. ${question.question}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        isCorrect
                            ? 'Correct'
                            : answer == null
                                ? 'Unanswered'
                                : 'Incorrect',
                      ),
                    ),
                    children: [
                      _ReviewLine(
                        label: 'Your answer',
                        value: answer == null
                            ? 'Not answered'
                            : _optionText(question, answer),
                        icon: Icons.person_outline_rounded,
                      ),
                      const SizedBox(height: 10),
                      _ReviewLine(
                        label: 'Correct answer',
                        value: _optionText(
                          question,
                          question.correctAnswer,
                        ),
                        icon: Icons.check_circle_outline_rounded,
                      ),
                      const SizedBox(height: 10),
                      _ReviewLine(
                        label: 'Why it is correct',
                        value: question.explanation,
                        icon: Icons.lightbulb_outline_rounded,
                      ),
                      const SizedBox(height: 10),
                      _ReviewLine(
                        label: 'Topic',
                        value: question.topic,
                        icon: Icons.category_outlined,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// SAVED RESULTS
/// ---------------------------------------------------------------------------

class _SavedResultsPage extends StatefulWidget {
  final String courseName;
  final Color courseColor;
  final List<_SavedQuizAttempt> initialResults;
  final Future<void> Function(String resultId) onDelete;

  const _SavedResultsPage({
    required this.courseName,
    required this.courseColor,
    required this.initialResults,
    required this.onDelete,
  });

  @override
  State<_SavedResultsPage> createState() => _SavedResultsPageState();
}

class _SavedResultsPageState extends State<_SavedResultsPage> {
  late List<_SavedQuizAttempt> _results;

  @override
  void initState() {
    super.initState();
    _results = List<_SavedQuizAttempt>.from(widget.initialResults);
  }

  Future<void> _delete(_SavedQuizAttempt attempt) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete saved result?'),
          content: const Text(
            'This saved quiz result will be permanently removed from this device.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await widget.onDelete(attempt.id);

    if (!mounted) return;

    setState(() {
      _results.removeWhere((item) => item.id == attempt.id);
    });
  }

  void _review(_SavedQuizAttempt attempt) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizResultReviewPage(
          title: '${widget.courseName} Saved Result',
          courseColor: widget.courseColor,
          questions: attempt.questions,
          answers: attempt.answers,
          correct: attempt.correct,
          total: attempt.total,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Saved Results',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: _results.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.folder_open_rounded,
                      size: 68,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.35),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No saved results',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Finish a quiz and tap Save Result to keep it here.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _results.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final result = _results[index];
                final percent =
                    result.total == 0 ? 0.0 : (result.correct / result.total) * 100;

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: widget.courseColor
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    Icons.fact_check_outlined,
                                    color: widget.courseColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${result.correct}/${result.total} • '
                                        '${percent.toStringAsFixed(1)}%',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${result.difficulty} • '
                                        '${_formatDurationChoice(result.secondsPerQuestion)} each',
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Delete',
                                  onPressed: () => _delete(result),
                                  icon: const Icon(Icons.delete_outline_rounded),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _formatDateTime(result.completedAt),
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => _review(result),
                                icon: const Icon(Icons.visibility_outlined),
                                label: const Text('View Result'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// DATA MODELS
/// ---------------------------------------------------------------------------

class _QuizQuestion {
  final String id;
  final String topic;
  final String difficulty;
  final String type;
  final String question;
  final List<String> options;
  final int correctAnswer;
  final String explanation;

  const _QuizQuestion({
    required this.id,
    required this.topic,
    required this.difficulty,
    required this.type,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
  });

  static _QuizQuestion? tryParse(
    Map<String, dynamic> json, {
    required int fallbackIndex,
  }) {
    final rawQuestion = json['question']?.toString().trim() ?? '';
    final rawOptions = json['options'];
    final rawCorrect = json['correctAnswer'];

    if (rawQuestion.isEmpty || rawOptions is! List) return null;

    final options = rawOptions
        .map((option) => option?.toString() ?? '')
        .toList(growable: false);

    if (options.length < 2) return null;

    final correctAnswer = rawCorrect is int
        ? rawCorrect
        : int.tryParse(rawCorrect?.toString() ?? '');

    if (correctAnswer == null ||
        correctAnswer < 0 ||
        correctAnswer >= options.length) {
      return null;
    }

    final rawId = json['id']?.toString().trim() ?? '';
    final difficulty = _normalizeDifficulty(
      json['difficulty']?.toString() ?? '',
    );

    return _QuizQuestion(
      id: rawId.isEmpty ? 'question_$fallbackIndex' : rawId,
      topic: (json['topic']?.toString().trim().isNotEmpty ?? false)
          ? json['topic'].toString().trim()
          : 'General',
      difficulty: difficulty,
      type: json['type']?.toString().trim() ?? 'single',
      question: rawQuestion,
      options: options,
      correctAnswer: correctAnswer,
      explanation:
          (json['explanation']?.toString().trim().isNotEmpty ?? false)
              ? json['explanation'].toString().trim()
              : 'No explanation was provided for this question.',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'topic': topic,
      'difficulty': difficulty,
      'type': type,
      'question': question,
      'options': options,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
    };
  }
}

class _SavedQuizAttempt {
  final String id;
  final String courseId;
  final String courseName;
  final String difficulty;
  final int secondsPerQuestion;
  final DateTime completedAt;
  final int correct;
  final int total;
  final List<_QuizQuestion> questions;
  final Map<String, int?> answers;

  const _SavedQuizAttempt({
    required this.id,
    required this.courseId,
    required this.courseName,
    required this.difficulty,
    required this.secondsPerQuestion,
    required this.completedAt,
    required this.correct,
    required this.total,
    required this.questions,
    required this.answers,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'courseName': courseName,
      'difficulty': difficulty,
      'secondsPerQuestion': secondsPerQuestion,
      'completedAt': completedAt.toIso8601String(),
      'correct': correct,
      'total': total,
      'questions': questions.map((question) => question.toJson()).toList(),
      'answers': answers,
    };
  }

  static _SavedQuizAttempt? tryParse(Map<String, dynamic> json) {
    try {
      final rawQuestions = json['questions'];
      final rawAnswers = json['answers'];

      if (rawQuestions is! List || rawAnswers is! Map) return null;

      final questions = <_QuizQuestion>[];

      for (var i = 0; i < rawQuestions.length; i++) {
        final raw = rawQuestions[i];
        if (raw is! Map) continue;

        final parsed = _QuizQuestion.tryParse(
          Map<String, dynamic>.from(raw),
          fallbackIndex: i,
        );

        if (parsed != null) questions.add(parsed);
      }

      final answers = <String, int?>{};

      rawAnswers.forEach((key, value) {
        answers[key.toString()] = value == null
            ? null
            : value is int
                ? value
                : int.tryParse(value.toString());
      });

      return _SavedQuizAttempt(
        id: json['id']?.toString() ?? '',
        courseId: json['courseId']?.toString() ?? '',
        courseName: json['courseName']?.toString() ?? '',
        difficulty: json['difficulty']?.toString() ?? 'All',
        secondsPerQuestion:
            int.tryParse(json['secondsPerQuestion']?.toString() ?? '') ?? 30,
        completedAt:
            DateTime.tryParse(json['completedAt']?.toString() ?? '') ??
                DateTime.now(),
        correct: int.tryParse(json['correct']?.toString() ?? '') ?? 0,
        total: int.tryParse(json['total']?.toString() ?? '') ??
            questions.length,
        questions: questions,
        answers: answers,
      );
    } catch (_) {
      return null;
    }
  }
}

/// ---------------------------------------------------------------------------
/// UI COMPONENTS
/// ---------------------------------------------------------------------------

class _QuizHeroCard extends StatelessWidget {
  final String courseName;
  final Color courseColor;
  final int questionCount;

  const _QuizHeroCard({
    required this.courseName,
    required this.courseColor,
    required this.questionCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            courseColor.withValues(alpha: 0.18),
            theme.colorScheme.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: courseColor.withValues(alpha: 0.30),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: courseColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.quiz_rounded,
              color: _foregroundFor(courseColor),
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$courseName Knowledge Quiz',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  questionCount == 0
                      ? 'Choose another difficulty to continue.'
                      : '$questionCount random '
                          '${questionCount == 1 ? 'question' : 'questions'} '
                          'for this attempt.',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerOption extends StatelessWidget {
  final int index;
  final String text;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _AnswerOption({
    required this.index,
    required this.text,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: selected
          ? color.withValues(alpha: 0.13)
          : theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? color
                  : theme.dividerColor.withValues(alpha: 0.28),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? color
                      : theme.colorScheme.onSurface.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  String.fromCharCode(65 + index),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: selected
                        ? _foregroundFor(color)
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(
                    text,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.4,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 8),
                Icon(Icons.check_circle_rounded, color: color),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TimerBadge extends StatelessWidget {
  final int secondsLeft;
  final Color color;

  const _TimerBadge({
    required this.secondsLeft,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final urgent = secondsLeft <= 5;
    final displayColor = urgent ? Theme.of(context).colorScheme.error : color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: displayColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 18, color: displayColor),
          const SizedBox(width: 5),
          Text(
            _formatCountdown(secondsLeft),
            style: TextStyle(
              color: displayColor,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallTag extends StatelessWidget {
  final String label;
  final IconData icon;

  const _SmallTag({
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(99),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _InfoPanel({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _OfflinePanel extends StatelessWidget {
  const _OfflinePanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Internet connection is required to start the quiz. '
              'Waiting for connectivity...',
            ),
          ),
        ],
      ),
    );
  }
}

class _OfflineGate extends StatelessWidget {
  const _OfflineGate({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            children: [
              const SizedBox(
                width: 54,
                height: 54,
                child: CircularProgressIndicator(strokeWidth: 5),
              ),
              const SizedBox(height: 24),
              Icon(
                Icons.wifi_off_rounded,
                size: 54,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Internet connection lost',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Your question is hidden and the quiz timer is paused. '
                'The same question and remaining time will return automatically '
                'when network connectivity is restored.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultSummaryCard extends StatelessWidget {
  final int correct;
  final int total;
  final double percent;
  final Color color;

  const _ResultSummaryCard({
    required this.correct,
    required this.total,
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(Icons.analytics_outlined, size: 38, color: color),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$correct / $total correct',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${percent.toStringAsFixed(1)}% • Review every question below',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewLine extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ReviewLine({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _HelpRow({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  text,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Kept with the same class name requested by the existing courses code.
/// It is used whenever the supplied course question list is null, empty,
/// or contains no valid quiz records.
class _EmptyCourses extends StatelessWidget {
  const _EmptyCourses();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.quiz_outlined,
              size: 68,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 16),
            Text(
              'No quiz available',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Quiz questions have not been added for this course yet.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// HELPERS
/// ---------------------------------------------------------------------------

String _normalizeDifficulty(String value) {
  final normalized = value.trim().toLowerCase();

  switch (normalized) {
    case 'beginner':
    case 'basic':
      return 'beginner';
    case 'intermediate':
    case 'medium':
      return 'intermediate';
    case 'advance':
    case 'advanced':
    case 'expert':
      return 'advanced';
    default:
      return normalized.isEmpty ? 'beginner' : normalized;
  }
}

String _displayDifficulty(String value) {
  switch (_normalizeDifficulty(value)) {
    case 'beginner':
      return 'Beginner';
    case 'intermediate':
      return 'Intermediate';
    case 'advanced':
      return 'Advance';
    default:
      if (value.isEmpty) return 'Unknown';
      return '${value[0].toUpperCase()}${value.substring(1)}';
  }
}

String _formatDurationChoice(int seconds) {
  if (seconds < 60) return '${seconds}s';
  if (seconds == 60) return '1 min';
  if (seconds == 120) return '2 mins';

  final minutes = seconds ~/ 60;
  final remaining = seconds % 60;

  return remaining == 0
      ? '$minutes mins'
      : '${minutes}m ${remaining}s';
}

String _formatCountdown(int seconds) {
  final minutes = seconds ~/ 60;
  final remaining = seconds % 60;

  return '$minutes:${remaining.toString().padLeft(2, '0')}';
}

String _optionText(_QuizQuestion question, int index) {
  if (index < 0 || index >= question.options.length) {
    return 'Invalid option';
  }

  final letter = String.fromCharCode(65 + index);
  return '$letter. ${question.options[index]}';
}

String _congratulationMessage(double percent) {
  if (percent >= 90) {
    return 'Outstanding work! Congratulations!';
  }
  if (percent >= 75) {
    return 'Great job! Congratulations!';
  }
  if (percent >= 60) {
    return 'Well done! Keep improving!';
  }
  if (percent >= 40) {
    return 'Good effort! Review and try again.';
  }
  return 'Keep learning — your next attempt can be stronger.';
}

String _formatDateTime(DateTime dateTime) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  final hour12 = dateTime.hour == 0
      ? 12
      : dateTime.hour > 12
          ? dateTime.hour - 12
          : dateTime.hour;

  final period = dateTime.hour >= 12 ? 'PM' : 'AM';
  final minute = dateTime.minute.toString().padLeft(2, '0');

  return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}, '
      '$hour12:$minute $period';
}

Color _foregroundFor(Color background) {
  return ThemeData.estimateBrightnessForColor(background) == Brightness.dark
      ? Colors.white
      : const Color(0xFF111827);
}
