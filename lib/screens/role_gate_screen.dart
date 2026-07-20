import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'login_screen.dart';
import 'role_select_screen.dart';
import 'signin_screen.dart';
import 'about_us_screen.dart';
import 'contact_us_screen.dart';
import 'faq_screen.dart';
import 'how_it_works_screen.dart';
import 'membership_screen.dart';
import 'platform_features_screen.dart';
import 'category_listing_screen.dart';
import 'broker_map_screen.dart';
import '../data/faq_data.dart';
import '../data/landing_content.dart';
import '../models/asset.dart';
import '../services/mock_asset_data.dart';
import '../theme/landing_colors.dart';
import '../widgets/asset_list_card.dart';
import '../widgets/landing_shared.dart';

// -----------------------------------------------------------------------------
// Maps the marketing "services" categories (in the order they're declared in
// landing_content.dart) onto the Asset model's category enum, so category
// chips and search results can filter the live listings feed below.
// Order: Vehicles, Apartments, Condominium, Machinery, House, Warehouse,
// Land, Building, Construction Materials, Broker List.
// The last entry (Broker List) isn't a real asset category — it's handled
// as a special case in the grid's onTap below, opening the broker
// directory instead of filtering listings, so its slug here is a
// placeholder that's never used for filtering.
// -----------------------------------------------------------------------------
const _serviceToAssetCategory = <AssetCategorySlug>[
  AssetCategorySlug.vehicles,
  AssetCategorySlug.apartments,
  AssetCategorySlug.condominium,
  AssetCategorySlug.machinery,
  AssetCategorySlug.house,
  AssetCategorySlug.warehouse,
  AssetCategorySlug.land,
  AssetCategorySlug.building,
  AssetCategorySlug.constructionMaterials,
  AssetCategorySlug.others,
];

// Index of the "Broker List" tile within `kServices` — kept as a constant
// so the special-cased tap handling below doesn't rely on a magic number.
const _brokerListServiceIndex = 9;

// -----------------------------------------------------------------------------
// Section anchors -- module-level so they survive rebuilds; used so the
// landing-page search can scroll straight to the section a result lives in.
// The properties key is a GlobalKey<State> so search can also reach into
// _PropertiesSection and apply a filter directly.
// -----------------------------------------------------------------------------
final _propertiesSectionKey = GlobalKey<_PropertiesSectionState>();

void _scrollToSection(GlobalKey key) {
  final ctx = key.currentContext;
  if (ctx != null) {
    Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
  }
}

void _scrollToProperties({AssetCategorySlug? category, String? query}) {
  _propertiesSectionKey.currentState?.applyExternalFilter(category: category, query: query);
  _scrollToSection(_propertiesSectionKey);
}

// -----------------------------------------------------------------------------
// Landing-page search -- now spans marketing pages *and* the live listings.
// -----------------------------------------------------------------------------
class _SearchResult {
  final String category;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onSelect;
  const _SearchResult({
    required this.category,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onSelect,
  });
}

