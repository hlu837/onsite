/// "Order Us" — the reverse of Sell/Rent: a Visitor describes what they
/// want to buy/rent instead of listing something themselves. Mirrors the
/// [SellRequest] pattern (submit → land in a queue → get matched) but the
/// payload here is a *requirement*, not a listing.
library;

import 'asset.dart';
import 'machinery_requirement.dart';
import 'vehicle_requirement.dart';

/// Categories that go through the detailed property-buyer questionnaire.
/// Every other category uses [GeneralRequirement] instead.
const kPropertyRequirementCategories = {
  AssetCategorySlug.house,
  AssetCategorySlug.apartments,
  AssetCategorySlug.condominium,
  AssetCategorySlug.building,
  AssetCategorySlug.warehouse,
  AssetCategorySlug.land,
};

/// The Vehicles category goes through its own dedicated buyer/renter
/// questionnaire ([VehicleRequirement]) instead of the generic form.
const kVehicleRequirementCategories = {
  AssetCategorySlug.vehicles,
};

/// The Machinery category goes through its own dedicated buyer/renter
/// questionnaire ([MachineryRequirement]) instead of the generic form.
const kMachineryRequirementCategories = {
  AssetCategorySlug.machinery,
};

enum RequirementPurpose { personalResidence, officeBusiness, investmentRental }

extension RequirementPurposeX on RequirementPurpose {
  String get label => switch (this) {
        RequirementPurpose.personalResidence => 'Personal residence',
        RequirementPurpose.officeBusiness => 'Office / business space',
        RequirementPurpose.investmentRental => 'Investment (rental income)',
      };
}

enum RequirementFinishing { fullyFinished, semiFinishedOffPlan, noPreference }

extension RequirementFinishingX on RequirementFinishing {
  String get label => switch (this) {
        RequirementFinishing.fullyFinished => 'Fully finished — ready to move in',
        RequirementFinishing.semiFinishedOffPlan => 'Semi-finished / off-plan (discounted)',
        RequirementFinishing.noPreference => 'No preference',
      };
}

enum RequirementPaymentMethod { fullCash, bankLoan, installmentRentToOwn }

extension RequirementPaymentMethodX on RequirementPaymentMethod {
  String get label => switch (this) {
        RequirementPaymentMethod.fullCash => 'Full cash',
        RequirementPaymentMethod.bankLoan => 'Bank loan / mortgage',
        RequirementPaymentMethod.installmentRentToOwn => 'Phased / installment (rent-to-own)',
      };
}

enum RequirementUrgency { urgent, browsing }

extension RequirementUrgencyX on RequirementUrgency {
  String get label => switch (this) {
        RequirementUrgency.urgent => 'Urgent — within this week/month',
        RequirementUrgency.browsing => 'Just browsing — deciding over time',
      };
}

enum RequirementDecisionMaker { self, consultingOthers }

extension RequirementDecisionMakerX on RequirementDecisionMaker {
  String get label => switch (this) {
        RequirementDecisionMaker.self => 'I\'ll decide directly',
        RequirementDecisionMaker.consultingOthers => 'Consulting family / other stakeholders',
      };
}

/// The detailed property-buyer questionnaire — one section per step of the
/// checklist: Property Type & Purpose, Location & Accessibility,
/// Specifications & Layout, Budget & Financial Terms, Urgency & Decision.
class PropertyRequirement {
  // ── 1. Property Type & Purpose ──────────────────────────────────────
  AssetCategorySlug propertyType;
  RequirementPurpose purpose;
  RequirementFinishing finishing;

  // ── 2. Location & Accessibility ─────────────────────────────────────
  String preferredAreas; // e.g. "Bole, Saris"
  String accessibilityNotes; // main road / workplace / school proximity

  // ── 3. Specifications & Layout ──────────────────────────────────────
  int minBedrooms;
  int minBathrooms;
  double minAreaSqm;
  double? maxAreaSqm;
  bool needsSpaciousLaundry;
  int parkingCarsNeeded;
  bool needsGuardhouse;
  bool needsSharedAmenities; // relevant for apartments/condos

