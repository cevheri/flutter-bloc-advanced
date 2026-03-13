import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/testing/app_key_constants.dart';
import '../../../../generated/l10n.dart';
import '../../../../infrastructure/config/template_config.dart';

class CommunityUrls {
  static const repo = 'https://github.com/cevheri/flutter-bloc-advanced';
  static const issues = 'https://github.com/cevheri/flutter-bloc-advanced/issues';
  static const discussions = 'https://github.com/cevheri/flutter-bloc-advanced/discussions';
  static const contributing = 'https://github.com/cevheri/flutter-bloc-advanced/blob/main/CONTRIBUTING.md';
  static const translate = 'https://github.com/cevheri/flutter-bloc-advanced/tree/main/lib/l10n';
  static const sponsor = 'https://github.com/sponsors/cevheri';
  static const docs = TemplateConfig.docsUrl;
}

class _CommunityAction {
  final Key key;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String Function(S l10n) label;
  final String url;

  const _CommunityAction({
    required this.key,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.label,
    required this.url,
  });
}

final List<_CommunityAction> _communityActions = [
  _CommunityAction(
    key: communityStarKey,
    icon: Icons.star_border_rounded,
    iconBackground: const Color(0xFF6366F1),
    iconColor: const Color(0xFFA5B4FC),
    label: (l10n) => l10n.community_star,
    url: CommunityUrls.repo,
  ),
  _CommunityAction(
    key: communityIssueKey,
    icon: Icons.bug_report_outlined,
    iconBackground: const Color(0xFFEF4444),
    iconColor: const Color(0xFFFCA5A5),
    label: (l10n) => l10n.community_issue,
    url: CommunityUrls.issues,
  ),
  _CommunityAction(
    key: communityDiscussionsKey,
    icon: Icons.forum_outlined,
    iconBackground: const Color(0xFF06B6D4),
    iconColor: const Color(0xFF67E8F9),
    label: (l10n) => l10n.community_discussions,
    url: CommunityUrls.discussions,
  ),
  _CommunityAction(
    key: communityContributeKey,
    icon: Icons.code_rounded,
    iconBackground: const Color(0xFF8B5CF6),
    iconColor: const Color(0xFFC4B5FD),
    label: (l10n) => l10n.community_contribute,
    url: CommunityUrls.contributing,
  ),
  _CommunityAction(
    key: communityTranslateKey,
    icon: Icons.translate_rounded,
    iconBackground: const Color(0xFF10B981),
    iconColor: const Color(0xFF6EE7B7),
    label: (l10n) => l10n.community_translate,
    url: CommunityUrls.translate,
  ),
  _CommunityAction(
    key: communitySponsorKey,
    icon: Icons.favorite_border_rounded,
    iconBackground: const Color(0xFFEC4899),
    iconColor: const Color(0xFFF9A8D4),
    label: (l10n) => l10n.community_sponsor,
    url: CommunityUrls.sponsor,
  ),
  _CommunityAction(
    key: communityDocsKey,
    icon: Icons.menu_book_rounded,
    iconBackground: const Color(0xFFF59E0B),
    iconColor: const Color(0xFFFCD34D),
    label: (l10n) => l10n.community_docs,
    url: CommunityUrls.docs,
  ),
];

Future<void> _launchCommunityUrl(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class CommunitySectionWidget extends StatelessWidget {
  final bool isDesktop;

  const CommunitySectionWidget({super.key, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return isDesktop ? _DesktopCommunitySection() : _MobileCommunitySection();
  }
}

class _DesktopCommunitySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.community_title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.community_subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.45), height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _openSourcePill(),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _communityActions.map((action) => _DesktopCommunityCard(action: action)).toList(),
        ),
      ],
    );
  }

  Widget _openSourcePill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.25)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_open_rounded, size: 13, color: Color(0xFF6EE7B7)),
          SizedBox(width: 6),
          Text(
            'Open Source',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6EE7B7), letterSpacing: -0.2),
          ),
        ],
      ),
    );
  }
}

class _DesktopCommunityCard extends StatefulWidget {
  final _CommunityAction action;

  const _DesktopCommunityCard({required this.action});

  @override
  State<_DesktopCommunityCard> createState() => _DesktopCommunityCardState();
}

class _DesktopCommunityCardState extends State<_DesktopCommunityCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final action = widget.action;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 160),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: GestureDetector(
              onTap: () => _launchCommunityUrl(action.url),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: _isHovered ? 0.10 : 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: _isHovered ? 0.15 : 0.08)),
                ),
                child: Row(
                  key: action.key,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: action.iconBackground.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(action.icon, size: 16, color: action.iconColor),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      action.label(l10n),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: _isHovered ? 0.95 : 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileCommunitySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = S.of(context);

    return Column(
      children: [
        const SizedBox(height: 24),
        Divider(color: cs.outlineVariant),
        const SizedBox(height: 16),
        Text(
          l10n.community_title,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.community_subtitle,
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: _communityActions.map((action) => _MobileCommunityChip(action: action)).toList(),
        ),
      ],
    );
  }
}

class _MobileCommunityChip extends StatelessWidget {
  final _CommunityAction action;

  const _MobileCommunityChip({required this.action});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = S.of(context);

    return GestureDetector(
      onTap: () => _launchCommunityUrl(action.url),
      child: Container(
        key: action.key,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(action.icon, size: 14, color: action.iconBackground),
            const SizedBox(width: 6),
            Text(
              action.label(l10n),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
