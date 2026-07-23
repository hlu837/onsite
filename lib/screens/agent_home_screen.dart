import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/asset.dart';
import '../models/auth_response.dart';
import '../providers/loop_controller.dart';
import '../services/mock_asset_data.dart';
import '../theme/app_theme.dart';
import '../widgets/agent_drawer.dart';
import '../widgets/app_buttons.dart';
import '../widgets/asset_list_card.dart';
import '../widgets/loop_progress.dart';
import 'agent_sell_requests_screen.dart';
import 'placeholder_page.dart';
import 'role_gate_screen.dart';

enum _SortOption { newest, priceLow, priceHigh }

extension on _SortOption {
  String get label => switch (this) {
        _SortOption.newest => 'Newest',
        _SortOption.priceLow => 'Price: Low to High',
        _SortOption.priceHigh => 'Price: High to Low',
      };
}

/// The Agent side — its own full flow: listings feed behind a drawer, plus
/// a live ringing overlay whenever Admin dispatches the shared
/// [LoopController] to this agent. Accept/Decline here is instantly
/// reflected on the Customer and Admin sides.
class AgentHomeScreen extends StatefulWidget {
  const AgentHomeScreen({super.key, required this.user});

  final AppUser user;

  @override
  State<AgentHomeScreen> createState() => _AgentHomeScreenState();
}

