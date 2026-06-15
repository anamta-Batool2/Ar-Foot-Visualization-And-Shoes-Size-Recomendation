import 'package:flutter/material.dart';
import 'scan_screen.dart';
import 'virtual_tryon_screen.dart';

class CustomerDashboardScreen extends StatelessWidget {
  const CustomerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // ── Top Bar ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFB2DFDB),
                          borderRadius: BorderRadius.circular(21),
                        ),
                        child: const Icon(Icons.person,
                            color: Color(0xFF00695C), size: 24),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Hello Ahad Khan',
                        style: TextStyle(
                          color: Color(0xFF1B4332),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFB2DFDB), width: 1.5),
                    ),
                    child: const Icon(Icons.notifications_outlined,
                        color: Color(0xFF00695C), size: 20),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Hero Banner ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B4332),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ready to find\nyour perfect\nfit?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ScanScreen()),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00695C),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Row(
                              children: [
                                Text('Start Scan',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600)),
                                SizedBox(width: 6),
                                Icon(Icons.qr_code_scanner,
                                    color: Colors.white, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00695C).withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 82,
                            height: 82,
                            decoration: BoxDecoration(
                              color: const Color(0xFF00695C).withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Image.asset(
                            'assets/images/foot-icon.png',
                            width: 64,
                            height: 64,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.directions_walk,
                                color: Color(0xFFB2DFDB),
                                size: 52),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Virtual Try-On Banner ──────────────────────────────
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const VirtualTryOnScreen()),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFB2DFDB), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF0FF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: Text('👟', style: TextStyle(fontSize: 26)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Virtual Try-On',
                                style: TextStyle(
                                    color: Color(0xFF1B4332),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800)),
                            SizedBox(height: 4),
                            Text(
                              'See how shoes look on your actual foot before buying',
                              style: TextStyle(
                                  color: Color(0xFF90A4AA),
                                  fontSize: 11,
                                  height: 1.4),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          color: Color(0xFFB2DFDB), size: 22),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── 2×2 Grid ──
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.3,
                children: [
                  _GridCard(
                    icon: Icons.view_in_ar_outlined,
                    label: '3D Scan',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const ScanScreen())),
                  ),
                  _GridCard(
                    icon: Icons.history_outlined,
                    label: 'Size History',
                    onTap: () {},
                  ),
                  _GridCard(
                    icon: Icons.inventory_2_outlined,
                    label: 'Browse Shoes',
                    onTap: () {},
                  ),
                  _GridCard(
                    icon: Icons.person_outline,
                    label: 'My Profile',
                    onTap: () {},
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Recent Recommendations Header ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent recommendations',
                    style: TextStyle(
                        color: Color(0xFF1B4332),
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: const Text('View All',
                        style: TextStyle(
                            color: Color(0xFF00695C),
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              const Text('Based on your last 3D scan',
                  style: TextStyle(color: Colors.black45, fontSize: 12)),

              const SizedBox(height: 14),

              _ShoeCard(
                brand: 'NIKE',
                name: 'Air Max 270',
                price: '₹8,995',
                imagePath: 'assets/images/air max.jpg',
              ),
              const SizedBox(height: 12),
              _ShoeCard(
                brand: 'ADIDAS',
                name: 'Ultraboost 22',
                price: '₹12,499',
                imagePath: 'assets/images/ultraboost 22.jpg',
              ),
              const SizedBox(height: 12),
              _ShoeCard(
                brand: 'SERVIS',
                name: 'Cheetah Pro Run',
                price: 'Rs. 3,500',
                imagePath: 'assets/images/cheetah pro run.jpg',
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),

      // ── Bottom Nav Bar ──
      bottomNavigationBar: Container(
        height: 70,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFB2DFDB), width: 1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(icon: Icons.home_outlined, label: 'Home',
                isActive: true, onTap: () {}),
            _NavItem(
              icon: Icons.qr_code_scanner,
              label: 'Scan',
              isActive: false,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ScanScreen())),
            ),
            _NavItem(
              icon: Icons.style_outlined,
              label: 'Try-On',
              isActive: false,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const VirtualTryOnScreen())),
            ),
            _NavItem(
              icon: Icons.person_outline,
              label: 'Profile',
              isActive: false,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

// ── Grid Card ──
class _GridCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _GridCard({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF00695C), size: 22),
            ),
            const SizedBox(height: 10),
            Text(label,
                style: const TextStyle(
                    color: Color(0xFF1B4332),
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ── Shoe Card ──
class _ShoeCard extends StatelessWidget {
  final String brand;
  final String name;
  final String price;
  final String imagePath;

  const _ShoeCard(
      {required this.brand,
      required this.name,
      required this.price,
      required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 90,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F7F5),
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.hardEdge,
            child: Image.asset(
              imagePath,
              width: 90,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Center(
                child: Icon(Icons.image_not_supported_outlined,
                    color: Color(0xFF00695C), size: 36),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(brand,
                    style: const TextStyle(
                        color: Colors.black45,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1)),
                const SizedBox(height: 4),
                Text(name,
                    style: const TextStyle(
                        color: Color(0xFF1B4332),
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Perfect Fit',
                      style: TextStyle(
                          color: Color(0xFF00695C),
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 6),
                Text(price,
                    style: const TextStyle(
                        color: Color(0xFF1B4332),
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(Icons.arrow_forward,
                color: Color(0xFF00695C), size: 16),
          ),
        ],
      ),
    );
  }
}

// ── Bottom Nav Item ──
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem(
      {required this.icon,
      required this.label,
      required this.isActive,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFFE8F5E9)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon,
                color: isActive
                    ? const Color(0xFF00695C)
                    : Colors.black38,
                size: 22),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  color: isActive ? const Color(0xFF00695C) : Colors.black38,
                  fontSize: 11,
                  fontWeight:
                      isActive ? FontWeight.w600 : FontWeight.normal)),
        ],
      ),
    );
  }
}