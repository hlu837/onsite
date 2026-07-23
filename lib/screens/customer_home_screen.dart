import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/landing_content.dart';
import '../models/asset.dart';
import '../models/auth_response.dart';
import '../providers/loop_controller.dart';
import '../services/mock_asset_data.dart';
import '../theme/app_theme.dart';
import '../widgets/asset_list_card.dart';
import '../widgets/landing_shared.dart';
import '../widgets/listing_intent_sheet.dart';
import '../widgets/loop_progress.dart';
import '../widgets/order_category_sheet.dart';
import '../widgets/sell_or_meet_broker_card.dart';
import '../widgets/visitor_drawer.dart';
import 'asset_detail_screen.dart';
import 'broker_map_screen.dart';
import 'category_listing_screen.dart';
import 'my_sell_requests_screen.dart';
import 'order_request_form_screen.dart';
import 'placeholder_page.dart';
import 'rent_property_form_screen.dart';
import 'role_gate_screen.dart';
import 'sell_property_form_screen.dart';

/// Number of listings shown in the "Trending ads" strip below the category
/// grid — mirrors the landing page's properties section, which also caps
/// itself at a handful of listings rather than showing everything.
const _featuredListingCount = 6;

/// Maps `kServices` (declared in landing_content.dart, in display order) onto
/// the Asset model's category enum, mirroring the same mapping used by the
/// public landing page's category grid so the Visitor dashboard and the
/// marketing site stay in sync. The last entry (Broker List) isn't a real
/// asset category — it's special-cased below to open the broker directory.
const _serviceToAssetCategory = <AssetCategorySlug>[
  AssetCategorySlug.vehicles,
  AssetCategorySlug.machinery,
  AssetCategorySlug.house,
  AssetCategorySlug.warehouse,
  AssetCategorySlug.land,
  AssetCategorySlug.constructionMaterials,
  AssetCategorySlug.others,
];
const _brokerListServiceIndex = 6;