class _AgentHomeScreenState extends State<AgentHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  AssetCategorySlug? _categoryFilter;
  _SortOption _sort = _SortOption.newest;
  double? _minPrice;
  double? _maxPrice;
  final Set<String> _savedIds = {};

  bool get _hasActiveFilters => _minPrice != null || _maxPrice != null;

  List<Asset> get _visibleAssets {
    final query = _searchController.text.trim().toLowerCase();
    var list = kMockCompanyAssets.where((asset) {
      final matchesCategory = _categoryFilter == null || asset.category == _categoryFilter;
      final matchesQuery = query.isEmpty ||
          (asset.city?.toLowerCase().contains(query) ?? false) ||
          (asset.addressLine?.toLowerCase().contains(query) ?? false) ||
          asset.title.toLowerCase().contains(query);
      final matchesMin = _minPrice == null || asset.priceAmount >= _minPrice!;
      final matchesMax = _maxPrice == null || asset.priceAmount <= _maxPrice!;
      return matchesCategory && matchesQuery && matchesMin && matchesMax;
    }).toList();

    switch (_sort) {
      case _SortOption.priceLow:
        list.sort((a, b) => a.priceAmount.compareTo(b.priceAmount));
        break;
      case _SortOption.priceHigh:
        list.sort((a, b) => b.priceAmount.compareTo(a.priceAmount));
        break;
      case _SortOption.newest:
        break;
    }
    return list;
  }

  Future<void> _openFilters(BuildContext context) async {
    _minPriceController.text = _minPrice == null ? '' : _minPrice!.toStringAsFixed(0);
    _maxPriceController.text = _maxPrice == null ? '' : _maxPrice!.toStringAsFixed(0);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cloud,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: 20 + MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('Filters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
                  ),
                  TextButton(
                    onPressed: () {
                      _minPriceController.clear();
                      _maxPriceController.clear();
                    },
                    child: const Text('Reset', style: TextStyle(color: AppColors.slate, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Price range', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _minPriceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Min',
                        filled: true,
                        fillColor: AppColors.card,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('–', style: TextStyle(color: AppColors.slate)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _maxPriceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Max',
                        filled: true,
                        fillColor: AppColors.card,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _minPrice = double.tryParse(_minPriceController.text.trim());
                    _maxPrice = double.tryParse(_maxPriceController.text.trim());
                  });
                  Navigator.of(sheetContext).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryYellow,
                  foregroundColor: AppColors.ink,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                ),
                child: const Text('Apply filters', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _logout(LoopController loop) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RoleGateScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loop = context.watch<LoopController>();
    final assets = _visibleAssets;

    return Scaffold(
      backgroundColor: AppColors.cloud,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('EBN', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            Text('Agent · ${widget.user.fullName}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500)),
          ],
        ),
        backgroundColor: AppColors.ink,
        actions: [
          IconButton(tooltip: 'Reset demo', onPressed: loop.reset, icon: const Icon(Icons.restart_alt_rounded)),
          const SizedBox(width: 4),
        ],
      ),
      drawer: AgentDrawer(
        agentName: widget.user.fullName,
        tier: AgentTier.gold,
        isOnline: loop.agentOnline,
        onOnlineChanged: loop.toggleOnline,
        actions: AgentDrawerActions(
          onDashboard: () {}, // already here — closing the drawer is enough
          onPropertyManagement: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => AgentSellRequestsScreen(user: widget.user),
          )),
          onCustomers: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const PlaceholderPage(
              title: 'Customers',
              icon: Icons.people_outline,
              description: 'Every buyer and tenant you\'ve worked with, in one directory.',
              bullets: [
                'Full contact and interaction history per customer',
                'Active vs. past client status',
                'Notes and preferences carried over from each tour',
                'Quick actions to message or call',
              ],
            ),
          )),
          onReferrals: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const PlaceholderPage(
              title: 'Referrals',
              icon: Icons.handshake_outlined,
              description: 'Track referrals you\'ve sent or received from other agents.',
              bullets: [
                'Send a referral with client details to another agent',
                'Track referral fee status once a deal closes',
                'See referrals coming in from your network',
                'Referral history and payout log',
              ],
            ),
          )),
          onBrokerNetwork: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const PlaceholderPage(
              title: 'Broker Network',
              icon: Icons.public,
              description: 'Connect with other agents and brokerages on the platform.',
              bullets: [
                'Browse and connect with nearby agents',
                'Co-list or collaborate on shared deals',
                'Message other members of the network',
                'See who\'s active in your target areas',
              ],
            ),
          )),
          onVisibilityProfile: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const PlaceholderPage(
              title: 'Visibility & Profile',
              icon: Icons.star_outline,
              description: 'Manage your public profile and how prominently you appear to customers.',
              bullets: [
                'Edit your public bio, photo, and specialties',
                'Client ratings and reviews',
                'Boost visibility in search results',
                'Preview how your profile looks to customers',
              ],
            ),
          )),
          onWallet: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const PlaceholderPage(
              title: 'Wallet',
              icon: Icons.account_balance_wallet_outlined,
              description: 'Your balance, commission payouts, and transaction history.',
              bullets: [
                'Current balance and pending payouts',
                'Commission per closed deal, itemized',
                'Withdraw to a linked bank account',
                'Downloadable statements for tax season',
              ],
            ),
          )),
          onMembership: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const PlaceholderPage(
              title: 'Membership',
              icon: Icons.workspace_premium_outlined,
              description: 'Your current tier, perks, and options to upgrade.',
              bullets: [
                'Current tier and progress to the next one',
                'Perks unlocked at each tier',
                'Upgrade or manage billing',
                'Renewal date and payment history',
              ],
            ),
          )),
          onCommunication: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const PlaceholderPage(
              title: 'Communication',
              icon: Icons.chat_bubble_outline,
              description: 'Message customers, other agents, and Admin from one inbox.',
              bullets: [
                'Threaded conversations per customer or lead',
                'Notifications for new tour requests and dispatches',
                'Broadcast updates to your active leads',
                'Message history synced across devices',
              ],
            ),
          )),
          onSchedule: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const PlaceholderPage(
              title: 'Schedule',
              icon: Icons.calendar_month_outlined,
              description: 'Your calendar for property tours and client bookings.',
              bullets: [
                'Day/week calendar view of confirmed walkthroughs',
                'Buffer time and travel windows between tours',
                'Reschedule or cancel with automatic client notice',
                'Syncs with dispatches accepted from the ringing overlay',
              ],
            ),
          )),
          onSettings: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const PlaceholderPage(
              title: 'Settings',
              icon: Icons.settings_outlined,
              description: 'Account, notification, and app preferences.',
              bullets: [
                'Edit account details and password',
                'Notification preferences',
                'Payout and banking details',
                'App theme and language',
              ],
            ),
          )),
          onSupport: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const PlaceholderPage(
              title: 'Support',
              icon: Icons.support_agent_outlined,
              description: 'Get help from the EBN team.',
              bullets: [
                'Browse FAQs and help articles',
                'Start a live chat with support',
                'Submit a ticket for account or billing issues',
                'Report a bug or give feedback',
              ],
            ),
          )),
          onLogout: () => _logout(loop),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              LoopProgress(stage: loop.stage),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SearchRow(
                              controller: _searchController,
                              onChanged: (_) => setState(() {}),
                              onFilterTap: () => _openFilters(context),
                              hasActiveFilters: _hasActiveFilters,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _CategoryFilterRow(
                              selected: _categoryFilter,
                              onSelected: (v) => setState(() => _categoryFilter = v),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _ResultsSortRow(count: assets.length, sort: _sort, onSortChanged: (v) => setState(() => _sort = v)),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: AppSpacing.sm,
                          crossAxisSpacing: AppSpacing.sm,
                          childAspectRatio: 0.72,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final asset = assets[index];
                            return AssetListCard(
                              asset: asset,
                              compact: true,
                              isSaved: _savedIds.contains(asset.id),
                              onSaveToggle: (v) => setState(() => v ? _savedIds.add(asset.id) : _savedIds.remove(asset.id)),
                              actionLabel: 'View',
                              onActionPressed: () {},
                            );
                          },
                          childCount: assets.length,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (loop.isRinging) _RingingOverlay(loop: loop),
        ],
      ),
    );
  }
}

