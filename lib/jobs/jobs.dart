import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:learn/common/common.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

//isSafeHttp

bool isSafeHttpUrl(String value) {
  final uri = Uri.tryParse(value);

  if (uri == null) {
    return false;
  }

  return uri.scheme == 'https' && uri.host.isNotEmpty;
}

String? bestJobUrl(JobResult job) {
  if (isSafeHttpUrl(job.applyUrl)) return job.applyUrl;
  if (isSafeHttpUrl(job.sourceUrl)) return job.sourceUrl;
  if (isSafeHttpUrl(job.companyUrl)) return job.companyUrl;
  return null;
}

bool isSafeJobApplicationUrl(JobResult job) {
  final uri = Uri.tryParse(job.applyUrl);

  if (uri == null) {
    return false;
  }

  switch (job.applicationMethod) {
    case JobApplicationMethod.email:
      return uri.scheme == 'mailto' && uri.path.trim().isNotEmpty;

    case JobApplicationMethod.website:
    case JobApplicationMethod.linkedin:
    case JobApplicationMethod.other:
      return uri.scheme == 'https' && uri.host.isNotEmpty;
  }
}

Future<void> showContactMessageForm(
  BuildContext context, {
  required ContactChannel channel,
}) async {
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();

  String selectedService = 'Software';

  final formKey = GlobalKey<FormState>();

  try {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final channelName = channel == ContactChannel.whatsapp
                ? 'WhatsApp'
                : 'Email';

            return AlertDialog(
              title: Text(
                'Contact via $channelName',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),

              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Your Name / Business',
                            hintText: 'Enter your name or business name',
                            prefixIcon: Icon(Icons.person_outline_rounded),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your name or business name.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        DropdownButtonFormField<String>(
                          initialValue: selectedService,
                          decoration: const InputDecoration(
                            labelText: 'Service Needed',
                            prefixIcon: Icon(Icons.design_services_outlined),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Software',
                              child: Text('Software'),
                            ),
                            DropdownMenuItem(value: 'Web', child: Text('Web')),
                            DropdownMenuItem(
                              value: 'Cloud',
                              child: Text('Cloud'),
                            ),
                            DropdownMenuItem(
                              value: 'DevOps',
                              child: Text('DevOps'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;

                            setDialogState(() {
                              selectedService = value;
                            });
                          },
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: descriptionController,
                          minLines: 4,
                          maxLines: 7,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            labelText: 'More Explanation',
                            alignLabelWithHint: true,
                            hintText: 'Briefly explain what you want us to build or help you with...',
                            prefixIcon: Padding(
                              padding: EdgeInsets.only(bottom: 75),
                              child: Icon(Icons.description_outlined),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please provide a short description.';
                            }

                            if (value.trim().length < 10) {
                              return 'Please provide a little more detail.';
                            }

                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),

                FilledButton.icon(
                  onPressed: () async {
                    final valid = formKey.currentState?.validate() ?? false;

                    if (!valid) return;

                    final message = buildEarnDeeContactMessage(
                      name: nameController.text,
                      service: selectedService,
                      description: descriptionController.text,
                    );

                    Navigator.pop(dialogContext);

                    if (!context.mounted) return;

                    switch (channel) {
                      case ContactChannel.whatsapp:
                        await sendEarnDeeWhatsAppMessage(context, message);
                        break;

                      case ContactChannel.email:
                        await sendEarnDeeEmail(context, message);
                        break;
                    }
                  },
                  icon: Icon(
                    channel == ContactChannel.whatsapp
                        ? Icons.send_rounded
                        : Icons.email_outlined,
                  ),
                  label: Text(
                    channel == ContactChannel.whatsapp
                        ? 'Continue to WhatsApp'
                        : 'Continue to Email',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  } finally {
    nameController.dispose();
    descriptionController.dispose();
  }
}

String buildEarnDeeContactMessage({
  required String name,
  required String service,
  required String description,
}) {
  final cleanName = name.trim();
  final cleanService = service.trim();
  final cleanDescription = description.trim();

  return '''
Hello, EarnDee.

I will need your $cleanService services.

Name / Business: $cleanName

More explanation:
$cleanDescription
'''
      .trim();
}

Future<void> sendEarnDeeWhatsAppMessage(
  BuildContext context,
  String message,
) async {
  const phone = ContactUsTab.whatsappInternationalNumber;

  final uri = Uri.https('wa.me', '/$phone', {'text': message});

  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

  if (!opened && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Unable to open WhatsApp.')));
  }
}

Future<void> sendEarnDeeEmail(BuildContext context, String message) async {
  const recipient = ContactUsTab.contactEmail;

  if (recipient.trim().isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('EarnDee email address has not been configured yet.'),
        ),
      );
    }

    return;
  }

  final uri = Uri(
    scheme: 'mailto',
    path: recipient,
    queryParameters: {'subject': 'EarnDee Service Request', 'body': message},
  );

  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unable to open your email application.')),
    );
  }
}