List<_SearchResult> _buildSearchIndex(
  BuildContext context, {
  required VoidCallback goToAboutUs,
  required VoidCallback goToContactUs,
  required VoidCallback goToFaq,
  required VoidCallback goToSignUp,
  required VoidCallback goToHowItWorks,
  required VoidCallback goToMembership,
  required VoidCallback goToPlatform,
}) {
  final results = <_SearchResult>[];

  for (int i = 0; i < kServices.length; i++) {
    final s = kServices[i];
    final assetCategory = _serviceToAssetCategory[i];
    final isBrokerList = i == _brokerListServiceIndex;
    results.add(_SearchResult(
      category: 'Category',
      title: s.title,
      subtitle: s.desc,
      icon: s.icon,
      onSelect: isBrokerList
          ? () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const BrokerMapScreen(
                  category: AssetCategorySlug.others,
                  categoryLabel: 'All',
                  showAllBrokers: true,
                ),
              ))
          : () => _scrollToProperties(category: assetCategory),
    ));
    if (isBrokerList) continue;
    for (final sub in s.subcategories) {
      results.add(_SearchResult(
        category: s.title,
        title: sub,
        subtitle: 'Subcategory under ${s.title}',
        icon: s.icon,
        onSelect: () => _scrollToProperties(category: assetCategory, query: sub),
      ));
    }
  }
  for (final asset in kMockCompanyAssets) {
    results.add(_SearchResult(
      category: asset.category.label,
      title: asset.title,
      subtitle: '${asset.formattedPrice} \u00b7 ${asset.city ?? ''}',
      icon: Icons.location_on_outlined,
      onSelect: () => _scrollToProperties(category: asset.category, query: asset.title),
    ));
  }
  for (final step in kSteps) {
    results.add(_SearchResult(
      category: 'How it works',
      title: step.title,
      subtitle: step.desc,
      icon: step.icon,
      onSelect: goToHowItWorks,
    ));
  }
  for (final tier in kTiers) {
    results.add(_SearchResult(
      category: 'Membership',
      title: tier.name,
      subtitle: tier.priority,
      icon: tier.icon,
      onSelect: goToMembership,
    ));
  }
  for (final f in kFeatures) {
    results.add(_SearchResult(
      category: 'Platform',
      title: f.title,
      subtitle: 'Key platform feature',
      icon: f.icon,
      onSelect: goToPlatform,
    ));
  }
  for (final faq in faqItems) {
    results.add(_SearchResult(
      category: 'FAQ',
      title: faq.question,
      subtitle: faq.answer,
      icon: Icons.help_outline,
      onSelect: goToFaq,
    ));
  }
  results.add(_SearchResult(
    category: 'Page',
    title: 'About Us',
    subtitle: 'Learn more about Onsite',
    icon: Icons.info_outline,
    onSelect: goToAboutUs,
  ));
  results.add(_SearchResult(
    category: 'Page',
    title: 'Contact Us',
    subtitle: 'Get in touch with the team',
    icon: Icons.mail_outline,
    onSelect: goToContactUs,
  ));
  results.add(_SearchResult(
    category: 'Action',
    title: 'Sign Up / Get Started',
    subtitle: 'Create an account',
    icon: Icons.arrow_forward,
    onSelect: goToSignUp,
  ));
  return results;
}

