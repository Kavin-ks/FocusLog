import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../widgets/section_header.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, child) {
        // If logged in, redirect to app
        if (auth.isLoggedIn) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed('/app');
          });
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        return Scaffold(
          floatingActionButton: FloatingActionButton(
            onPressed: () {},
            mini: true,
            tooltip: 'Toggle theme',
            child: const Icon(Icons.nights_stay),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text('Focuslog', style: Theme.of(context).textTheme.headlineLarge),
                  ),
                  const SizedBox(height: 24),

                  // Hero section (centered constrained card)
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Quiet time tracking for reflection', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 12),
                              Text('A calm, privacy-first way to notice patterns in your days — no scores, no nudges, just gentle context for reflection.', style: Theme.of(context).textTheme.bodyLarge),
                              const SizedBox(height: 20),

                              // Buttons: stacked, full-width style from screenshot
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  onPressed: () => Navigator.of(context).pushNamed('/signup'),
                                  child: const Text('Get started'),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  onPressed: () => Navigator.of(context).pushNamed('/login'),
                                  child: const Text('Sign in'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const SectionHeader(title: 'What it does', showDivider: false),
                  const SizedBox(height: 8),
                  Text('Log time with simple categories, add optional tags for energy and intent, and explore calm, neutral comparisons that help you reflect.', style: Theme.of(context).textTheme.bodyMedium),

                  const SizedBox(height: 16),
                  const SectionHeader(title: 'Why calm & non-judgmental', showDivider: false),
                  const SizedBox(height: 8),
                  Text('No scoring. No reminders. Just clear, private records you can look back on when you want to notice trends.', style: Theme.of(context).textTheme.bodyMedium),

                  const SizedBox(height: 24),
                  Center(
                    child: Text('DESIGNED FOR DEEP WORK', style: Theme.of(context).textTheme.bodySmall?.copyWith(letterSpacing: 1.2, color: Theme.of(context).textTheme.bodySmall?.color?.withAlpha(160))),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