class GeminiJobService {
  const GeminiJobService();

  FirebaseFunctions get _functions {
    return FirebaseFunctions.instanceFor(region: 'africa-south1');
  }

  Future<String> generateJobSearch({required String prompt}) async {
    final callable = _functions.httpsCallable(
      'searchJobsWithGemini',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 120)),
    );

    try {
      final result = await callable.call<Map<String, dynamic>>({
        'prompt': prompt,
      });

      final data = result.data;

      final success = data['success'];
      final rawText = data['rawText'];

      if (success != true) {
        throw const FormatException(
          'The backend did not report a successful Gemini request.',
        );
      }

      if (rawText is! String || rawText.trim().isEmpty) {
        throw const FormatException('Gemini returned an empty response.');
      }

      return rawText.trim();
    } on FirebaseFunctionsException {
      rethrow;
    } catch (error) {
      throw Exception('Unable to communicate with the AI service: $error');
    }
  }
}

class JobResponseAnalyzer {
  const JobResponseAnalyzer._();

  static JobSearchResponse analyze(String rawResponse) {
    final json = GeminiJsonExtractor.extractObject(rawResponse);

    _normalizeResponse(json);

    return JobSearchResponse.fromJson(json);
  }

  static void _normalizeResponse(Map<String, dynamic> json) {
    json['summary'] = _stringValue(json['summary']);

    json['searched_at'] = _stringValue(json['searched_at']);

    final rawJobs = json['jobs'];

    if (rawJobs is! List) {
      json['jobs'] = <Map<String, dynamic>>[];
      return;
    }

    final normalizedJobs = <Map<String, dynamic>>[];

    for (var index = 0; index < rawJobs.length; index++) {
      final item = rawJobs[index];

      if (item is! Map) {
        continue;
      }

      final job = Map<String, dynamic>.from(item);

      final title = _stringValue(job['job_title']);

      final company = _stringValue(job['company_name']);

      // A result without these two fields is not useful
      // enough to become a job card.
      if (title.isEmpty || company.isEmpty) {
        continue;
      }

      job['id'] = _stringValue(
        job['id'],
        fallback: 'job-${DateTime.now().microsecondsSinceEpoch}-$index',
      );

      job['job_title'] = title;

      job['company_name'] = company;

      job['job_location'] = _stringValue(job['job_location']);

      job['work_mode'] = _stringValue(job['work_mode']);

      job['employment_type'] = _stringValue(job['employment_type']);

      job['posted_at'] = _stringValue(job['posted_at']);

      job['application_deadline'] = _stringValue(job['application_deadline']);

      job['short_description'] = _stringValue(job['short_description']);

      job['company_url'] = _safeUrl(job['company_url']);

      job['apply_url'] = _safeUrl(job['apply_url']);

      job['source_url'] = _safeUrl(job['source_url']);

      job['application_method'] = _applicationMethod(job['application_method']);

      job['requirements'] = _requirements(job['requirements']);

      normalizedJobs.add(job);
    }

    json['jobs'] = normalizedJobs;
  }

  static String _stringValue(dynamic value, {String fallback = ''}) {
    if (value == null) {
      return fallback;
    }

    final text = value.toString().trim();

    return text.isEmpty ? fallback : text;
  }

