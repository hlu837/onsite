import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/auth_response.dart';
import '../providers/loop_controller.dart';
import '../providers/sell_request_controller.dart';
import '../services/mock_asset_data.dart';
import '../theme/app_theme.dart';
import '../widgets/admin_drawer.dart';
import '../widgets/app_buttons.dart';
import '../widgets/asset_list_card.dart';
import '../widgets/loop_progress.dart';
import 'admin_sell_requests_screen.dart';
import 'role_gate_screen.dart';

/// The Admin side — its own full flow: sidebar navigation, live approvals
/// queue, and a snapshot of the asset catalogue. Watches the shared
/// [LoopController] so requests placed on the Customer side show up here
/// the moment they're submitted.
class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key, required this.user});

  final AppUser user;

  void _logout(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RoleGateScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loop = context.watch<LoopController>();
    final sellRequests = context.watch<SellRequestController>();

    return Scaffold(
      backgroundColor: AppColors.cloud,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('EBN', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            Text('Admin · ${user.fullName}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500)),
          ],
        ),
        backgroundColor: AppColors.ink,
        actions: [
          IconButton(tooltip: 'Reset demo', onPressed: loop.reset, icon: const Icon(Icons.restart_alt_rounded)),
          const SizedBox(width: 4),
        ],
      ),
      drawer: AdminDrawer(
        adminName: user.fullName,
        actions: AdminDrawerActions(
          onApprovalsQueue: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const AdminSellRequestsScreen(),
          )),
          onLogout: () => _logout(context),
        ),
      ),
      body: Column(
        children: [
          LoopProgress(stage: loop.stage),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Row(
                  children: [
                    _StatCard(value: '${kMockCompanyAssets.length}', label: 'Total Listings'),
                    const SizedBox(width: AppSpacing.sm),
                    _StatCard(value: _pendingCount(loop), label: 'Pending Approvals'),
                    const SizedBox(width: AppSpacing.sm),
                    _StatCard(value: '12', label: 'Active Agents'),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                Text('Approvals Queue', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.md),
                _ApprovalCard(loop: loop),
                const SizedBox(height: AppSpacing.xl),
                Text('Property Sell Requests', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.md),
                _SellRequestsSummaryCard(
                  pendingSubmissions: sellRequests.pendingSubmissions.length,
                  pendingReports: sellRequests.pendingReports.length,
                  onOpen: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const AdminSellRequestsScreen(),
                  )),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text('Asset Catalogue', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.md),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: kMockCompanyAssets.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: AppSpacing.sm,
                    crossAxisSpacing: AppSpacing.sm,
                    childAspectRatio: 0.72,
                  ),
                  itemBuilder: (context, index) => AssetListCard(
                    asset: kMockCompanyAssets[index],
                    compact: true,
                    actionLabel: 'Manage',
                    onActionPressed: () {},
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _pendingCount(LoopController loop) {
    final active = loop.stage == LoopStage.pendingApproval ||
        loop.stage == LoopStage.declined ||
        loop.stage == LoopStage.expired;
    return active ? '1' : '0';
  }
}

class _SellRequestsSummaryCard extends StatelessWidget {
  const _SellRequestsSummaryCard({required this.pendingSubmissions, required this.pendingReports, required this.onOpen});

  final int pendingSubmissions;
  final int pendingReports;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final total = pendingSubmissions + pendingReports;
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadii.lg), border: Border.all(color: AppColors.border)),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: AppColors.primaryYellow.withOpacity(0.18), borderRadius: BorderRadius.circular(AppRadii.md)),
                alignment: Alignment.center,
                child: const Icon(Icons.sell_outlined, color: AppColors.ink),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      total == 0 ? 'Nothing waiting' : '$total item${total == 1 ? '' : 's'} need review',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$pendingSubmissions new submission${pendingSubmissions == 1 ? '' : 's'} · $pendingReports inspection report${pendingReports == 1 ? '' : 's'}',
                      style: const TextStyle(fontSize: 12, color: AppColors.slate),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.slate),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(AppRadii.lg), border: Border.all(color: AppColors.border)),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 19, color: AppColors.ink)),
            const SizedBox(height: 2),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, color: AppColors.slate)),
          ],
        ),
      ),
    );
  }
}

class _ApprovalCard extends StatelessWidget {
  const _ApprovalCard({required this.loop});

  final LoopController loop;

  @override
  Widget build(BuildContext context) {
    final showQueueItem = loop.stage == LoopStage.pendingApproval ||
        loop.stage == LoopStage.declined ||
        loop.stage == LoopStage.expired;

    if (!showQueueItem) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.inbox_rounded, color: AppColors.slate, size: 22),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                loop.stage == LoopStage.idle
                    ? 'Nothing waiting — queue is empty.'
                    : 'Request is out with an agent right now.',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.slate),
              ),
            ),
          ],
        ),
      );
    }

    final asset = loop.requestedAsset;
    final isRetry = loop.stage != LoopStage.pendingApproval;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(color: AppColors.primaryYellow, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Icon(
                  isRetry ? Icons.replay_rounded : Icons.request_page_rounded,
                  color: AppColors.ink,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isRetry ? 'Needs re-dispatch' : 'New tour request',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    if (asset != null)
                      Text(
                        asset.title,
                        style: const TextStyle(color: Color(0xFFB9B8AE), fontSize: 12.5),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (isRetry) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              loop.stage == LoopStage.declined
                  ? 'Previous agent declined the dispatch.'
                  : 'Previous dispatch window expired with no response.',
              style: const TextStyle(color: Color(0xFFB9B8AE), fontSize: 12, height: 1.4),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: isRetry ? 'Re-dispatch to Agent' : 'Approve & Publish',
            backgroundColor: AppColors.primaryYellow,
            foregroundColor: AppColors.ink,
            onPressed: loop.adminApprove,
          ),
        ],
      ),
    );
  }
}
