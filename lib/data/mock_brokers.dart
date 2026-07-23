import 'package:flutter/material.dart';
import '../models/asset.dart';

/// Mirrors the platform's membership tiers (see `landing_content.dart`
/// `kTiers`) as they apply to a broker's posting rights.
///
/// Business rule (mock, matches membership plan copy):
///  - Diamond / Gold  -> can post listings in ANY category.
///  - Silver / Bronze -> can only post listings in ONE category
///    (their `lockedCategory`), e.g. a Silver broker who only does
///    vehicles can't also post apartments.
enum BrokerTier { diamond, gold, silver, bronze }

extension BrokerTierX on BrokerTier {
  String get label {
    switch (this) {
      case BrokerTier.diamond:
        return 'Diamond';
      case BrokerTier.gold:
        return 'Gold';
      case BrokerTier.silver:
        return 'Silver';
      case BrokerTier.bronze:
        return 'Bronze';
    }
  }

  /// Whether this tier is allowed to post across every category, or is
  /// restricted to a single locked category.
  bool get canPostAnyCategory => this == BrokerTier.diamond || this == BrokerTier.gold;

  IconData get icon {
    switch (this) {
      case BrokerTier.diamond:
        return Icons.diamond;
      case BrokerTier.gold:
        return Icons.emoji_events;
      case BrokerTier.silver:
        return Icons.military_tech;
      case BrokerTier.bronze:
        return Icons.shield_outlined;
    }
  }

  Color get color {
    switch (this) {
      case BrokerTier.diamond:
        return const Color(0xFF7FD8E8);
      case BrokerTier.gold:
        return const Color(0xFFE8B23A);
      case BrokerTier.silver:
        return const Color(0xFFB8BEC7);
      case BrokerTier.bronze:
        return const Color(0xFFB0763F);
    }
  }

  String get description {
    switch (this) {
      case BrokerTier.diamond:
        return 'Top priority leads and full posting rights across every listing category.';
      case BrokerTier.gold:
        return 'Premium visibility and full posting rights across every listing category.';
      case BrokerTier.silver:
        return 'Standard visibility. Can only post listings in one category.';
      case BrokerTier.bronze:
        return 'Overflow / starter tier. Can only post listings in one category.';
    }
  }
}

/// Hard-coded stand-in for a real broker/agent directory — used to power
/// the "Find brokers" list on category detail pages.
///
/// TODO: replace with a real `AgentService.fetchBrokers(category)` call once
/// the backend exposes a broker directory endpoint.
class Broker {
  final String id;
  final String name;
  final String company;
  final String city;
  final String? addressLine;
  final String? phone;
  final String? bio;
  final double rating;
  final List<AssetCategorySlug> specialties;
  final BrokerTier tier;

  /// Only meaningful when `tier.canPostAnyCategory` is false — the single
  /// category this broker is allowed to post listings in.
  final AssetCategorySlug? lockedCategory;
  final double latitude;
  final double longitude;

  const Broker({
    required this.id,
    required this.name,
    required this.company,
    required this.city,
    required this.rating,
    required this.specialties,
    required this.tier,
    required this.latitude,
    required this.longitude,
    this.addressLine,
    this.phone,
    this.bio,
    this.lockedCategory,
  });

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  /// Categories this broker is actually allowed to post listings in right
  /// now, given their membership tier.
  List<AssetCategorySlug> get postableCategories {
    if (tier.canPostAnyCategory) return specialties;
    return [lockedCategory ?? specialties.first];
  }
}