/// The Visitor side — its own full flow: browse categories (same tappable
/// category-card grid as the public landing page) and drill into a category
/// page to view listings, chat with brokers, and request an on-site
/// walkthrough. Watches the shared [LoopController] so the status card below
/// updates in real time as Admin/Agent act on any active request.
class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key, required this.user});

  final AppUser user;

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final GlobalKey _categorySectionKey = GlobalKey();

  /// Same handful-of-listings cap the landing page's "Trending ads" section
  /// uses, so the two stay visually identical.
  List<Asset> get _visibleFeaturedAssets => kMockCompanyAssets.take(_featuredListingCount).toList();

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RoleGateScreen()),
      (route) => false,
    );
  }

  void _openCategory(ServiceItem service) {
    final index = kServices.indexOf(service);
    if (index == _brokerListServiceIndex) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => const BrokerMapScreen(
          category: AssetCategorySlug.others,
          categoryLabel: 'All',
          showAllBrokers: true,
        ),
      ));
      return;
    }
    final category = _serviceToAssetCategory[index];
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CategoryListingScreen(
        category: category,
        categoryLabel: service.title,
        categoryIcon: service.icon,
        // For a signed-in Visitor, "Get started" (the Sell CTA / tapping a
        // listing) connects them straight to a broker for this category
        // instead of the anonymous sign-up flow the marketing site uses.
        onGetStarted: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => BrokerMapScreen(category: category, categoryLabel: service.title),
        )),
        // The "Sell it here / Meet a broker" prompt now lives at the bottom
        // of the Visitor dashboard instead of repeating on every category
        // listing page.
        showSellCard: false,
        // House absorbs the categories dropped from the dashboard grid
        // (Apartments, Condominium, Building), same as the landing page.
        extraCategories: index == 2
            ? const [AssetCategorySlug.apartments, AssetCategorySlug.condominium, AssetCategorySlug.building]
            : const [],
      ),
    ));
  }

  Future<void> _openOrderUs(BuildContext context) async {
    final category = await showOrderCategorySheet(context);
    if (category == null || !context.mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => OrderRequestFormScreen(user: widget.user, category: category),
    ));
  }

  void _scrollToCategories() {
    final ctx = _categorySectionKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
  }

  void _openRequestAgent() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const BrokerMapScreen(
        category: AssetCategorySlug.others,
        categoryLabel: 'All',
        showAllBrokers: true,
      ),
    ));
  }

  Future<void> _openListingIntent(BuildContext context) async {
    final intent = await showListingIntentSheet(context);
    if (intent == null || !context.mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => intent == ListingIntent.sell
          ? SellPropertyFormScreen(user: widget.user)
          : RentPropertyFormScreen(user: widget.user),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final loop = context.watch<LoopController>();
    final featuredAssets = _visibleFeaturedAssets;
    final totalListingCount = kMockCompanyAssets.length;

    return Scaffold(
      backgroundColor: AppColors.cloud,
      drawer: VisitorDrawer(
        visitorName: widget.user.fullName,
        actions: VisitorDrawerActions(
          onExploreFeed: () {}, // already here — closing the drawer is enough
          onSavedListings: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const PlaceholderPage(
              title: 'Saved Listings / Favorites',
              icon: Icons.favorite_border_rounded,
              description: 'Every listing you\'ve favorited from the Explore Feed, in one place.',
            ),
          )),
          onFindBrokers: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const BrokerMapScreen(
              category: AssetCategorySlug.others,
              categoryLabel: 'All',
              showAllBrokers: true,
            ),
          )),
          onMySellRequests: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => MySellRequestsScreen(user: widget.user),
          )),
          onAccountSettings: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const PlaceholderPage(
              title: 'Account & Settings',
              icon: Icons.settings_outlined,
              description: 'Manage your profile, notification preferences, and account details.',
              bullets: [
                'Edit name, phone number, and profile photo',
                'Update password and login security',
                'Notification preferences',
                'Language and region',
              ],
            ),
          )),
          onAboutFaq: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const PlaceholderPage(
              title: 'About Us / FAQ',
              icon: Icons.help_outline_rounded,
              description: 'Who EBN is, how verification works, and answers to common questions.',
            ),
          )),
          onLogout: _logout,
        ),
      ),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('EBN', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            Text('Visitor · ${widget.user.fullName}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500)),
          ],
        ),
        backgroundColor: AppColors.ink,
        actions: [
          IconButton(
            tooltip: 'Reset demo',
            onPressed: loop.reset,
            icon: const Icon(Icons.restart_alt_rounded),
          ),
          IconButton(
            tooltip: 'Log out',
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          LoopProgress(
            stage: loop.stage,
            idleContent: _QuickStartLinks(
              onOrderUs: () => _openOrderUs(context),
              onRequestAgent: _openRequestAgent,
            ),
          ),
          if (loop.stage != LoopStage.idle) _StatusCard(loop: loop),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                    child: Text('Category',
                        key: _categorySectionKey,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink)),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 4,
                      childAspectRatio: 0.76,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == 0) {
                          return _CategoryGridCard(
                            label: 'Post ad',
                            icon: Icons.add_circle_rounded,
                            highlighted: true,
                            onTap: () => _openListingIntent(context),
                          );
                        }
                        final service = kServices[index - 1];
                        return _CategoryGridCard(
                          label: service.title,
                          icon: service.icon,
                          imageUrl: service.imageUrl,
                          onTap: () => _openCategory(service),
                        );
                      },
                      childCount: kServices.length + 1,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Trending ads',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink)),
                        const SizedBox(height: 2),
                        Text('$totalListingCount listing${totalListingCount == 1 ? '' : 's'} available',
                            style: const TextStyle(fontSize: 12.5, color: AppColors.slate)),
                      ],
                    ),
                  ),
                ),
                if (featuredAssets.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(AppRadii.lg),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        alignment: Alignment.center,
                        child: const Text('No listings match your search yet.', style: TextStyle(color: AppColors.slate)),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
                    sliver: SliverToBoxAdapter(
                      child: ResponsiveGrid(
                        itemCount: featuredAssets.length,
                        gap: AppSpacing.sm,
                        breakpoints: {0: 2, 640: 3, 1024: 4},
                        itemBuilder: (i) {
                          final asset = featuredAssets[i];
                          return AssetListCard(
                            asset: asset,
                            compact: true,
                            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => AssetDetailScreen(asset: asset),
                            )),
                          );
                        },
                      ),
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
                  sliver: SliverToBoxAdapter(
                    child: SellOrMeetBrokerCard(
                      title: 'Have something to sell or rent?',
                      onSell: () => _openListingIntent(context),
                      onMeetBroker: _openRequestAgent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A tappable category tile for the Visitor dashboard grid — the exact same
/// compact tile style as the landing page's category grid (`_GridCategoryTile`
/// in role_gate_screen.dart): no bordered card, just a colored square
/// thumbnail with the label centered underneath.
class _CategoryGridCard extends StatelessWidget {
  const _CategoryGridCard({
    required this.label,
    required this.icon,
    this.imageUrl,
    this.highlighted = false,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final String? imageUrl;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 54,
            width: 54,
            decoration: BoxDecoration(
              color: highlighted ? AppColors.primaryYellow : AppColors.primaryYellow.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: (imageUrl == null || highlighted)
                ? Icon(icon, color: AppColors.ink, size: 25)
                : Padding(
                    padding: const EdgeInsets.all(9),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) =>
                            progress == null ? child : Icon(icon, color: AppColors.ink, size: 25),
                        errorBuilder: (context, error, stack) => Icon(icon, color: AppColors.ink, size: 25),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.ink),
          ),
        ],
      ),
    );
  }
}

