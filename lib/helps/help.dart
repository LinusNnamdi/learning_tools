import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────────────────────
class HelpFaqItem {
  final String question;
  final String answer;

  const HelpFaqItem({required this.question, required this.answer});
}

// ─────────────────────────────────────────────────────────────
// FAQ content for every page
// ─────────────────────────────────────────────────────────────
class HelpFaqData {
  // ── WORKSPACE (Home tools) – 20+ ──────────────────────────
  static const List<HelpFaqItem> workspace = [
    HelpFaqItem(
      question: 'How do I start a new diagram?',
      answer: 'On the Home screen tap “Start Work”. This opens a blank workspace where you can add shapes, containers and connections.',
    ),
    HelpFaqItem(
      question: 'How do I add a shape / component?',
      answer: 'Use the shape palette at the top. Select a shape type, then tap anywhere on the canvas to place it.',
    ),
    HelpFaqItem(
      question: 'How do I connect two components?',
      answer: 'Select the “Connection” tool (Single → or Double ↔), then tap the source shape and the target shape.',
    ),
    HelpFaqItem(
      question: 'How do I move or resize a component?',
      answer: 'Tap a component to select it. Drag it to move. Use the small handle at the bottom-right corner to resize.',
    ),
    HelpFaqItem(
      question: 'How do I edit the name or colour of a component?',
      answer: 'Long-press the component (or use the Edit button in the toolbar) and change the text, fill colour or border colour.',
    ),
    HelpFaqItem(
      question: 'What does the Play button do?',
      answer: 'Play animates information flow along the connections so you can demonstrate how data moves through your architecture.',
    ),
    HelpFaqItem(
      question: 'How do I save my work?',
      answer: 'Use the save option in the toolbar / menu. You can give the diagram a name and put it in any folder you like.',
    ),
    HelpFaqItem(
      question: 'Where are my saved diagrams?',
      answer: 'Tap “View Saved Work” on the Home screen or the folder icon in the workspace toolbar. Diagrams are grouped by folder.',
    ),
    HelpFaqItem(
      question: 'Can I duplicate a shape or container?',
      answer: 'Yes. Select it and tap the Duplicate button in the toolbar, or long-press and choose Duplicate.',
    ),
    HelpFaqItem(
      question: 'How do I delete one or many components?',
      answer: 'Select the item(s) and tap Delete. You can also long-press and choose Delete. “Delete All” clears the whole canvas.',
    ),
    HelpFaqItem(
      question: 'What is Undo / Redo?',
      answer: 'Undo reverses your last action; Redo brings it back. Both are available in the workspace toolbar.',
    ),
    HelpFaqItem(
      question: 'Can I change connection style or colour?',
      answer: 'Yes. Select a connection, open Edit, then choose Single/Double arrow and pick a colour.',
    ),
    HelpFaqItem(
      question: 'How do containers work?',
      answer: 'Containers group related components. Select the Container tool, place it, then drag shapes inside or onto it.',
    ),
    HelpFaqItem(
      question: 'Is there a grid on the canvas?',
      answer: 'Yes. A light grid helps alignment. It adapts automatically to light and dark theme.',
    ),
    HelpFaqItem(
      question: 'Can I work offline?',
      answer: 'Yes. Creating, editing and saving diagrams works offline. Only features that need the internet (AI job search, ads, etc.) require a connection.',
    ),
    HelpFaqItem(
      question: 'How do I switch between light and dark mode?',
      answer: 'Use the sun/moon icon in the top AppBar on the Home screen. Your preference is remembered.',
    ),
    HelpFaqItem(
      question: 'What does “Reset” do in the animation toolbar?',
      answer: 'Reset stops the current animation and returns all moving particles to the start of their paths.',
    ),
    HelpFaqItem(
      question: 'Can I select multiple components at once?',
      answer: 'Long-press supports multi-selection in supported modes. Selected items can then be moved, duplicated or deleted together.',
    ),
    HelpFaqItem(
      question: 'My diagram disappeared after leaving the page. What happened?',
      answer: 'Unsaved work may be lost if the app is killed. Always save important diagrams. Saved projects reappear under “View Saved Work”.',
    ),
    HelpFaqItem(
      question: 'Who can I contact if something is broken?',
      answer: 'Go to the Jobs → Contact Us tab and reach us via WhatsApp or Email. Describe the problem and we will help.',
    ),
  ];

