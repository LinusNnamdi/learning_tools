import 'package:flutter/material.dart';
import 'package:learn/common/common.dart';
import 'package:learn/courses/course.dart';
import 'package:provider/provider.dart';

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CourseController>();

    final categories = ['All', ...controller.categories];

    final games = _selectedCategory == 'All'
        ? controller.courses
        : controller.byCategory(_selectedCategory);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Games',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Game Help',
            onPressed: () => _showGameHelp(context),
            icon: const Icon(Icons.help_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFF0C75C).withValues(alpha: 0.22),
                      Theme.of(context).colorScheme.surface,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: const Color(0xFFF0C75C).withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0C75C),
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: const Icon(
                        Icons.sports_esports_rounded,
                        color: Color(0xFF111827),
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Technology Challenge',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Practice what you have learned and test your technical knowledge.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(
              height: 52,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final selected = category == _selectedCategory;

                  return ChoiceChip(
                    label: Text(category),
                    selected: selected,
                    onSelected: (_) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    selectedColor: const Color(0xFFF0C75C),
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: selected ? const Color(0xFF111827) : null,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;

                  int columns;

                  if (width >= 1200) {
                    columns = 4;
                  } else if (width >= 850) {
                    columns = 3;
                  } else if (width >= 560) {
                    columns = 2;
                  } else {
                    columns = 1;
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(20),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: columns == 1 ? 1.35 : 0.92,
                    ),
                    itemCount: games.length,
                    itemBuilder: (context, index) {
                      final course = games[index];

                      return GameCard(
  course: course,
  onPlay: () {
    if (!isConfiguredSkillUrl(course.gameUrl)) {
      showSkillPageNotReady(
        context,
        skillName: course.name,
        pageType: 'game',
      );
      return;
    }

    openCourseUrl(
      context,
      title: '${course.name} Game',
      url: course.gameUrl,
    );
  },
);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGameHelp(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'How Games Work',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 16),
                _HelpRow(
                  icon: Icons.play_arrow_rounded,
                  text: 'Choose a technology and start its challenge.',
                ),
                _HelpRow(
                  icon: Icons.quiz_outlined,
                  text: 'Answer technical questions and complete challenges.',
                ),
                _HelpRow(
                  icon: Icons.emoji_events_outlined,
                  text: 'Use your results to identify areas that need more practice.',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HelpRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HelpRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.circle, size: 9, color: Color(0xFFF0C75C)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}

class GameCard extends StatelessWidget {
  final Course course;
  final VoidCallback onPlay;

  const GameCard({super.key, required this.course, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFF0C75C).withValues(alpha: 0.28),
                        course.color.withValues(alpha: 0.10),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Icon(
                    Icons.sports_esports_outlined,
                    color: course.color,
                    size: 29,
                  ),
                ),
                const Spacer(),
                Icon(course.icon, color: course.color),
              ],
            ),

            const SizedBox(height: 18),

            Text(
              '${course.name} Game',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: Text(
                'Test your knowledge of ${course.name} through an interactive technology challenge.',
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                  color: theme.textTheme.bodyMedium?.color?.withValues(
                    alpha: 0.72,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
  onPressed: onPlay,
  icon: const Icon(
    Icons.play_arrow_rounded,
    size: 21,
  ),
  label: const Text('Play Course Game'),
  style: FilledButton.styleFrom(
    backgroundColor: const Color(0xFFF0C75C),
    foregroundColor: const Color(0xFF111827),
    padding: const EdgeInsets.symmetric(
      vertical: 13,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(13),
    ),
  ),
),
            ),
          ],
        ),
      ),
    );
  }
}