class _LandingSearchDelegate extends SearchDelegate<void> {
  final List<_SearchResult> results;
  _LandingSearchDelegate(this.results) : super(searchFieldLabel: 'Search Onsite\u2026');

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty) IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final q = query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? results
        : results.where((r) {
            return r.title.toLowerCase().contains(q) ||
                r.subtitle.toLowerCase().contains(q) ||
                r.category.toLowerCase().contains(q);
          }).toList();

    if (filtered.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No matches found.', style: TextStyle(color: LandingColors.muted)),
        ),
      );
    }

    return Container(
      color: LandingColors.background,
      child: ListView.separated(
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: LandingColors.border),
        itemBuilder: (context, i) {
          final r = filtered[i];
          return ListTile(
            leading: Icon(r.icon, color: LandingColors.gold),
            title: Text(r.title, style: const TextStyle(color: LandingColors.foreground, fontWeight: FontWeight.w600)),
            subtitle: Text(r.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: LandingColors.muted)),
            trailing: Text(r.category, style: const TextStyle(fontSize: 11, color: LandingColors.muted)),
            onTap: () {
              close(context, null);
              r.onSelect();
            },
          );
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// RoleGateScreen -- public entry point (unchanged name/signature so main.dart
// and every other file that imports this screen keeps working untouched).
// -----------------------------------------------------------------------------
class RoleGateScreen extends StatelessWidget {
  const RoleGateScreen({super.key});

  void _goToRoleSelect(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RoleSelectScreen()));
  }

  void _goToLogin(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  void _goToAdmin(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SignInScreen()));
  }

  void _goToAboutUs(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AboutUsScreen()));
  }

  void _goToContactUs(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ContactUsScreen()));
  }

  void _goToFaq(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FaqScreen()));
  }

  void _goToHowItWorks(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HowItWorksScreen()));
  }

  void _goToMembership(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MembershipScreen()));
  }

  void _goToPlatform(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PlatformFeaturesScreen()));
  }

  void _openSearch(BuildContext context) {
    final index = _buildSearchIndex(
      context,
      goToAboutUs: () => _goToAboutUs(context),
      goToContactUs: () => _goToContactUs(context),
      goToFaq: () => _goToFaq(context),
      goToSignUp: () => _goToRoleSelect(context),
      goToHowItWorks: () => _goToHowItWorks(context),
      goToMembership: () => _goToMembership(context),
      goToPlatform: () => _goToPlatform(context),
    );
    showSearch(context: context, delegate: _LandingSearchDelegate(index));
  }

  void _onLanguageSelected(BuildContext context, String language) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$language selected. Full translation is coming soon.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LandingColors.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
        child: Column(
          children: [
            _Nav(
              onGetStarted: () => _goToRoleSelect(context),
              onLogIn: () => _goToLogin(context),
              onAboutUs: () => _goToAboutUs(context),
              onContactUs: () => _goToContactUs(context),
              onFaq: () => _goToFaq(context),
              onHowItWorks: () => _goToHowItWorks(context),
              onMembership: () => _goToMembership(context),
              onPlatform: () => _goToPlatform(context),
              onSearch: () => _openSearch(context),
              onLanguage: (language) => _onLanguageSelected(context, language),
            ),
            _Hero(onSearch: () => _openSearch(context), onRequest: () => _goToRoleSelect(context)),
            _PropertiesSection(key: _propertiesSectionKey, onGetStarted: () => _goToRoleSelect(context)),
            _Footer(onAdminTap: () => _goToAdmin(context)),
          ],
        ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// HERO
// -----------------------------------------------------------------------------
class _Hero extends StatelessWidget {
  final VoidCallback onSearch;
  final VoidCallback onRequest;
  const _Hero({required this.onSearch, required this.onRequest});
  @override
  Widget build(BuildContext context) {
    final wide = !LandingBreakpoints.isMobile(context);
    return MaxWidth(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: wide ? 80 : 40),
      child: Column(
        children: [
          const _MarqueeStrip(),
          const SizedBox(height: 40),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Material(
                color: LandingColors.gold,
                borderRadius: BorderRadius.circular(999),
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: onSearch,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    child: Text(
                      'Get your agent',
                      style: TextStyle(fontSize: 13.5, color: LandingColors.goldFg, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(999),
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: onRequest,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text("Can't find it? ", style: TextStyle(fontSize: 13.5, color: LandingColors.muted)),
                        Text('Request what you want', style: TextStyle(fontSize: 13.5, color: LandingColors.gold, fontWeight: FontWeight.w700)),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward, size: 14, color: LandingColors.gold),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// HERO MARQUEE -- continuously-scrolling row of category/use-case "stickers".
// Now doubles as the hero visual itself, so the chips are sized up into a
// card-like format; the scroll/ticker behavior is unchanged from before.
// -----------------------------------------------------------------------------
class _MarqueeStrip extends StatefulWidget {
  const _MarqueeStrip();
  @override
  State<_MarqueeStrip> createState() => _MarqueeStripState();
}

class _MarqueeStripState extends State<_MarqueeStrip> with SingleTickerProviderStateMixin {
  final ScrollController _controller = ScrollController();
  Ticker? _ticker;
  Duration _lastElapsed = Duration.zero;
  static const int _repeatCount = 40; // long enough loop for a demo session

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  // Runs once per rendering frame (via Ticker) instead of on a wall-clock
  // Timer, so the jumpTo below always lands inside Flutter's normal frame
  // pipeline. Mutating scroll position from an out-of-band Timer can leave
  // the render tree briefly inconsistent and trip hit-test assertions.
  void _onTick(Duration elapsed) {
    if (!mounted || !_controller.hasClients) return;
    final position = _controller.position;
    // Guards against reading scroll metrics before the ListView has
    // finished measuring its content on the first few frames.
    if (!position.hasContentDimensions) return;

    final deltaMs = (elapsed - _lastElapsed).inMilliseconds;
    _lastElapsed = elapsed;
    if (deltaMs <= 0 || deltaMs > 200) return; // skip the first tick / long pauses (tab backgrounded, etc.)

    final max = position.maxScrollExtent;
    if (max <= 0) return;
    final next = _controller.offset + (deltaMs * 0.024); // ~0.7px per 30ms, frame-rate independent
    _controller.jumpTo(next >= max ? 0 : next);
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemCount = kStickers.length * _repeatCount;
    return ShaderMask(
      shaderCallback: (rect) => const LinearGradient(
        colors: [Colors.transparent, Colors.black, Colors.black, Colors.transparent],
        stops: [0.0, 0.06, 0.94, 1.0],
      ).createShader(rect),
      blendMode: BlendMode.dstIn,
      child: SizedBox(
        height: 132,
        child: ListView.separated(
          controller: _controller,
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itemCount,
          separatorBuilder: (_, __) => const SizedBox(width: 16),
          itemBuilder: (_, i) => _StickerChip(kStickers[i % kStickers.length]),
        ),
      ),
    );
  }
}

class _StickerChip extends StatelessWidget {
  final StickerItem item;
  const _StickerChip(this.item);
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      decoration: BoxDecoration(
        color: LandingColors.card,
        border: Border.all(color: LandingColors.border),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: LandingColors.gold.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            clipBehavior: Clip.antiAlias,
            child: item.imageUrl == null
                ? Icon(item.icon, size: 22, color: LandingColors.gold)
                : ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      item.imageUrl!,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) =>
                          progress == null ? child : Icon(item.icon, size: 22, color: LandingColors.gold),
                      errorBuilder: (context, error, stack) => Icon(item.icon, size: 22, color: LandingColors.gold),
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: LandingColors.foreground),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// PROPERTIES -- the heart of the landing page now: category chips, a search
// box scoped to whichever category/subcategory is active, and the live
// listings feed. Search here only ever touches this section; the nav-bar
// search up top is the site-wide one and can also drop straight into this
// section with a category/query already applied (see _scrollToProperties).
// -----------------------------------------------------------------------------
class _PropertiesSection extends StatefulWidget {
  final VoidCallback onGetStarted;
  const _PropertiesSection({super.key, required this.onGetStarted});

  @override
  State<_PropertiesSection> createState() => _PropertiesSectionState();
}

class _PropertiesSectionState extends State<_PropertiesSection> {
  final TextEditingController _searchController = TextEditingController();
  AssetCategorySlug? _categoryFilter;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Called from the top-nav search so a result can both scroll here *and*
  /// pre-filter the section, e.g. tapping "Villas" under Property.
  void applyExternalFilter({AssetCategorySlug? category, String? query}) {
    setState(() {
      _categoryFilter = category;
      if (query != null) {
        _searchController.value = TextEditingValue(text: query, selection: TextSelection.collapsed(offset: query.length));
      }
    });
  }

  List<Asset> get _visibleAssets {
    final query = _searchController.text.trim().toLowerCase();
    return kMockCompanyAssets.where((asset) {
      if (_categoryFilter != null && asset.category != _categoryFilter) return false;
      if (query.isEmpty) return true;
      final haystack = [
        asset.title,
        asset.city ?? '',
        asset.addressLine ?? '',
        asset.category.label,
        asset.specLine,
        asset.attributes.values.join(' '),
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  ServiceItem? get _activeService {
    if (_categoryFilter == null) return null;
    final i = _serviceToAssetCategory.indexOf(_categoryFilter!);
    return i == -1 ? null : kServices[i];
  }

  @override
  Widget build(BuildContext context) {
    final assets = _visibleAssets;
    final activeService = _activeService;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 56),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: LandingColors.border)),
        color: Color(0xFFF1EBDD),
      ),
      child: MaxWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            ResponsiveGrid(
              itemCount: kServices.length + 1,
              gap: 12,
              breakpoints: {0: 4, 480: 5, 900: 6},
              itemBuilder: (i) {
                if (i == 0) {
                  return _CategoryTile(
                    label: 'All',
                    icon: Icons.apps_rounded,
                    selected: _categoryFilter == null,
                    onTap: () => setState(() => _categoryFilter = null),
                  );
                }
                final s = kServices[i - 1];
                final isBrokerList = (i - 1) == _brokerListServiceIndex;
                return _CategoryTile(
                  label: s.title,
                  icon: s.icon,
                  imageUrl: s.imageUrl,
                  selected: !isBrokerList && _categoryFilter == _serviceToAssetCategory[i - 1],
                  onTap: () {
                    if (isBrokerList) {
                      // Not an asset category — open the full broker
                      // directory instead of filtering the listings grid.
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const BrokerMapScreen(
                          category: AssetCategorySlug.others,
                          categoryLabel: 'All',
                          showAllBrokers: true,
                        ),
                      ));
                      return;
                    }
                    setState(() => _categoryFilter = _serviceToAssetCategory[i - 1]);
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => CategoryListingScreen(
                        category: _serviceToAssetCategory[i - 1],
                        categoryLabel: s.title,
                        categoryIcon: s.icon,
                        onGetStarted: widget.onGetStarted,
                      ),
                    ));
                  },
                );
              },
            ),
            if (activeService != null) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: activeService.subcategories.map((sub) {
                  final selected = _searchController.text.trim().toLowerCase() == sub.toLowerCase();
                  return _SubcategoryChip(
                    label: sub,
                    selected: selected,
                    onTap: () => setState(() => selected ? _searchController.clear() : _searchController.text = sub),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 20),
            Text('${assets.length} listing${assets.length == 1 ? '' : 's'}',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: LandingColors.muted)),
            const SizedBox(height: 16),
            if (assets.isEmpty)
              Container(
                decoration: BoxDecoration(
                  color: LandingColors.card,
                  border: Border.all(color: LandingColors.border),
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(vertical: 48),
                alignment: Alignment.center,
                child: const Text('No listings match your search yet.', style: TextStyle(color: LandingColors.muted)),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: LandingColors.card,
                  border: Border.all(color: LandingColors.border),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 6)),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                constraints: const BoxConstraints(maxHeight: 560),
                child: Scrollbar(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(right: 4),
                    child: ResponsiveGrid(
                      itemCount: assets.length,
                      gap: 12,
                      breakpoints: {0: 2, 640: 3, 1024: 4},
                      itemBuilder: (i) => AssetListCard(
                        asset: assets[i],
                        compact: true,
                        actionLabel: 'Get started to request',
                        onActionPressed: widget.onGetStarted,
                        onTap: widget.onGetStarted,
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 40),
            _BrowseCta(onGetStarted: widget.onGetStarted),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? imageUrl;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryTile({required this.label, required this.icon, this.imageUrl, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: selected ? LandingColors.gold : LandingColors.gold.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: selected ? Border.all(color: LandingColors.gold, width: 2) : null,
                ),
                alignment: Alignment.center,
                clipBehavior: Clip.antiAlias,
                child: imageUrl == null
                    ? Icon(icon, size: 26, color: selected ? LandingColors.goldFg : LandingColors.gold)
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          imageUrl!,
                          height: 56,
                          width: 56,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Icon(icon, size: 26, color: selected ? LandingColors.goldFg : LandingColors.gold);
                          },
                          errorBuilder: (context, error, stack) =>
                              Icon(icon, size: 26, color: selected ? LandingColors.goldFg : LandingColors.gold),
                        ),
                      ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: LandingColors.foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubcategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SubcategoryChip({required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? LandingColors.gold : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), border: Border.all(color: selected ? LandingColors.gold : LandingColors.border)),
          child: Text(label,
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: selected ? LandingColors.goldFg : LandingColors.muted)),
        ),
      ),
    );
  }
}

class _BrowseCta extends StatelessWidget {
  final VoidCallback onGetStarted;
  const _BrowseCta({required this.onGetStarted});
  @override
  Widget build(BuildContext context) {
    final wide = LandingBreakpoints.isDesktop(context);
    final text = const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ready to verify with confidence?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: LandingColors.foreground)),
        SizedBox(height: 6),
        Text('Sign up to request an on-site inspection on any listing above.', style: TextStyle(fontSize: 14, color: LandingColors.muted)),
      ],
    );
    final btn = GoldButton(label: 'Get Started / Sign Up', trailing: Icons.arrow_forward, fontSize: 14, onTap: onGetStarted);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: LandingColors.card, border: Border.all(color: LandingColors.border), borderRadius: BorderRadius.circular(16)),
      child: wide
          ? Row(children: [Expanded(child: text), const SizedBox(width: 24), btn])
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [text, const SizedBox(height: 16), btn]),
    );
  }
}

