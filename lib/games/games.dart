import 'package:flutter/material.dart';
import 'package:learn/common/banner_ads.dart';
import 'package:learn/common/common.dart';
import 'package:learn/courses/course.dart';
import 'package:learn/helps/help.dart';
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

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Games',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          actions: [
            IconButton(
              tooltip: 'Help',
              icon: const Icon(Icons.help_outline_rounded),
              onPressed: () => openEarnDeeAiHelp(
                context,
                pageTitle: 'Games',
                faqs: HelpFaqData.games,
              ),
            ),
          ],
        ),
        body: ResponsiveAdShell(
          showTopOnSmall: true,
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
                icon: const Icon(Icons.play_arrow_rounded, size: 21),
                label: const Text('Play Course Game'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFF0C75C),
                  foregroundColor: const Color(0xFF111827),
                  padding: const EdgeInsets.symmetric(vertical: 13),
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
