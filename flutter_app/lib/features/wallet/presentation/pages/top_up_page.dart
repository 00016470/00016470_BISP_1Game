import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/constants.dart';
import '../bloc/wallet_bloc.dart';
import '../bloc/wallet_event.dart';
import '../bloc/wallet_state.dart';
import '../../../../injection.dart';

class TopUpPage extends StatefulWidget {
  const TopUpPage({super.key});

  @override
  State<TopUpPage> createState() => _TopUpPageState();
}

class _TopUpPageState extends State<TopUpPage> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<WalletBloc>()..add(const WalletLoadRequested()),
      child: BlocListener<WalletBloc, WalletState>(
        listener: (context, state) {
          if (state is WalletTopUpSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Topped up ${state.amount.toStringAsFixed(0)} UZS! (${state.referenceCode})',
                  style: const TextStyle(color: Colors.black),
                ),
                backgroundColor: const Color(0xFF76FF03),
              ),
            );
            context.pop();
          } else if (state is WalletError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        child: Scaffold(
          backgroundColor: const Color(AppConstants.backgroundPrimary),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'TOP UP WALLET',
              style: GoogleFonts.orbitron(
                color: const Color(AppConstants.primaryAccent),
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            centerTitle: true,
          ),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Text(
                    'Enter Amount (UZS)',
                    style: GoogleFonts.orbitron(
                      color: Colors.white54,
                      fontSize: 12,
                      letterSpacing: 1.5,
                    ),
                  ).animate().fadeIn(),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: '0',
                      hintStyle: GoogleFonts.orbitron(
                        color: Colors.white24,
                        fontSize: 28,
                      ),
                      suffix: Text(
                        'UZS',
                        style: GoogleFonts.orbitron(
                          color: const Color(AppConstants.primaryAccent),
                          fontSize: 16,
                        ),
                      ),
                      filled: true,
                      fillColor: const Color(AppConstants.backgroundSecondary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                            color: Color(AppConstants.primaryAccent)),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter an amount';
                      final amount = double.tryParse(v);
                      if (amount == null || amount <= 0) return 'Enter a valid amount';
                      if (amount > 10000000) return 'Maximum 10,000,000 UZS';
                      return null;
                    },
                  ).animate().fadeIn(delay: 100.ms),
                  const SizedBox(height: 32),
                  BlocBuilder<WalletBloc, WalletState>(
                    builder: (context, state) {
                      final loading = state is WalletTopUpInProgress;
                      return SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: loading
                              ? null
                              : () {
                                  if (_formKey.currentState!.validate()) {
                                    context.read<WalletBloc>().add(
                                          WalletTopUpRequested(
                                            double.parse(_controller.text),
                                          ),
                                        );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(AppConstants.primaryAccent),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: loading
                              ? const CircularProgressIndicator(color: Colors.black)
                              : Text(
                                  'TOP UP NOW',
                                  style: GoogleFonts.orbitron(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    letterSpacing: 2,
                                  ),
                                ),
                        ),
                      );
                    },
                  ).animate().fadeIn(delay: 200.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
