import 'package:flutter/material.dart';
import '../models/asset.dart';
import '../theme/app_theme.dart';

/// A single listing card for the company property/asset feed.
/// Layout mirrors familiar real-estate marketplace cards (image up top with
/// a status pill and favorite button, price + specs + address below, and a
/// primary action) restyled with the platform's ink/yellow palette.
class AssetListCard extends StatelessWidget {
  const AssetListCard({
    super.key,
    required this.asset,
    this.isSaved = false,
    this.onSaveToggle,
    this.onTap,
    this.onActionPressed,
    this.actionLabel = 'View details',
    this.compact = false,
    this.showCategoryPill = true,
  });

  final Asset asset;
  final bool isSaved;
  final ValueChanged<bool>? onSaveToggle;
  final VoidCallback? onTap;
  final VoidCallback? onActionPressed;
  final String actionLabel;
  final bool compact;
  /// Whether to show the category pill (e.g. "Apartments") on the card.
  /// Set to false on screens where the category is already implied by
  /// context (e.g. a category detail page) to avoid redundant labeling.
  final bool showCategoryPill;

  Color get _statusColor {
    switch (asset.status) {
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

  @override
  Widget build(BuildContext context) {
    if (compact) return _buildCompact(context);
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ImageHeader(
                asset: asset,
                isSaved: isSaved,
                onSaveToggle: onSaveToggle,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.circle, size: 9, color: _statusColor),
                        const SizedBox(width: 6),
                        Text(
                          asset.status.label,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: _statusColor,
                          ),
                        ),
                        if (showCategoryPill) ...[
                          const Spacer(),
                          _CategoryPill(label: asset.category.label),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      asset.formattedPrice,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontSize: 21),
                    ),
                    if (asset.specLine.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        asset.specLine,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.slate,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            [
                              if (asset.addressLine != null) asset.addressLine!,
                              if (asset.city != null) asset.city!,
                            ].join('\n'),
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              color: AppColors.ink,
                              height: 1.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        OutlinedButton(
                          onPressed: onActionPressed,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 32),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            side: const BorderSide(color: AppColors.ink, width: 1.2),
                            textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                          child: Text(actionLabel, textAlign: TextAlign.center),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Small 2-column grid card (Jiji-style): image up top, price + title +
  /// location packed tightly underneath, no inline action button -- the
  /// whole card is tappable instead.
  Widget _buildCompact(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap ?? onActionPressed,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1.15,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (asset.imageUrl != null)
                      Image.network(
                        asset.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => _ImageFallback(category: asset.category),
                        loadingBuilder: (context, child, progress) =>
                            progress == null ? child : _ImageFallback(category: asset.category),
                      )
                    else
                      _ImageFallback(category: asset.category),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Transform.scale(
                        scale: 0.8,
                        child: _FavoriteButton(isSaved: isSaved, onToggle: onSaveToggle),
                      ),
                    ),
                    if (asset.postedLabel != null)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.ink,
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                          ),
                          child: Text(
                            asset.postedLabel!,
                            style: const TextStyle(
                              color: AppColors.primaryYellow,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      asset.formattedPrice,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (asset.specLine.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        asset.specLine,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.slate,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (asset.city != null) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 11, color: AppColors.slate),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              asset.city!,
                              style: const TextStyle(fontSize: 11, color: AppColors.slate, fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
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
      ),
    );
  }
}

class _ImageHeader extends StatelessWidget {
  const _ImageHeader({required this.asset, this.isSaved = false, this.onSaveToggle});

  final Asset asset;
  final bool isSaved;
  final ValueChanged<bool>? onSaveToggle;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 10,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (asset.imageUrl != null)
            Image.network(
              asset.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => _ImageFallback(category: asset.category),
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : _ImageFallback(category: asset.category),
            )
          else
            _ImageFallback(category: asset.category),

          // Gradient scrim so the top badges stay legible over any photo.
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment(0, -0.4),
                  colors: [Color(0x33000000), Colors.transparent],
                ),
              ),
            ),
          ),

          if (asset.postedLabel != null)
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Text(
                  asset.postedLabel!,
                  style: const TextStyle(
                    color: AppColors.primaryYellow,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

          Positioned(
            top: 8,
            right: 8,
            child: _FavoriteButton(isSaved: isSaved, onToggle: onSaveToggle),
          ),
        ],
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({required this.category});

  final AssetCategorySlug category;

  IconData get _icon {
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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.inkSoft,
      alignment: Alignment.center,
      child: Icon(_icon, color: AppColors.primaryYellow.withOpacity(0.85), size: 40),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.isSaved, this.onToggle});

  final bool isSaved;
  final ValueChanged<bool>? onToggle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => onToggle?.call(!isSaved),
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(
            isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            size: 18,
            color: isSaved ? AppColors.danger : AppColors.ink,
          ),
        ),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primaryYellow.withOpacity(0.25),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
      ),
    );
  }
}
