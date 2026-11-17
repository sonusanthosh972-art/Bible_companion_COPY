import 'dart:io';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../services/image_service.dart';

/// Verse-card composer modelled on the reference editor:
///  • large live preview, Classic / Poster style toggle
///  • a background gallery backed by the real image API (named categories)
///  • Background / Typography / Format / More Options rows that open editors
///  • Instagram export formats (9:16, 4:5, 1:1, 1.91:1)
///  • renders the preview to a PNG at the format's resolution and shares it.
class ShareVerseScreen extends StatefulWidget {
  const ShareVerseScreen({
    super.key,
    required this.verse,
    required this.reference,
    required this.lang,
    this.userName,
  });

  final String verse;
  final String reference;
  final String lang;
  final String? userName;

  @override
  State<ShareVerseScreen> createState() => _ShareVerseScreenState();
}

enum _Style { classic, poster }

enum _FontStyle { serif, sans, classic, modern, elegant, bold }

enum _Fmt { story, portrait, square, landscape }

/// A background: a gradient preset, a photo (from the image API or the user).
class _Bg {
  _Bg.gradient(this.colors, {this.darkText = false})
      : url = null,
        file = null,
        catKey = null;
  _Bg.photo(this.url, {this.catKey})
      : colors = null,
        darkText = false,
        file = null;
  _Bg.file(this.file)
      : colors = null,
        darkText = false,
        url = null,
        catKey = null;

  final List<Color>? colors;
  final bool darkText;
  final String? url;
  final File? file;
  final String? catKey;

  bool get isGradient => colors != null;
  bool get isPhoto => url != null || file != null;
}

class _ShareVerseScreenState extends State<ShareVerseScreen> {
  final GlobalKey _cardKey = GlobalKey();
  final ImageService _images = ImageService();

  // Named background categories -> image-API search query. Thumbnails and the
  // full "See all" grid are fetched live from the backend image proxy.
  static const List<(String, String)> _categories = [
    ('bg_golden_waters', 'golden ocean sunset water'),
    ('bg_lake_reflection', 'lake reflection mountains calm'),
    ('bg_golden_ridges', 'golden mountain ridges sunset'),
    ('bg_sunrise', 'sunrise mountains sky'),
    ('bg_mountains', 'mountain valley landscape'),
    ('bg_nature', 'forest green trees landscape'),
    ('bg_sky', 'blue sky clouds'),
    ('bg_ocean', 'ocean sea waves'),
  ];

  static final List<_Bg> _gradients = [
    _Bg.gradient(const [Color(0xFFFDF1CE), Color(0xFFF2CE7B)], darkText: true),
    _Bg.gradient(const [Color(0xFF26424D), Color(0xFF0F2027)]),
    _Bg.gradient(const [Color(0xFF355C3A), Color(0xFF17301A)]),
    _Bg.gradient(const [Color(0xFF6A3A6E), Color(0xFF3A2142)]),
    _Bg.gradient(const [Color(0xFF2C5364), Color(0xFF1C333D)]),
    _Bg.gradient(const [Color(0xFF3A2A25), Color(0xFF17100E)]),
  ];

  // Representative thumbnail per category (null while loading / on failure).
  final Map<String, SectionImage?> _thumbs = {};
  bool _thumbsLoading = true;

  _Style _style = _Style.classic;
  _FontStyle _fontStyle = _FontStyle.serif;
  _Fmt _fmt = _Fmt.portrait;
  TextAlign _align = TextAlign.center;
  double _sizeScale = 1.0;
  bool _showReference = true;
  bool _showLogo = true;
  bool _showName = false;
  bool _sharing = false;

  late _Bg _bg = _gradients.first;
  double _previewW = 360; // last laid-out preview width, for export resolution

  @override
  void initState() {
    super.initState();
    _loadThumbs();
  }

  Future<void> _loadThumbs() async {
    await Future.wait(_categories.map((c) async {
      try {
        final list =
            await _images.forQueryList(c.$2, count: 1, orientation: 'landscape');
        if (list.isNotEmpty) _thumbs[c.$1] = list.first;
      } catch (_) {
        _thumbs[c.$1] = null;
      }
    }));
    if (mounted) setState(() => _thumbsLoading = false);
  }

