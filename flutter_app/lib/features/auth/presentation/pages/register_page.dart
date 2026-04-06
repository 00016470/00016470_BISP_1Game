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

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
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
        appBar: AppBar(
          title: const Text('CREATE ACCOUNT'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => context.pop(),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildHeader(),
                const SizedBox(height: 32),
                _buildForm(),
                const SizedBox(height: 24),
                _buildActions(),
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
        Text(
          'JOIN THE CLUB',
          style: GoogleFonts.orbitron(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: const Color(AppConstants.primaryAccent),
            letterSpacing: 2,
          ),
        ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
        Text(
          'Create your gaming account',
          style: GoogleFonts.inter(fontSize: 13, color: Colors.white38),
        ).animate(delay: 100.ms).fadeIn(),
      ],
    );
  }

  Widget _buildForm() {
    return GlassCard(
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildField(
              controller: _usernameCtrl,
              label: 'Username',
              icon: Icons.person_outline,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Username required';
                if (v.length < 3) return 'Minimum 3 characters';
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildField(
              controller: _emailCtrl,
              label: 'Email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email required';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildField(
              controller: _phoneCtrl,
              label: 'Phone',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Phone required';
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
                if (v == null || v.isEmpty) return 'Password required';
                if (v.length < 6) return 'Minimum 6 characters';
                return null;
              },
            ),
          ],
        ),
      ),
    ).animate(delay: 150.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      validator: validator,
    );
  }

  Widget _buildActions() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: NeonButton(
                label: 'CREATE ACCOUNT',
                isLoading: isLoading,
                onPressed: isLoading ? null : _onRegister,
                icon: Icons.person_add_outlined,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Already have an account?',
                    style:
                        GoogleFonts.inter(fontSize: 13, color: Colors.white54)),
                TextButton(
                  onPressed: () => context.pop(),
                  child: Text(
                    'Login',
                    style: GoogleFonts.orbitron(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(AppConstants.primaryAccent),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    ).animate(delay: 300.ms).fadeIn();
  }

  void _onRegister() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            AuthRegisterRequested(
              username: _usernameCtrl.text.trim(),
              email: _emailCtrl.text.trim(),
              password: _passwordCtrl.text,
              phone: _phoneCtrl.text.trim(),
            ),
          );
    }
  }
}
