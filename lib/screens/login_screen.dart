import 'package:flutter/material.dart';
import '../services/mock_auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';
import '../widgets/app_buttons.dart';
import 'role_router.dart';
import 'role_select_screen.dart';

/// The standard, single login page — plain email + password, no role
/// picker in sight. All the role logic happens after "Login" is pressed:
/// authenticate, look up the account's saved role, then redirect straight
/// into that role's workspace. This is the smart router described in the
/// spec — Visitor → Marketplace Feed, Affiliater → Token Dashboard,
/// Agent/Broker → Listing Manager, Investor → Portfolio Portal.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _authService = MockAuthService();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    // 1. Authenticate.
    final user = await _authService.login(email: _emailCtrl.text.trim());

    if (!mounted) return;
    setState(() => _isLoading = false);

    // 2. Smart router — the account's saved role decides the destination.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => dashboardForRole(user.role, user)),
      (route) => false,
    );
  }

  void _fillDemo(String email) {
    _emailCtrl.text = email;
    _passwordCtrl.text = 'demopass';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.cloud,
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome back', style: textTheme.displayLarge?.copyWith(fontSize: 28)),
                const SizedBox(height: 6),
                Text(
                  "We'll take you straight to your workspace.",
                  style: textTheme.bodyLarge?.copyWith(color: AppColors.slate),
                ),

                const SizedBox(height: AppSpacing.xl),

                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email', hintText: 'you@example.com'),
                  validator: Validators.email,
                ),
                const SizedBox(height: AppSpacing.md),

                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) => Validators.notEmpty(v, label: 'Password'),
                ),

                const SizedBox(height: AppSpacing.lg),

                PrimaryButton(label: 'Log In', isLoading: _isLoading, onPressed: _submit),

                const SizedBox(height: AppSpacing.lg),

                Center(
                  child: GestureDetector(
                    onTap: _isLoading
                        ? null
                        : () => Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => const RoleSelectScreen()),
                            ),
                    child: RichText(
                      text: TextSpan(
                        style: textTheme.bodyMedium,
                        children: const [
                          TextSpan(text: "Don't have an account?  "),
                          TextSpan(text: 'Choose your path', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),

                _DemoRouterPanel(onPick: _fillDemo),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// For client demos only — a visible cheat-sheet of seeded accounts so
/// whoever's watching can log in as each role and see the smart router
/// land them somewhere different every time.
class _DemoRouterPanel extends StatelessWidget {
  const _DemoRouterPanel({required this.onPick});

  final ValueChanged<String> onPick;

  static const _accounts = [
    ('visitor@onsite.demo', 'Visitor', Icons.explore_rounded),
    ('affiliater@onsite.demo', 'Affiliater', Icons.share_rounded),
    ('agent@onsite.demo', 'Agent / Broker', Icons.badge_rounded),
    ('investor@onsite.demo', 'Investor', Icons.trending_up_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Demo: try the smart router', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
          const SizedBox(height: 4),
          const Text(
            'Same login form, four different destinations. Tap one to fill it in, then Log In.',
            style: TextStyle(fontSize: 12, color: AppColors.slate, height: 1.4),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (email, label, icon) in _accounts)
                InkWell(
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  onTap: () => onPick(email),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.cloud,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 14, color: AppColors.ink),
                        const SizedBox(width: 6),
                        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink)),
                      ],
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
