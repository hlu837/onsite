import 'package:flutter/material.dart';
import '../data/mock_brokers.dart';
import '../models/asset.dart';
import '../theme/landing_colors.dart';
import 'broker_profile_screen.dart';

/// Mock map screen showing every broker for a category as a pin, using
/// their mock lat/lng from `mock_brokers.dart`. There's no real map SDK
/// wired into this demo, so the "map" is a lightweight custom-painted
/// stand-in — good enough to place pins at realistic relative positions
/// and let the person tap through to a broker's profile.
///
/// TODO: swap `_MockMapBackground` for a real map widget (e.g. Google Maps
/// or flutter_map) once a maps SDK + API key is wired into the app; the
/// pin-placement / tap-to-profile logic below can stay as-is.
class BrokerMapScreen extends StatefulWidget {
  final AssetCategorySlug category;
  final String categoryLabel;
  final Broker? highlightBroker;

  /// When true, shows every broker in the directory instead of filtering
  /// down to [category] — used by the "Broker List" tile on the landing
  /// page, which isn't tied to a single asset category.
  final bool showAllBrokers;

  const BrokerMapScreen({
    super.key,
    required this.category,
    required this.categoryLabel,
    this.highlightBroker,
    this.showAllBrokers = false,
  });

  @override
  State<BrokerMapScreen> createState() => _BrokerMapScreenState();
}

