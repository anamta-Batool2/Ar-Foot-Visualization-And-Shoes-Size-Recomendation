import 'package:flutter/material.dart';
import 'login_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,

            children: [
              // Main Content
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 30),

                  // Logo + StepFit
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/foot-icon.png',
                        width: 52,
                        height: 52,
                        fit: BoxFit.contain,
                      ),

                      Transform.translate(
                        offset: const Offset(-8, 0),
                        child: const Text(
                          'StepFit',
                          style: TextStyle(
                            color: Color(0xFF00695C),
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Heading
                  const Text(
                    'Who are you?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF1B4332),
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Subtitle
                  const Text(
                    'Choose your journey to get started.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Customer Card
                  _RoleCard(
  icon: Icons.person_outline,
  title: "I'm a Customer",
  subtitle: 'Scan my foot & find shoes',
  onTap: () {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1), // neeche se upar aayegi
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  },
),
                  const SizedBox(height: 14),

                  // Admin Card
                  _RoleCard(
                    icon: Icons.admin_panel_settings_outlined,
                    title: "I'm an Admin",
                    subtitle: 'Manage shoes & view scans',
                    onTap: () {
                      // Navigator.pushNamed(context, '/admin');
                    },
                  ),

                  const SizedBox(height: 24),

                  // Bottom Banner
                  Container(
                    width: double.infinity,
                    height: 160,

                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),

                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFB2DFDB),
                          Color(0xFF80CBC4),
                        ],
                      ),
                    ),

                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),

                      child: Stack(
                        alignment: Alignment.center,

                        children: [
                          Container(
                            margin: const EdgeInsets.all(12),

                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),

                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),

                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),

                              child: Opacity(
                                opacity: 0.7,

                                child: Image.asset(
                                  'assets/images/shoe.png',
                                  width: 280,
                                  height: 136,
                                  fit: BoxFit.cover,

                                  errorBuilder: (context, error, stackTrace) {
                                    return const SizedBox(
                                      height: 136,

                                      child: Icon(
                                        Icons.directions_walk,
                                        size: 100,
                                        color: Color(0xFF00695C),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),

                          const Text(
                            '"Precision fit for every\nmovement."',
                            textAlign: TextAlign.center,

                            style: TextStyle(
                              color: Color(0xFF00695C),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,

                              shadows: [
                                Shadow(
                                  color: Colors.white54,
                                  blurRadius: 6,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Terms & Conditions
              Padding(
                padding: const EdgeInsets.only(bottom: 40),

                child: RichText(
                  textAlign: TextAlign.center,

                  text: const TextSpan(
                    text: 'By continuing, you agree to our ',

                    style: TextStyle(
                      color: Colors.black45,
                      fontSize: 13,
                    ),

                    children: [
                      TextSpan(
                        text: 'Terms of Service',

                        style: TextStyle(
                          color: Color(0xFF00695C),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),

          border: Border.all(
            color: const Color(0xFFB2DFDB),
            width: 1.5,
          ),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),

        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,

              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
              ),

              child: Icon(
                icon,
                color: const Color(0xFF00695C),
                size: 24,
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    title,

                    style: const TextStyle(
                      color: Color(0xFF1B4332),
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    subtitle,

                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right,
              color: Colors.black38,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}