  // ---- Fonts (Instagram-style, script-aware) -------------------------------

  String _fontName(_FontStyle s) {
    switch (widget.lang) {
      case 'hi':
        return switch (s) {
          _FontStyle.serif => 'Tiro Devanagari Hindi',
          _FontStyle.sans => 'Noto Sans Devanagari',
          _FontStyle.classic => 'Mukta',
          _FontStyle.modern => 'Hind',
          _FontStyle.elegant => 'Baloo 2',
          _FontStyle.bold => 'Noto Sans Devanagari',
        };
      case 'ta':
        return switch (s) {
          _FontStyle.serif => 'Catamaran',
          _FontStyle.sans => 'Noto Sans Tamil',
          _FontStyle.classic => 'Mukta Malar',
          _FontStyle.modern => 'Hind Madurai',
          _FontStyle.elegant => 'Pavanam',
          _FontStyle.bold => 'Noto Sans Tamil',
        };
      default:
        return switch (s) {
          _FontStyle.serif => 'Lora',
          _FontStyle.sans => 'Inter',
          _FontStyle.classic => 'EB Garamond',
          _FontStyle.modern => 'Montserrat',
          _FontStyle.elegant => 'Playfair Display',
          _FontStyle.bold => 'Oswald',
        };
    }
  }

  String? get _fallbackFamily => switch (widget.lang) {
        'hi' => 'NotoSansDevanagari',
        'ta' => 'NotoSansTamil',
        _ => null,
      };

  TextStyle _font(
    _FontStyle s, {
    required double fontSize,
    required Color color,
    FontStyle? style,
    double height = 1.4,
    double letterSpacing = 0,
  }) {
    final weight = s == _FontStyle.bold ? FontWeight.w700 : FontWeight.w500;
    try {
      return GoogleFonts.getFont(
        _fontName(s),
        fontSize: fontSize,
        color: color,
        fontWeight: weight,
        fontStyle: style,
        height: height,
        letterSpacing: letterSpacing,
      );
    } catch (_) {
      return TextStyle(
        fontFamily: _fallbackFamily,
        fontSize: fontSize,
        color: color,
        fontWeight: weight,
        fontStyle: style,
        height: height,
        letterSpacing: letterSpacing,
      );
    }
  }

  // ---- Format --------------------------------------------------------------

  double get _aspect => switch (_fmt) {
        _Fmt.story => 9 / 16,
        _Fmt.portrait => 4 / 5,
        _Fmt.square => 1,
        _Fmt.landscape => 1.91,
      };

  String _fmtLabel(AppLocalizations l) => switch (_fmt) {
        _Fmt.story => '${l.t('share_fmt_story')} (9:16)',
        _Fmt.portrait => '${l.t('share_fmt_portrait')} (4:5)',
        _Fmt.square => '${l.t('share_fmt_square')} (1:1)',
        _Fmt.landscape => '${l.t('share_fmt_landscape')} (1.91:1)',
      };

  String _fontLabel(AppLocalizations l, _FontStyle s) => switch (s) {
        _FontStyle.serif => l.t('share_font_serif'),
        _FontStyle.sans => l.t('share_font_sans'),
        _FontStyle.classic => l.t('share_style_classic'),
        _FontStyle.modern => 'Modern',
        _FontStyle.elegant => 'Elegant',
        _FontStyle.bold => l.t('share_font_bold'),
      };

  // ---- Actions -------------------------------------------------------------

  Future<void> _pickPhoto() async {
    final failMsg = AppLocalizations.of(context).t('share_photo_failed');
    try {
      final x = await ImagePicker().pickImage(
          source: ImageSource.gallery, maxWidth: 2200, imageQuality: 92);
      if (x == null || !mounted) return;
      setState(() => _bg = _Bg.file(File(x.path)));
    } catch (_) {
      if (mounted) _toast(failMsg);
    }
  }