// -----------------------------------------------------------------------------
// FOOTER
// -----------------------------------------------------------------------------
class _Footer extends StatelessWidget {
  final VoidCallback onAdminTap;
  const _Footer({required this.onAdminTap});
  @override
  Widget build(BuildContext context) {
    final wide = LandingBreakpoints.isDesktop(context);
    final year = DateTime.now().year;
    final left = Text('\u00a9 $year Onsite. Addis Ababa, Ethiopia.', style: const TextStyle(fontSize: 13, color: LandingColors.muted));
    final right = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Verify any asset. On-site. On demand.', style: TextStyle(fontSize: 12, color: LandingColors.muted, fontFamily: 'monospace')),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: onAdminTap,
          child: const Text('Admin', style: TextStyle(fontSize: 12, color: LandingColors.muted, decoration: TextDecoration.underline)),
        ),
      ],
    );
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: LandingColors.border))),
      child: MaxWidth(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: wide
            ? Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [left, right])
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [left, const SizedBox(height: 8), right]),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// NAV -- links to How it works / Membership / Platform now navigate to their
// own pages. Get started + Log in are always visible, even on mobile.
// -----------------------------------------------------------------------------
class _Nav extends StatelessWidget {
  final VoidCallback onGetStarted;
  final VoidCallback onLogIn;
  final VoidCallback onAboutUs;
  final VoidCallback onContactUs;
  final VoidCallback onFaq;
  final VoidCallback onHowItWorks;
  final VoidCallback onMembership;
  final VoidCallback onPlatform;
  final VoidCallback onSearch;
  final void Function(String language) onLanguage;
  const _Nav({
    required this.onGetStarted,
    required this.onLogIn,
    required this.onAboutUs,
    required this.onContactUs,
    required this.onFaq,
    required this.onHowItWorks,
    required this.onMembership,
    required this.onPlatform,
    required this.onSearch,
    required this.onLanguage,
  });

