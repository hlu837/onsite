import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/loop_controller.dart';
import 'screens/role_gate_screen.dart';
import 'theme/app_theme.dart';

void main() => runApp(const OnsiteDemoApp());

/// Root of the demo. [LoopController] is provided once here, above the
/// Navigator, so it stays the single shared source of truth no matter which
/// side (Customer / Admin / Agent) is currently pushed on the stack.
class OnsiteDemoApp extends StatelessWidget {
  const OnsiteDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LoopController(),
      child: MaterialApp(
        title: 'Onsite — Verify Any Asset',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const RoleGateScreen(),
      ),
    );
  }
}
