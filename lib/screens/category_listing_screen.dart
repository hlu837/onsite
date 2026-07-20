import 'package:flutter/material.dart';
import '../data/mock_brokers.dart';
import '../models/asset.dart';
import '../services/mock_asset_data.dart';
import '../theme/landing_colors.dart';
import '../widgets/asset_list_card.dart';
import 'broker_map_screen.dart';
import 'broker_profile_screen.dart';

/// Category detail page reached by tapping a tile in the landing page's
/// category grid. Shows a search bar, a horizontally-scrollable strip of
/// listings in that category, and a way to pull up nearby brokers who
/// specialize in it.
class CategoryListingScreen extends StatefulWidget {
  final AssetCategorySlug category;
  final String categoryLabel;
  final IconData categoryIcon;
  final VoidCallback onGetStarted;

  const CategoryListingScreen({
    super.key,
    required this.category,
    required this.categoryLabel,
    required this.categoryIcon,
    required this.onGetStarted,
  });

  @override
  State<CategoryListingScreen> createState() => _CategoryListingScreenState();
}

enum _SortOption { relevance, priceLowHigh, priceHighLow }

extension _SortOptionX on _SortOption {
  String get label {
    switch (this) {
      case _SortOption.relevance:
        return 'Relevance';
      case _SortOption.priceLowHigh:
        return 'Price: Low to High';
      case _SortOption.priceHighLow:
        return 'Price: High to Low';
    }
  }
}

class _CategoryListingScreenState extends State<CategoryListingScreen> {
  final _searchController = TextEditingController();
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();
  String _query = '';
  double? _minPrice;
  double? _maxPrice;
  _SortOption _sort = _SortOption.relevance;

  bool get _hasActiveFilters => _minPrice != null || _maxPrice != null || _sort != _SortOption.relevance;