  // ── COURSES – ~8–10 ───────────────────────────────────────
  static const List<HelpFaqItem> courses = [
    HelpFaqItem(
      question: 'What is the Courses section for?',
      answer: 'Courses lets you explore learning materials and structured content related to the skills and tools covered in Learning Tech / EarnDee.',
    ),
    HelpFaqItem(
      question: 'How do I open a course?',
      answer: 'Tap any course card. It will open the course content or launch the related screen.',
    ),
    HelpFaqItem(
      question: 'Are the courses free?',
      answer: 'Most content inside the app is free to access. Any paid or external resources will be clearly marked.',
    ),
    HelpFaqItem(
      question: 'Can I download courses for offline use?',
      answer: 'Offline download depends on the specific course. If a download option is available it will appear on the course page.',
    ),
    HelpFaqItem(
      question: 'How do I track my progress?',
      answer: 'Progress is shown on course cards or inside the course when that feature is enabled. Completed items are usually marked visually.',
    ),
    HelpFaqItem(
      question: 'I cannot open a course. What should I do?',
      answer: 'Check your internet connection first. If the problem continues, restart the app or contact us via the Contact Us tab.',
    ),
    HelpFaqItem(
      question: 'Are new courses added regularly?',
      answer: 'Yes. We add and update courses over time. Keep the app updated to see the latest content.',
    ),
    HelpFaqItem(
      question: 'Can I suggest a new course topic?',
      answer: 'Absolutely. Use Jobs → Contact Us and tell us what you would like to learn. We read every request.',
    ),
  ];

  // ── GAMES – ~8–10 ─────────────────────────────────────────
  static const List<HelpFaqItem> games = [
    HelpFaqItem(
      question: 'What kind of games are available?',
      answer: 'The Games section contains educational and skill-building games that reinforce concepts from the rest of the app.',
    ),
    HelpFaqItem(
      question: 'How do I start a game?',
      answer: 'Tap a game card. The game will load and you can begin playing immediately.',
    ),
    HelpFaqItem(
      question: 'Do games work offline?',
      answer: 'Many games work offline once they have been opened at least once. Some may need a short online check the first time.',
    ),
    HelpFaqItem(
      question: 'How do I exit a game?',
      answer: 'Use the back button / system back gesture, or any Exit / Home control provided inside the game.',
    ),
    HelpFaqItem(
      question: 'Can I reset my game progress?',
      answer: 'If a reset option exists it will be inside the game settings or on the game card. Otherwise progress is stored locally.',
    ),
    HelpFaqItem(
      question: 'A game is lagging or crashing. What can I do?',
      answer: 'Close other apps, restart Learning Tech, and make sure your device has enough free memory. Contact us if it keeps happening.',
    ),
    HelpFaqItem(
      question: 'Are the games suitable for beginners?',
      answer: 'Yes. Most games start simple and increase in difficulty so both beginners and advanced users can enjoy them.',
    ),
    HelpFaqItem(
      question: 'Can I request a new game idea?',
      answer: 'Yes. Send your idea through the Contact Us tab. We love community suggestions.',
    ),
  ];

  // ── CONTACT US – ~8–10 ────────────────────────────────────
  static const List<HelpFaqItem> contactUs = [
    HelpFaqItem(
      question: 'How can I contact EarnDee?',
      answer: 'Use the WhatsApp or Email options on this page. Fill in your name, the service you need, and a short description, then continue.',
    ),
    HelpFaqItem(
      question: 'What services does EarnDee offer?',
      answer: 'We offer Software, Web, Cloud and DevOps services. Choose the closest option when you fill the contact form.',
    ),
    HelpFaqItem(
      question: 'Do I need to create an account to contact you?',
      answer: 'No. Just open the contact form, enter your details and send the message via WhatsApp or Email.',
    ),
    HelpFaqItem(
      question: 'How fast do you reply?',
      answer: 'We usually respond within one business day. Urgent requests sent via WhatsApp are often answered faster.',
    ),
    HelpFaqItem(
      question: 'Can I attach files or screenshots?',
      answer: 'After the message opens in WhatsApp or your email app you can attach files there before sending.',
    ),
    HelpFaqItem(
      question: 'Is my information kept private?',
      answer: 'Yes. We only use the details you send to understand and reply to your request. We do not sell your data.',
    ),
    HelpFaqItem(
      question: 'The WhatsApp / Email button does nothing. Why?',
      answer: 'Make sure WhatsApp or an email app is installed. Also check that the device allows opening external links.',
    ),
    HelpFaqItem(
      question: 'Where can I see your previous work?',
      answer: 'Use the TikTok, LinkedIn and GitHub links on this same page to view projects and updates.',
    ),
  ];