  Future<void> _share() async {
    if (_sharing) return;
    final failMsg = AppLocalizations.of(context).t('share_photo_failed');
    setState(() => _sharing = true);
    try {
      // Give any newly selected Google Font a moment to finish loading so it is
      // baked into the exported image, then capture at export resolution.
      await Future<void>.delayed(const Duration(milliseconds: 180));
      final boundary =
          _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final pr = (1080 / _previewW).clamp(1.0, 4.0).toDouble();
      final image = await boundary.toImage(pixelRatio: pr);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw Exception('encode failed');
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/verse_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(data.buffer.asUint8List());
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        text: '${widget.verse}\n\n${widget.reference}',
      );
    } catch (_) {
      if (mounted) _toast(failMsg);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  void _toast(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  // ---- Build ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.t('share_verse_title'))),
      body: Column(
        children: [
          Expanded(flex: 48, child: _preview()),
          Expanded(
            flex: 52,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _styleToggle(l),
                  const SizedBox(height: 16),
                  _galleryHeader(l),
                  const SizedBox(height: 10),
                  _gallery(l),
                  const SizedBox(height: 14),
                  _panel([
                    _row(
                      icon: Icons.image_outlined,
                      label: l.t('share_background'),
                      value: _bgValueLabel(l),
                      onTap: () => _openBackgroundSheet(l),
                    ),
                    _divider(),
                    _row(
                      icon: Icons.text_fields_rounded,
                      label: l.t('share_typography'),
                      value: _fontLabel(l, _fontStyle),
                      onTap: () => _openTypographySheet(l),
                    ),
                    _divider(),
                    _row(
                      icon: Icons.crop_rounded,
                      label: l.t('share_format'),
                      value: _fmtLabel(l),
                      onTap: () => _openFormatSheet(l),
                    ),
                    _divider(),
                    _row(
                      icon: Icons.tune_rounded,
                      label: l.t('share_more_options'),
                      value: _showReference
                          ? l.t('share_show_reference')
                          : '—',
                      onTap: () => _openMoreSheet(l),
                    ),
                  ]),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    minimumSize: const Size.fromHeight(52)),
                onPressed: _sharing ? null : _share,
                icon: _sharing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.share),
                label: Text(l.t('share_verse_title')),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _bgValueLabel(AppLocalizations l) {
    if (_bg.file != null) return l.t('share_your_photo');
    if (_bg.catKey != null) return l.t(_bg.catKey!);
    if (_bg.url != null) return l.t('bg_nature');
    return l.t('share_bg_gradient');
  }

  // ---- Preview -------------------------------------------------------------

  Widget _preview() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: LayoutBuilder(
        builder: (context, c) {
          var w = c.maxWidth;
          var h = w / _aspect;
          if (h > c.maxHeight) {
            h = c.maxHeight;
            w = h * _aspect;
          }
          _previewW = w;
          return Center(
            child: Material(
              elevation: 10,
              borderRadius:
                  BorderRadius.circular(_style == _Style.poster ? 6 : 20),
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                width: w,
                height: h,
                child: RepaintBoundary(key: _cardKey, child: _card()),
              ),
            ),
          );
        },
      ),
    );
  }

  // ---- Controls: style toggle, gallery -------------------------------------