  // ── 4. Budget & Financial Terms ─────────────────────────────────────
  double budgetMinEtb;
  double budgetMaxEtb;
  RequirementPaymentMethod paymentMethod;
  String? bankLoanDetails; // which bank, approved vs. processing

  // ── 5. Urgency & Decision Making ────────────────────────────────────
  RequirementUrgency urgency;
  RequirementDecisionMaker decisionMaker;

  PropertyRequirement({
    this.propertyType = AssetCategorySlug.house,
    this.purpose = RequirementPurpose.personalResidence,
    this.finishing = RequirementFinishing.fullyFinished,
    this.preferredAreas = '',
    this.accessibilityNotes = '',
    this.minBedrooms = 0,
    this.minBathrooms = 0,
    this.minAreaSqm = 0,
    this.maxAreaSqm,
    this.needsSpaciousLaundry = false,
    this.parkingCarsNeeded = 0,
    this.needsGuardhouse = false,
    this.needsSharedAmenities = false,
    this.budgetMinEtb = 0,
    this.budgetMaxEtb = 0,
    this.paymentMethod = RequirementPaymentMethod.fullCash,
    this.bankLoanDetails,
    this.urgency = RequirementUrgency.browsing,
    this.decisionMaker = RequirementDecisionMaker.self,
  });

  /// Renders every answer into a readable block, same idea as
  /// `HousePropertyDetails.toDescriptionText()` — keeps plain-text-only
  /// screens (Admin queues, etc.) useful without needing bespoke UI.
  String toDescriptionText() {
    final buffer = StringBuffer();
    buffer.writeln('Property Type & Purpose');
    buffer.writeln('• Looking for: ${propertyType.label}');
    buffer.writeln('• Purpose: ${purpose.label}');
    buffer.writeln('• Finishing: ${finishing.label}');
    buffer.writeln();
    buffer.writeln('Location & Accessibility');
    buffer.writeln('• Preferred areas: ${preferredAreas.trim().isNotEmpty ? preferredAreas : 'No preference'}');
    if (accessibilityNotes.trim().isNotEmpty) buffer.writeln('• Accessibility notes: $accessibilityNotes');
    buffer.writeln();
    buffer.writeln('Specifications & Layout');
    buffer.writeln('• Min $minBedrooms bedroom(s), $minBathrooms bathroom(s)');
    buffer.writeln('• Area: ${minAreaSqm.toStringAsFixed(0)} m²${maxAreaSqm != null ? ' – ${maxAreaSqm!.toStringAsFixed(0)} m²' : '+'}');
    final extras = <String>[
      if (needsSpaciousLaundry) 'spacious laundry/utility area',
      if (parkingCarsNeeded > 0) 'parking for $parkingCarsNeeded car(s)',
      if (needsGuardhouse) 'guardhouse',
      if (needsSharedAmenities) 'shared amenities',
    ];
    if (extras.isNotEmpty) buffer.writeln('• Needs: ${extras.join(', ')}');
    buffer.writeln();
    buffer.writeln('Budget & Financial Terms');
    buffer.writeln('• Budget: ETB ${_fmt(budgetMinEtb)} – ETB ${_fmt(budgetMaxEtb)}');
    buffer.writeln('• Payment method: ${paymentMethod.label}'
        '${paymentMethod == RequirementPaymentMethod.bankLoan && bankLoanDetails?.trim().isNotEmpty == true ? ' — $bankLoanDetails' : ''}');
    buffer.writeln();
    buffer.writeln('Urgency & Decision Making');
    buffer.writeln('• ${urgency.label}');
    buffer.writeln('• ${decisionMaker.label}');
    return buffer.toString().trim();
  }

  static String _fmt(double v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final posFromEnd = s.length - i;
      buf.write(s[i]);
      if (posFromEnd > 1 && posFromEnd % 3 == 1) buf.write(',');
    }
    return buf.toString();
  }
}

/// Lighter requirement form for categories without a dedicated wizard
/// (construction materials, others) — same spirit, fewer fields.
class GeneralRequirement {
  String description; // free text: exactly what they're looking for
  double budgetMinEtb;
  double budgetMaxEtb;
  String preferredLocation;
  RequirementPaymentMethod paymentMethod;
  RequirementUrgency urgency;

