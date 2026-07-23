import 'package:flutter/foundation.dart';
import '../models/asset.dart';
import '../models/house_property_details.dart';
import '../models/vehicle_details.dart';
import '../models/machinery_details.dart';
import '../models/sell_request.dart';
import '../services/mock_asset_data.dart';

/// Single source of truth for every "sell my property" submission —
/// mirrors the shared-controller pattern [LoopController] uses for tour
/// requests, but holds a *list* since many submissions can be in flight
/// at once (one per Visitor, vs. the tour loop's single active request).
///
/// Visitor → Admin → Agent/Broker → Admin → live [Asset], all watching this
/// one instance so actions on one side show up instantly on the others —
/// same "no backend, minus the backend" approach as [LoopController].
class SellRequestController extends ChangeNotifier {
  final List<SellRequest> _requests = [];

  List<SellRequest> get all => List.unmodifiable(_requests);

  int _nextId = 1;

  // ── Visitor ──────────────────────────────────────────────────────────
  /// Submits a new property for sale. Payment is mocked — in this
  /// frontend-only build the 100 ETB fee is treated as paid the moment
  /// this is called (the UI shows a mock "processing payment" step before
  /// calling this).
  SellRequest submit({
    required String ownerUserId,
    required String ownerName,
    required String ownerPhone,
    required AssetCategorySlug category,
    required String title,
    required String description,
    required double askingPrice,
    required String city,
    required String addressLine,
    HousePropertyDetails? houseDetails,
    VehicleDetails? vehicleDetails,
    MachineryDetails? machineryDetails,
  }) {
    final request = SellRequest(
      id: 'sr${_nextId++}',
      submittedAt: DateTime.now(),
      ownerUserId: ownerUserId,
      ownerName: ownerName,
      ownerPhone: ownerPhone,
      category: category,
      title: title,
      description: description,
      askingPrice: askingPrice,
      city: city,
      addressLine: addressLine,
      houseDetails: houseDetails,
      vehicleDetails: vehicleDetails,
      machineryDetails: machineryDetails,
    );
    _requests.insert(0, request);
    notifyListeners();
    return request;
  }

  List<SellRequest> byOwner(String ownerUserId) =>
      _requests.where((r) => r.ownerUserId == ownerUserId).toList();

  // ── Admin: submission screening ─────────────────────────────────────────
  List<SellRequest> get pendingSubmissions =>
      _requests.where((r) => r.status == SellRequestStatus.pendingAdminApproval).toList();

  void adminApproveSubmission(String id) {
    final r = _find(id);
    if (r == null || r.status != SellRequestStatus.pendingAdminApproval) return;
    r.status = SellRequestStatus.openToBrokers;
    notifyListeners();
  }

  void adminRejectSubmission(String id, {String? reason}) {
    final r = _find(id);
    if (r == null || r.status != SellRequestStatus.pendingAdminApproval) return;
    r.status = SellRequestStatus.submissionRejected;
    r.submissionRejectionReason = reason?.trim().isNotEmpty == true ? reason : 'Did not meet listing requirements.';
    notifyListeners();
  }

  // ── Agent/Broker: claim ──────────────────────────────────────────────
  List<SellRequest> get openToBrokers =>
      _requests.where((r) => r.status == SellRequestStatus.openToBrokers).toList();

  List<SellRequest> claimedBy(String agentId) => _requests
      .where((r) =>
          r.agentId == agentId &&
          (r.status == SellRequestStatus.claimed || r.status == SellRequestStatus.reportRejected))
      .toList();

  List<SellRequest> reportsPendingBy(String agentId) =>
      _requests.where((r) => r.agentId == agentId && r.status == SellRequestStatus.reportPendingApproval).toList();

  List<SellRequest> listedBy(String agentId) =>
      _requests.where((r) => r.agentId == agentId && r.status == SellRequestStatus.listed).toList();

  /// First-come-first-served: only succeeds while the request is still
  /// `openToBrokers`. Returns false if someone else already claimed it.
  bool agentClaim(String id, {required String agentId, required String agentName}) {
    final r = _find(id);
    if (r == null || r.status != SellRequestStatus.openToBrokers) return false;
    r.status = SellRequestStatus.claimed;
    r.agentId = agentId;
    r.agentName = agentName;
    r.claimedAt = DateTime.now();
    notifyListeners();
    return true;
  }

  // ── Agent/Broker: inspection report ─────────────────────────────────────
  void agentSubmitReport(
    String id, {
    required List<ReportMediaItem> media,
    required String notes,
  }) {
    final r = _find(id);
    if (r == null ||
        (r.status != SellRequestStatus.claimed && r.status != SellRequestStatus.reportRejected)) {
      return;
    }
    r.reportMedia = media;
    r.reportNotes = notes;
    r.reportSubmittedAt = DateTime.now();
    r.reportRejectionReason = null;
    r.status = SellRequestStatus.reportPendingApproval;
    notifyListeners();
  }

  // ── Admin: report screening → publish ───────────────────────────────────
  List<SellRequest> get pendingReports =>
      _requests.where((r) => r.status == SellRequestStatus.reportPendingApproval).toList();

  /// Approves the inspection report, turns it into a real [Asset], appends
  /// it to [kMockCompanyAssets] so it shows up everywhere listings are
  /// read from, and credits it to the claiming Agent.
  Asset adminApproveReport(String id) {
    final r = _find(id);
    if (r == null || r.status != SellRequestStatus.reportPendingApproval) {
      throw StateError('Sell request $id is not awaiting report approval');
    }
    final asset = Asset(
      id: 'sell-${r.id}',
      title: r.title,
      priceAmount: r.askingPrice,
      priceCurrency: 'ETB',
      addressLine: r.addressLine,
      city: r.city,
      category: r.category,
      status: AssetStatus.active,
      attributes: const {},
      imageUrl: r.reportMedia.isNotEmpty
          ? 'https://images.unsplash.com/photo-1560518883-ce09059eeffa?w=800&q=80'
          : null,
      postedLabel: 'New · listed by ${r.agentName ?? 'agent'}',
      brokerId: r.agentId,
    );
    kMockCompanyAssets.add(asset);
    r.status = SellRequestStatus.listed;
    r.listedAssetId = asset.id;
    notifyListeners();
    return asset;
  }

  void adminRejectReport(String id, {String? reason}) {
    final r = _find(id);
    if (r == null || r.status != SellRequestStatus.reportPendingApproval) return;
    r.status = SellRequestStatus.reportRejected;
    r.reportRejectionReason = reason?.trim().isNotEmpty == true ? reason : 'Report needs more detail before this can go live.';
    notifyListeners();
  }

  SellRequest? _find(String id) {
    for (final r in _requests) {
      if (r.id == id) return r;
    }
    return null;
  }

  /// Wipes every submission — used by the demo's "reset" controls.
  void reset() {
    _requests.clear();
    _nextId = 1;
    notifyListeners();
  }
}