  @override
  void dispose() {
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  List<Asset> get _assets {
    final q = _query.trim().toLowerCase();
    final list = kMockCompanyAssets.where((a) {
      if (a.category != widget.category) return false;
      if (_minPrice != null && a.priceAmount < _minPrice!) return false;
      if (_maxPrice != null && a.priceAmount > _maxPrice!) return false;
      if (q.isEmpty) return true;
      return a.title.toLowerCase().contains(q) ||
          (a.city ?? '').toLowerCase().contains(q) ||
          (a.addressLine ?? '').toLowerCase().contains(q);
    }).toList();
    switch (_sort) {
      case _SortOption.relevance:
        break;
      case _SortOption.priceLowHigh:
        list.sort((a, b) => a.priceAmount.compareTo(b.priceAmount));
        break;
      case _SortOption.priceHighLow:
        list.sort((a, b) => b.priceAmount.compareTo(a.priceAmount));
        break;
    }
    return list;
  }

  Future<void> _openFilters(BuildContext context) async {
    _minPriceController.text = _minPrice == null ? '' : _minPrice!.toStringAsFixed(0);
    _maxPriceController.text = _maxPrice == null ? '' : _maxPrice!.toStringAsFixed(0);
    var sheetSort = _sort;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: LandingColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
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
                        child: Text('Filters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: LandingColors.foreground)),
                      ),
                      TextButton(
                        onPressed: () {
                          setSheetState(() {
                            sheetSort = _SortOption.relevance;
                            _minPriceController.clear();
                            _maxPriceController.clear();
                          });
                        },
                        child: const Text('Reset', style: TextStyle(color: LandingColors.muted, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Sort by', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: LandingColors.foreground)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _SortOption.values.map((option) {
                      final selected = sheetSort == option;
                      return ChoiceChip(
                        label: Text(option.label),
                        selected: selected,
                        onSelected: (_) => setSheetState(() => sheetSort = option),
                        labelStyle: TextStyle(
                          color: selected ? LandingColors.goldFg : LandingColors.foreground,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                        ),
                        backgroundColor: LandingColors.card,
                        selectedColor: LandingColors.gold,
                        side: const BorderSide(color: LandingColors.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  const Text('Price range', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: LandingColors.foreground)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _minPriceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Min',
                            hintStyle: const TextStyle(color: LandingColors.muted),
                            filled: true,
                            fillColor: LandingColors.card,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: LandingColors.border)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: LandingColors.border)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: LandingColors.gold, width: 1.5)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text('–', style: TextStyle(color: LandingColors.muted)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _maxPriceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Max',
                            hintStyle: const TextStyle(color: LandingColors.muted),
                            filled: true,
                            fillColor: LandingColors.card,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: LandingColors.border)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: LandingColors.border)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: LandingColors.gold, width: 1.5)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _sort = sheetSort;
                        _minPrice = double.tryParse(_minPriceController.text.trim());
                        _maxPrice = double.tryParse(_maxPriceController.text.trim());
                      });
                      Navigator.of(sheetContext).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LandingColors.gold,
                      foregroundColor: LandingColors.goldFg,
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
      },
    );
  }

  void _openBrokerFinder(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: LandingColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => _BrokerFinderSheet(category: widget.category, categoryLabel: widget.categoryLabel),
    );
  }

  @override
  Widget build(BuildContext context) {
    final assets = _assets;
    return Scaffold(
      backgroundColor: LandingColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: LandingColors.foreground),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: LandingColors.gold.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                    alignment: Alignment.center,
                    child: Icon(widget.categoryIcon, size: 18, color: LandingColors.gold),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(widget.categoryLabel, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: LandingColors.foreground)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        hintText: 'Search ${widget.categoryLabel.toLowerCase()}...',
                        hintStyle: const TextStyle(color: LandingColors.muted),
                        prefixIcon: const Icon(Icons.search, color: LandingColors.muted),
                        filled: true,
                        fillColor: LandingColors.card,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: const BorderSide(color: LandingColors.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: const BorderSide(color: LandingColors.border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: const BorderSide(color: LandingColors.gold, width: 1.5)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Material(
                    color: _hasActiveFilters ? LandingColors.gold : LandingColors.card,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                      side: BorderSide(color: _hasActiveFilters ? LandingColors.gold : LandingColors.border),
                    ),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => _openFilters(context),
                      child: Padding(
                        padding: const EdgeInsets.all(13),
                        child: Icon(
                          Icons.tune_rounded,
                          size: 20,
                          color: _hasActiveFilters ? LandingColors.goldFg : LandingColors.foreground,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                children: [
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () => _openBrokerFinder(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        decoration: BoxDecoration(
                          color: LandingColors.foreground,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.groups_rounded, size: 18, color: LandingColors.primaryFg),
                            const SizedBox(width: 8),
                            Text('Find ${widget.categoryLabel.toLowerCase()} brokers',
                                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: LandingColors.primaryFg)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('${assets.length} listing${assets.length == 1 ? '' : 's'}',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: LandingColors.muted)),
                  const SizedBox(height: 12),
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
                    SizedBox(
                      height: 260,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: assets.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (_, i) => SizedBox(
                          width: 190,
                          child: AssetListCard(
                            asset: assets[i],
                            showCategoryPill: false,
                            actionLabel: 'Get started',
                            onActionPressed: widget.onGetStarted,
                            onTap: widget.onGetStarted,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 28),
                  _SellOrMeetBrokerCard(
                    categoryLabel: widget.categoryLabel,
                    onSell: widget.onGetStarted,
                    onMeetBroker: () => _openBrokerFinder(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SellOrMeetBrokerCard extends StatelessWidget {
  final String categoryLabel;
  final VoidCallback onSell;
  final VoidCallback onMeetBroker;

  const _SellOrMeetBrokerCard({
    required this.categoryLabel,
    required this.onSell,
    required this.onMeetBroker,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        color: LandingColors.card,
        border: Border.all(color: LandingColors.border),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Have a ${categoryLabel.toLowerCase()} to sell?',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: LandingColors.foreground),
          ),
          const SizedBox(height: 6),
          const Text(
            'List it in minutes, or talk to a broker who can guide you through it.',
            style: TextStyle(fontSize: 13, color: LandingColors.muted),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: onSell,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: LandingColors.gold,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.sell_outlined, size: 16, color: LandingColors.goldFg),
                          SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Sell it here',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: LandingColors.goldFg),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: onMeetBroker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        border: Border.all(color: LandingColors.foreground, width: 1.4),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.groups_rounded, size: 16, color: LandingColors.foreground),
                          SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Meet a broker',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: LandingColors.foreground),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
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

class _BrokerFinderSheet extends StatelessWidget {
  final AssetCategorySlug category;
  final String categoryLabel;
  const _BrokerFinderSheet({required this.category, required this.categoryLabel});

  void _openMap(BuildContext context, {Broker? highlight}) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BrokerMapScreen(category: category, categoryLabel: categoryLabel, highlightBroker: highlight),
    ));
  }

  void _openProfile(BuildContext context, Broker broker) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BrokerProfileScreen(broker: broker),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final brokers = brokersFor(category);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                height: 4,
                width: 40,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: LandingColors.border, borderRadius: BorderRadius.circular(999)),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$categoryLabel brokers', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: LandingColors.foreground)),
                      const SizedBox(height: 4),
                      const Text('Verified agents who can help you close this deal.', style: TextStyle(fontSize: 13, color: LandingColors.muted)),
                    ],
                  ),
                ),
                Material(
                  color: LandingColors.foreground,
                  borderRadius: BorderRadius.circular(999),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => _openMap(context),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          Icon(Icons.map_rounded, size: 16, color: LandingColors.primaryFg),
                          SizedBox(width: 6),
                          Text('Map', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: LandingColors.primaryFg)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: brokers.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: LandingColors.border),
                itemBuilder: (_, i) {
                  final broker = brokers[i];
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _openProfile(context, broker),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: const BoxDecoration(color: LandingColors.gold, shape: BoxShape.circle),
                              alignment: Alignment.center,
                              child: Text(broker.initials, style: const TextStyle(fontWeight: FontWeight.w700, color: LandingColors.goldFg)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(broker.name, style: const TextStyle(fontWeight: FontWeight.w700, color: LandingColors.foreground, fontSize: 14.5)),
                                  const SizedBox(height: 2),
                                  Text('${broker.company} · ${broker.city}',
                                      style: const TextStyle(color: LandingColors.muted, fontSize: 12.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      const Icon(Icons.star_rounded, size: 14, color: LandingColors.gold),
                                      const SizedBox(width: 2),
                                      Text(broker.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 12, color: LandingColors.muted)),
                                      const SizedBox(width: 8),
                                      Icon(broker.tier.icon, size: 13, color: broker.tier.color),
                                      const SizedBox(width: 2),
                                      Text(broker.tier.label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: broker.tier.color)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              onPressed: () => _openMap(context, highlight: broker),
                              icon: const Icon(Icons.map_outlined, color: LandingColors.foreground),
                              tooltip: 'View on map',
                            ),
                            const Icon(Icons.chevron_right_rounded, color: LandingColors.muted),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