  void _openMobileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: LandingColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => _MobileMenuSheet(
        onHowItWorks: () { Navigator.pop(sheetContext); onHowItWorks(); },
        onMembership: () { Navigator.pop(sheetContext); onMembership(); },
        onPlatform: () { Navigator.pop(sheetContext); onPlatform(); },
        onAboutUs: () { Navigator.pop(sheetContext); onAboutUs(); },
        onContactUs: () { Navigator.pop(sheetContext); onContactUs(); },
        onFaq: () { Navigator.pop(sheetContext); onFaq(); },
        onGetStarted: () { Navigator.pop(sheetContext); onGetStarted(); },
        onLogIn: () { Navigator.pop(sheetContext); onLogIn(); },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showLinks = LandingBreakpoints.isDesktop(context);
    return MaxWidth(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          IconButton(onPressed: () => _openMobileMenu(context), icon: const Icon(Icons.menu, color: LandingColors.foreground, size: 20), tooltip: 'Menu'),
          const SizedBox(width: 4),
          const Text('EBN', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: LandingColors.foreground)),
          const Spacer(),
          if (showLinks) ...[
            _NavLink('Browse', onTap: () => _scrollToSection(_propertiesSectionKey)),
            const SizedBox(width: 24),
            _NavLink('How it works', onTap: onHowItWorks),
            const SizedBox(width: 24),
            _NavLink('Membership', onTap: onMembership),
            const SizedBox(width: 24),
            _NavLink('Platform', onTap: onPlatform),
            const SizedBox(width: 24),
            _NavLink('About Us', onTap: onAboutUs),
            const SizedBox(width: 24),
            _NavLink('Contact Us', onTap: onContactUs),
            const SizedBox(width: 24),
            _NavLink('FAQ', onTap: onFaq),
            const SizedBox(width: 20),
          ],
          IconButton(onPressed: onSearch, icon: const Icon(Icons.search, color: LandingColors.foreground, size: 20), tooltip: 'Search'),
          PopupMenuButton<String>(
            tooltip: 'Language',
            icon: const Icon(Icons.language, color: LandingColors.foreground, size: 20),
            onSelected: onLanguage,
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'English', child: Text('English')),
              PopupMenuItem(value: 'Amharic', child: Text('Amharic')),
              PopupMenuItem(value: 'Afan Oromo', child: Text('Afan Oromo')),
              PopupMenuItem(value: 'Tigregna', child: Text('Tigregna')),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _NavLink(this.label, {this.onTap});
  @override
  Widget build(BuildContext context) {
    final text = Text(label, style: const TextStyle(color: LandingColors.muted, fontSize: 14));
    if (onTap == null) return text;
    return InkWell(onTap: onTap, child: text);
  }
}

// -----------------------------------------------------------------------------
// MOBILE MENU SHEET -- hamburger destination, used on every breakpoint now
// that the nav bar itself only shows search / language / menu icons. Carries
// the secondary marketing links plus Log In and Get started.
// -----------------------------------------------------------------------------
class _MobileMenuItem {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _MobileMenuItem(this.icon, this.label, this.onTap);
}

class _MobileMenuSheet extends StatelessWidget {
  final VoidCallback onHowItWorks;
  final VoidCallback onMembership;
  final VoidCallback onPlatform;
  final VoidCallback onAboutUs;
  final VoidCallback onContactUs;
  final VoidCallback onFaq;
  final VoidCallback onGetStarted;
  final VoidCallback onLogIn;
  const _MobileMenuSheet({
    required this.onHowItWorks,
    required this.onMembership,
    required this.onPlatform,
    required this.onAboutUs,
    required this.onContactUs,
    required this.onFaq,
    required this.onGetStarted,
    required this.onLogIn,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _MobileMenuItem(Icons.route_outlined, 'How it works', onHowItWorks),
      _MobileMenuItem(Icons.workspace_premium_outlined, 'Membership', onMembership),
      _MobileMenuItem(Icons.dashboard_customize_outlined, 'Platform', onPlatform),
      _MobileMenuItem(Icons.info_outline, 'About Us', onAboutUs),
      _MobileMenuItem(Icons.mail_outline, 'Contact Us', onContactUs),
      _MobileMenuItem(Icons.help_outline, 'FAQ', onFaq),
    ];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                height: 4,
                width: 40,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: LandingColors.border, borderRadius: BorderRadius.circular(999)),
              ),
            ),
            for (final item in items)
              ListTile(
                leading: Icon(item.icon, color: LandingColors.gold),
                title: Text(item.label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: LandingColors.foreground)),
                onTap: item.onTap,
              ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1, color: LandingColors.border),
            ),
            ListTile(
              leading: const Icon(Icons.login, color: LandingColors.gold),
              title: const Text('Log In', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: LandingColors.foreground)),
              onTap: onLogIn,
            ),
            ListTile(
              leading: const Icon(Icons.north_east, color: LandingColors.gold),
              title: const Text('Get started', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: LandingColors.foreground)),
              onTap: onGetStarted,
            ),
          ],
        ),
      ),
    );
  }
}