/// The two quick-start links shown in place of the "No active request yet"
/// message on the Visitor dashboard — plain clickable text, not buttons,
/// laid out side by side with a thin divider between them.
class _QuickStartLinks extends StatelessWidget {
  const _QuickStartLinks({required this.onOrderUs, required this.onRequestAgent});

  final VoidCallback onOrderUs;
  final VoidCallback onRequestAgent;

  @override
  Widget build(BuildContext context) {
    const linkStyle = TextStyle(
      fontSize: 12.5,
      fontWeight: FontWeight.w700,
      color: AppColors.ink,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.ink,
    );
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onOrderUs,
            child: const Text('Order Us', style: linkStyle),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(width: 1, height: 14, color: AppColors.border),
          ),
          InkWell(
            onTap: onRequestAgent,
            child: const Text('Request agent', style: linkStyle),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.loop});

  final LoopController loop;

  @override
  Widget build(BuildContext context) {
    final asset = loop.requestedAsset;
    late final IconData icon;
    late final Color color;
    late final String title;
    late final String subtitle;
    Widget? trailing;

    switch (loop.stage) {
      case LoopStage.searching:
        icon = Icons.search_rounded;
        color = AppColors.primaryYellowDark;
        title = 'Searching for the nearest agent…';
        subtitle = asset?.title ?? '';
        trailing = const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.primaryYellowDark),
        );
        break;
      case LoopStage.pendingApproval:
        icon = Icons.hourglass_top_rounded;
        color = AppColors.primaryYellowDark;
        title = 'Waiting on admin approval';
        subtitle = 'Your request for "${asset?.title}" is in the queue.';
        break;
      case LoopStage.dispatched:
        icon = Icons.campaign_rounded;
        color = AppColors.ink;
        title = 'Dispatching to an agent…';
        subtitle = 'Ringing ${loop.agentName} · ${loop.secondsLeft}s left';
        break;
      case LoopStage.accepted:
        icon = Icons.verified_rounded;
        color = AppColors.success;
        title = 'Tour confirmed!';
        subtitle = '${loop.agentName} is on the way for "${asset?.title}".';
        break;
      case LoopStage.declined:
        icon = Icons.undo_rounded;
        color = AppColors.danger;
        title = 'Agent declined — re-dispatching';
        subtitle = 'Admin will assign another agent shortly.';
        break;
      case LoopStage.expired:
        icon = Icons.timer_off_rounded;
        color = AppColors.danger;
        title = 'No response — re-dispatching';
        subtitle = 'Admin will assign another agent shortly.';
        break;
      case LoopStage.idle:
        return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      color: AppColors.cloud,
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.slate)),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }
}
