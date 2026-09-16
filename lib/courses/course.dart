import 'package:flutter/material.dart';
import 'package:learn/common/common.dart';
import 'package:provider/provider.dart';

class Course {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;

  /// Official/recommended learning resource for this technology.
  final String learnUrl;

  /// Your practical project samples for this technology.
  ///
  /// Replace only `skill_name` with the actual folder name when
  /// that skill's project page is ready.
  final String projectUrl;

  /// Your game/challenge page for this technology.
  ///
  /// Replace only `skill_name` with the actual folder name when
  /// that skill's game page is ready.
  final String gameUrl;

  final String category;

  const Course({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.learnUrl,
    required this.projectUrl,
    required this.gameUrl,
    required this.category,
  });
}

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  String _selectedCategory = 'All';
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CourseController>();
    final theme = Theme.of(context);

    final categories = ['All', ...controller.categories];

    final courses = controller.courses.where((course) {
      final categoryMatch =
          _selectedCategory == 'All' || course.category == _selectedCategory;

      final searchMatch =
          _search.trim().isEmpty ||
          course.name.toLowerCase().contains(_search.toLowerCase()) ||
          course.description.toLowerCase().contains(_search.toLowerCase());

      return categoryMatch && searchMatch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Courses',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Search',
            icon: const Icon(Icons.search),
            onPressed: () {
              _showSearchDialog(context);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _CoursesHeader(
              totalCourses: controller.courses.length,
              search: _search,
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
                      color: selected
                          ? const Color(0xFF111827)
                          : theme.textTheme.bodyMedium?.color,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: courses.isEmpty
                  ? const _EmptyCourses()
                  : LayoutBuilder(
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
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: columns == 1 ? 1.35 : 0.92,
                              ),
                          itemCount: courses.length,
                          itemBuilder: (context, index) {
                            final course = courses[index];

                            return CourseCard(
                              course: course,

                              onLearn: () {
                                openCourseUrl(
                                  context,
                                  title: 'Learn ${course.name}',
                                  url: course.learnUrl,
                                );
                              },

                              onPractice: () {
                                if (!isConfiguredSkillUrl(course.projectUrl)) {
                                  showSkillPageNotReady(
                                    context,
                                    skillName: course.name,
                                    pageType: 'practice project',
                                  );
                                  return;
                                }

                                openCourseUrl(
                                  context,
                                  title: '${course.name} Practice Project',
                                  url: course.projectUrl,
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

  void _showSearchDialog(BuildContext context) {
    final controller = TextEditingController(text: _search);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Search Courses'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'AWS, Flutter, Docker...',
              prefixIcon: Icon(Icons.search),
            ),
            onSubmitted: (_) {
              setState(() {
                _search = controller.text;
              });

              Navigator.pop(dialogContext);
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                controller.clear();

                setState(() {
                  _search = '';
                });

                Navigator.pop(dialogContext);
              },
              child: const Text('Clear'),
            ),
            FilledButton(
              onPressed: () {
                setState(() {
                  _search = controller.text;
                });

                Navigator.pop(dialogContext);
              },
              child: const Text('Search'),
            ),
          ],
        );
      },
    );
  }
}

class _CoursesHeader extends StatelessWidget {
  final int totalCourses;
  final String search;

  const _CoursesHeader({required this.totalCourses, required this.search});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFF0C75C).withValues(alpha: 0.18),
              theme.colorScheme.surface,
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFFF0C75C).withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                color: const Color(0xFFF0C75C),
                borderRadius: BorderRadius.circular(17),
              ),
              child: const Icon(
                Icons.school_rounded,
                color: Color(0xFF111827),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Learn Technology',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    search.isEmpty
                        ? '$totalCourses technology courses available'
                        : 'Searching for "$search"',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCourses extends StatelessWidget {
  const _EmptyCourses();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 60,
            color: Theme.of(context).colorScheme.onSurface
                .withValues(alpha: 0.4),
          ),
          const SizedBox(height: 14),
          const Text(
            'No courses found',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text('Try another search or category.'),
        ],
      ),
    );
  }
}

