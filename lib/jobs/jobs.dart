import 'package:flutter/material.dart';
import 'package:learn/common/common.dart';
import 'package:url_launcher/url_launcher.dart';

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

    _tabController = TabController(
      length: 2,
      vsync: this,
    );
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
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.support_agent_rounded),
              text: 'Contact Us',
            ),
            Tab(
              icon: Icon(Icons.search_rounded),
              text: 'Find Jobs',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ContactUsTab(),
          FindJobsTab(),
        ],
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

  static const String whatsappInternationalNumber =
      '2348148478414';

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
            constraints: const BoxConstraints(
              maxWidth: 900,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFF0C75C)
                            .withValues(alpha: 0.20),
                        theme.colorScheme.surface,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFFF0C75C)
                          .withValues(alpha: 0.35),
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
                        style:
                            theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Need Software, Web, Cloud or DevOps services? '
                        'Choose a contact method and tell us what you need.',
                        textAlign: TextAlign.center,
                        style:
                            theme.textTheme.bodyLarge?.copyWith(
                          height: 1.5,
                        ),
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
                      color: theme.dividerColor
                          .withValues(alpha: 0.15),
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
                          style:
                              theme.textTheme.bodyMedium?.copyWith(
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

enum ContactChannel {
  whatsapp,
  email,
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
            final channelName =
                channel == ContactChannel.whatsapp
                    ? 'WhatsApp'
                    : 'Email';

            return AlertDialog(
              title: Text(
                'Contact via $channelName',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                ),
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
                            prefixIcon: Icon(
                              Icons.person_outline_rounded,
                            ),
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
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
                            prefixIcon: Icon(
                              Icons.design_services_outlined,
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Software',
                              child: Text('Software'),
                            ),
                            DropdownMenuItem(
                              value: 'Web',
                              child: Text('Web'),
                            ),
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
                          textCapitalization:
                              TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            labelText: 'More Explanation',
                            alignLabelWithHint: true,
                            hintText:
                                'Briefly explain what you want us to build or help you with...',
                            prefixIcon: Padding(
                              padding: EdgeInsets.only(
                                bottom: 75,
                              ),
                              child: Icon(
                                Icons.description_outlined,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
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
                    final valid =
                        formKey.currentState?.validate() ??
                            false;

                    if (!valid) return;

                    final message = buildEarnDeeContactMessage(
                      name: nameController.text,
                      service: selectedService,
                      description:
                          descriptionController.text,
                    );

                    Navigator.pop(dialogContext);

                    if (!context.mounted) return;

                    switch (channel) {
                      case ContactChannel.whatsapp:
                        await sendEarnDeeWhatsAppMessage(
                          context,
                          message,
                        );
                        break;

                      case ContactChannel.email:
                        await sendEarnDeeEmail(
                          context,
                          message,
                        );
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
'''.trim();
}

Future<void> sendEarnDeeWhatsAppMessage(
  BuildContext context,
  String message,
) async {
  const phone =
      ContactUsTab.whatsappInternationalNumber;

  final uri = Uri.https(
    'wa.me',
    '/$phone',
    {
      'text': message,
    },
  );

  final opened = await launchUrl(
    uri,
    mode: LaunchMode.externalApplication,
  );

  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Unable to open WhatsApp.',
        ),
      ),
    );
  }
}

Future<void> sendEarnDeeEmail(
  BuildContext context,
  String message,
) async {
  const recipient = ContactUsTab.contactEmail;

  if (recipient.trim().isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'EarnDee email address has not been configured yet.',
          ),
        ),
      );
    }

    return;
  }

  final uri = Uri(
    scheme: 'mailto',
    path: recipient,
    queryParameters: {
      'subject': 'EarnDee Service Request',
      'body': message,
    },
  );

  final opened = await launchUrl(
    uri,
    mode: LaunchMode.externalApplication,
  );

  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Unable to open your email application.',
        ),
      ),
    );
  }
}

class FindJobsTab extends StatefulWidget {
  const FindJobsTab({super.key});

  @override
  State<FindJobsTab> createState() => _FindJobsTabState();
}

class _FindJobsTabState extends State<FindJobsTab> {
  final _formKey = GlobalKey<FormState>();

  final _skillsController = TextEditingController();
  final _currentLocationController =
      TextEditingController();
  final _targetLocationController =
      TextEditingController();

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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 850,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFF0C75C)
                            .withValues(alpha: 0.20),
                        theme.colorScheme.surface,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFFF0C75C)
                          .withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0C75C),
                          borderRadius:
                              BorderRadius.circular(18),
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
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Job Finder',
                              style: theme
                                  .textTheme.titleLarge
                                  ?.copyWith(
                                fontWeight:
                                    FontWeight.w900,
                              ),
                            ),

                            const SizedBox(height: 6),

                            Text(
                              'Tell us your skills, current location and where '
                              'you want to work. The job engine will use this '
                              'information to find and rank suitable opportunities.',
                              style: theme
                                  .textTheme.bodyMedium
                                  ?.copyWith(
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
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _skillsController,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Your Skills',
                          hintText:
                              'Flutter, AWS, Docker, GitHub Actions...',
                          prefixIcon: Icon(
                            Icons.psychology_outlined,
                          ),
                        ),
                        validator: _requiredField,
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller:
                            _currentLocationController,
                        textInputAction:
                            TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText:
                              'Your Current Location',
                          hintText:
                              'Country, state or city',
                          prefixIcon: Icon(
                            Icons.location_on_outlined,
                          ),
                        ),
                        validator: _requiredField,
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller:
                            _targetLocationController,
                        textInputAction:
                            TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText:
                              'Where Do You Want to Work?',
                          hintText:
                              'Country, state, city or Remote',
                          prefixIcon: Icon(
                            Icons.travel_explore_rounded,
                          ),
                        ),
                        validator: _requiredField,
                      ),

                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        initialValue:
                            _experienceLevel,
                        decoration: const InputDecoration(
                          labelText:
                              'Experience Level',
                          prefixIcon: Icon(
                            Icons.stairs_outlined,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Entry Level',
                            child: Text(
                              'Entry Level',
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Junior',
                            child: Text('Junior'),
                          ),
                          DropdownMenuItem(
                            value: 'Mid Level',
                            child:
                                Text('Mid Level'),
                          ),
                          DropdownMenuItem(
                            value: 'Senior',
                            child: Text('Senior'),
                          ),
                          DropdownMenuItem(
                            value: 'Any Level',
                            child:
                                Text('Any Level'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;

                          setState(() {
                            _experienceLevel =
                                value;
                          });
                        },
                      ),

                      const SizedBox(height: 10),

                      SwitchListTile.adaptive(
                        contentPadding:
                            EdgeInsets.zero,
                        title: const Text(
                          'Include remote jobs',
                        ),
                        subtitle: const Text(
                          'Also consider jobs that can be performed remotely.',
                        ),
                        value: _includeRemoteJobs,
                        onChanged: (value) {
                          setState(() {
                            _includeRemoteJobs =
                                value;
                          });
                        },
                      ),

                      const SizedBox(height: 20),

                      FilledButton.icon(
                        onPressed:
                            _prepareJobSearch,
                        icon: const Icon(
                          Icons.auto_awesome_rounded,
                        ),
                        label: const Text(
                          'Find Jobs With AI',
                        ),
                        style:
                            FilledButton.styleFrom(
                          backgroundColor:
                              const Color(
                            0xFFF0C75C,
                          ),
                          foregroundColor:
                              const Color(
                            0xFF111827,
                          ),
                          padding:
                              const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      Text(
                        'The AI/backend connection is intentionally not enabled '
                        'in this patch. The next patch will connect this validated '
                        'form to the job-search service without exposing API secrets.',
                        textAlign: TextAlign.center,
                        style: theme
                            .textTheme.bodySmall
                            ?.copyWith(
                          height: 1.45,
                          color: theme
                              .textTheme
                              .bodySmall
                              ?.color
                              ?.withValues(
                                alpha: 0.70,
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

  String? _requiredField(String? value) {
    if (value == null ||
        value.trim().isEmpty) {
      return 'This field is required.';
    }

    return null;
  }

  void _prepareJobSearch() {
    final valid =
        _formKey.currentState?.validate() ??
            false;

    if (!valid) return;

    final request = JobSearchRequest(
      skills: _skillsController.text.trim(),
      currentLocation:
          _currentLocationController.text.trim(),
      targetLocation:
          _targetLocationController.text.trim(),
      experienceLevel: _experienceLevel,
      includeRemoteJobs: _includeRemoteJobs,
    );

    // The object is deliberately constructed now so the next
    // backend patch can send this exact request without changing
    // the form UI.
    debugPrint(
      'Validated job request: ${request.toJson()}',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Job search form is ready. AI job-search integration will be connected next.',
        ),
      ),
    );
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

enum JobApplicationMethod {
  website,
  email,
  linkedin,
  other,
}

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

  factory JobResult.fromJson(
    Map<String, dynamic> json,
  ) {
    final requirementsValue =
        json['requirements'];

    final requirements =
        requirementsValue is List
            ? requirementsValue
                .whereType<String>()
                .map((item) => item.trim())
                .where((item) => item.isNotEmpty)
                .toList()
            : <String>[];

    return JobResult(
      id: _requiredJobString(
        json,
        'id',
      ),
      jobTitle: _requiredJobString(
        json,
        'job_title',
      ),
      companyName: _requiredJobString(
        json,
        'company_name',
      ),
      jobLocation: _requiredJobString(
        json,
        'job_location',
      ),
      workMode: _requiredJobString(
        json,
        'work_mode',
      ),
      employmentType: _requiredJobString(
        json,
        'employment_type',
      ),
      postedAt: _requiredJobString(
        json,
        'posted_at',
      ),
      applicationDeadline:
          _requiredJobString(
        json,
        'application_deadline',
      ),
      shortDescription:
          _requiredJobString(
        json,
        'short_description',
      ),
      requirements: requirements,
      companyUrl: _requiredJobString(
        json,
        'company_url',
      ),
      applyUrl: _requiredJobString(
        json,
        'apply_url',
      ),
      applicationMethod:
          _parseApplicationMethod(
        json['application_method'],
      ),
      sourceUrl: _requiredJobString(
        json,
        'source_url',
      ),
    );
  }

  static String _requiredJobString(
    Map<String, dynamic> json,
    String key,
  ) {
    final value = json[key];

    if (value is! String ||
        value.trim().isEmpty) {
      throw FormatException(
        'Invalid or missing job field: $key',
      );
    }

    return value.trim();
  }

  static JobApplicationMethod
      _parseApplicationMethod(
    dynamic value,
  ) {
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
        throw const FormatException(
          'Invalid application_method.',
        );
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

  factory JobSearchResponse.fromJson(
    Map<String, dynamic> json,
  ) {
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
        final job = JobResult.fromJson(
          Map<String, dynamic>.from(item),
        );

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
      summary:
          (json['summary'] as String?)
                  ?.trim() ??
              '',
      searchedAt:
          (json['searched_at'] as String?)
                  ?.trim() ??
              '',
    );
  }
}

bool isSafeHttpUrl(String value) {
  final uri = Uri.tryParse(value);

  if (uri == null) {
    return false;
  }

  return uri.scheme == 'https' &&
      uri.host.isNotEmpty;
}

bool isSafeJobApplicationUrl(
  JobResult job,
) {
  final uri = Uri.tryParse(
    job.applyUrl,
  );

  if (uri == null) {
    return false;
  }

  switch (job.applicationMethod) {
    case JobApplicationMethod.email:
      return uri.scheme == 'mailto' &&
          uri.path.trim().isNotEmpty;

    case JobApplicationMethod.website:
    case JobApplicationMethod.linkedin:
    case JobApplicationMethod.other:
      return uri.scheme == 'https' &&
          uri.host.isNotEmpty;
  }
}

// class _InfoCard extends StatelessWidget {
//   final IconData icon;
//   final String title;
//   final String description;

//   const _InfoCard({
//     required this.icon,
//     required this.title,
//     required this.description,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);

//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(22),
//       decoration: BoxDecoration(
//         color: theme.cardColor,
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: theme.dividerColor.withValues(alpha: 0.12)),
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             width: 50,
//             height: 50,
//             decoration: BoxDecoration(
//               color: const Color(0xFFF0C75C).withValues(alpha: 0.16),
//               borderRadius: BorderRadius.circular(15),
//             ),
//             child: const Icon(
//               Icons.lightbulb_outline,
//               color: Color(0xFFF0C75C),
//             ),
//           ),

//           const SizedBox(width: 16),

//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Icon(icon, size: 18, color: const Color(0xFFF0C75C)),
//                     const SizedBox(width: 7),
//                     Expanded(
//                       child: Text(
//                         title,
//                         style: theme.textTheme.titleMedium?.copyWith(
//                           fontWeight: FontWeight.w800,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),

//                 const SizedBox(height: 9),

//                 Text(
//                   description,
//                   style: theme.textTheme.bodyMedium?.copyWith(
//                     height: 1.55,
//                     color: theme.textTheme.bodyMedium?.color?.withValues(
//                       alpha: 0.72,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

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