  static List<String> _requirements(dynamic value) {
    if (value is! List) {
      return const [];
    }

    return value
        .where((item) => item != null)
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  static String _applicationMethod(dynamic value) {
    final method = _stringValue(value).toLowerCase();

    const allowed = {'website', 'email', 'linkedin', 'other'};

    return allowed.contains(method) ? method : 'other';
  }

  static String _safeUrl(dynamic value) {
    final text = _stringValue(value);

    if (text.isEmpty) {
      return '';
    }

    final uri = Uri.tryParse(text);

    if (uri == null) {
      return '';
    }

    if (uri.scheme != 'https' && uri.scheme != 'http') {
      return '';
    }

    if (uri.host.isEmpty) {
      return '';
    }

    return uri.toString();
  }
}

class GeminiJsonExtractor {
  const GeminiJsonExtractor._();

  static Map<String, dynamic> extractObject(String rawResponse) {
    var cleaned = rawResponse.trim();

    // Remove Markdown code fences if Gemini ever returns them.
    cleaned = cleaned.replaceFirst(
      RegExp(r'^```(?:json)?\s*', caseSensitive: false),
      '',
    );

    cleaned = cleaned.replaceFirst(RegExp(r'\s*```$'), '');

    cleaned = cleaned.trim();

    // First try the entire response.
    try {
      final decoded = jsonDecode(cleaned);

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      // Continue with JSON extraction below.
    }

    // Gemini may occasionally surround JSON with unwanted text.
    final firstBrace = cleaned.indexOf('{');
    final lastBrace = cleaned.lastIndexOf('}');

    if (firstBrace == -1 || lastBrace == -1 || lastBrace <= firstBrace) {
      throw const FormatException(
        'No valid JSON object was found in the AI response.',
      );
    }

    final jsonText = cleaned.substring(firstBrace, lastBrace + 1);

    final decoded = jsonDecode(jsonText);

    if (decoded is! Map) {
      throw const FormatException('The AI response is not a JSON object.');
    }

    return Map<String, dynamic>.from(decoded);
  }
}

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Jobs',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.support_agent_rounded), text: 'Contact Us'),
            Tab(icon: Icon(Icons.search_rounded), text: 'Find Jobs'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [ContactUsTab(), FindJobsTab()],
      ),
    );
  }
}

class ContactUsTab extends StatelessWidget {
  const ContactUsTab({super.key});

  // ---------------------------------------------------------------------------
  // CONTACT CONFIGURATION
  // ---------------------------------------------------------------------------

  static const String whatsappDisplayNumber = '08148478414';

  static const String whatsappInternationalNumber = '2348148478414';

  // TODO: Replace when you provide the real email.
  static const String contactEmail = '';

