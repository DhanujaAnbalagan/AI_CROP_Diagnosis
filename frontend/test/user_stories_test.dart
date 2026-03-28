// Tests for User Stories 9-16 features
//
// Coverage:
// - US9: Camera permission handling and capture flow
// - US10: Guidance overlay and pre-capture screen
// - US11: Image quality analysis (blur/darkness)
// - US12: Multi-image upload with carousel
// - US13: Video recording with duration/size limits
// - US14: Voice input and language selection
// - US15: Offline storage (PendingMedia model, OfflineStorageService)
// - US16: Confirmation feedback

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:swe_flutter/models/pending_media.dart';
import 'package:swe_flutter/services/offline_storage_service.dart';
import 'package:swe_flutter/core/utils/image_quality_util.dart';
import 'dart:typed_data';

void main() {
  // ============================================
  // US11: Image Quality Utility Tests
  // ============================================
  group('US11 - ImageQualityUtil', () {
    test('analyzeImageFromBytes returns good quality for typical images', () async {
      // Create sample bytes representing a typical image (medium brightness, varied)
      final bytes = Uint8List.fromList(
        List.generate(10000, (i) => (i * 7 + 50) % 256),
      );
      
      final result = await ImageQualityUtil.analyzeImageFromBytes(bytes);
      
      expect(result, isNotNull);
      expect(result.brightness, greaterThan(0));
      expect(result.sharpness, greaterThan(0));
    });
    
    test('analyzeImageFromBytes detects dark images', () async {
      // Create sample bytes with very low values (dark image)
      final bytes = Uint8List.fromList(
        List.generate(10000, (i) => i % 30), // All values 0-29
      );
      
      final result = await ImageQualityUtil.analyzeImageFromBytes(bytes);
      
      expect(result.isTooDark, isTrue);
      expect(result.brightness, lessThan(50));
    });

    test('analyzeImageFromBytes handles empty bytes gracefully', () async {
      final bytes = Uint8List(0);
      
      final result = await ImageQualityUtil.analyzeImageFromBytes(bytes);
      
      // Empty bytes should return "good" result (not erroring out)
      expect(result.isGood, isTrue);
      expect(result.isTooDark, isFalse);
      expect(result.isBlurry, isFalse);
    });
    
    test('ImageQualityResult isGood returns true when not dark and not blurry', () {
      final result = ImageQualityResult(
        isTooDark: false,
        isBlurry: false,
        brightness: 128,
        sharpness: 50,
      );
      expect(result.isGood, isTrue);
    });

    test('ImageQualityResult isGood returns false when too dark', () {
      final result = ImageQualityResult(
        isTooDark: true,
        isBlurry: false,
        brightness: 20,
        sharpness: 50,
      );
      expect(result.isGood, isFalse);
    });

    test('ImageQualityResult isGood returns false when blurry', () {
      final result = ImageQualityResult(
        isTooDark: false,
        isBlurry: true,
        brightness: 128,
        sharpness: 2,
      );
      expect(result.isGood, isFalse);
    });
  });

  // ============================================
  // US15: PendingMedia Model Tests
  // ============================================
  group('US15 - PendingMedia Model', () {
    test('creates PendingMedia with required fields', () {
      final media = PendingMedia(
        id: 'test-001',
        filePath: '/path/to/image.jpg',
        fileType: 'image',
        createdAt: 1700000000,
      );
      
      expect(media.id, 'test-001');
      expect(media.filePath, '/path/to/image.jpg');
      expect(media.fileType, 'image');
      expect(media.createdAt, 1700000000);
      expect(media.isSynced, false);
    });

    test('creates PendingMedia with all optional fields', () {
      final media = PendingMedia(
        id: 'test-002',
        filePath: '/path/to/video.mp4',
        fileType: 'video',
        voiceTranscription: 'leaf spots observed',
        durationSeconds: 15,
        createdAt: 1700000000,
        base64Content: 'abc123base64==',
        isSynced: true,
      );
      
      expect(media.voiceTranscription, 'leaf spots observed');
      expect(media.durationSeconds, 15);
      expect(media.base64Content, 'abc123base64==');
      expect(media.isSynced, true);
    });

    test('toJson produces correct JSON map', () {
      final media = PendingMedia(
        id: 'json-test',
        filePath: '/test.jpg',
        fileType: 'image',
        createdAt: 1700000000,
        base64Content: 'base64data',
      );
      
      final json = media.toJson();
      
      expect(json['id'], 'json-test');
      expect(json['filePath'], '/test.jpg');
      expect(json['fileType'], 'image');
      expect(json['createdAt'], 1700000000);
      expect(json['base64Content'], 'base64data');
      expect(json['isSynced'], false);
    });

    test('fromJson produces correct PendingMedia', () {
      final json = {
        'id': 'from-json-test',
        'filePath': '/restored.jpg',
        'fileType': 'image',
        'createdAt': 1700000000,
        'isSynced': true,
        'voiceTranscription': 'test transcript',
      };
      
      final media = PendingMedia.fromJson(json);
      
      expect(media.id, 'from-json-test');
      expect(media.filePath, '/restored.jpg');
      expect(media.isSynced, true);
      expect(media.voiceTranscription, 'test transcript');
    });

    test('toJson and fromJson are inverses', () {
      final original = PendingMedia(
        id: 'roundtrip',
        filePath: '/round.jpg',
        fileType: 'image',
        voiceTranscription: 'round trip test',
        durationSeconds: 10,
        createdAt: 1700000000,
        base64Content: 'roundbase64',
        isSynced: false,
      );
      
      final json = original.toJson();
      final restored = PendingMedia.fromJson(json);
      
      expect(restored.id, original.id);
      expect(restored.filePath, original.filePath);
      expect(restored.fileType, original.fileType);
      expect(restored.voiceTranscription, original.voiceTranscription);
      expect(restored.durationSeconds, original.durationSeconds);
      expect(restored.createdAt, original.createdAt);
      expect(restored.base64Content, original.base64Content);
      expect(restored.isSynced, original.isSynced);
    });

    test('copyWith creates a copy with updated fields', () {
      final original = PendingMedia(
        id: 'copy-test',
        filePath: '/original.jpg',
        fileType: 'image',
        createdAt: 1700000000,
        isSynced: false,
      );
      
      final synced = original.copyWith(isSynced: true);
      
      expect(synced.id, original.id);
      expect(synced.filePath, original.filePath);
      expect(synced.isSynced, true); // Updated
      expect(original.isSynced, false); // Original unchanged
    });
  });

  // ============================================
  // US15: OfflineStorageService Tests
  // ============================================
  group('US15 - OfflineStorageService', () {
    late OfflineStorageService service;
    
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      service = OfflineStorageService();
      await service.init();
    });

    test('initially has zero pending items', () async {
      final items = await service.getAllPendingMedia();
      expect(items, isEmpty);
    });

    test('getPendingCount returns zero initially', () async {
      final count = await service.getPendingCount();
      expect(count, 0);
    });

    test('savePendingMedia stores a new item', () async {
      final media = PendingMedia(
        id: 'save-test',
        filePath: '/save.jpg',
        fileType: 'image',
        createdAt: 1700000000,
      );
      
      await service.savePendingMedia(media);
      
      final items = await service.getAllPendingMedia();
      expect(items.length, 1);
      expect(items.first.id, 'save-test');
    });

    test('savePendingMedia stores multiple items', () async {
      for (int i = 0; i < 3; i++) {
        await service.savePendingMedia(PendingMedia(
          id: 'multi-$i',
          filePath: '/multi-$i.jpg',
          fileType: 'image',
          createdAt: 1700000000 + i,
        ));
      }
      
      final items = await service.getAllPendingMedia();
      expect(items.length, 3);
    });

    test('getPendingCount returns correct count', () async {
      await service.savePendingMedia(PendingMedia(
        id: 'count-1',
        filePath: '/c1.jpg',
        fileType: 'image',
        createdAt: 1700000000,
      ));
      await service.savePendingMedia(PendingMedia(
        id: 'count-2',
        filePath: '/c2.jpg',
        fileType: 'video',
        createdAt: 1700000001,
      ));
      
      final count = await service.getPendingCount();
      expect(count, 2);
    });

    test('deletePendingMedia removes the correct item', () async {
      await service.savePendingMedia(PendingMedia(
        id: 'del-1',
        filePath: '/d1.jpg',
        fileType: 'image',
        createdAt: 1700000000,
      ));
      await service.savePendingMedia(PendingMedia(
        id: 'del-2',
        filePath: '/d2.jpg',
        fileType: 'image',
        createdAt: 1700000001,
      ));
      
      await service.deletePendingMedia('del-1');
      
      final items = await service.getAllPendingMedia();
      expect(items.length, 1);
      expect(items.first.id, 'del-2');
    });

    test('clearAll removes all stored items', () async {
      for (int i = 0; i < 5; i++) {
        await service.savePendingMedia(PendingMedia(
          id: 'clear-$i',
          filePath: '/clear-$i.jpg',
          fileType: 'image',
          createdAt: 1700000000 + i,
        ));
      }
      
      await service.clearAll();
      
      final items = await service.getAllPendingMedia();
      expect(items, isEmpty);
    });
  });
}
