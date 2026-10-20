import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/app_colors.dart';
import '../../../core/theme.dart';
import '../../assistant/data/assistant_assets.dart';
import '../providers/my_place_providers.dart';
import '../widgets/community/tag_suggestion_tiles.dart';

/// 제목 · 태그 검색 — 입력하는 동안 제안을 띄운다
class CommunitySearchPage extends ConsumerStatefulWidget {
  const CommunitySearchPage({super.key});

  @override
  ConsumerState<CommunitySearchPage> createState() =>
      _CommunitySearchPageState();
}

class _CommunitySearchPageState extends ConsumerState<CommunitySearchPage> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = ref.watch(tagSuggestionsProvider(_query));
    final recent = ref.watch(recentSearchesProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Gap.md,
                Gap.card,
                Gap.screenH,
                Gap.md,
              ),
              child: Row(
                spacing: Gap.md,
                children: [
                  Semantics(
                    button: true,
                    label: 'Back',
                    child: InkWell(
                      onTap: () => context.pop(),
                      customBorder: const CircleBorder(),
                      child: SizedBox(
                        width: 32,
                        height: 32,
                        child: Center(
                          child: SvgPicture.asset(
                            chatBackIconPath,
                            width: 29,
                            height: 29,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _SearchBar(
                      controller: _controller,
                      onChanged: _onChanged,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  Gap.screenH,
                  Gap.sm,
                  Gap.screenH,
                  Gap.xl,
                ),
                children: [
                  if (suggestions.items.isNotEmpty) ...[
                    const _SectionLabel('Tags'),
                    for (final item in suggestions.items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: Gap.xs),
                        child: TagSuggestionTile(
                          item: item,
                          onTap: () => _openTag(item.tag),
                        ),
                      ),
                    const SizedBox(height: Gap.card),
                  ],
                  if (suggestions.titles.isNotEmpty) ...[
                    const _SectionLabel('Titles'),
                    for (final title in suggestions.titles)
                      Padding(
                        padding: const EdgeInsets.only(bottom: Gap.sm),
                        child: TitleSuggestionTile(
                          suggestion: title,
                          onTap: () => context.push(
                            '/my-place/community/post/${title.postId}',
                          ),
                        ),
                      ),
                    const SizedBox(height: Gap.card),
                  ],
                  if (_query.isNotEmpty && suggestions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: Gap.lg),
                      child: Text(
                        'Nothing matches that yet',
                        style: TextStyle(
                          color: AppColors.textSubtle,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  if (recent.isNotEmpty) ...[
                    const _SectionLabel('Recent Searches'),
                    Wrap(
                      spacing: Gap.sm,
                      runSpacing: Gap.sm,
                      children: [
                        for (final tag in recent)
                          RecentSearchChip(
                            tag: tag,
                            onTap: () => _openTag(tag),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onChanged(String value) => setState(() => _query = value);

  void _openTag(String tag) {
    ref.read(recentSearchesProvider.notifier).record(tag);
    context.push('/my-place/community/tags/${Uri.encodeComponent(tag)}');
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.navy, width: 1.5),
        borderRadius: BorderRadius.circular(Gap.sm),
      ),
      padding: const EdgeInsets.symmetric(horizontal: Gap.card),
      child: Row(
        spacing: Gap.sm,
        children: [
          const Icon(LucideIcons.search, size: 18, color: AppColors.textTitle),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              autofocus: true,
              textInputAction: TextInputAction.search,
              inputFormatters: [LengthLimitingTextInputFormatter(40)],
              style: const TextStyle(
                color: AppColors.textTitle,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Search title or #tag',
                hintStyle: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Gap.card),
    child: Text(
      label,
      style: const TextStyle(
        color: AppColors.textTitle,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 1.3,
      ),
    ),
  );
}