/// Full-screen overlay that appears the instant Admin dispatches this agent
/// while they're online — matches the platform's ink/yellow language even
/// though it's a dark "focus" moment layered over the light feed below.
class _RingingOverlay extends StatelessWidget {
  const _RingingOverlay({required this.loop});

  final LoopController loop;

  @override
  Widget build(BuildContext context) {
    final asset = loop.requestedAsset;
    return Positioned.fill(
      child: Container(
        color: AppColors.ink.withOpacity(0.94),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryYellow.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  border: Border.all(color: AppColors.primaryYellow.withOpacity(0.4)),
                ),
                child: const Text(
                  'NEW DISPATCH',
                  style: TextStyle(color: AppColors.primaryYellow, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _CountdownRing(seconds: loop.secondsLeft, total: LoopController.dispatchWindowSeconds),
              const SizedBox(height: AppSpacing.lg),
              Text(
                asset?.title ?? 'New tour request',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              if (asset != null)
                Text(
                  [if (asset.addressLine != null) asset.addressLine!, if (asset.city != null) asset.city!].join(' · '),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFB9B8AE), fontSize: 13.5),
                ),
              const SizedBox(height: AppSpacing.xxl),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'Decline',
                      borderColor: AppColors.danger,
                      textColor: AppColors.danger,
                      onPressed: loop.agentDecline,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Accept',
                      backgroundColor: AppColors.primaryYellow,
                      foregroundColor: AppColors.ink,
                      onPressed: loop.agentAccept,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountdownRing extends StatelessWidget {
  const _CountdownRing({required this.seconds, required this.total, this.size = 100});
  final int seconds;
  final int total;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = seconds > total * .5
        ? AppColors.success
        : seconds > total * .25
            ? AppColors.primaryYellow
            : AppColors.danger;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(alignment: Alignment.center, children: [
        SizedBox.expand(
          child: CircularProgressIndicator(
            value: total == 0 ? 0 : seconds / total,
            strokeWidth: 6,
            color: color,
            backgroundColor: Colors.white.withOpacity(.12),
          ),
        ),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Text('$seconds', style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.w900)),
          const Text('sec', style: TextStyle(color: Colors.white54, fontSize: 11)),
        ]),
      ]),
    );
  }
}

class _SearchRow extends StatelessWidget {
  const _SearchRow({required this.controller, required this.onChanged, this.onFilterTap, this.hasActiveFilters = false});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onFilterTap;
  final bool hasActiveFilters;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Search city or address',
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.slate),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.pill), borderSide: const BorderSide(color: AppColors.border)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Material(
          color: hasActiveFilters ? AppColors.primaryYellow : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
            side: BorderSide(color: hasActiveFilters ? AppColors.primaryYellow : AppColors.border),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onFilterTap,
            child: Padding(
              padding: const EdgeInsets.all(13),
              child: Icon(Icons.tune_rounded, size: 20, color: AppColors.ink),
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryFilterRow extends StatelessWidget {
  const _CategoryFilterRow({required this.selected, required this.onSelected});
  final AssetCategorySlug? selected;
  final ValueChanged<AssetCategorySlug?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _FilterChip(label: 'All', isSelected: selected == null, onTap: () => onSelected(null)),
          const SizedBox(width: 8),
          for (final category in AssetCategorySlug.values) ...[
            _FilterChip(label: category.label, isSelected: selected == category, onTap: () => onSelected(category)),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.isSelected, required this.onTap});
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.ink : AppColors.card,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.pill),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadii.pill), border: Border.all(color: isSelected ? AppColors.ink : AppColors.border)),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: isSelected ? AppColors.primaryYellow : AppColors.ink)),
        ),
      ),
    );
  }
}

class _ResultsSortRow extends StatelessWidget {
  const _ResultsSortRow({required this.count, required this.sort, required this.onSortChanged});
  final int count;
  final _SortOption sort;
  final ValueChanged<_SortOption> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$count result${count == 1 ? '' : 's'}', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.slate)),
        const Spacer(),
        PopupMenuButton<_SortOption>(
          initialValue: sort,
          onSelected: onSortChanged,
          color: AppColors.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
          itemBuilder: (context) => _SortOption.values.map((o) => PopupMenuItem(value: o, child: Text(o.label))).toList(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(sort.label, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
              const Icon(Icons.expand_more_rounded, size: 18, color: AppColors.ink),
            ],
          ),
        ),
      ],
    );
  }
}