  // TODO: Replace with your real social profile URLs.
  static const String tiktokUrl = '';
  static const String linkedInUrl = '';
  static const String githubUrl = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFF0C75C).withValues(alpha: 0.20),
                        theme.colorScheme.surface,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFFF0C75C).withValues(alpha: 0.35),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0C75C),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Icon(
                          Icons.support_agent_rounded,
                          size: 38,
                          color: Color(0xFF111827),
                        ),
                      ),

                      const SizedBox(height: 18),

                      Text(
                        'Work With EarnDee',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Need Software, Web, Cloud or DevOps services? '
                        'Choose a contact method and tell us what you need.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  'Contact',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 12),

                _ContactTile(
                  icon: Icons.chat_rounded,
                  title: 'WhatsApp',
                  value: whatsappDisplayNumber,
                  onTap: () {
                    showContactMessageForm(
                      context,
                      channel: ContactChannel.whatsapp,
                    );
                  },
                ),

                const SizedBox(height: 12),

                _ContactTile(
                  icon: Icons.email_outlined,
                  title: 'Email',
                  value: contactEmail.isEmpty
                      ? 'Email address not configured yet'
                      : contactEmail,
                  onTap: () {
                    showContactMessageForm(
                      context,
                      channel: ContactChannel.email,
                    );
                  },
                ),

                const SizedBox(height: 30),

                Text(
                  'Follow Us & View Our Work',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 12),

                _ContactTile(
                  icon: Icons.play_circle_outline_rounded,
                  title: 'TikTok',
                  value: 'Follow us and view our works',
                  onTap: () {
                    openConfiguredSocialUrl(
                      context,
                      url: tiktokUrl,
                      platformName: 'TikTok',
                    );
                  },
                ),

                const SizedBox(height: 12),

                _ContactTile(
                  icon: Icons.business_center_outlined,
                  title: 'LinkedIn',
                  value: 'Follow us and view our works',
                  onTap: () {
                    openConfiguredSocialUrl(
                      context,
                      url: linkedInUrl,
                      platformName: 'LinkedIn',
                    );
                  },
                ),

                const SizedBox(height: 12),

                _ContactTile(
                  icon: Icons.code_rounded,
                  title: 'GitHub',
                  value: 'View our projects and works',
                  onTap: () {
                    openConfiguredSocialUrl(
                      context,
                      url: githubUrl,
                      platformName: 'GitHub',
                    );
                  },
                ),

                const SizedBox(height: 32),

                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: theme.dividerColor.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.verified_user_outlined,
                        color: Color(0xFFF0C75C),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Text(
                          'Tell us what service you need and provide enough '
                          'detail for us to understand your project before contacting you.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum ContactChannel { whatsapp, email }

class FindJobsTab extends StatefulWidget {
  const FindJobsTab({super.key});

  @override
  State<FindJobsTab> createState() => _FindJobsTabState();
}

class _FindJobsTabState extends State<FindJobsTab> {
  bool _isSearching = false;

  String? _searchError;

  JobSearchResponse? _searchResponse;
  final _formKey = GlobalKey<FormState>();

  final _skillsController = TextEditingController();
  final _currentLocationController = TextEditingController();
  final _targetLocationController = TextEditingController();

  String _experienceLevel = 'Entry Level';

  bool _includeRemoteJobs = true;

  @override
  void dispose() {
    _skillsController.dispose();
    _currentLocationController.dispose();
    _targetLocationController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: const Color(0xFFF0C75C),
          foregroundColor: const Color(0xFF111827),
          icon: const Icon(Icons.bookmarks_rounded),
          label: const Text('Saved Jobs'),
          onPressed: () => _showSavedJobs(context),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 850),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFF0C75C).withValues(alpha: 0.20),
                          theme.colorScheme.surface,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFFF0C75C).withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0C75C),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.search_rounded,
                            size: 32,
                            color: Color(0xFF111827),
                          ),
                        ),

                        const SizedBox(width: 18),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Job Finder',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),

                              const SizedBox(height: 6),

                              Text(
                                'Tell us your skills, current location and where '
                                'you want to work. The job engine will use this '
                                'information to find and rank suitable opportunities.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _skillsController,
                          minLines: 2,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Your Skills',
                            hintText: 'Flutter, AWS, Docker, GitHub Actions...',
                            prefixIcon: Icon(Icons.psychology_outlined),
                          ),
                          validator: _requiredField,
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _currentLocationController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Your Current Location',
                            hintText: 'Country, state or city',
                            prefixIcon: Icon(Icons.location_on_outlined),
                          ),
                          validator: _requiredField,
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _targetLocationController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Where Do You Want to Work?',
                            hintText: 'Country, state, city or Remote',
                            prefixIcon: Icon(Icons.travel_explore_rounded),
                          ),
                          validator: _requiredField,
                        ),

                        const SizedBox(height: 16),

                        DropdownButtonFormField<String>(
                          initialValue: _experienceLevel,
                          decoration: const InputDecoration(
                            labelText: 'Experience Level',
                            prefixIcon: Icon(Icons.stairs_outlined),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Entry Level',
                              child: Text('Entry Level'),
                            ),
                            DropdownMenuItem(
                              value: 'Junior',
                              child: Text('Junior'),
                            ),
                            DropdownMenuItem(
                              value: 'Mid Level',
                              child: Text('Mid Level'),
                            ),
                            DropdownMenuItem(
                              value: 'Senior',
                              child: Text('Senior'),
                            ),
                            DropdownMenuItem(
                              value: 'Any Level',
                              child: Text('Any Level'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;

                            setState(() {
                              _experienceLevel = value;
                            });
                          },
                        ),

                        const SizedBox(height: 10),

                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Include remote jobs'),
                          subtitle: const Text(
                            'Also consider jobs that can be performed remotely.',
                          ),
                          value: _includeRemoteJobs,
                          onChanged: (value) {
                            setState(() {
                              _includeRemoteJobs = value;
                            });
                          },
                        ),

                        const SizedBox(height: 20),

                        FilledButton.icon(
                          onPressed: _isSearching ? null : _prepareJobSearch,
                          icon: _isSearching
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Icon(Icons.auto_awesome_rounded),
                          label: Text(
                            _isSearching
                                ? 'Searching Jobs...'
                                : 'Find Jobs With AI',
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFF0C75C),
                            foregroundColor: const Color(0xFF111827),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),

                        const SizedBox(height: 14),

                        Text(
                          'EarnDee Ai-powered job search protected by '
                          'Firebase App Check and Other security measures!',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            height: 1.45,
                            color: theme.textTheme.bodySmall?.color?.withValues(
                              alpha: 0.70,
                            ),
                          ),
                        ),
                        if (_searchError != null) ...[
                          const SizedBox(height: 24),

                          _JobSearchErrorCard(message: _searchError!),
                        ],

                        if (_searchResponse != null) ...[
                          const SizedBox(height: 30),

                          JobSearchResultsSection(response: _searchResponse!),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSavedJobs(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return const _SavedJobsSheet();
      },
    );
  }

  String? _requiredField(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required.';
    }

    return null;
  }

  Future<void> _prepareJobSearch() async {
    final valid = _formKey.currentState?.validate() ?? false;

    if (!valid || _isSearching) {
      return;
    }

    final request = JobSearchRequest(
      skills: _skillsController.text.trim(),
      currentLocation: _currentLocationController.text.trim(),
      targetLocation: _targetLocationController.text.trim(),
      experienceLevel: _experienceLevel,
      includeRemoteJobs: _includeRemoteJobs,
    );

    setState(() {
      _isSearching = true;
      _searchError = null;
      _searchResponse = null;
    });

    try {
      const service = GeminiJobService();

      final rawResponse = await service.generateJobSearch(
        prompt: request.toGeminiPrompt(),
      );

      final analyzedResponse = JobResponseAnalyzer.analyze(rawResponse);

      if (!mounted) {
        return;
      }

      setState(() {
        _searchResponse = analyzedResponse;
      });
    } on FirebaseFunctionsException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _searchError = _firebaseErrorMessage(error);
      });
    } on FormatException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _searchError =
            'The AI returned an invalid job response. '
            '${error.message}';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _searchError =
            'Unable to search for jobs right now. '
            'Please try again.';
      });

      debugPrint('Job search error: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  String _firebaseErrorMessage(FirebaseFunctionsException error) {
    switch (error.code) {
      case 'invalid-argument':
        return error.message ?? 'The job search request is invalid.';

      case 'unauthenticated':
        return 'The application could not be verified. '
            'Check Firebase App Check configuration.';

      case 'permission-denied':
        return 'The job-search service rejected this request.';

      case 'resource-exhausted':
        return 'The job-search service is temporarily busy. '
            'Please try again shortly.';

      case 'deadline-exceeded':
        return 'The AI took too long to respond. '
            'Please try again.';

      case 'unavailable':
        return 'The job-search service is temporarily unavailable.';

      case 'internal':
        return error.message ?? 'The AI service encountered an internal error.';

      default:
        return error.message ?? 'Unable to complete the job search.';
    }
  }
}

