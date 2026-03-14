import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic)),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl() async {
    final Uri url = Uri.parse('https://supplychainhub.com/');
    if (!await launchUrl(url)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch website')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          // Background accents (Subtle geometric shapes)
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.03),
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Top Nav
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Row(
                    children: [
                      SvgPicture.asset('assets/images/sch_logo.svg', height: 40),
                      const Spacer(),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: Text(
                          'LOG IN',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: colorScheme.onSurface,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 800),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Text(
                                    'LIBRARY MANAGEMENT',
                                    style: TextStyle(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 11,
                                      letterSpacing: 2.0,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 32),
                                Text(
                                  'Your Intelligent\nLibrary.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.outfit(
                                    fontSize: MediaQuery.of(context).size.width > 600 ? 56 : 36,
                                    fontWeight: FontWeight.w900,
                                    height: 1.05,
                                    color: colorScheme.onSurface,
                                    letterSpacing: -1.0,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 600),
                                  child: Text(
                                    'SCH BookChain is the library management system for our company, unifying book discovery, inventory tracking, and employee collaboration.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: colorScheme.onSurface.withOpacity(0.6),
                                      height: 1.6,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 56),
                                // Action Buttons
                                Wrap(
                                  spacing: 24,
                                  runSpacing: 16,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () => context.go('/register'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: colorScheme.onSurface,
                                        foregroundColor: colorScheme.surface,
                                        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 28),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        elevation: 0,
                                      ),
                                      child: const Text(
                                        'GET STARTED',
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                                      ),
                                    ),
                                    OutlinedButton(
                                      onPressed: _launchUrl,
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
                                        side: BorderSide(color: colorScheme.onSurface.withOpacity(0.1), width: 2),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      child: Text(
                                        'LEARN MORE',
                                        style: TextStyle(
                                          fontSize: 14, 
                                          fontWeight: FontWeight.w900, 
                                          letterSpacing: 1.5,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 80),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
              ],
            ),
          ),
        ],
      ),
    );
  }
}