  Widget _styleToggle(AppLocalizations l) {
    Widget seg(String label, _Style s, IconData icon) {
      final sel = _style == s;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _style = s),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color: sel ? AppColors.brand : Colors.transparent,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 18,
                    color: sel
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(label,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: sel
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
          color: AppTheme.card(context),
          borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        seg(l.t('share_style_classic'), _Style.classic, Icons.notes_rounded),
        seg(l.t('share_style_poster'), _Style.poster, Icons.auto_awesome),
      ]),
    );
  }

  Widget _galleryHeader(AppLocalizations l) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l.t('share_backgrounds'),
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          GestureDetector(
            onTap: () => _openBackgroundSheet(l),
            child: Text(l.t('share_see_all'),
                style: const TextStyle(
                    color: AppColors.brand, fontWeight: FontWeight.w600)),
          ),
        ],
      );

  Widget _gallery(AppLocalizations l) {
    final items = <Widget>[
      _thumb(
        selected: _bg.file != null,
        onTap: _pickPhoto,
        caption: l.t('share_your_photo'),
        child: Container(
          color: AppTheme.card(context),
          child: Icon(Icons.add_photo_alternate_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ),
      _thumb(
        selected: _bg.isGradient,
        onTap: () => setState(() => _bg = _gradients.first),
        caption: l.t('share_bg_gradient'),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _gradients.first.colors!),
          ),
        ),
      ),
      for (final c in _categories)
        _thumb(
          selected: _bg.catKey == c.$1,
          onTap: () {
            final img = _thumbs[c.$1];
            if (img != null) {
              setState(() => _bg = _Bg.photo(img.url, catKey: c.$1));
            }
          },
          caption: l.t(c.$1),
          child: _thumbs[c.$1] != null
              ? CachedNetworkImage(
                  imageUrl: _thumbs[c.$1]!.url,
                  fit: BoxFit.cover,
                  memCacheWidth: 180,
                  placeholder: (_, __) => _shimmer(),
                  errorWidget: (_, __, ___) => _shimmer(),
                )
              : _shimmer(),
        ),
    ];
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => items[i],
      ),
    );
  }

  Widget _shimmer() => Container(
        color: AppTheme.card(context),
        child: _thumbsLoading
            ? const Center(
                child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2)))
            : Icon(Icons.image_not_supported_outlined,
                size: 18,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
      );

  Widget _thumb({
    required bool selected,
    required VoidCallback onTap,
    required Widget child,
    String? caption,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: selected ? AppColors.brand : Colors.transparent,
                  width: 2.5),
            ),
            clipBehavior: Clip.antiAlias,
            child: child,
          ),
          if (caption != null) ...[
            const SizedBox(height: 4),
            SizedBox(
              width: 64,
              child: Text(caption,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10)),
            ),
          ],
        ],
      ),
    );
  }

  // ---- Settings rows -------------------------------------------------------

  Widget _panel(List<Widget> children) => Container(
        decoration: BoxDecoration(
            color: AppTheme.card(context),
            borderRadius: BorderRadius.circular(16)),
        child: Column(children: children),
      );

  Widget _divider() => Divider(
      height: 1,
      thickness: 1,
      indent: 54,
      color: Theme.of(context).dividerColor.withValues(alpha: 0.4));

  Widget _row({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        child: Row(
          children: [
            Icon(icon, size: 22, color: muted),
            const SizedBox(width: 14),
            Text(label,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600)),
            const Spacer(),
            Flexible(
              child: Text(value,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: muted, fontSize: 13)),
            ),
            Icon(Icons.chevron_right, color: muted),
          ],
        ),
      ),
    );
  }

  // ---- Bottom sheets -------------------------------------------------------

  Future<void> _sheet(Widget Function(StateSetter setSheet) builder) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (_) => StatefulBuilder(
        builder: (_, setSheet) => SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: builder(setSheet),
          ),
        ),
      ),
    );
  }

  Widget _sheetTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 12, top: 6),
        child: Row(children: [
          Text(t, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        ]),
      );

  void _openBackgroundSheet(AppLocalizations l) {
    _sheet((setSheet) {
      void pick(_Bg bg) {
        setState(() => _bg = bg);
        setSheet(() {});
      }

      final tiles = <Widget>[
        _bgTile(
          label: l.t('share_your_photo'),
          selected: _bg.file != null,
          onTap: () async {
            await _pickPhoto();
            setSheet(() {});
          },
          child: Container(
            color: AppTheme.card(context),
            child: Icon(Icons.add_photo_alternate_outlined,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
        for (final g in _gradients)
          _bgTile(
            label: l.t('share_bg_gradient'),
            selected: identical(_bg.colors, g.colors),
            onTap: () => pick(g),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: g.colors!),
              ),
            ),
          ),
        for (final c in _categories)
          _bgTile(
            label: l.t(c.$1),
            selected: _bg.catKey == c.$1,
            onTap: () {
              final img = _thumbs[c.$1];
              if (img != null) pick(_Bg.photo(img.url, catKey: c.$1));
            },
            child: _thumbs[c.$1] != null
                ? CachedNetworkImage(
                    imageUrl: _thumbs[c.$1]!.url,
                    fit: BoxFit.cover,
                    memCacheWidth: 260,
                    placeholder: (_, __) => _shimmer(),
                    errorWidget: (_, __, ___) => _shimmer())
                : _shimmer(),
          ),
      ];
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sheetTitle(l.t('share_backgrounds')),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.15,
            children: tiles,
          ),
        ],
      );
    });
  }

  Widget _bgTile({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: selected ? AppColors.brand : Colors.transparent,
                    width: 3),
              ),
              clipBehavior: Clip.antiAlias,
              child: child,
            ),
          ),
          const SizedBox(height: 4),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  void _openTypographySheet(AppLocalizations l) {
    final sample = widget.verse.length > 22
        ? widget.verse.substring(0, 22)
        : widget.verse;
    _sheet((setSheet) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sheetTitle(l.t('share_typography')),
          // Font list with live previews.
          SizedBox(
            height: 210,
            child: ListView(
              children: [
                for (final s in _FontStyle.values)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _fontStyle = s);
                        setSheet(() {});
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: _fontStyle == s
                              ? AppColors.brand.withValues(alpha: 0.14)
                              : AppTheme.card(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: _fontStyle == s
                                  ? AppColors.brand
                                  : Colors.transparent,
                              width: 1.5),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(sample,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: _font(s,
                                      fontSize: 20,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface)),
                            ),
                            const SizedBox(width: 10),
                            Text(_fontLabel(l, s),
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant)),
                            if (_fontStyle == s) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.check_circle,
                                  size: 18, color: AppColors.brand),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Size slider.
          Row(children: [
            const Icon(Icons.format_size, size: 20),
            Expanded(
              child: Slider(
                value: _sizeScale,
                min: 0.7,
                max: 1.4,
                activeColor: AppColors.brand,
                onChanged: (v) {
                  setState(() => _sizeScale = v);
                  setSheet(() {});
                },
              ),
            ),
          ]),
          // Alignment.
          Row(
            children: [
              Text(l.t('share_text_align'),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              for (final a in [
                (TextAlign.left, Icons.format_align_left),
                (TextAlign.center, Icons.format_align_center),
                (TextAlign.right, Icons.format_align_right),
              ])
                IconButton(
                  onPressed: () {
                    setState(() => _align = a.$1);
                    setSheet(() {});
                  },
                  icon: Icon(a.$2,
                      color: _align == a.$1
                          ? AppColors.brand
                          : Theme.of(context).colorScheme.onSurfaceVariant),
                ),
            ],
          ),
        ],
      );
    });
  }

  void _openFormatSheet(AppLocalizations l) {
    _sheet((setSheet) {
      Widget tile(_Fmt f, String name, String ratio, double aspect) {
        final sel = _fmt == f;
        return GestureDetector(
          onTap: () {
            setState(() => _fmt = f);
            setSheet(() {});
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: sel
                  ? AppColors.brand.withValues(alpha: 0.14)
                  : AppTheme.card(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: sel ? AppColors.brand : Colors.transparent,
                  width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 42,
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: aspect,
                      child: Container(
                        decoration: BoxDecoration(
                          color: sel ? AppColors.brand : Colors.grey,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(name,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700)),
                Text(ratio,
                    style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        );
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sheetTitle(l.t('share_format')),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              tile(_Fmt.story, l.t('share_fmt_story'), '9:16', 9 / 16),
              tile(_Fmt.portrait, l.t('share_fmt_portrait'), '4:5', 4 / 5),
              tile(_Fmt.square, l.t('share_fmt_square'), '1:1', 1),
              tile(_Fmt.landscape, l.t('share_fmt_landscape'), '1.91:1', 1.91),
            ],
          ),
        ],
      );
    });
  }

  void _openMoreSheet(AppLocalizations l) {
    _sheet((setSheet) {
      Widget sw(String label, bool value, ValueChanged<bool> onChanged) =>
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeColor: AppColors.brand,
            title: Text(label),
            value: value,
            onChanged: (v) {
              onChanged(v);
              setSheet(() {});
            },
          );
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sheetTitle(l.t('share_more_options')),
          sw(l.t('share_show_reference'), _showReference,
              (v) => setState(() => _showReference = v)),
          sw(l.t('share_show_logo'), _showLogo,
              (v) => setState(() => _showLogo = v)),
          if (widget.userName != null && widget.userName!.isNotEmpty)
            sw(l.t('share_show_name'), _showName,
                (v) => setState(() => _showName = v)),
        ],
      );
    });
  }

  // ---- The rendered card ---------------------------------------------------

  Widget _card() {
    final poster = _style == _Style.poster;
    final darkText = _bg.isGradient && _bg.darkText;
    final textColor = darkText ? const Color(0xFF1C1A17) : Colors.white;
    final subColor =
        (darkText ? Colors.black : Colors.white).withValues(alpha: 0.72);

    return Stack(
      fit: StackFit.expand,
      children: [
        _bgLayer(),
        if (_bg.isPhoto) _scrim(poster),
        LayoutBuilder(
          builder: (context, c) {
            final pad = c.maxWidth * (poster ? 0.085 : 0.09);
            return Padding(
              padding: EdgeInsets.all(pad),
              child: poster
                  ? _posterContent(c, textColor, subColor)
                  : _classicContent(c, textColor, subColor),
            );
          },
        ),
        if (_showLogo || _showName)
          Positioned(
            left: 0,
            right: 0,
            bottom: 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_showName &&
                    widget.userName != null &&
                    widget.userName!.isNotEmpty)
                  Text('— ${widget.userName}',
                      style: TextStyle(
                          color: subColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                if (_showLogo)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.menu_book_rounded, size: 13, color: subColor),
                      const SizedBox(width: 6),
                      Text('Bible Companion',
                          style: TextStyle(
                              color: subColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3)),
                    ],
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _bgLayer() {
    if (_bg.file != null) return Image.file(_bg.file!, fit: BoxFit.cover);
    if (_bg.url != null) {
      return CachedNetworkImage(
          imageUrl: _bg.url!, fit: BoxFit.cover, memCacheWidth: 1400);
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _bg.colors!),
      ),
    );
  }

  Widget _scrim(bool poster) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: poster
                ? [
                    Colors.black.withValues(alpha: 0.25),
                    Colors.black.withValues(alpha: 0.55),
                    Colors.black.withValues(alpha: 0.80),
                  ]
                : [
                    Colors.black.withValues(alpha: 0.45),
                    Colors.black.withValues(alpha: 0.35),
                    Colors.black.withValues(alpha: 0.55),
                  ],
          ),
        ),
      );

  Widget _classicContent(BoxConstraints c, Color textColor, Color subColor) {
    final base = 30 * _sizeScale;
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: c.maxWidth * 0.82,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: _crossFor(_align),
            children: [
              Text('“${widget.verse}”',
                  textAlign: _align,
                  style: _font(_fontStyle,
                      fontSize: base, color: textColor, height: 1.4)),
              if (_showReference) ...[
                const SizedBox(height: 18),
                Text(widget.reference,
                    textAlign: _align,
                    style: _font(_fontStyle,
                        fontSize: base * 0.56,
                        color: subColor,
                        style: FontStyle.italic,
                        height: 1.2)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _posterContent(BoxConstraints c, Color textColor, Color subColor) {
    final base = 30 * _sizeScale;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('“',
            style: _font(_fontStyle,
                    fontSize: 64, color: textColor, height: 0.7)
                .copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: c.maxWidth * 0.84,
              child: Text(widget.verse,
                  textAlign: TextAlign.left,
                  style: _font(_fontStyle,
                      fontSize: base, color: textColor, height: 1.35)),
            ),
          ),
        ),
        if (_showReference) ...[
          const SizedBox(height: 16),
          Container(width: 34, height: 2, color: subColor),
          const SizedBox(height: 10),
          Text(widget.reference,
              style: _font(_fontStyle,
                  fontSize: base * 0.5,
                  color: subColor,
                  height: 1.1,
                  letterSpacing: 0.5)),
        ],
        const SizedBox(height: 26),
      ],
    );
  }

  CrossAxisAlignment _crossFor(TextAlign a) => switch (a) {
        TextAlign.left => CrossAxisAlignment.start,
        TextAlign.right => CrossAxisAlignment.end,
        _ => CrossAxisAlignment.center,
      };
}
