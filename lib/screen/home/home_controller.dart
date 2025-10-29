import 'dart:async';
import 'package:back_test_strategy/constants/api_constants.dart';
import 'package:back_test_strategy/models/candel_models.dart';
import 'package:back_test_strategy/services/api_service.dart';
import 'package:get/get.dart';


class HomeController extends GetxController {
  final ApiService _apiService = ApiService();

  // Full dataset from API
  final RxList<Candle> candles = <Candle>[].obs;

  // Candles currently visible on chart (grows as replay progresses or on scrub)
  final RxList<Candle> visibleCandles = <Candle>[].obs;

  final isLoading = false.obs;
  final errorMessage = ''.obs;

  // Replay state
  final isPlaying = false.obs;
  final currentIndex = 0.obs; // index in candles
  final playbackSpeed = 1.0.obs; // 0.5x, 1x, 2x, 4x
  Timer? _replayTimer;

  @override
  void onInit() {
    super.onInit();
    fetchCandles();
  }

  @override
  void onClose() {
    _stopReplayTimer();
    super.onClose();
  }

  Future<void> fetchCandles() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final response = await _apiService.getRequest(ApiConstants.historicalCandle);
      if (response?.statusCode == 200) {
        final data = response?.data;
        final List<dynamic> arr = data != null && data['data'] != null && data['data']['candles'] != null
            ? List<dynamic>.from(data['data']['candles'] as List)
            : <dynamic>[];

        final parsed = arr.map((e) {
          try {
            return Candle.fromList(e as List<dynamic>);
          } catch (ex) {
            return null;
          }
        }).whereType<Candle>().toList();

        candles.assignAll(parsed);
        // initialize visibleCandles with a small window or first candle
        if (candles.isNotEmpty) {
          currentIndex.value = 0;
          visibleCandles.assignAll([candles[0]]);
        }
      } else {
        errorMessage.value = 'Failed: ${response?.statusCode}';
      }
    } catch (e) {
      errorMessage.value = 'Error fetching candles: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // Start replay from currentIndex (if at end, reset to 0 first)
  void play() {
    if (candles.isEmpty) return;
    if (currentIndex.value >= candles.length - 1) {
      currentIndex.value = 0;
      visibleCandles.assignAll([candles[0]]);
    }
    isPlaying.value = true;
    _startReplayTimer();
  }

  void pause() {
    isPlaying.value = false;
    _stopReplayTimer();
  }

  void togglePlayPause() {
    if (isPlaying.value) {
      pause();
    } else {
      play();
    }
  }

  void _startReplayTimer() {
    _stopReplayTimer();
    // baseDelayMs controls base speed; lower = faster playback
    const int baseDelayMs = 800; // base delay for 1x
    final int delay = (baseDelayMs / playbackSpeed.value).round();
    _replayTimer = Timer.periodic(Duration(milliseconds: delay), (timer) {
      if (currentIndex.value < candles.length - 1) {
        currentIndex.value++;
        _updateVisibleForIndex(currentIndex.value);
      } else {
        // stop when finished
        pause();
      }
    });
  }

  void _stopReplayTimer() {
    _replayTimer?.cancel();
    _replayTimer = null;
  }

  // Set playback speed (e.g., 0.5, 1, 2, 4)
  void setPlaybackSpeed(double speed) {
    playbackSpeed.value = speed;
    if (isPlaying.value) {
      // restart timer with new interval
      _startReplayTimer();
    }
  }

  // Scrub / slider set
  void seekToIndex(int idx) {
    if (candles.isEmpty) return;
    final clamped = idx.clamp(0, candles.length - 1);
    currentIndex.value = clamped;
    _updateVisibleForIndex(clamped);
  }

  void _updateVisibleForIndex(int idx) {
    // For better UX we can show a window of candles (e.g., last N candles) or show all from start
    // We'll show all candles up to idx to mimic replay growth
    visibleCandles.assignAll(candles.sublist(0, idx + 1));
  }
}
