import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/app_colors.dart';
import '../../../core/theme.dart';
import '../models/post_draft.dart';
import '../providers/my_place_providers.dart';
import '../widgets/common/my_place_app_bar.dart';
import '../widgets/community/board_chip_selector.dart';
import '../widgets/community/image_picker_tile.dart';
import '../widgets/community/tag_input_field.dart';

/// 글쓰기 — 수정도 같은 화면이다
class PostEditorPage extends ConsumerStatefulWidget {
  const PostEditorPage({super.key, this.postId});

  /// null 이면 새 글
  final int? postId;

  @override
  ConsumerState<PostEditorPage> createState() => _PostEditorPageState();
}

class _PostEditorPageState extends ConsumerState<PostEditorPage> {
  final _title = TextEditingController();
  final _content = TextEditingController();
  final _tagInput = TextEditingController();
  final _tagFocus = FocusNode();

  PostDraft _draft = const PostDraft();

  @override
  void initState() {
    super.initState();
    _tagFocus.addListener(() => setState(() {}));

    final postId = widget.postId;
    if (postId == null) return;

    for (final post in ref.read(neighborPostsProvider)) {
      if (post.postId != postId) continue;
      _draft = PostDraft(
        board: post.board,
        title: post.title,
        content: post.body,
        tags: post.tags,
      );
      _title.text = post.title;
      _content.text = post.body;
      break;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    _tagInput.dispose();
    _tagFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final typed = _typedTag;
    final suggestions = ref.watch(tagSuggestionsProvider(typed));

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MyPlaceAppBar(
              title: widget.postId == null ? 'New Post' : 'Edit Post',
              onBack: () => context.pop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  Gap.screenH,
                  Gap.card,
                  Gap.screenH,
                  Gap.lg,
                ),
                children: [
                  const _FieldLabel('Board'),
                  BoardChipSelector(
                    board: _draft.board,
                    onSelected: (board) =>
                        setState(() => _draft = _draft.copyWith(board: board)),
                  ),
                  const SizedBox(height: Gap.lg),
                  const _FieldLabel('Title'),
                  _BoxedField(
                    child: TextField(
                      controller: _title,
                      onChanged: (value) => setState(
                        () => _draft = _draft.copyWith(title: value),
                      ),
                      textInputAction: TextInputAction.next,
                      inputFormatters: [LengthLimitingTextInputFormatter(80)],
                      style: const TextStyle(
                        color: AppColors.cardBody,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: 'What happened?',
                        hintStyle: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: Gap.lg),
                  const _FieldLabel('Details'),
                  _BoxedField(
                    minHeight: 92,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        TextField(
                          controller: _content,
                          onChanged: (value) => setState(
                            () => _draft = _draft.copyWith(content: value),
                          ),
                          minLines: 3,
                          maxLines: 8,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(
                              PostDraft.contentLimit,
                            ),
                          ],
                          style: const TextStyle(
                            color: AppColors.textStrong,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            hintText:
                                'Describe what you see, and when it started.',
                            hintStyle: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          '${_draft.content.length}/${PostDraft.contentLimit}',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Gap.lg),
                  const _FieldLabel('Tags'),
                  TagInputField(
                    tags: _draft.tags,
                    controller: _tagInput,
                    focusNode: _tagFocus,
                    focused: _tagFocus.hasFocus,
                    onChanged: _onTagChanged,
                    onSubmitted: (_) => _addTag(typed),
                    onRemove: _removeTag,
                  ),
                  if (typed.length > 1) ...[
                    const SizedBox(height: Gap.xs),
                    TagSuggestionPanel(
                      suggestions: suggestions,
                      typed: typed,
                      onPick: _addTag,
                      onCreate: () => _addTag(typed),
                    ),
                  ],
                  const SizedBox(height: Gap.lg),
                  const _FieldLabel('Images'),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ImagePickerTile(onTap: _pickImage),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Gap.screenH,
                Gap.sm,
                Gap.screenH,
                Gap.lg,
              ),
              child: _SubmitButton(
                label: widget.postId == null ? 'Post' : 'Save',
                enabled: _draft.canSubmit,
                onTap: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 입력 중인 태그 — 앞의 `#` 는 한 번만 붙인다
  String get _typedTag {
    final text = _tagInput.text.replaceAll('#', '').trim();
    return text.isEmpty ? '' : '#$text';
  }

  /// 엔터와 같이 스페이스바로도 태그를 확정한다
  void _onTagChanged(String value) {
    if (!value.endsWith(' ')) {
      setState(() {});
      return;
    }
    final tag = _typedTag;
    if (tag.length > 1) {
      _addTag(tag);
    } else {
      setState(_tagInput.clear);
    }
  }

  void _addTag(String tag) {
    if (tag.length < 2 || _draft.tags.contains(tag)) return;
    setState(() {
      _draft = _draft.copyWith(tags: [..._draft.tags, tag]);
      _tagInput.clear();
    });
  }

  void _removeTag(String tag) => setState(
    () => _draft = _draft.copyWith(
      tags: [
        for (final item in _draft.tags)
          if (item != tag) item,
      ],
    ),
  );

  void _pickImage() => ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      const SnackBar(content: Text('Photos are not connected yet')),
    );

  /// 칩으로 확정하지 않고 Post 를 눌러도 입력 중이던 태그는 살린다
  PostDraft get _pending {
    final tag = _typedTag;
    if (tag.length < 2 || _draft.tags.contains(tag)) return _draft;
    return _draft.copyWith(tags: [..._draft.tags, tag]);
  }

  void _submit() {
    if (!_draft.canSubmit) return;
    ref
        .read(neighborPostsProvider.notifier)
        .submit(_pending, postId: widget.postId);
    // 새 글은 올린 게시판 탭으로 돌아간다
    context.pop(widget.postId == null ? _draft.board : null);
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Gap.sm),
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

class _BoxedField extends StatelessWidget {
  const _BoxedField({required this.child, this.minHeight = 46});

  final Widget child;
  final double minHeight;

  @override
  Widget build(BuildContext context) => Container(
    constraints: BoxConstraints(minHeight: minHeight),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.divider),
      borderRadius: BorderRadius.circular(Gap.sm),
    ),
    padding: const EdgeInsets.symmetric(horizontal: Gap.card, vertical: 10),
    child: child,
  );
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? AppColors.navy : AppColors.systemPill,
      borderRadius: BorderRadius.circular(Gap.sm),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: enabled ? AppColors.surface : AppColors.textMuted,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
