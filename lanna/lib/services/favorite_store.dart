import 'package:flutter/material.dart';
import 'api_service.dart';
import 'favorite_service.dart';
import 'vocabulary_service.dart';
import '../models/vocabulary_model.dart';

class FavoriteItem {
  final String? favoriteId;
  final String thai;
  final String lanna;
  final String roman;
  final String? vocabId;

  FavoriteItem({
    this.favoriteId,
    required this.thai,
    required this.lanna,
    required this.roman,
    this.vocabId,
  });
}

class FavoriteStore extends ChangeNotifier {
  final List<FavoriteItem> _items = [];
  bool _isLoading = false;

  List<FavoriteItem> get items => _items;
  bool get isLoading => _isLoading;

  final _favoriteService = FavoriteService();
  final _vocabService = VocabularyService();

  bool contains(String thai) {
    return _items.any((e) => e.thai == thai);
  }

  /// Sync favorites list with backend API if logged in
  Future<void> syncWithApi() async {
    final sessionType = await ApiService.getSessionType();
    if (sessionType == 'guest') return;

    _isLoading = true;
    notifyListeners();

    try {
      String userId = '';
      if (sessionType == 'admin') {
        final admin = await ApiService.getCachedAdmin();
        userId = admin?.adminId ?? '';
      } else if (sessionType == 'user') {
        final user = await ApiService.getCachedUser();
        userId = user?.userId ?? '';
      }

      if (userId.isEmpty) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Fetch user favorites from backend
      final dbFavorites = await _favoriteService.getFavoritesByUserId(userId);
      
      // Fetch vocabulary to resolve ID to words
      final allVocabs = await _vocabService.getAllVocabulary();

      _items.clear();
      for (final fav in dbFavorites) {
        VocabularyModel? vocab;
        for (final v in allVocabs) {
          if (v.vocabId == fav.vocabId ||
              v.vocabId.toLowerCase() == fav.vocabId.toLowerCase()) {
            vocab = v;
            break;
          }
        }
        if (vocab == null) continue; // Skip favorites with no matching vocab

        _items.add(FavoriteItem(
          favoriteId: fav.favoriteId,
          thai: vocab.thaiWord,
          lanna: vocab.lannaWord,
          roman: vocab.reading,
          vocabId: fav.vocabId,
        ));
      }
    } catch (e) {
      debugPrint('Error syncing favorites: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add item to favorites (sync with API if logged in)
  Future<void> add(FavoriteItem item) async {
    if (contains(item.thai)) return;

    final sessionType = await ApiService.getSessionType();
    if (sessionType == 'guest') {
      _items.add(item);
      notifyListeners();
      return;
    }

    // Authenticated path
    try {
      String userId = '';
      if (sessionType == 'admin') {
        final admin = await ApiService.getCachedAdmin();
        userId = admin?.adminId ?? '';
      } else if (sessionType == 'user') {
        final user = await ApiService.getCachedUser();
        userId = user?.userId ?? '';
      }

      // Find matching vocab ID from backend vocabulary list if not provided
      String? vocabId = item.vocabId;
      if (vocabId == null) {
        final allVocabs = await _vocabService.getAllVocabulary();
        final normalizedThai = item.thai.trim().toLowerCase();
        final normalizedLanna = item.lanna.trim().toLowerCase();
        
        VocabularyModel? match;
        for (var v in allVocabs) {
          if (v.thaiWord.trim().toLowerCase() == normalizedThai ||
              v.lannaWord.trim().toLowerCase() == normalizedLanna) {
            match = v;
            break;
          }
        }

        if (match != null) {
          vocabId = match.vocabId;
        } else {
          // Add new vocabulary item to database
          final newVocab = VocabularyModel(
            vocabId: '',
            lannaWord: item.lanna,
            thaiWord: item.thai,
            reading: item.roman.isEmpty ? item.thai : item.roman,
            meaning: item.thai,
            categoryVocabId: 'CV0001', // Default category
          );
          final createdVocab = await _vocabService.createVocabulary(newVocab);
          vocabId = createdVocab.vocabId;
        }
      }

      final favResult = await _favoriteService.createFavorite(userId, vocabId);
      
      _items.add(FavoriteItem(
        favoriteId: favResult.favoriteId,
        thai: item.thai,
        lanna: item.lanna,
        roman: item.roman,
        vocabId: vocabId,
      ));
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding favorite to backend: $e');
      // Fallback local add
      _items.add(item);
      notifyListeners();
    }
  }

  /// Remove item from favorites (sync with API if logged in)
  Future<void> remove(String thai) async {
    final itemIndex = _items.indexWhere((e) => e.thai == thai);
    if (itemIndex == -1) return;

    final item = _items[itemIndex];
    final sessionType = await ApiService.getSessionType();
    
    if (sessionType == 'guest' || item.favoriteId == null) {
      _items.removeAt(itemIndex);
      notifyListeners();
      return;
    }

    try {
      await _favoriteService.deleteFavorite(item.favoriteId!);
      _items.removeAt(itemIndex);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting favorite from backend: $e');
      // Force remove locally
      _items.removeAt(itemIndex);
      notifyListeners();
    }
  }
}