class _JobSearchErrorCard extends StatelessWidget {
  final String message;

  const _JobSearchErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, color: theme.colorScheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class JobSearchResultsSection extends StatelessWidget {
  final JobSearchResponse response;

  const JobSearchResultsSection({super.key, required this.response});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (response.jobs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          children: [
            const Icon(Icons.work_off_outlined, size: 42),
            const SizedBox(height: 12),
            Text(
              'No Jobs Found',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              response.summary.isNotEmpty
                  ? response.summary
                  : 'No suitable job opportunities were returned.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.work_outline_rounded),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Job Results',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF0C75C),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text(
                '${response.jobs.length}',
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),

        if (response.summary.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            response.summary,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ],

        const SizedBox(height: 20),

        ...response.jobs.map(
          (job) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _JobResultCard(job: job),
          ),
        ),
      ],
    );
  }
}

class _JobResultCard extends StatelessWidget {
  final JobResult job;

  const _JobResultCard({required this.job});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = bestJobUrl(job);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // …… keep all your existing header / location / description / requirements UI ……

          const SizedBox(height: 20),

          // ---------- ACTION BUTTONS ----------
          Row(
            children: [
              // Visit / Apply
              Expanded(
                child: FilledButton.icon(
                  onPressed: url == null ? null : () => _openUrl(context, url),
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: const Text('Visit page'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFF0C75C),
                    foregroundColor: const Color(0xFF111827),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Copy link
              IconButton.filledTonal(
                tooltip: 'Copy link',
                onPressed: url == null
                    ? null
                    : () async {
                        await Clipboard.setData(ClipboardData(text: url));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Link copied')),
                          );
                        }
                      },
                icon: const Icon(Icons.copy_rounded),
              ),
              const SizedBox(width: 6),
              // Save
              IconButton.filledTonal(
                tooltip: 'Save job',
                onPressed: () => _saveJob(context, job),
                icon: const Icon(Icons.bookmark_add_outlined),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open this link.')),
      );
    }
  }