const kMockBrokers = <Broker>[
  Broker(
    id: 'b1',
    name: 'Selam Tesfaye',
    company: 'Selam Auto Brokers',
    city: 'Addis Ababa',
    addressLine: 'Mexico Square, Global Insurance Bldg, 4th Fl',
    phone: '+251 91 234 5678',
    bio: 'Vehicle specialist with 8 years sourcing sedans and SUVs across Addis Ababa dealer networks.',
    rating: 4.8,
    specialties: [AssetCategorySlug.vehicles],
    tier: BrokerTier.gold,
    latitude: 9.0192,
    longitude: 38.7525,
  ),
  Broker(
    id: 'b2',
    name: 'Dawit Alemu',
    company: 'DA Motors & Machinery',
    city: 'Addis Ababa',
    addressLine: 'CMC Road, near Century Mall',
    phone: '+251 91 345 6789',
    bio: 'Handles both light vehicles and heavy machinery for contractors and fleet buyers.',
    rating: 4.6,
    specialties: [AssetCategorySlug.vehicles, AssetCategorySlug.machinery],
    tier: BrokerTier.gold,
    latitude: 9.0107,
    longitude: 38.7613,
  ),
  Broker(
    id: 'b3',
    name: 'Hana Girma',
    company: 'Hana Homes',
    city: 'Addis Ababa',
    addressLine: 'Bole Medhanialem, Friendship Bldg',
    phone: '+251 91 456 7890',
    bio: 'Apartment-focused agent working the Bole and Kazanchis corridors.',
    rating: 4.9,
    specialties: [AssetCategorySlug.apartments, AssetCategorySlug.condominium],
    tier: BrokerTier.silver,
    lockedCategory: AssetCategorySlug.apartments,
    latitude: 9.0084,
    longitude: 38.7645,
  ),
  Broker(
    id: 'b4',
    name: 'Bereket Fikru',
    company: 'BF Real Estate',
    city: 'Addis Ababa',
    addressLine: 'Bole Atlas, near Atlas Hotel',
    phone: '+251 91 567 8901',
    bio: 'Full-service real estate broker covering houses, buildings and land across the city.',
    rating: 4.5,
    specialties: [AssetCategorySlug.house, AssetCategorySlug.building, AssetCategorySlug.land],
    tier: BrokerTier.diamond,
    latitude: 9.0250,
    longitude: 38.7469,
  ),
  Broker(
    id: 'b5',
    name: 'Meron Yohannes',
    company: 'Meron Property Group',
    city: 'Bahir Dar',
    addressLine: 'Tana Riverside Rd',
    phone: '+251 91 678 9012',
    bio: 'Land and residential plots around Bahir Dar and the Tana lakeshore.',
    rating: 4.7,
    specialties: [AssetCategorySlug.house, AssetCategorySlug.land],
    tier: BrokerTier.bronze,
    lockedCategory: AssetCategorySlug.land,
    latitude: 11.5936,
    longitude: 37.3908,
  ),
  Broker(
    id: 'b6',
    name: 'Yonas Kebede',
    company: 'YK Industrial Equipment',
    city: 'Addis Ababa',
    addressLine: 'Bole Lemi Industrial Park, Gate 2',
    phone: '+251 91 789 0123',
    bio: 'Heavy machinery and construction equipment sourcing for industrial clients.',
    rating: 4.4,
    specialties: [AssetCategorySlug.machinery, AssetCategorySlug.constructionMaterials],
    tier: BrokerTier.gold,
    latitude: 8.9779,
    longitude: 38.7967,
  ),
  Broker(
    id: 'b7',
    name: 'Ruth Assefa',
    company: 'Ruth Logistics Space',
    city: 'Addis Ababa',
    addressLine: 'Bole Lemi Industrial Park, Warehouse Row',
    phone: '+251 91 890 1234',
    bio: 'Warehouse and storage space broker for logistics and e-commerce tenants.',
    rating: 4.6,
    specialties: [AssetCategorySlug.warehouse, AssetCategorySlug.building],
    tier: BrokerTier.silver,
    lockedCategory: AssetCategorySlug.warehouse,
    latitude: 8.9612,
    longitude: 38.8021,
  ),
  Broker(
    id: 'b8',
    name: 'Kaleb Mulugeta',
    company: 'Kaleb Sourcing & Supply',
    city: 'Addis Ababa',
    addressLine: 'Akaki Steel Yard, Kality',
    phone: '+251 91 901 2345',
    bio: 'Bulk construction material sourcing — steel, cement, aggregates.',
    rating: 4.3,
    specialties: [AssetCategorySlug.constructionMaterials, AssetCategorySlug.others],
    tier: BrokerTier.bronze,
    lockedCategory: AssetCategorySlug.constructionMaterials,
    latitude: 9.0333,
    longitude: 38.7000,
  ),
  Broker(
    id: 'b9',
    name: 'Tigist Wolde',
    company: 'Tigist General Brokerage',
    city: 'Hawassa',
    addressLine: 'Lake Hawassa Rd, near Amora Gedel',
    phone: '+251 92 012 3456',
    bio: 'General brokerage covering land deals around Hawassa.',
    rating: 4.5,
    specialties: [AssetCategorySlug.others, AssetCategorySlug.land],
    tier: BrokerTier.silver,
    lockedCategory: AssetCategorySlug.land,
    latitude: 7.0504,
    longitude: 38.4955,
  ),
];

List<Broker> brokersFor(AssetCategorySlug category) {
  final matches = kMockBrokers.where((b) => b.specialties.contains(category)).toList();
  return matches.isEmpty ? kMockBrokers : matches;
}

Broker? brokerById(String id) {
  for (final b in kMockBrokers) {
    if (b.id == id) return b;
  }
  return null;
}