class _BrokerMapScreenState extends State<BrokerMapScreen> {
  Broker? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.highlightBroker;
  }

  @override
  Widget build(BuildContext context) {
    final brokers = widget.showAllBrokers ? kMockBrokers : brokersFor(widget.category);

    final lats = brokers.map((b) => b.latitude).toList();
    final lngs = brokers.map((b) => b.longitude).toList();
    final minLat = lats.reduce((a, b) => a < b ? a : b);
    final maxLat = lats.reduce((a, b) => a > b ? a : b);
    final minLng = lngs.reduce((a, b) => a < b ? a : b);
    final maxLng = lngs.reduce((a, b) => a > b ? a : b);

    return Scaffold(
      backgroundColor: LandingColors.background,
      body: Stack(
        children: [
          // Full-bleed map fills the entire screen behind everything else.
          const Positioned.fill(child: _MockMapBackground()),
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: brokers.map((b) {
                    final offset = _project(
                      b.latitude, b.longitude,
                      minLat, maxLat, minLng, maxLng,
                      constraints.biggest,
                    );
                    final isSelected = _selected?.id == b.id;
                    return Positioned(
                      left: offset.dx - 20,
                      top: offset.dy - 44,
                      child: _MapPin(
                        broker: b,
                        selected: isSelected,
                        onTap: () => setState(() => _selected = b),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          // Small floating back button + title pill, top-left.
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Row(
                children: [
                  _FloatingCircleButton(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: LandingColors.card,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 2))],
                      ),
                      child: Text('${widget.categoryLabel} brokers · map',
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: LandingColors.foreground),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Small floating broker count / live indicator, top-right.
          SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 10, 12, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: LandingColors.card,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 2))],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text('${brokers.length} active', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: LandingColors.muted)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Small floating broker preview, docked to the bottom over the map.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: _selected == null
                    ? Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        decoration: BoxDecoration(
                          color: LandingColors.card,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 10, offset: Offset(0, 3))],
                        ),
                        child: const Text('Tap a pin to see that broker\'s details.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: LandingColors.muted, fontSize: 12.5)),
                      )
                    : _BrokerPreviewCard(broker: _selected!),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Projects a lat/lng into pixel coordinates within `size`, padded so
  /// pins never sit flush against the map's edge. Falls back to centering
  /// everything when every broker shares the same coordinate (avoids
  /// divide-by-zero when there's only one pin).
  Offset _project(double lat, double lng, double minLat, double maxLat, double minLng, double maxLng, Size size) {
    const padding = 46.0;
    final latSpan = (maxLat - minLat).abs();
    final lngSpan = (maxLng - minLng).abs();
    final nx = lngSpan == 0 ? 0.5 : (lng - minLng) / lngSpan;
    // Latitude increases northward but screen y increases downward.
    final ny = latSpan == 0 ? 0.5 : 1 - (lat - minLat) / latSpan;
    final dx = padding + nx * (size.width - padding * 2);
    final dy = padding + ny * (size.height - padding * 2);
    return Offset(dx, dy);
  }
}

/// Lightweight custom-painted stand-in for a real map tile layer — draws a
/// muted terrain-style background with a road grid so pins have context to
/// sit on, without depending on any map SDK or network tiles.
class _MockMapBackground extends StatelessWidget {
  const _MockMapBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE9E4D6),
      child: CustomPaint(painter: _MapGridPainter(), size: Size.infinite),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final blockPaint = Paint()..color = const Color(0xFFF2EEE1);
    final roadPaint = Paint()
      ..color = const Color(0xFFD8D0BC)
      ..strokeWidth = 3;
    final mainRoadPaint = Paint()
      ..color = const Color(0xFFE8B23A).withOpacity(0.55)
      ..strokeWidth = 5;

    // Soft "land parcel" blocks.
    const blockSize = 64.0;
    for (double y = 0; y < size.height; y += blockSize) {
      for (double x = 0; x < size.width; x += blockSize) {
        if (((x / blockSize).floor() + (y / blockSize).floor()) % 2 == 0) {
          canvas.drawRect(Rect.fromLTWH(x + 4, y + 4, blockSize - 8, blockSize - 8), blockPaint);
        }
      }
    }

    // Grid "streets".
    for (double x = 0; x < size.width; x += blockSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), roadPaint);
    }
    for (double y = 0; y < size.height; y += blockSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), roadPaint);
    }

    // A couple of "main roads" for visual interest.
    canvas.drawLine(Offset(0, size.height * 0.38), Offset(size.width, size.height * 0.42), mainRoadPaint);
    canvas.drawLine(Offset(size.width * 0.62, 0), Offset(size.width * 0.55, size.height), mainRoadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Small circular icon button that floats on top of the map (used for the
/// back button) instead of the old full-width app-bar-style header.
class _FloatingCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _FloatingCircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: LandingColors.card,
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 2))],
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: LandingColors.foreground),
        ),
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  final Broker broker;
  final bool selected;
  final VoidCallback onTap;
  const _MapPin({required this.broker, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 40,
        height: 48,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: selected ? 36 : 30,
              height: selected ? 36 : 30,
              decoration: BoxDecoration(
                color: selected ? LandingColors.foreground : LandingColors.gold,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 2))],
              ),
              alignment: Alignment.center,
              child: Icon(Icons.person, size: selected ? 18 : 15, color: selected ? LandingColors.primaryFg : LandingColors.goldFg),
            ),
            CustomPaint(size: const Size(10, 8), painter: _PinTailPainter(color: selected ? LandingColors.foreground : LandingColors.gold)),
          ],
        ),
      ),
    );
  }
}

class _PinTailPainter extends CustomPainter {
  final Color color;
  _PinTailPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PinTailPainter oldDelegate) => oldDelegate.color != color;
}

class _BrokerPreviewCard extends StatelessWidget {
  final Broker broker;
  const _BrokerPreviewCard({required this.broker});

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: LandingColors.card,
          border: Border.all(color: LandingColors.border),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 10, offset: Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
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
                      Text('${broker.company} · ${broker.city}', style: const TextStyle(color: LandingColors.muted, fontSize: 12.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Icon(broker.tier.icon, size: 16, color: broker.tier.color),
                const SizedBox(width: 3),
                Text(broker.tier.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: broker.tier.color)),
              ],
            ),
            if (broker.addressLine != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 15, color: LandingColors.muted),
                  const SizedBox(width: 4),
                  Expanded(child: Text(broker.addressLine!, style: const TextStyle(fontSize: 12.5, color: LandingColors.muted))),
                ],
              ),
            ],
            const SizedBox(height: 14),
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => BrokerProfileScreen(broker: broker))),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(color: LandingColors.foreground, borderRadius: BorderRadius.circular(999)),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('View profile', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: LandingColors.primaryFg)),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward_rounded, size: 15, color: LandingColors.primaryFg),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
    );
  }
}
