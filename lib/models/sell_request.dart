import 'asset.dart';
import 'house_property_details.dart';
import 'vehicle_details.dart';
import 'machinery_details.dart';

/// Stages of the "Sell my property" pipeline — separate from [LoopStage]
/// (the tour-request loop). A Visitor submits a property + pays a listing
/// fee, Admin screens it, any online Agent/Broker can claim it and go
/// inspect it in person, then Admin reviews the Agent's inspection report
/// before the property goes live under that Agent's name.
enum SellRequestStatus {
  /// Submitted + paid, waiting for Admin to screen it.
  pendingAdminApproval,

  /// Admin rejected the submission outright — never opened to brokers.
  submissionRejected,

  /// Admin approved it — visible to every Agent/Broker to claim.
  openToBrokers,

  /// An Agent claimed it and is expected to go inspect it in person.
  claimed,

  /// Agent submitted their inspection report — waiting for Admin's final
  /// sign-off before it becomes a real listing.
  reportPendingApproval,

  /// Admin sent the report back — Agent can revise and resubmit.
  reportRejected,

  /// Admin approved the report — now a real, live [Asset] listed under the
  /// claiming Agent's name.
  listed,
}

extension SellRequestStatusX on SellRequestStatus {
  String get label => switch (this) {
        SellRequestStatus.pendingAdminApproval => 'Pending review',
        SellRequestStatus.submissionRejected => 'Rejected',
        SellRequestStatus.openToBrokers => 'Open to brokers',
        SellRequestStatus.claimed => 'Broker assigned',
        SellRequestStatus.reportPendingApproval => 'Report under review',
        SellRequestStatus.reportRejected => 'Report needs changes',
        SellRequestStatus.listed => 'Listed',
      };

  /// Visitor-facing copy — a little more explanatory than the admin/agent
  /// facing [label].
  String get visitorDescription => switch (this) {
        SellRequestStatus.pendingAdminApproval =>
          'We received your submission and the 100 ETB fee. Our team is reviewing it now.',
        SellRequestStatus.submissionRejected => 'This submission wasn\'t approved. See the note below.',
        SellRequestStatus.openToBrokers => 'Approved! Waiting for a broker to pick it up for inspection.',
        SellRequestStatus.claimed => 'A broker has been assigned and will visit to inspect the property.',
        SellRequestStatus.reportPendingApproval => 'The broker submitted their inspection report — pending final approval.',
        SellRequestStatus.reportRejected => 'The inspection report needs changes before it can go live.',
        SellRequestStatus.listed => 'Your property is live on the marketplace!',
      };
}

/// A photo/video attached to an inspection report. In this frontend-only
/// demo there's no real file picker or upload — each entry is just a mock
/// placeholder the Agent "adds" from the report form.
class ReportMediaItem {
  final String id;
  final bool isVideo;
  const ReportMediaItem({required this.id, this.isVideo = false});
}

/// One end-to-end "sell my property" submission.
class SellRequest {
  final String id;
  final DateTime submittedAt;

  // ── Visitor submission ────────────────────────────────────────────────
  final String ownerUserId;
  final String ownerName;
  final String ownerPhone;
  final AssetCategorySlug category;
  final String title;
  final String description;
  final double askingPrice;
  final String city;
  final String addressLine;
  final double feeAmount;
  final bool feePaid;

  /// Populated only when this submission went through the House-specific
  /// wizard (Property Type is house/villa/apartment/condominium). `null`
  /// for submissions made through the generic short form.
  final HousePropertyDetails? houseDetails;

  /// Populated only when this submission went through the Vehicle-specific
  /// wizard (category is Vehicles). `null` for every other submission.
  final VehicleDetails? vehicleDetails;

  /// Populated only when this submission went through the Machinery-specific
  /// wizard (category is Machinery). `null` for every other submission.
  final MachineryDetails? machineryDetails;

  // ── Admin (submission stage) ────────────────────────────────────────────
  String? submissionRejectionReason;

  // ── Agent claim ──────────────────────────────────────────────────────
  String? agentId;
  String? agentName;
  DateTime? claimedAt;

  // ── Agent inspection report ─────────────────────────────────────────────
  List<ReportMediaItem> reportMedia;
  String? reportNotes;
  DateTime? reportSubmittedAt;
  String? reportRejectionReason;

  // ── Final listing ────────────────────────────────────────────────────
  String? listedAssetId;

  SellRequestStatus status;

  SellRequest({
    required this.id,
    required this.submittedAt,
    required this.ownerUserId,
    required this.ownerName,
    required this.ownerPhone,
    required this.category,
    required this.title,
    required this.description,
    required this.askingPrice,
    required this.city,
    required this.addressLine,
    this.feeAmount = 100,
    this.feePaid = true,
    this.houseDetails,
    this.vehicleDetails,
    this.machineryDetails,
    this.status = SellRequestStatus.pendingAdminApproval,
    this.submissionRejectionReason,
    this.agentId,
    this.agentName,
    this.claimedAt,
    List<ReportMediaItem>? reportMedia,
    this.reportNotes,
    this.reportSubmittedAt,
    this.reportRejectionReason,
    this.listedAssetId,
  }) : reportMedia = reportMedia ?? [];
}
