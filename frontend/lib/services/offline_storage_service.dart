import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pending_media.dart';

/// Service for managing offline media storage and synchronization.
/// 
/// Implements User Story 15: Offline image saving with sync status.
/// Uses [SharedPreferences] to store pending uploads encoded as JSON strings.
class OfflineStorageService {
  static const String _storageKey = 'pending_media_items';
  static const String _syncStatusKey = 'sync_status';
  
  SharedPreferences? _prefs;
  bool _isSyncing = false;

  /// Initializes the service.
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Retrieves all pending media items, sorted by date (newest first).
  Future<List<PendingMedia>> getAllPendingMedia() async {
    _prefs ??= await SharedPreferences.getInstance();
    final List<String> list = _prefs!.getStringList(_storageKey) ?? [];
    
    return list
        .map((item) => PendingMedia.fromJson(json.decode(item)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Saves a media item for later synchronization.
  Future<void> savePendingMedia(PendingMedia media) async {
    _prefs ??= await SharedPreferences.getInstance();
    final List<String> list = _prefs!.getStringList(_storageKey) ?? [];
    
    list.add(json.encode(media.toJson()));
    await _prefs!.setStringList(_storageKey, list);

    debugPrint('Saved pending media: ${media.id}');
  }

  /// Deletes a specific pending media item by [id].
  Future<void> deletePendingMedia(String id) async {
    _prefs ??= await SharedPreferences.getInstance();
    final List<String> list = _prefs!.getStringList(_storageKey) ?? [];
    
    final updatedList = list.where((item) {
      final media = PendingMedia.fromJson(json.decode(item));
      return media.id != id;
    }).toList();

    await _prefs!.setStringList(_storageKey, updatedList);
    debugPrint('Deleted pending media: $id');
  }

  /// Returns the total count of pending items (synced + unsynced).
  Future<int> getPendingCount() async {
    final items = await getAllPendingMedia();
    return items.length;
  }

  /// Returns true if a sync operation is currently in progress.
  bool get isSyncing => _isSyncing;

  /// Marks a specific media item as synced.
  /// 
  /// Updates the `isSynced` flag of the item in local storage.
  Future<void> markAsSynced(String id) async {
    _prefs ??= await SharedPreferences.getInstance();
    final List<String> list = _prefs!.getStringList(_storageKey) ?? [];
    
    final updatedList = list.map((item) {
      final media = PendingMedia.fromJson(json.decode(item));
      if (media.id == id) {
        return json.encode(media.copyWith(isSynced: true).toJson());
      }
      return item;
    }).toList();

    await _prefs!.setStringList(_storageKey, updatedList);
  }

  /// Attempts to sync all pending media items to the server.
  /// 
  /// Returns a [SyncResult] summarizing successes and failures.
  /// Currently simulates the upload process.
  Future<SyncResult> syncAllPending() async {
    if (_isSyncing) {
      return SyncResult(success: 0, failed: 0, message: 'Sync already in progress');
    }

    _isSyncing = true;

    try {
      final pendingItems = await getAllPendingMedia();
      final unsyncedItems = pendingItems.where((m) => !m.isSynced).toList();

      if (unsyncedItems.isEmpty) {
        _isSyncing = false;
        return SyncResult(success: 0, failed: 0, message: 'Nothing to sync');
      }

      int successCount = 0;
      int failedCount = 0;

      for (final item in unsyncedItems) {
        // Simulate upload delay
        await Future.delayed(const Duration(milliseconds: 500));

        // In a real app, this would upload to the server
        // For now, we just mark as synced
        try {
          await markAsSynced(item.id);
          successCount++;
        } catch (e) {
          failedCount++;
          debugPrint('Failed to sync ${item.id}: $e');
        }
      }

      _isSyncing = false;
      return SyncResult(
        success: successCount,
        failed: failedCount,
        message: 'Synced $successCount items',
      );
    } catch (e) {
      _isSyncing = false;
      return SyncResult(success: 0, failed: 0, message: 'Sync error: $e');
    }
  }

  /// Returns the count of items that have not yet been synced.
  Future<int> getUnsyncedCount() async {
    final items = await getAllPendingMedia();
    return items.where((m) => !m.isSynced).length;
  }

  /// Clears all pending media from storage.
  Future<void> clearAll() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.remove(_storageKey);
  }
}

/// Result of a synchronization operation.
class SyncResult {
  final int success;
  final int failed;
  final String message;

  SyncResult({
    required this.success,
    required this.failed,
    required this.message,
  });
}

final offlineStorageService = OfflineStorageService();
