import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/community.dart';
import '../../../data/photo_prep.dart';
import '../../../l10n/app_localizations.dart';
import '../../../state/community_state.dart';
import '../../motion.dart';
import '../../theme.dart';
import 'community_common.dart';
import 'community_widgets.dart';

/// Write a post (or edit one's text and tag): returns the saved post.
Future<Post?> showComposeSheet(
  BuildContext context, {
  required String gymId,
  Post? editing,
}) => showModalBottomSheet<Post>(
  context: context,
  isScrollControlled: true,
  sheetAnimationStyle: Motion.sheet,
  builder: (_) => FractionallySizedBox(
    heightFactor: 0.92,
    child: _ComposeSheet(gymId: gymId, editing: editing),
  ),
);

class _ComposeSheet extends StatefulWidget {
  final String gymId;
  final Post? editing;
  const _ComposeSheet({required this.gymId, this.editing});

  @override
  State<_ComposeSheet> createState() => _ComposeSheetState();
}

class _ComposeSheetState extends State<_ComposeSheet> {
  late final _body = TextEditingController(text: widget.editing?.body);
  late var _tag = widget.editing?.tag ?? PostTag.free;
  final _photos = <Uint8List>[];
  var _busy = false;
  var _picking = false;

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  /// Something typed or picked that closing would throw away.
  bool get _dirty =>
      _body.text.trim() != (widget.editing?.body ?? '').trim() ||
      _photos.isNotEmpty;

  /// Close (the ✕, back, a tap outside or a swipe down): asks first when
  /// there's something to lose.
  Future<void> _close() async {
    if (!_dirty || _busy) {
      if (!_busy) Navigator.pop(context);
      return;
    }
    final t = L.of(context);
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.discardDraftTitle),
        content: Text(t.discardDraftBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.keepWriting),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              t.discardDraft,
              style: const TextStyle(color: AppColors.over),
            ),
          ),
        ],
      ),
    );
    if (discard == true && mounted) Navigator.pop(context);
  }

  String _hint(L t) => switch (_tag) {
    PostTag.mate => t.tagHintMate,
    PostTag.question => t.tagHintQuestion,
    PostTag.info => t.tagHintInfo,
    PostTag.review => t.tagHintReview,
    PostTag.free => t.tagHintFree,
  };

  Future<void> _pick() async {
    final t = L.of(context);
    final room = CommunityLimits.photos - _photos.length;
    if (room <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.photoLimit('${CommunityLimits.photos}'))),
      );
      return;
    }
    setState(() => _picking = true);
    try {
      final files = await ImagePicker().pickMultiImage(
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 82,
        limit: room > 1 ? room : null,
      );
      var rejected = false;
      final picked = <Uint8List>[];
      for (final f in files.take(room)) {
        // Every photo becomes a plain JPEG: HEIC and other formats work,
        // and the location saved in the photo is dropped.
        final bytes = await prepareUploadPhoto(await f.readAsBytes());
        if (bytes == null || bytes.length > CommunityLimits.photoBytes) {
          rejected = true;
        } else {
          picked.add(bytes);
        }
      }
      if (!mounted) return;
      setState(() => _photos.addAll(picked));
      if (rejected) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(t.badImage)));
      }
    } catch (e) {
      debugPrint('photo pick failed: $e');
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _submit() async {
    final text = _body.text.trim();
    // Photos still being read would be left out.
    if (text.isEmpty || _busy || _picking) return;
    setState(() => _busy = true);
    final repo = CommunityScope.read(context).repo;
    try {
      final post = widget.editing == null
          ? await repo.writePost(widget.gymId, text, _photos, tag: _tag)
          : await repo.editPost(widget.editing!, text, tag: _tag);
      if (mounted) Navigator.pop(context, post);
    } catch (e) {
      if (mounted) showCommunityError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final editing = widget.editing != null;
    final (_, _, tagColor, tagSoft) = tagStyle(t, _tag);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          4,
          16,
          12 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  icon: const Icon(Icons.close_rounded),
                  onPressed: _close,
                ),
                Expanded(
                  child: Text(
                    editing ? t.editPost : t.writePost,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                ListenableBuilder(
                  listenable: _body,
                  builder: (context, _) {
                    final ready =
                        !_busy && !_picking && _body.text.trim().isNotEmpty;
                    return AnimatedOpacity(
                      duration: Motion.fast,
                      opacity: ready ? 1 : 0.45,
                      child: GestureDetector(
                        onTap: ready ? _submit : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.peach, Color(0xFFFFA98F)],
                            ),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: ready
                                ? [
                                    BoxShadow(
                                      color: AppColors.peach.withValues(
                                        alpha: 0.35,
                                      ),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: _busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  editing ? t.save : t.postSubmit,
                                  style: const TextStyle(
                                    fontFamily: headingFont,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                t.chooseTag,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inkSoft,
                ),
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in TagFilterBar.order)
                  _TagOption(
                    tag: tag,
                    selected: tag == _tag,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _tag = tag);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: AnimatedContainer(
                duration: Motion.medium,
                curve: Motion.ease,
                decoration: BoxDecoration(
                  color: tagSoft.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: tagColor.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
                child: TextField(
                  controller: _body,
                  autofocus: !editing,
                  maxLines: null,
                  expands: true,
                  maxLength: CommunityLimits.postLength,
                  textAlignVertical: TextAlignVertical.top,
                  style: const TextStyle(fontSize: 15.5, height: 1.55),
                  decoration: InputDecoration(
                    hintText: _hint(t),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            if (!editing) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 78,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _AddPhoto(
                      count: _photos.length,
                      busy: _picking,
                      onTap: _busy || _picking ? null : _pick,
                    ),
                    for (final (i, b) in _photos.indexed)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: FadeSlideIn(
                          key: ValueKey(b.hashCode),
                          dy: 6,
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.memory(
                                  b,
                                  width: 78,
                                  height: 78,
                                  fit: BoxFit.cover,
                                  cacheWidth: 234,
                                ),
                              ),
                              Positioned(
                                right: 4,
                                top: 4,
                                child: GestureDetector(
                                  onTap: _busy
                                      ? null
                                      : () =>
                                            setState(() => _photos.removeAt(i)),
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close_rounded,
                                      size: 13,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TagOption extends StatelessWidget {
  final PostTag tag;
  final bool selected;
  final VoidCallback onTap;
  const _TagOption({
    required this.tag,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (label, icon, fg, bg) = tagStyle(L.of(context), tag);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Motion.fast,
        curve: Motion.ease,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? fg : bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: selected ? Colors.white : fg),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontFamily: headingFont,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: selected ? Colors.white : fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddPhoto extends StatelessWidget {
  final int count;
  final bool busy;
  final VoidCallback? onTap;
  const _AddPhoto({required this.count, required this.busy, this.onTap});

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: L.of(context).addPhotos('$count', '${CommunityLimits.photos}'),
    excludeSemantics: true,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: 78,
        height: 78,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.line, width: 1.6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: busy
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_photo_alternate_rounded,
                    color: AppColors.peach,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$count/${CommunityLimits.photos}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
      ),
    ),
  );
}
