import 'package:flutter/material.dart';

/// จำนวนคอลัมน์มาตรฐานสำหรับรายการอักขระล้านนา
int lannaGridColumnCount(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width >= 600) return 3;
  if (width >= 420) return 3;
  return 2;
}

/// การ์ดรายการแบบเรียบง่าย แสดงเฉพาะอักขระล้านนากึ่งกลาง
class LannaGlyphCard extends StatelessWidget {
  final String glyph;
  final String thaiEquivalent;

  const LannaGlyphCard({
    super.key,
    required this.glyph,
    required this.thaiEquivalent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEADBC8), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  glyph,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 44,
                    height: 1.15,
                    fontFamily: 'LNTilok',
                    fontFamilyFallback: [
                      'LNTilok',
                      'THSarabunNew',
                      'sans-serif',
                    ],
                    color: Color(0xFF924E19),
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'เทียบภาษาไทย: $thaiEquivalent',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF7A5C3A),
            ),
          ),
        ],
      ),
    );
  }
}

/// Grid View พร้อมระบบเปลี่ยนหน้า (Pagination) แสดงผลหน้าละ 16 รายการ
class PaginatedLannaGrid<T> extends StatefulWidget {
  final List<T> items;
  final int pageSize;
  final Widget Function(BuildContext context, T item, int globalIndex) itemBuilder;
  final String? referenceText;

  const PaginatedLannaGrid({
    super.key,
    required this.items,
    this.pageSize = 16,
    required this.itemBuilder,
    this.referenceText,
  });

  @override
  State<PaginatedLannaGrid<T>> createState() => _PaginatedLannaGridState<T>();
}

class _PaginatedLannaGridState<T> extends State<PaginatedLannaGrid<T>> {
  int _currentPage = 0;

  @override
  void didUpdateWidget(covariant PaginatedLannaGrid<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _currentPage = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const Center(child: Text('ไม่มีข้อมูล'));
    }

    final totalPages = (widget.items.length / widget.pageSize).ceil();
    final safePage = _currentPage.clamp(0, totalPages > 0 ? totalPages - 1 : 0);

    final startIndex = safePage * widget.pageSize;
    final endIndex = (startIndex + widget.pageSize < widget.items.length)
        ? startIndex + widget.pageSize
        : widget.items.length;
    final pageItems = widget.items.sublist(startIndex, endIndex);
    final int crossAxisCount = lannaGridColumnCount(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 95),
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0,
          ),
          itemCount: pageItems.length,
          itemBuilder: (context, index) {
            return widget.itemBuilder(
              context,
              pageItems[index],
              startIndex + index,
            );
          },
        ),
        if (totalPages > 1) ...[
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFEADBC8), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF924E19).withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap:
                        safePage > 0
                            ? () => setState(() => _currentPage--)
                            : null,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
                        color:
                            safePage > 0
                                ? const Color(0xFFE16905)
                                : Colors.grey.shade300,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'หน้า ${safePage + 1} จาก $totalPages',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D1A00),
                    ),
                  ),
                  const SizedBox(width: 16),
                  InkWell(
                    onTap:
                        safePage < totalPages - 1
                            ? () => setState(() => _currentPage++)
                            : null,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color:
                            safePage < totalPages - 1
                                ? const Color(0xFFE16905)
                                : Colors.grey.shade300,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
        _buildReferenceFooter(widget.referenceText),
      ],
    );
  }

  Widget _buildReferenceFooter(String? customReference) {
    final String textToShow = customReference ??
        '• พจนานุกรมภาษาล้านนา - ไทย ฉบับสถาบันวิจัยสังคม มหาวิทยาลัยเชียงใหม่\n'
        '• ตำราอักขรวิธีตั๋วเมือง สำนักส่งเสริมศิลปวัฒนธรรม มหาวิทยาลัยเชียงใหม่';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF6EF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEADBC8), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(
                Icons.menu_book_rounded,
                size: 18,
                color: Color(0xFF924E19),
              ),
              SizedBox(width: 8),
              Text(
                'แหล่งอ้างอิงข้อมูล',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5C3A21),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            textToShow,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 9.5,
              color: Color(0xFF7A5C3A),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