class CourseController extends ChangeNotifier {
  final List<Course> _courses = const [
    Course(
      id: 'html',
      name: 'HTML5',
      description: 'Learn how to structure professional, semantic and accessible websites.',
      icon: Icons.html,
      color: Color(0xFFE44D26),
      learnUrl: 'https://developer.mozilla.org/en-US/docs/Web/HTML',
      projectUrl:
          'https://linusnnamdi.github.io/linus_okolo/html/projects/home.html',

      gameUrl: 'https://linusnnamdi.github.io/linus_okolo/html/games/home.html',
      category: 'Web Development',
    ),

    Course(
      id: 'css',
      name: 'CSS3',
      description: 'Master responsive layouts, animations, positioning, grids and modern styling.',
      icon: Icons.style,
      color: Color(0xFF1572B6),
      learnUrl: 'https://developer.mozilla.org/en-US/docs/Web/CSS',
      projectUrl:
          'https://linusnnamdi.github.io/linus_okolo/html/projects/home.html',

      gameUrl: 'https://linusnnamdi.github.io/linus_okolo/html/games/home.html',
      category: 'Web Development',
    ),

    Course(
      id: 'javascript',
      name: 'JavaScript',
      description: 'Build interactive web applications using modern JavaScript and browser APIs.',
      icon: Icons.javascript,
      color: Color(0xFFF7DF1E),
      learnUrl: 'https://developer.mozilla.org/en-US/docs/Web/JavaScript',
      projectUrl:
          'https://linusnnamdi.github.io/linus_okolo/html/projects/home.html',

      gameUrl: 'https://linusnnamdi.github.io/linus_okolo/html/games/home.html',
      category: 'Web Development',
    ),

    Course(
      id: 'flutter',
      name: 'Flutter',
      description: 'Build responsive cross-platform mobile, desktop and web applications.',
      icon: Icons.flutter_dash,
      color: Color(0xFF02569B),
      learnUrl: 'https://docs.flutter.dev/',
      projectUrl:
          'https://linusnnamdi.github.io/linus_okolo/html/projects/home.html',

      gameUrl: 'https://linusnnamdi.github.io/linus_okolo/html/games/home.html',
      category: 'App Development',
    ),

    Course(
      id: 'dart',
      name: 'Dart',
      description: 'Learn the Dart language powering modern Flutter application development.',
      icon: Icons.code,
      color: Color(0xFF0175C2),
      learnUrl: 'https://dart.dev/language',
      projectUrl:
          'https://linusnnamdi.github.io/linus_okolo/html/projects/home.html',

      gameUrl: 'https://linusnnamdi.github.io/linus_okolo/html/games/home.html',
      category: 'App Development',
    ),

    Course(
      id: 'aws',
      name: 'AWS',
      description: 'Practice cloud architecture using EC2, VPC, ALB, ASG, IAM, S3 and more.',
      icon: Icons.cloud,
      color: Color(0xFFFF9900),
      learnUrl: 'https://aws.amazon.com/getting-started/',
      projectUrl:
          'https://linusnnamdi.github.io/linus_okolo/html/projects/home.html',

      gameUrl: 'https://linusnnamdi.github.io/linus_okolo/html/games/home.html',
      category: 'Cloud',
    ),

    Course(
      id: 'azure',
      name: 'Microsoft Azure',
      description: 'Explore Azure compute, networking, identity, storage and cloud architecture.',
      icon: Icons.cloud_queue,
      color: Color(0xFF0078D4),
      learnUrl: 'https://learn.microsoft.com/azure/',
      projectUrl:
          'https://linusnnamdi.github.io/linus_okolo/html/projects/home.html',

      gameUrl: 'https://linusnnamdi.github.io/linus_okolo/html/games/home.html',
      category: 'Cloud',
    ),

    Course(
      id: 'gcp',
      name: 'Google Cloud',
      description: 'Learn compute, networking, storage, IAM and scalable Google Cloud architectures.',
      icon: Icons.cloud_circle,
      color: Color(0xFF4285F4),
      learnUrl: 'https://cloud.google.com/docs',
      projectUrl:
          'https://linusnnamdi.github.io/linus_okolo/html/projects/home.html',

      gameUrl: 'https://linusnnamdi.github.io/linus_okolo/html/games/home.html',
      category: 'Cloud',
    ),

    Course(
      id: 'docker',
      name: 'Docker',
      description: 'Learn containers, images, Dockerfiles, networks, volumes and deployments.',
      icon: Icons.inventory_2,
      color: Color(0xFF2496ED),
      learnUrl: 'https://docs.docker.com/get-started/',
      projectUrl:
          'https://linusnnamdi.github.io/linus_okolo/html/projects/home.html',

      gameUrl: 'https://linusnnamdi.github.io/linus_okolo/html/games/home.html',
      category: 'DevOps',
    ),

    Course(
      id: 'github-actions',
      name: 'GitHub Actions',
      description: 'Create CI/CD workflows for testing, building and deploying applications.',
      icon: Icons.account_tree,
      color: Color(0xFF24292F),
      learnUrl: 'https://docs.github.com/actions',
      projectUrl:
          'https://linusnnamdi.github.io/linus_okolo/html/projects/home.html',

      gameUrl: 'https://linusnnamdi.github.io/linus_okolo/html/games/home.html',
      category: 'DevOps',
    ),

    Course(
      id: 'kubernetes',
      name: 'Kubernetes',
      description: 'Understand containers orchestration, pods, services, deployments and clusters.',
      icon: Icons.hub,
      color: Color(0xFF326CE5),
      learnUrl: 'https://kubernetes.io/docs/home/',
      projectUrl:
          'https://linusnnamdi.github.io/linus_okolo/html/projects/home.html',

      gameUrl: 'https://linusnnamdi.github.io/linus_okolo/html/games/home.html',
      category: 'DevOps',
    ),

    Course(
      id: 'terraform',
      name: 'Terraform',
      description: 'Practice infrastructure as code and repeatable cloud infrastructure deployment.',
      icon: Icons.construction,
      color: Color(0xFF844FBA),
      learnUrl: 'https://developer.hashicorp.com/terraform/docs',
      projectUrl:
          'https://linusnnamdi.github.io/linus_okolo/html/projects/home.html',

      gameUrl: 'https://linusnnamdi.github.io/linus_okolo/html/games/home.html',
      category: 'Infrastructure',
    ),

    Course(
      id: 'lambda',
      name: 'AWS Lambda',
      description:
          'Build serverless applications using event-driven cloud functions.',
      icon: Icons.functions,
      color: Color(0xFFFF9900),
      learnUrl: 'https://docs.aws.amazon.com/lambda/',
      projectUrl:
          'https://linusnnamdi.github.io/linus_okolo/html/projects/home.html',

      gameUrl: 'https://linusnnamdi.github.io/linus_okolo/html/games/home.html',
      category: 'Serverless',
    ),

    Course(
      id: 'cloud-security',
      name: 'Cloud Security',
      description: 'Learn IAM, encryption, network security, secrets and cloud security principles.',
      icon: Icons.security,
      color: Color(0xFF64748B),
      learnUrl: 'https://aws.amazon.com/security/',
      projectUrl:
          'https://linusnnamdi.github.io/linus_okolo/html/projects/home.html',

      gameUrl: 'https://linusnnamdi.github.io/linus_okolo/html/games/home.html',
      category: 'Security',
    ),

    Course(
      id: 'devops',
      name: 'DevOps',
      description: 'Combine development, automation, CI/CD, monitoring and infrastructure practices.',
      icon: Icons.sync_alt,
      color: Color(0xFF475569),
      learnUrl: 'https://aws.amazon.com/devops/',
      projectUrl:
          'https://linusnnamdi.github.io/linus_okolo/html/projects/home.html',

      gameUrl: 'https://linusnnamdi.github.io/linus_okolo/html/games/home.html',
      category: 'DevOps',
    ),

    Course(
      id: 'databases',
      name: 'Databases',
      description: 'Understand relational, NoSQL, distributed and cloud database architecture.',
      icon: Icons.storage,
      color: Color(0xFF0F766E),
      learnUrl: 'https://www.mongodb.com/docs/',
      projectUrl:
          'https://linusnnamdi.github.io/linus_okolo/html/projects/home.html',

      gameUrl: 'https://linusnnamdi.github.io/linus_okolo/html/games/home.html',
      category: 'Backend',
    ),

    Course(
      id: 'git',
      name: 'Git & GitHub',
      description: 'Learn source control, branching, merging, pull requests and collaboration.',
      icon: Icons.merge_type,
      color: Color(0xFFF05032),
      learnUrl: 'https://docs.github.com/',
      projectUrl:
          'https://linusnnamdi.github.io/linus_okolo/html/projects/home.html',

      gameUrl: 'https://linusnnamdi.github.io/linus_okolo/html/games/home.html',
      category: 'Development',
    ),

    Course(
      id: 'agentic-ai',
      name: 'Agentic AI',
      description: 'Explore AI agents, tools, workflows, orchestration and autonomous systems.',
      icon: Icons.auto_awesome,
      color: Color(0xFF7C3AED),
      learnUrl: 'https://platform.openai.com/docs',
      projectUrl:
          'https://linusnnamdi.github.io/linus_okolo/html/projects/home.html',

      gameUrl: 'https://linusnnamdi.github.io/linus_okolo/html/games/home.html',
      category: 'Artificial Intelligence',
    ),
  ];

  List<Course> get courses => List.unmodifiable(_courses);

  List<String> get categories {
    return _courses.map((course) => course.category).toSet().toList();
  }

  List<Course> byCategory(String category) {
    return _courses.where((course) => course.category == category).toList();
  }

  Course? findById(String id) {
    for (final course in _courses) {
      if (course.id == id) {
        return course;
      }
    }

    return null;
  }
}

class CourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback onLearn;
  final VoidCallback onPractice;

  const CourseCard({
    super.key,
    required this.course,
    required this.onLearn,
    required this.onPractice,
  });

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
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: course.color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(course.icon, color: course.color, size: 28),
                ),

                const Spacer(),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    course.category,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            Text(
              course.name,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: Text(
                course.description,
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

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onLearn,
                    icon: const Icon(Icons.school_outlined, size: 18),
                    label: const Text('Learn'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: FilledButton.icon(
                    onPressed: onPractice,
                    icon: const Icon(Icons.terminal_rounded, size: 18),
                    label: const Text('Projects'),
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
          ],
        ),
      ),
    );
  }
}