  // ── JOB FINDER – ~12–15 ───────────────────────────────────
  static const List<HelpFaqItem> jobFinder = [
    HelpFaqItem(
      question: 'How does “Find Jobs With AI” work?',
      answer: 'You enter your skills, current location, preferred location and experience level. The AI searches the live web and returns matching job openings.',
    ),
    HelpFaqItem(
      question: 'Why do I have to watch an ad?',
      answer: 'The AI job search uses paid API calls. Rewarded ads help cover that cost so we can keep the feature available to you.',
    ),
    HelpFaqItem(
      question: 'Why is the button disabled on the website?',
      answer: 'AI job search is only available in the Android app (where rewarded ads work). On the web you will see a “Download app to continue” button.',
    ),
    HelpFaqItem(
      question: 'How do I save a job?',
      answer: 'On any job card tap the bookmark icon. Saved jobs appear when you open the “Saved Jobs” floating button.',
    ),
    HelpFaqItem(
      question: 'How do I open or copy a job link?',
      answer: 'Use “Visit page” to open the posting or the copy icon to copy the link. On mobile you may need to watch a short ad first.',
    ),
    HelpFaqItem(
      question: 'Why did I see “No Jobs Found” even though the summary mentioned jobs?',
      answer: 'The AI sometimes writes a summary before fully validating every result. Only jobs with usable titles and safe URLs are shown in the list.',
    ),
    HelpFaqItem(
      question: 'Are the job links safe?',
      answer: 'Yes. Only http/https links with a valid host are accepted. Fake or malformed URLs are filtered out.',
    ),
    HelpFaqItem(
      question: 'Can I search for remote jobs?',
      answer: 'Yes. Turn on “Include remote jobs” and set your preferred location to Remote or leave it broad.',
    ),
    HelpFaqItem(
      question: 'How recent are the job results?',
      answer: 'The AI is instructed to return openings posted or still open within the last 90 days.',
    ),
    HelpFaqItem(
      question: 'I watched the ad but still got an error. What now?',
      answer: 'Check your internet connection and try again. If the AI service is busy you may see a temporary error message.',
    ),
    HelpFaqItem(
      question: 'Can I remove ads?',
      answer: 'Yes. A “Remove Ads” option (via in-app purchase) will skip rewarded ads for job search, visit and copy actions.',
    ),
    HelpFaqItem(
      question: 'Does job search work offline?',
      answer: 'No. Live web search and the AI backend require an internet connection.',
    ),
  ];
}

// ─────────────────────────────────────────────────────────────
// Simple connectivity check (no extra package required)
// ─────────────────────────────────────────────────────────────
Future<bool> hasInternetConnection() async {
  try {
    // Lightweight DNS-style check that works on mobile & web
    final result = await InternetAddress.lookup('google.com')
        .timeout(const Duration(seconds: 4));
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } catch (_) {
    // On web InternetAddress may not be available – fall back
    if (kIsWeb) {
      try {
        // ignore: avoid_web_libraries_in_flutter
        // A simple alternative for web is to assume online
        // or use a package. For now we treat web as online
        // when the page itself loaded.
        return true;
      } catch (_) {
        return false;
      }
    }
    return false;
  }
}

// ─────────────────────────────────────────────────────────────
// Main Help Screen – “EarnDee AI”
// ─────────────────────────────────────────────────────────────
class EarnDeeAiHelpScreen extends StatelessWidget {
  final String pageTitle;
  final List<HelpFaqItem> faqs;

  const EarnDeeAiHelpScreen({
    super.key,
    required this.pageTitle,
    required this.faqs,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'EarnDee AI',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                pageTitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodySmall?.color?.withValues(
                    alpha: 0.7,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        itemCount: faqs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = faqs[index];
          return _FaqQuestionTile(item: item);
        },
      ),
    );
  }
}

class _FaqQuestionTile extends StatelessWidget {
  final HelpFaqItem item;

  const _FaqQuestionTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openAnswer(context, item),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const Icon(Icons.help_outline_rounded, color: Color(0xFFF0C75C)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.question,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openAnswer(BuildContext context, HelpFaqItem item) async {
    // 1. Check internet
    final online = await hasInternetConnection();

    if (!context.mounted) return;

    if (!online) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No internet connection. Please check your network.'),
        ),
      );
      return;
    }

    // 2. Show loading dialog for 3 seconds (fake thinking)
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _ThinkingDialog(),
    );

    await Future.delayed(const Duration(seconds: 3));

    if (!context.mounted) return;
    Navigator.of(context).pop(); // close loading

    // 3. Show the stored answer
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.question,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  item.answer,
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(height: 1.5),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFF0C75C),
                      foregroundColor: const Color(0xFF111827),
                    ),
                    child: const Text('Got it'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ThinkingDialog extends StatelessWidget {
  const _ThinkingDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            SizedBox(height: 18),
            Text(
              'EarnDee AI is thinking…',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Helper to open the help screen from any page
// ─────────────────────────────────────────────────────────────
void openEarnDeeAiHelp(
  BuildContext context, {
  required String pageTitle,
  required List<HelpFaqItem> faqs,
}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => EarnDeeAiHelpScreen(pageTitle: pageTitle, faqs: faqs),
    ),
  );
}