  Future<void> _saveJob(BuildContext context, JobResult job) async {
    try {
      await SavedJobsStorage().save(job);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Saved "${job.jobTitle}"')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save this job.')),
        );
      }
    }
  }
}

class JobSearchRequest {
  final String skills;
  final String currentLocation;
  final String targetLocation;
  final String experienceLevel;
  final bool includeRemoteJobs;

  const JobSearchRequest({
    required this.skills,
    required this.currentLocation,
    required this.targetLocation,
    required this.experienceLevel,
    required this.includeRemoteJobs,
  });

  String toGeminiPrompt() {
    return '''
You are a professional job-search assistant.

Your task is to find job opportunities that closely match the candidate information below.

CANDIDATE INFORMATION

Skills:
$skills

Current location:
$currentLocation

Preferred work location:
$targetLocation

Experience level:
$experienceLevel

Include remote jobs:
$includeRemoteJobs

SEARCH REQUIREMENTS

1. Prioritize jobs matching the candidate's listed skills.
2. Prioritize the requested target location.
3. If includeRemoteJobs is true, remote opportunities may also be included.
4. Match the requested experience level where possible.
5. Do not invent missing information.
6. Do not return explanatory text before or after the JSON.
7. Return a maximum of 20 jobs.
8. Every job must be represented as a JSON object.
9. requirements must always be a JSON array of strings.
10. application_method must be exactly one of:
   "website",
   "email",
   "linkedin",
   "other".
11. If a value is unknown, return an empty string instead of inventing it.
12. If no suitable jobs can be found, return an empty jobs array.
13. ONLY return jobs posted or still open within the last 90 days from today (${DateTime.now().toIso8601String().substring(0, 10)}).
14. For every job you MUST provide a real, working URL in "apply_url" or "source_url" that points to the actual job posting page (company career page, LinkedIn, Indeed, etc.). Never invent fake URLs.
15. Prefer the direct application / job-detail page URL over a generic company homepage.

Return ONLY this JSON structure:

{
  "summary": "Short summary of the job search results",
  "searched_at": "ISO-8601 date/time if known, otherwise empty string",
  "jobs": [
    {
      "id": "unique job identifier",
      "job_title": "Job title",
      "company_name": "Company name",
      "job_location": "Job location",
      "work_mode": "Remote, Hybrid, On-site or unknown",
      "employment_type": "Full-time, Part-time, Contract, Internship or unknown",
      "posted_at": "Date posted or empty string",
      "application_deadline": "Application deadline or empty string",
      "short_description": "Short description of the role",
      "requirements": [
        "Requirement 1",
        "Requirement 2"
      ],
      "company_url": "Company website URL or empty string",
      "apply_url": "Direct application / job posting URL (required when possible)",
      "application_method": "website",
      "source_url": "URL where the job information came from or empty string"
    }
  ]
}
''';
  }

  Map<String, dynamic> toJson() {
    return {
      'skills': skills,
      'currentLocation': currentLocation,
      'targetLocation': targetLocation,
      'experienceLevel': experienceLevel,
      'includeRemoteJobs': includeRemoteJobs,
    };
  }
}

enum JobApplicationMethod { website, email, linkedin, other }

