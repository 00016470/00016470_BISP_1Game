import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/constants.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/neon_button.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated || state is AuthGuest) {
          context.go('/home');
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message,
                  style: GoogleFonts.inter(color: Colors.white)),
              backgroundColor: const Color(AppConstants.errorColor),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(AppConstants.backgroundPrimary),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                _buildHeader(),
                const SizedBox(height: 40),
                _buildForm(),
                const SizedBox(height: 24),
                _buildActions(),
                const SizedBox(height: 32),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.videogame_asset_rounded,
                size: 48, color: Color(AppConstants.primaryAccent))
            .animate()
            .fadeIn(duration: 500.ms)
            .scale(begin: const Offset(0.5, 0.5)),
        const SizedBox(height: 16),
        Text(
          'WELCOME BACK',
          style: GoogleFonts.orbitron(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: const Color(AppConstants.primaryAccent),
            letterSpacing: 2,
          ),
        ).animate(delay: 100.ms).fadeIn().slideX(begin: -0.1),
        Text(
          'Sign in to your account',
          style: GoogleFonts.inter(fontSize: 14, color: Colors.white38),
        ).animate(delay: 200.ms).fadeIn(),
      ],
    );
  }

  Widget _buildForm() {
    return GlassCard(
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: GoogleFonts.inter(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email is required';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordCtrl,
              obscureText: _obscurePassword,
              style: GoogleFonts.inter(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Colors.white54,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required';
                if (v.length < 6) return 'Minimum 6 characters';
                return null;
              },
            ),
          ],
        ),
      ),
    ).animate(delay: 200.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildActions() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        return SizedBox(
          width: double.infinity,
          child: NeonButton(
            label: 'LOGIN',
            isLoading: isLoading,
            onPressed: isLoading ? null : _onLogin,
            icon: Icons.login,
          ),
        );
      },
    ).animate(delay: 300.ms).fadeIn();
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Don't have an account?",
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white54)),
            TextButton(
              onPressed: () => context.push('/register'),
              child: Text(
                'Register',
                style: GoogleFonts.orbitron(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(AppConstants.primaryAccent),
                ),
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: () =>
              context.read<AuthBloc>().add(AuthGuestModeEntered()),
          child: Text(
            'Continue as Guest',
            style: GoogleFonts.inter(fontSize: 13, color: Colors.white38),
          ),
        ),
      ],
    ).animate(delay: 400.ms).fadeIn();
  }

  void _onLogin() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            AuthLoginRequested(
              email: _emailCtrl.text.trim(),
              password: _passwordCtrl.text,
            ),
          );
    }
  }
}
