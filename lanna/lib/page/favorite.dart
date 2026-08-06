import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../services/favorite_store.dart';
import '../services/api_service.dart';
import '../widgets/app_header.dart';

class FavoritePage extends StatefulWidget {
  const FavoritePage({super.key});

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  static const Color primaryOrange = Color(0xFF924E19);
  static const Color bgColor = Color(0xFFFFFBF7);
  static const Color warmBrown = Color(0xFF7A5C3A);
  static const Color darkBrown = Color(0xFF2D1A00);

  bool _isLoggedIn = false;
  bool _isCheckingAuth = true;

  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _checkAuthAndSync();
    _searchCtrl.addListener(() {
      setState(() {
        _searchQuery = _searchCtrl.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkAuthAndSync() async {
    final sessionType = await ApiService.getSessionType();
    if (!mounted) return;
    setState(() {
      _isLoggedIn = sessionType != 'guest';
      _isCheckingAuth = false;
    });
    if (_isLoggedIn) {
      if (!mounted) return;
      context.read<FavoriteStore>().syncWithApi();
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<FavoriteStore>();

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppHeader(title: 'รายการโปรด'),
            const SizedBox(height: 8),

            if (_isLoggedIn) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(fontSize: 10, color: Color(0xFF2D1A00)),
                    decoration: InputDecoration(
                      hintText: 'ค้นหารายการโปรด...',
                      hintStyle: TextStyle(
                        fontSize: 9,
                        color: const Color(0xFF7A5C3A).withValues(alpha: 0.5),
                      ),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF7A5C3A)),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(100),
                        borderSide: const BorderSide(color: Color(0xFFEADBC8), width: 1.2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(100),
                        borderSide: const BorderSide(color: Color(0xFF924E19), width: 1.5),
                      ),
                    ),
                  ),
                ),
              ),
            ],

            // Content area
            Expanded(
              child: _isCheckingAuth
                  ? const Center(
                      child: CircularProgressIndicator(color: primaryOrange),
                    )
                  : !_isLoggedIn
                      ? _buildNotLoggedInView(context)
                      : store.isLoading
                          ? const Center(
                              child: CircularProgressIndicator(color: primaryOrange),
                            )
                          : store.items.isEmpty
                              ? _buildEmptyView()
                              : _buildFavoriteList(store),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotLoggedInView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                color: Color(0xFFF5EAE1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.star_outline_rounded,
                size: 50,
                color: primaryOrange,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'เข้าสู่ระบบเพื่อดูรายการโปรด',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: darkBrown,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'กดดาวขณะแปลภาษา เพื่อบันทึกคำที่ชอบไว้',
              style: TextStyle(
                fontSize: 8,
                color: warmBrown,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: 180,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'เข้าสู่ระบบ',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 90,
              height: 90,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0xFFF5EAE1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.star_border_rounded,
                  size: 50,
                  color: primaryOrange,
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'ยังไม่มีรายการโปรด',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: darkBrown,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'กดปุ่ม ⭐ ขณะแปลภาษา\nเพื่อบันทึกคำที่ต้องการ',
              style: TextStyle(
                fontSize: 8,
                color: warmBrown,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteList(FavoriteStore store) {
    final filteredItems = store.items.where((item) {
      final query = _searchQuery.trim().toLowerCase();
      if (query.isEmpty) return true;
      return item.thai.toLowerCase().contains(query) ||
             item.lanna.toLowerCase().contains(query) ||
             item.roman.toLowerCase().contains(query);
    }).toList();

    if (filteredItems.isEmpty) {
      return const Center(
        child: Text(
          'ไม่พบรายการโปรดที่ตรงกับการค้นหา',
          style: TextStyle(fontSize: 10, color: warmBrown),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: filteredItems.length + 1,
      itemBuilder: (context, index) {
        if (index == filteredItems.length) {
          // Bottom Decor
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                // const Text(
                //   'สิ้นสุดรายการ',
                //   style: TextStyle(
                //     fontSize: 8,
                //     color: Color(0xFF7A5C3A),
                //     fontWeight: FontWeight.w500,
                //   ),
                // ),
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEADBC8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ],
            ),
          );
        }
        final item = filteredItems[index];
        return FavoriteCard(
          thai: item.thai,
          lanna: item.lanna,
          roman: item.roman,
          onRemove: () => store.remove(item.thai),
        );
      },
    );
  }
}

// =======================================================
// FAVORITE CARD
// =======================================================

class FavoriteCard extends StatefulWidget {
  final String thai;
  final String lanna;
  final String roman;
  final VoidCallback onRemove;

  const FavoriteCard({
    super.key,
    required this.thai,
    required this.lanna,
    required this.roman,
    required this.onRemove,
  });

  @override
  State<FavoriteCard> createState() => _FavoriteCardState();
}

class _FavoriteCardState extends State<FavoriteCard> {
  static const Color darkBrown = Color(0xFF2D1A00);
  static const Color warmBrown = Color(0xFF7A5C3A);

  final FlutterTts _tts = FlutterTts();

  Future<void> _speak() async {
    await _tts.setLanguage('th-TH');
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    await _tts.speak(widget.roman.isNotEmpty ? widget.roman : widget.thai);
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFEADBC8),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7A5C3A).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Row(
          children: [
            // Left accent bar (Solid Brown)
            Container(
              width: 5,
              height: 94,
              color: const Color(0xFF924E19),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
                child: Row(
                  children: [
                    // Sound button (Circular Cream)
                    GestureDetector(
                      onTap: _speak,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5EAE1),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFEADBC8), width: 1.0),
                        ),
                        child: const Icon(
                          Icons.volume_up_rounded,
                          color: Color(0xFF924E19),
                          size: 22,
                        ),
                      ),
                    ),

                    const SizedBox(width: 14),

                    // Text content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ไทย: ${widget.thai}',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: darkBrown,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.lanna,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF924E19),
                              fontFamily: 'PayapLanna',
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.roman,
                            style: const TextStyle(
                              fontSize: 8,
                              color: warmBrown,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Remove (star filled) button
                    IconButton(
                      icon: const Icon(
                        Icons.star_rounded,
                        color: Color(0xFF924E19),
                        size: 30,
                      ),
                      onPressed: widget.onRemove,
                      tooltip: 'ลบออกจากรายการโปรด',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DottedGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintDot = Paint()..color = const Color(0xFFFFFBF7).withValues(alpha: 0.15);
    const double spacing = 14.0;
    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.0, paintDot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant DottedGridPainter oldDelegate) => false;
}
