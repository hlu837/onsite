import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/asset.dart';
import '../models/auth_response.dart';
import '../providers/loop_controller.dart';
import '../services/mock_asset_data.dart';
import '../theme/app_theme.dart';
import '../widgets/asset_list_card.dart';
import '../widgets/loop_progress.dart';
import '../widgets/visitor_drawer.dart';
import 'placeholder_page.dart';
import 'role_gate_screen.dart';

/// The Customer side — its own full flow: browse the live asset feed and
/// request an on-site walkthrough. Watches the shared [LoopController] so
/// the status card below updates in real time as Admin/Agent act on it.
class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key, required this.user});

  final AppUser user;

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  AssetCategorySlug? _categoryFilter;

  List<Asset> get _visibleAssets {
    final query = _searchController.text.trim().toLowerCase();
    return kMockCompanyAssets.where((asset) {
      final matchesCategory = _categoryFilter == null || asset.category == _categoryFilter;
      final matchesQuery = query.isEmpty ||
          (asset.city?.toLowerCase().contains(query) ?? false) ||
          (asset.addressLine?.toLowerCase().contains(query) ?? false) ||
          asset.title.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _logout() {
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
          onSearchMap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const PlaceholderPage(
              title: 'Search & Map Directory',
              icon: Icons.map_outlined,
              description: 'Filter listings by location, price, and category, with a live map view.',
            ),
          )),
          onAboutFaq: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const PlaceholderPage(
              title: 'About Us / FAQ',
              icon: Icons.help_outline_rounded,
              description: 'Who Onsite is, how verification works, and answers to common questions.',
            ),
          )),
          onLogout: _logout,
        ),
      ),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Onsite', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            Text('Visitor · ${widget.user.fullName}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500)),
          ],
        ),
        backgroundColor: AppColors.cloud,
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
          LoopProgress(stage: loop.stage),
          if (loop.stage != LoopStage.idle) _StatusCard(loop: loop),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'Search city or address',
                            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.slate),
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadii.pill),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                          height: 38,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              _FilterChip(label: 'All', isSelected: _categoryFilter == null, onTap: () => setState(() => _categoryFilter = null)),
                              const SizedBox(width: 8),
                              for (final c in AssetCategorySlug.values) ...[
                                _FilterChip(
                                  label: c.label,
                                  isSelected: _categoryFilter == c,
                                  onTap: () => setState(() => _categoryFilter = c),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text('${assets.length} result${assets.length == 1 ? '' : 's'}',
                            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.slate)),
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
                        final isThisRequested = loop.requestedAsset?.id == asset.id && loop.stage != LoopStage.idle;
                        final canRequest = loop.stage == LoopStage.idle;
                        return AssetListCard(
                          asset: asset,
                          compact: true,
                          actionLabel: isThisRequested ? 'Requested' : 'Request Tour',
                          onActionPressed: !canRequest
                              ? null
                              : () {
                                  loop.customerRequest(asset);
                                  ScaffoldMessenger.of(context)
                                    ..hideCurrentSnackBar()
                                    ..showSnackBar(SnackBar(content: Text('Searching for the nearest agent for "${asset.title}"…')));
                                },
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
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: Border.all(color: isSelected ? AppColors.ink : AppColors.border),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: isSelected ? AppColors.primaryYellow : AppColors.ink),
          ),
        ),
      ),
    );
  }
}