class JobResult {
  final String id;

  final String jobTitle;
  final String companyName;

  final String jobLocation;
  final String workMode;
  final String employmentType;

  final String postedAt;
  final String applicationDeadline;

  final String shortDescription;
  final List<String> requirements;

  /// Actual company/company-job information page.
  final String companyUrl;

  /// Best available legitimate application target.
  ///
  /// May be:
  /// https://...
  /// mailto:jobs@example.com
  final String applyUrl;

  final JobApplicationMethod applicationMethod;

  /// URL from which this vacancy was verified.
  final String sourceUrl;

  const JobResult({
    required this.id,
    required this.jobTitle,
    required this.companyName,
    required this.jobLocation,
    required this.workMode,
    required this.employmentType,
    required this.postedAt,
    required this.applicationDeadline,
    required this.shortDescription,
    required this.requirements,
    required this.companyUrl,
    required this.applyUrl,
    required this.applicationMethod,
    required this.sourceUrl,
  });

  factory JobResult.fromJson(Map<String, dynamic> json) {
    final requirementsValue = json['requirements'];

    final requirements = requirementsValue is List
        ? requirementsValue
              .whereType<String>()
              .map((item) => item.trim())
              .where((item) => item.isNotEmpty)
              .toList()
        : <String>[];

    return JobResult(
      id: _requiredJobString(json, 'id'),
      jobTitle: _requiredJobString(json, 'job_title'),
      companyName: _requiredJobString(json, 'company_name'),
      jobLocation: _requiredJobString(json, 'job_location'),
      workMode: _requiredJobString(json, 'work_mode'),
      employmentType: _requiredJobString(json, 'employment_type'),
      postedAt: _requiredJobString(json, 'posted_at'),
      applicationDeadline: _requiredJobString(json, 'application_deadline'),
      shortDescription: _requiredJobString(json, 'short_description'),
      requirements: requirements,
      companyUrl: _requiredJobString(json, 'company_url'),
      applyUrl: _requiredJobString(json, 'apply_url'),
      applicationMethod: _parseApplicationMethod(json['application_method']),
      sourceUrl: _requiredJobString(json, 'source_url'),
    );
  }

  static String _requiredJobString(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Invalid or missing job field: $key');
    }

    return value.trim();
  }

  static JobApplicationMethod _parseApplicationMethod(dynamic value) {
    switch (value) {
      case 'website':
        return JobApplicationMethod.website;

      case 'email':
        return JobApplicationMethod.email;

      case 'linkedin':
        return JobApplicationMethod.linkedin;

      case 'other':
        return JobApplicationMethod.other;

      default:
        throw const FormatException('Invalid application_method.');
    }
  }
}

class JobSearchResponse {
  final List<JobResult> jobs;
  final String summary;
  final String searchedAt;

  const JobSearchResponse({
    required this.jobs,
    required this.summary,
    required this.searchedAt,
  });

  factory JobSearchResponse.fromJson(Map<String, dynamic> json) {
    final rawJobs = json['jobs'];

    if (rawJobs is! List) {
      throw const FormatException(
        'Job response does not contain a valid jobs array.',
      );
    }

    final parsedJobs = <JobResult>[];
    final seenJobs = <String>{};

    for (final item in rawJobs) {
      if (item is! Map) {
        continue;
      }

      try {
        final job = JobResult.fromJson(Map<String, dynamic>.from(item));

        final duplicateKey =
            '${job.companyName.toLowerCase()}|'
            '${job.jobTitle.toLowerCase()}|'
            '${job.applyUrl.toLowerCase()}';

        if (seenJobs.add(duplicateKey)) {
          parsedJobs.add(job);
        }
      } on FormatException {
        // Do not let one malformed record destroy
        // all otherwise-valid search results.
        continue;
      }
    }

    return JobSearchResponse(
      jobs: parsedJobs.take(20).toList(),
      summary: (json['summary'] as String?)?.trim() ?? '',
      searchedAt: (json['searched_at'] as String?)?.trim() ?? '',
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  const _ContactTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(17),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFF0C75C).withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: const Color(0xFFF0C75C)),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class SavedJob {
  final String id;
  final String name; // job title
  final DateTime savedAt;
  final Map<String, dynamic> data; // full JobResult json

  SavedJob({
    required this.id,
    required this.name,
    required this.savedAt,
    required this.data,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'savedAt': savedAt.toIso8601String(),
    'data': data,
  };

  static SavedJob fromJson(Map<String, dynamic> json) {
    return SavedJob(
      id: json['id'] as String,
      name: json['name'] as String,
      savedAt: DateTime.parse(json['savedAt'] as String),
      data: Map<String, dynamic>.from(json['data'] as Map),
    );
  }
}

class SavedJobsStorage {
  static const _key = 'learning_tech_saved_jobs';

  Future<List<SavedJob>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => SavedJob.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
  }

  Future<void> _persist(List<SavedJob> jobs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(jobs.map((j) => j.toJson()).toList()),
    );
  }

