import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../services/lanna_transliterator.dart';
import '../services/vocabulary_service.dart';
import '../widgets/app_header.dart';

const Color _kPrimary = Color(0xFF924E19);

// ─── Model ────────────────────────────────────────────────────────────────────
class DictItem {
  final String? vocabId;
  final String category;
  final String lanna;
  final String reading;
  final String thaiSound;
  final String meaning;

  const DictItem({
    this.vocabId,
    required this.category,
    required this.lanna,
    required this.reading,
    required this.thaiSound,
    required this.meaning,
  });
}

// ─── Page ─────────────────────────────────────────────────────────────────────
class DictionaryPage extends StatefulWidget {
  const DictionaryPage({super.key});

  @override
  State<DictionaryPage> createState() => _DictionaryPageState();
}

class _DictionaryPageState extends State<DictionaryPage> {
  final _searchCtrl = TextEditingController();
  final _vocabService = VocabularyService();
  final FlutterTts _tts = FlutterTts();
  final _transliterator = LannaTransliterator();

  List<DictItem> _allItems = [];
  List<String> _categories = ['ทั้งหมด'];
  String _selectedCategory = 'ทั้งหมด';
  bool _isLoading = true;
  int _currentPage = 1;
  static const int _perPage = 10;

  @override
  void initState() {
    super.initState();
    _initTts();
    _loadData();
    _searchCtrl.addListener(() => setState(() => _currentPage = 1));
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('th-TH');
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
  }

