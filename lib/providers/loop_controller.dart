import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/asset.dart';

/// Stages of the core transactional loop. Shared, single source of truth —
/// the Customer, Admin, and Agent sides are separate full-screen flows in
/// this app, but they all watch the same [LoopController] instance, so
/// actions taken on one side are reflected live on the others (exactly like
/// they would be via a realtime backend, minus the backend).
enum LoopStage {
  idle,
  searching,
  pendingApproval,
  dispatched,
  accepted,
  declined,
  expired,
}

/// Single source of truth for the demo loop. Provided once at the app root
/// so every side (Customer / Admin / Agent) reads and mutates the same
/// state — swap the internals for real sockets/Postgres streams later.
class LoopController extends ChangeNotifier {
  static const dispatchWindowSeconds = 30;

  LoopStage stage = LoopStage.idle;
  bool agentOnline = true;
  int secondsLeft = dispatchWindowSeconds;
  Asset? requestedAsset;
  String agentName = 'Fadi Mohammed';

  Timer? _searchTimer;
  Timer? _countdown;

  bool get isRinging => stage == LoopStage.dispatched && agentOnline;

  // ── Customer ────────────────────────────────────────────────────────────
  void customerRequest(Asset asset) {
    if (stage != LoopStage.idle) return;
    requestedAsset = asset;
    stage = LoopStage.searching;
    notifyListeners();
    _searchTimer = Timer(const Duration(milliseconds: 2600), () {
      stage = LoopStage.pendingApproval;
      notifyListeners();
    });
  }

  // ── Admin ───────────────────────────────────────────────────────────────
  void adminApprove() {
    if (stage != LoopStage.pendingApproval &&
        stage != LoopStage.declined &&
        stage != LoopStage.expired) {
      return;
    }
    stage = LoopStage.dispatched;
    secondsLeft = dispatchWindowSeconds;
    _countdown?.cancel();
    _countdown = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!agentOnline) return; // countdown pauses while agent is offline
      if (secondsLeft <= 1) {
        secondsLeft = 0;
        stage = LoopStage.expired;
        t.cancel();
      } else {
        secondsLeft--;
      }
      notifyListeners();
    });
    notifyListeners();
  }

  // ── Agent ───────────────────────────────────────────────────────────────
  void agentAccept() {
    if (stage != LoopStage.dispatched) return;
    _countdown?.cancel();
    stage = LoopStage.accepted;
    notifyListeners();
  }

  void agentDecline() {
    if (stage != LoopStage.dispatched) return;
    _countdown?.cancel();
    stage = LoopStage.declined;
    notifyListeners();
  }

  void toggleOnline(bool value) {
    agentOnline = value;
    notifyListeners();
  }

  void reset() {
    _searchTimer?.cancel();
    _countdown?.cancel();
    stage = LoopStage.idle;
    agentOnline = true;
    secondsLeft = dispatchWindowSeconds;
    requestedAsset = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _countdown?.cancel();
    super.dispose();
  }
}
