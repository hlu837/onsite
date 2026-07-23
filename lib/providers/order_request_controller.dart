import 'package:flutter/foundation.dart';
import '../models/asset.dart';
import '../models/machinery_requirement.dart';
import '../models/order_request.dart';
import '../models/vehicle_requirement.dart';

/// Single source of truth for every "Order Us" submission — same
/// no-backend, single-shared-instance approach as [SellRequestController],
/// just for requirements instead of listings. A Visitor submits what
/// they're looking for; Admin/Agent screens (once built) can watch this
/// same instance to pick requests up and match them against listings.
class OrderRequestController extends ChangeNotifier {
  final List<OrderRequest> _requests = [];

  List<OrderRequest> get all => List.unmodifiable(_requests);

  int _nextId = 1;

  /// Submits a new "Order Us" request. Exactly one of [propertyRequirement]
  /// / [vehicleRequirement] / [machineryRequirement] / [generalRequirement]
  /// should be provided, matching the category.
  OrderRequest submit({
    required String requesterUserId,
    required String requesterName,
    required String requesterPhone,
    required AssetCategorySlug category,
    PropertyRequirement? propertyRequirement,
    VehicleRequirement? vehicleRequirement,
    MachineryRequirement? machineryRequirement,
    GeneralRequirement? generalRequirement,
  }) {
    final request = OrderRequest(
      id: 'or${_nextId++}',
      submittedAt: DateTime.now(),
      requesterUserId: requesterUserId,
      requesterName: requesterName,
      requesterPhone: requesterPhone,
      category: category,
      propertyRequirement: propertyRequirement,
      vehicleRequirement: vehicleRequirement,
      machineryRequirement: machineryRequirement,
      generalRequirement: generalRequirement,
    );
    _requests.insert(0, request);
    notifyListeners();
    return request;
  }

  List<OrderRequest> byRequester(String requesterUserId) =>
      _requests.where((r) => r.requesterUserId == requesterUserId).toList();

  // ── Admin / matching team ───────────────────────────────────────────
  List<OrderRequest> get pendingReview =>
      _requests.where((r) => r.status == OrderRequestStatus.pendingReview).toList();

  void markMatching(String id) => _updateStatus(id, from: OrderRequestStatus.pendingReview, to: OrderRequestStatus.matching);

  void markMatched(String id, {String? note}) {
    final r = _find(id);
    if (r == null) return;
    r.status = OrderRequestStatus.matched;
    if (note != null) r.adminNote = note;
    notifyListeners();
  }

  void close(String id, {String? note}) {
    final r = _find(id);
    if (r == null) return;
    r.status = OrderRequestStatus.closed;
    if (note != null) r.adminNote = note;
    notifyListeners();
  }

  void _updateStatus(String id, {required OrderRequestStatus from, required OrderRequestStatus to}) {
    final r = _find(id);
    if (r == null || r.status != from) return;
    r.status = to;
    notifyListeners();
  }

  OrderRequest? _find(String id) {
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
