import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/mock_brokers.dart';
import '../models/asset.dart';
import '../providers/loop_controller.dart';
import '../theme/app_theme.dart';
import 'broker_chat_screen.dart';
import 'broker_profile_screen.dart';

/// Mock office details shown when a listing has no assigned broker (i.e. it
/// was posted directly by Admin rather than through a broker). There's no
/// backend field for this yet, so it's hard-coded here as a stand-in.
class _EbnOffice {
  static const name = 'EBN Head Office';
  static const addressLine = 'Bole Road, Friendship Building, 4th Floor';
  static const city = 'Addis Ababa';
  static const phone = '+251 11 662 0000';
}

/// Full-page detail view for a single listing — reached by tapping any
/// listing card (Featured listings on the Visitor dashboard, or a category
/// page). Shows the full listing details plus who to reach about it: the
/// assigned broker, or EBN's office when Admin posted it directly with
/// no broker attached. The "Request Tour" button here is what actually
/// kicks off the live admin/agent loop — tapping a listing itself no longer
/// starts a request, so the approval-stage tracker only appears once this
/// button is pressed.
class AssetDetailScreen extends StatelessWidget {
  const AssetDetailScreen({super.key, required this.asset});

  final Asset asset;

  Broker? get _broker => asset.brokerId != null ? brokerById(asset.brokerId!) : null;

  static Color _statusColor(AssetStatus status) {
    switch (status) {
      case AssetStatus.active:
        return AppColors.success;
      case AssetStatus.underInspection:
        return AppColors.primaryYellowDark;
      case AssetStatus.sold:
        return AppColors.danger;
      case AssetStatus.draft:
      case AssetStatus.archived:
        return AppColors.slate;
    }
  }

  static IconData _categoryIcon(AssetCategorySlug category) {
    switch (category) {
      case AssetCategorySlug.apartments:
        return Icons.apartment_rounded;
      case AssetCategorySlug.vehicles:
        return Icons.directions_car_filled_rounded;
      case AssetCategorySlug.machinery:
        return Icons.precision_manufacturing_rounded;
      case AssetCategorySlug.realEstate:
        return Icons.villa_rounded;
      case AssetCategorySlug.condominium:
        return Icons.location_city_rounded;
      case AssetCategorySlug.house:
        return Icons.house_rounded;
      case AssetCategorySlug.warehouse:
        return Icons.warehouse_rounded;
      case AssetCategorySlug.land:
        return Icons.terrain_rounded;
      case AssetCategorySlug.building:
        return Icons.business_rounded;
      case AssetCategorySlug.constructionMaterials:
        return Icons.construction_rounded;
      case AssetCategorySlug.others:
        return Icons.category_rounded;
    }
  }

  void _requestTour(BuildContext context, LoopController loop) {
    loop.customerRequest(asset);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Searching for the nearest agent for "${asset.title}"…')));
  }

  @override
  Widget build(BuildContext context) {
    final loop = context.watch<LoopController>();
    final broker = _broker;
    final isThisRequested = loop.requestedAsset?.id == asset.id && loop.stage != LoopStage.idle;
    final hasActiveRequest = loop.stage != LoopStage.idle;
    final canRequest = !hasActiveRequest;

    return Scaffold(
      backgroundColor: AppColors.cloud,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.ink,
            foregroundColor: Colors.white,
            expandedHeight: 260,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (asset.imageUrl != null)
                    Image.network(
                      asset.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => _ImageFallback(icon: _categoryIcon(asset.category)),
                      loadingBuilder: (context, child, progress) =>
                          progress == null ? child : _ImageFallback(icon: _categoryIcon(asset.category)),
                    )
                  else
                    _ImageFallback(icon: _categoryIcon(asset.category)),
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment(0, -0.2),
                          colors: [Color(0x55000000), Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(asset.formattedPrice, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink)),
                      const SizedBox(width: 10),
                      Icon(Icons.circle, size: 9, color: _statusColor(asset.status)),
                      const SizedBox(width: 4),
                      Text(asset.status.label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _statusColor(asset.status))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(asset.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)),
                  if (asset.specLine.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(asset.specLine, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.slate)),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_outlined, size: 18, color: AppColors.slate),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          [if (asset.addressLine != null) asset.addressLine!, if (asset.city != null) asset.city!].join(', '),
                          style: const TextStyle(fontSize: 13.5, color: AppColors.ink, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: AppSpacing.lg),
                  broker != null ? _BrokerSection(broker: broker, asset: asset) : const _OfficeSection(),
                  if (hasActiveRequest && !isThisRequested) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Text(
                        'You already have an active request. Finish or wait for it to complete before starting a new one.',
                        style: TextStyle(fontSize: 12.5, color: AppColors.slate),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
          child: FilledButton(
            onPressed: !canRequest ? null : () => _requestTour(context, loop),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryYellow,
              foregroundColor: AppColors.ink,
              disabledBackgroundColor: AppColors.border,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.pill)),
            ),
            child: Text(
              isThisRequested ? 'Tour Requested' : 'Request Tour',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
            ),
          ),
        ),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.inkSoft,
      alignment: Alignment.center,
      child: Icon(icon, color: AppColors.primaryYellow.withOpacity(0.85), size: 64),
    );
  }
}

/// Shown when the listing has an assigned broker — who to contact, plus
/// quick actions to view their full profile or start a chat about this
/// specific listing.
class _BrokerSection extends StatelessWidget {
  const _BrokerSection({required this.broker, required this.asset});

  final Broker broker;
  final Asset asset;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Listed by', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.slate)),
        const SizedBox(height: AppSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(color: AppColors.primaryYellow, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(broker.initials, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(broker.name, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text('${broker.company} · ${broker.city}',
                      style: const TextStyle(color: AppColors.slate, fontSize: 12.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 15, color: AppColors.primaryYellowDark),
                      const SizedBox(width: 2),
                      Text(broker.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 12.5, color: AppColors.slate)),
                      const SizedBox(width: 10),
                      Icon(broker.tier.icon, size: 14, color: AppColors.ink),
                      const SizedBox(width: 2),
                      Text(broker.tier.label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => BrokerProfileScreen(broker: broker),
                )),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  side: const BorderSide(color: AppColors.ink, width: 1.2),
                  textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
                icon: const Icon(Icons.person_outline, size: 16),
                label: const Text('View profile'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => BrokerChatScreen(broker: broker, asset: asset),
                )),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryYellow,
                  foregroundColor: AppColors.ink,
                  minimumSize: const Size(0, 40),
                  textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
                icon: const Icon(Icons.chat_bubble_outline, size: 16),
                label: const Text('Chat'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Shown when the listing has no assigned broker — meaning it was posted
/// directly by Admin — pointing the Visitor to EBN's office instead of
/// a broker.
class _OfficeSection extends StatelessWidget {
  const _OfficeSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Posted by EBN', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.slate)),
        const SizedBox(height: AppSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(color: AppColors.primaryYellow, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: const Icon(Icons.storefront_rounded, color: AppColors.ink),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(_EbnOffice.name, style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text('${_EbnOffice.addressLine}, ${_EbnOffice.city}',
                      style: const TextStyle(fontSize: 12.5, color: AppColors.slate, height: 1.3)),
                  const SizedBox(height: 2),
                  const Text(_EbnOffice.phone, style: TextStyle(fontSize: 12.5, color: AppColors.slate)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'This listing was posted directly by EBN — request a tour and an agent will be dispatched from the office above.',
          style: TextStyle(fontSize: 12, color: AppColors.slate, height: 1.4),
        ),
      ],
    );
  }
}
