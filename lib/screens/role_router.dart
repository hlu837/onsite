import 'package:flutter/material.dart';
import '../models/auth_response.dart';
import '../models/user_role.dart';
import 'admin_home_screen.dart';
import 'agent_home_screen.dart';
import 'coming_soon_screen.dart';
import 'customer_home_screen.dart';

/// The one place that knows "this role → this workspace". Both the Login
/// page's smart router and the Sign-Up flow's post-registration redirect
/// call this, so there's a single source of truth for where each of the
/// four (five, counting Admin) roles land:
///
///   Visitor      → Standard Marketplace Feed   (CustomerHomeScreen)
///   Affiliater   → Gamified Task & Token Dashboard (placeholder for now)
///   Agent/Broker → Listing Manager & Client Tracker (AgentHomeScreen)
///   Investor     → Portfolio & Investment Portal (placeholder for now)
///   Admin        → Approvals & Ops Console      (AdminHomeScreen)
Widget dashboardForRole(UserRole role, AppUser user) {
  return switch (role) {
    UserRole.user => CustomerHomeScreen(user: user),
    UserRole.agent => AgentHomeScreen(user: user),
    UserRole.admin => AdminHomeScreen(user: user),
    UserRole.affiliater => ComingSoonScreen(
        role: UserRole.affiliater,
        userName: user.fullName,
        highlights: const [
          'A personal referral link for every listing you share',
          'Tokens credited automatically on clicks and sign-ups',
          'A task board with bonus-token challenges',
          'One-tap upgrade path from tokens to an Agent / Broker license',
        ],
      ),
    UserRole.investor => ComingSoonScreen(
        role: UserRole.investor,
        userName: user.fullName,
        highlights: const [
          'A single dashboard for every asset in your portfolio',
          'Curated, high-yield opportunities before they go public',
          'Live valuation and performance tracking',
          'Direct line to the agent handling each of your assets',
        ],
      ),
  };
}