  GeneralRequirement({
    this.description = '',
    this.budgetMinEtb = 0,
    this.budgetMaxEtb = 0,
    this.preferredLocation = '',
    this.paymentMethod = RequirementPaymentMethod.fullCash,
    this.urgency = RequirementUrgency.browsing,
  });

  String toDescriptionText() {
    final buffer = StringBuffer();
    buffer.writeln('What they\'re looking for');
    buffer.writeln('• $description');
    buffer.writeln();
    buffer.writeln('Budget & Location');
    buffer.writeln('• Budget: ETB ${PropertyRequirement._fmt(budgetMinEtb)} – ETB ${PropertyRequirement._fmt(budgetMaxEtb)}');
    if (preferredLocation.trim().isNotEmpty) buffer.writeln('• Preferred location: $preferredLocation');
    buffer.writeln('• Payment method: ${paymentMethod.label}');
    buffer.writeln();
    buffer.writeln('Urgency');
    buffer.writeln('• ${urgency.label}');
    return buffer.toString().trim();
  }
}

/// Stages of an "Order Us" request — lighter than [SellRequest]'s pipeline
/// since there's no listing fee or on-site inspection: Admin/matching team
/// just cross-references it against the existing listings.
enum OrderRequestStatus { pendingReview, matching, matched, closed }

extension OrderRequestStatusX on OrderRequestStatus {
  String get label => switch (this) {
        OrderRequestStatus.pendingReview => 'Submitted',
        OrderRequestStatus.matching => 'Being matched',
        OrderRequestStatus.matched => 'Matches found',
        OrderRequestStatus.closed => 'Closed',
      };

  String get visitorDescription => switch (this) {
        OrderRequestStatus.pendingReview => 'We received your request and will start matching it against available listings.',
        OrderRequestStatus.matching => 'Our team is cross-referencing your requirements against current listings.',
        OrderRequestStatus.matched => 'We found listings that match — an agent will reach out shortly.',
        OrderRequestStatus.closed => 'This request has been closed.',
      };
}

/// One end-to-end "Order Us" submission — exactly one of [propertyRequirement]
/// (house/apartments/condominium/building/warehouse/land), [vehicleRequirement]
/// (vehicles), [machineryRequirement] (machinery), or [generalRequirement]
/// (construction materials/others) is populated, matching the category.
class OrderRequest {
  final String id;
  final DateTime submittedAt;
  final String requesterUserId;
  final String requesterName;
  final String requesterPhone;
  final AssetCategorySlug category;

  final PropertyRequirement? propertyRequirement;
  final VehicleRequirement? vehicleRequirement;
  final MachineryRequirement? machineryRequirement;
  final GeneralRequirement? generalRequirement;

  OrderRequestStatus status;
  String? adminNote;

  OrderRequest({
    required this.id,
    required this.submittedAt,
    required this.requesterUserId,
    required this.requesterName,
    required this.requesterPhone,
    required this.category,
    this.propertyRequirement,
    this.vehicleRequirement,
    this.machineryRequirement,
    this.generalRequirement,
    this.status = OrderRequestStatus.pendingReview,
    this.adminNote,
  });

  String get title => 'Looking for ${category.label}';

  String get descriptionText =>
      propertyRequirement?.toDescriptionText() ??
      vehicleRequirement?.toDescriptionText() ??
      machineryRequirement?.toDescriptionText() ??
      generalRequirement?.toDescriptionText() ??
      '';

  /// Budget line for compact display (list rows, cards), regardless of
  /// which requirement variant this request holds.
  String get budgetSummary {
    if (vehicleRequirement != null) {
      return 'Up to ETB ${vehicleRequirement!.maxBudgetMillionEtb.toStringAsFixed(2)}M';
    }
    if (machineryRequirement != null) {
      return 'Up to ETB ${PropertyRequirement._fmt(machineryRequirement!.maxBudgetEtb)}';
    }
    final min = propertyRequirement?.budgetMinEtb ?? generalRequirement?.budgetMinEtb ?? 0;
    final max = propertyRequirement?.budgetMaxEtb ?? generalRequirement?.budgetMaxEtb ?? 0;
    return 'ETB ${PropertyRequirement._fmt(min)} – ${PropertyRequirement._fmt(max)}';
  }
}