  Future<SavedJob> save(JobResult job) async {
    final all = await loadAll();
    final id = 'saved-${DateTime.now().microsecondsSinceEpoch}';
    final saved = SavedJob(
      id: id,
      name: job.jobTitle.trim().isEmpty ? 'Untitled Job' : job.jobTitle.trim(),
      savedAt: DateTime.now(),
      data: {
        'id': job.id,
        'job_title': job.jobTitle,
        'company_name': job.companyName,
        'job_location': job.jobLocation,
        'work_mode': job.workMode,
        'employment_type': job.employmentType,
        'posted_at': job.postedAt,
        'application_deadline': job.applicationDeadline,
        'short_description': job.shortDescription,
        'requirements': job.requirements,
        'company_url': job.companyUrl,
        'apply_url': job.applyUrl,
        'application_method': job.applicationMethod.name,
        'source_url': job.sourceUrl,
      },
    );
    all.add(saved);
    await _persist(all);
    return saved;
  }

  Future<void> delete(String id) async {
    final all = await loadAll();
    all.removeWhere((j) => j.id == id);
    await _persist(all);
  }
}

class _SavedJobsSheet extends StatefulWidget {
  const _SavedJobsSheet();

  @override
  State<_SavedJobsSheet> createState() => _SavedJobsSheetState();
}

class _SavedJobsSheetState extends State<_SavedJobsSheet> {
  List<SavedJob> _jobs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final list = await SavedJobsStorage().loadAll();
    if (!mounted) return;
    setState(() {
      _jobs = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Saved Jobs',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                'Jobs you bookmarked from search results',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              if (_loading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_jobs.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      'No saved jobs yet.\nTap the bookmark icon on any job card.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: _jobs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final saved = _jobs[index];
                      final title = saved.name;
                      final company =
                          (saved.data['company_name'] as String?) ?? '';
                      final applyUrl =
                          (saved.data['apply_url'] as String?) ?? '';
                      final sourceUrl =
                          (saved.data['source_url'] as String?) ?? '';
                      final companyUrl =
                          (saved.data['company_url'] as String?) ?? '';

                      String? url;
                      if (isSafeHttpUrl(applyUrl)) {
                        url = applyUrl;
                      } else if (isSafeHttpUrl(sourceUrl)) {
                        url = sourceUrl;
                      } else if (isSafeHttpUrl(companyUrl)) {
                        url = companyUrl;
                      }

                      return Card(
                        child: ListTile(
                          title: Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(
                            company.isEmpty
                                ? 'Saved ${saved.savedAt.toLocal()}'
                                : '$company · ${saved.savedAt.toLocal()}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (url != null)
                                IconButton(
                                  tooltip: 'Visit page',
                                  icon: const Icon(Icons.open_in_new_rounded),
                                  onPressed: () async {
                                    final uri = Uri.parse(url!);
                                    await launchUrl(
                                      uri,
                                      mode: LaunchMode.externalApplication,
                                    );
                                  },
                                ),
                              IconButton(
                                tooltip: 'Delete',
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                onPressed: () async {
                                  await SavedJobsStorage().delete(saved.id);
                                  await _reload();
                                },
                              ),
                            ],
                          ),
                          onTap: url == null
                              ? null
                              : () async {
                                  final uri = Uri.parse(url!);
                                  await launchUrl(
                                    uri,
                                    mode: LaunchMode.externalApplication,
                                  );
                                },
                        ),
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