  Future<void> _speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final dbCategories = await _vocabService.getAllCategories();
      final dbVocabs = await _vocabService.getAllVocabulary();
      if (!mounted) return;
      setState(() {
        final knownCategories = dbCategories
            .map((c) => c.name.trim())
            .where((name) => name.isNotEmpty)
            .toSet();
        final categoryNameById = {
          for (final category in dbCategories)
            category.categoryVocabId: category.name.trim(),
        };
        const fallbackCategory = 'คำศัพท์ทั่วไป';
        _allItems = dbVocabs.map((v) {
          final sourceCategory =
              categoryNameById[v.categoryVocabId] ?? v.category?.trim();
          final displayCategory =
              sourceCategory != null && knownCategories.contains(sourceCategory)
              ? sourceCategory
              : fallbackCategory;

          final rawLanna = v.lannaWord.trim();
          final lannaText = (rawLanna.isNotEmpty && rawLanna != '-')
              ? rawLanna
              : _transliterator.thaiToLanna(v.thaiWord);

          return DictItem(
            vocabId: v.vocabId,
            category: displayCategory,
            lanna: lannaText,
            reading: v.reading,
            thaiSound: v.thaiWord,
            meaning: v.meaning,
          );
        }).toList();
        final displayCategories = _allItems
            .map((item) => item.category)
            .toSet();

        const priorityOrder = ['ทักทาย', 'สัตว์', 'อาหาร', 'พืชและสมุนไพร'];
        final orderedCategories = <String>[];

        for (final cat in priorityOrder) {
          if (displayCategories.contains(cat) && !orderedCategories.contains(cat)) {
            orderedCategories.add(cat);
          }
        }

        for (final cat in knownCategories) {
          if (displayCategories.contains(cat) && !orderedCategories.contains(cat)) {
            orderedCategories.add(cat);
          }
        }

        for (final cat in displayCategories) {
          if (!orderedCategories.contains(cat)) {
            orderedCategories.add(cat);
          }
        }

        _categories = ['ทั้งหมด', ...orderedCategories];
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _normalize(String text) {
    // Strip Thai combining vowels and tone marks to leave mostly consonants for fuzzy match
    final pattern = RegExp(r'[\u0E30\u0E31\u0E34-\u0E39\u0E47-\u0E4D]');
    return text.replaceAll(pattern, '').toLowerCase().trim();
  }

  double _calculateFuzzyScore(DictItem item, String query) {
    if (query.isEmpty) return 1.0;

    final normQuery = _normalize(query);
    double maxScore = 0.0;

    double scoreField(String field, double weight) {
      final val = field.toLowerCase().trim();
      if (val.isEmpty) return 0.0;

      // 1. Exact match on raw text
      if (val == query.toLowerCase()) return 100.0 * weight;

      // 2. Starts with on raw text
      if (val.startsWith(query.toLowerCase())) return 80.0 * weight;

      // 3. Contains on raw text
      if (val.contains(query.toLowerCase())) return 60.0 * weight;

      // 4. Exact match on normalized text
      final normVal = _normalize(val);
      if (normVal == normQuery) return 50.0 * weight;

      // 5. Starts with on normalized text
      if (normVal.startsWith(normQuery)) return 40.0 * weight;

      // 6. Contains on normalized text
      if (normVal.contains(normQuery)) return 30.0 * weight;

      // 7. Subsequence check on raw text (queries of length >= 2)
      if (query.length >= 2) {
        int sIdx = 0;
        int qIdx = 0;
        int gaps = 0;
        int lastMatchIdx = -1;
        while (sIdx < val.length && qIdx < query.length) {
          if (val[sIdx] == query.toLowerCase()[qIdx]) {
            if (lastMatchIdx != -1) {
              gaps += (sIdx - lastMatchIdx - 1);
            }
            lastMatchIdx = sIdx;
            qIdx++;
          }
          sIdx++;
        }
        if (qIdx == query.length) {
          double penalty = gaps * 0.05 + (val.length - query.length) * 0.01;
          return max(1.0, 20.0 - penalty) * weight;
        }
      }

      // 8. Subsequence check on normalized text (queries of length >= 2)
      if (normQuery.length >= 2) {
        int sIdx = 0;
        int qIdx = 0;
        int gaps = 0;
        int lastMatchIdx = -1;
        while (sIdx < normVal.length && qIdx < normQuery.length) {
          if (normVal[sIdx] == normQuery[qIdx]) {
            if (lastMatchIdx != -1) {
              gaps += (sIdx - lastMatchIdx - 1);
            }
            lastMatchIdx = sIdx;
            qIdx++;
          }
          sIdx++;
        }
        if (qIdx == normQuery.length) {
          double penalty = gaps * 0.05 + (normVal.length - normQuery.length) * 0.01;
          return max(1.0, 15.0 - penalty) * weight;
        }
      }

      return 0.0;
    }

    // Field weights: thaiSound (1.5), lanna (1.4), reading (1.2), meaning (1.0)
    maxScore = max(maxScore, scoreField(item.thaiSound, 1.5));
    maxScore = max(maxScore, scoreField(item.lanna, 1.4));
    maxScore = max(maxScore, scoreField(item.reading, 1.2));
    maxScore = max(maxScore, scoreField(item.meaning, 1.0));

    return maxScore;
  }

  List<DictItem> get _filtered {
    final keyword = _searchCtrl.text.trim();

    // Filter by category first
    final categoryFiltered = _allItems.where((item) {
      return _selectedCategory == 'ทั้งหมด' || item.category == _selectedCategory;
    });

    if (keyword.isEmpty) {
      return categoryFiltered.toList();
    }

    // Map items to their scores and filter out score == 0
    final scoredItems = categoryFiltered
        .map((item) => _ScoredDictItem(item: item, score: _calculateFuzzyScore(item, keyword)))
        .where((si) => si.score > 0.0)
        .toList();

    // Sort by score descending
    scoredItems.sort((a, b) => b.score.compareTo(a.score));

    return scoredItems.map((si) => si.item).toList();
  }

  List<DictItem> get _paged {
    final all = _filtered;
    final start = (_currentPage - 1) * _perPage;
    if (start >= all.length) return [];
    final end = (start + _perPage).clamp(0, all.length);
    return all.sublist(start, end);
  }

  int get _totalPages {
    if (_filtered.isEmpty) return 1;
    return (_filtered.length / _perPage).ceil();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF7),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const AppHeader(title: 'พจนานุกรมล้านนา'),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: _kPrimary),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      color: _kPrimary,
                      child: CustomScrollView(
                        slivers: [
                          // ── Search bar ──
                          SliverToBoxAdapter(child: _buildSearchBar()),
                          // ── Category chips ──
                          SliverToBoxAdapter(child: _buildCategoryChips()),
                          // ── Count badge ──
                          SliverToBoxAdapter(child: _buildCountBadge()),
                          // ── Items ──
                          if (_paged.isEmpty)
                            SliverFillRemaining(child: _buildEmpty())
                          else
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (_, i) => _DictCard(
                                    item: _paged[i],
                                    onSpeak: () => _speak(
                                      _paged[i].reading.isNotEmpty
                                          ? _paged[i].reading
                                          : _paged[i].thaiSound,
                                    ),
                                  ),
                                  childCount: _paged.length,
                                ),
                              ),
                            ),
                          // ── Pagination ──
                          SliverToBoxAdapter(child: _buildPagination()),
                          const SliverToBoxAdapter(child: SizedBox(height: 80)),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Search bar ──────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(fontSize: 14, color: Color(0xFF2D1A00)),
        decoration: InputDecoration(
          hintText: 'ค้นหาคำศัพท์ล้านนา, คำอ่าน, ความหมาย...',
          hintStyle: TextStyle(
            fontSize: 12,
            color: const Color(0xFF7A5C3A).withValues(alpha: 0.5),
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF7A5C3A),
          ),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.clear_rounded,
                    color: Color(0xFF7A5C3A),
                  ),
                  onPressed: () => setState(() {
                    _searchCtrl.clear();
                    _currentPage = 1;
                  }),
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 16,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFEADBC8), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _kPrimary, width: 1.5),
          ),
        ),
      ),
    );
  }

  // ── Category chips ──────────────────────────────────────────────────────────
  Widget _buildCategoryChips() {
    return SizedBox(
      height: 44,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: _categories.map((cat) {
            final active = cat == _selectedCategory;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                selected: active,
                showCheckmark: false,
                selectedColor: _kPrimary,
                backgroundColor: const Color(0xFFFFFBF7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: active ? _kPrimary : const Color(0xFFEADBC8),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                label: Text(
                  cat,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: active ? Colors.white : const Color(0xFF7A5C3A),
                  ),
                ),
                onSelected: (_) => setState(() {
                  _selectedCategory = cat;
                  _currentPage = 1;
                }),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Count badge ─────────────────────────────────────────────────────────────
  Widget _buildCountBadge() {
    final count = _filtered.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'พบ $count รายการ',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _kPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty ───────────────────────────────────────────────────────────────────
  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 56, color: Color(0xFFEADBC8)),
          SizedBox(height: 12),
          Text(
            'ไม่พบคำศัพท์ที่ต้องการ',
            style: TextStyle(fontSize: 12, color: Color(0xFF7A5C3A)),
          ),
        ],
      ),
    );
  }

  // ── Pagination ──────────────────────────────────────────────────────────────
  Widget _buildPagination() {
    if (_totalPages <= 1) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
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
                    _currentPage > 1
                        ? () => setState(() => _currentPage--)
                        : null,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 16,
                    color:
                        _currentPage > 1
                            ? const Color(0xFFE16905)
                            : Colors.grey.shade300,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'หน้า $_currentPage จาก $_totalPages',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D1A00),
                ),
              ),
              const SizedBox(width: 16),
              InkWell(
                onTap:
                    _currentPage < _totalPages
                        ? () => setState(() => _currentPage++)
                        : null,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color:
                        _currentPage < _totalPages
                            ? const Color(0xFFE16905)
                            : Colors.grey.shade300,
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

// ─── Dictionary Card ──────────────────────────────────────────────────────────
class _DictCard extends StatelessWidget {
  final DictItem item;
  final VoidCallback onSpeak;

  const _DictCard({required this.item, required this.onSpeak});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEADBC8), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Thai badge + speaker
            Row(
              children: [
                if (item.thaiSound.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7F2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFEADBC8),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      item.thaiSound,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF7A5C3A),
                      ),
                    ),
                  ),
                  const Spacer(),
                ] else
                  const Spacer(),
                // Category tag
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.category,
                    style: const TextStyle(
                      fontSize: 8,
                      color: _kPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Speaker
                GestureDetector(
                  onTap: onSpeak,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7F2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFEADBC8),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.volume_up_rounded,
                      size: 17,
                      color: _kPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Lanna script
            Text(
              item.lanna,
              style: const TextStyle(
                fontFamily: 'LNTilok',
                fontSize: 17,
                color: Color(0xFF924E19),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Divider(color: Color(0xFFEADBC8), height: 1),
            const SizedBox(height: 8),
            // Reading
            if (item.reading.isNotEmpty)
              _infoRow(
                Icons.record_voice_over_rounded,
                'คำอ่าน:',
                item.reading,
              ),
            // Meaning
            if (item.meaning.isNotEmpty) ...[
              const SizedBox(height: 4),
              _infoRow(Icons.menu_book_rounded, 'ความหมาย:', item.meaning),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 12, color: const Color(0xFF7A5C3A)),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: Color(0xFF7A5C3A),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 9, color: Color(0xFF2D1A00)),
          ),
        ),
      ],
    );
  }
}

// ─── Scored Dictionary Item Helper ───────────────────────────────────────────
class _ScoredDictItem {
  final DictItem item;
  final double score;

  const _ScoredDictItem({required this.item, required this.score});
}
