import 'package:back_test_strategy/models/candel_models.dart';
import 'package:back_test_strategy/screen/home/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class TradingViewChart extends StatelessWidget {
  const TradingViewChart({super.key});

  @override
  Widget build(BuildContext context) {
    final HomeController controller = Get.find<HomeController>();

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(controller),
            Expanded(child: _buildChart(controller)),
            _buildReplayControls(controller),
          ],
        ),
      ),
    );
  }

  // 🔹 TOP BAR
  Widget _buildTopBar(HomeController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: const Color(0xFF0E0E0E),
      child: Row(
        children: [
          const Text(
            'TradingView Replica',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Obx(() {
            if (controller.candles.isEmpty) return const SizedBox();
            final dt = controller.candles[controller.currentIndex.value].time;
            return Text(
              '${dt.toLocal()}'.split('.')[0],
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            );
          }),
        ],
      ),
    );
  }

  // 🔹 MAIN CHART
  Widget _buildChart(HomeController controller) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator(color: Colors.white));
      }

      if (controller.errorMessage.isNotEmpty) {
        return Center(
          child: Text(controller.errorMessage.value,
              style: const TextStyle(color: Colors.redAccent)),
        );
      }

      if (controller.visibleCandles.isEmpty) {
        return const Center(
            child: Text('No candle data', style: TextStyle(color: Colors.white)));
      }

      // Ensure left → right chronological order
      final List<Candle> data = controller.visibleCandles
          .where((c) =>
      c.time != null &&
          c.open != null &&
          c.high != null &&
          c.low != null &&
          c.close != null &&
          c.volume != null)
          .toList()
        ..sort((a, b) => a.time.compareTo(b.time));

      final double maxVolume =
      data.map((e) => e.volume).reduce((a, b) => a > b ? a : b).toDouble();

      return SfCartesianChart(
        backgroundColor: const Color(0xFF0E0E0E),
        plotAreaBorderWidth: 0,
        enableAxisAnimation: true,

        // X Axis - proper date & zoomable
        primaryXAxis: DateTimeAxis(
          // dateFormat: DateFormat.y(), // show time properly
          intervalType: DateTimeIntervalType.minutes,
          majorGridLines: const MajorGridLines(width: 0.2, color: Colors.white12),
          axisLine: const AxisLine(width: 0.5, color: Colors.white24),
          labelStyle: const TextStyle(color: Colors.white70, fontSize: 10),
          rangePadding: ChartRangePadding.none,
          labelRotation: -45,
        ),

        // Y Axis - price
        primaryYAxis: NumericAxis(
          opposedPosition: true,
          majorGridLines: const MajorGridLines(width: 0.3, color: Colors.white12),
          labelStyle: const TextStyle(color: Colors.white70, fontSize: 10),
          axisLine: const AxisLine(width: 0.5, color: Colors.white24),
        ),

        // Volume Axis
        axes: <ChartAxis>[
          NumericAxis(
            name: 'volumeAxis',
            isVisible: false,
            opposedPosition: true,
            minimum: 0,
            maximum: maxVolume,
          )
        ],

        // 🟢 Series
        series: <CartesianSeries>[
          CandleSeries<Candle, DateTime>(
            name: 'Candles',
            dataSource: data,
            xValueMapper: (Candle c, _) => c.time,
            lowValueMapper: (Candle c, _) => c.low,
            highValueMapper: (Candle c, _) => c.high,
            openValueMapper: (Candle c, _) => c.open,
            closeValueMapper: (Candle c, _) => c.close,
            bearColor: const Color(0xFFE74C3C),
            bullColor: const Color(0xFF27AE60),
            enableSolidCandles: true,
            animationDuration: 0,
            opacity: 0.9,
          ),
          ColumnSeries<Candle, DateTime>(
            name: 'Volume',
            yAxisName: 'volumeAxis',
            dataSource: data,
            xValueMapper: (Candle c, _) => c.time,
            yValueMapper: (Candle c, _) => c.volume,
            pointColorMapper: (Candle c, _) => (c.close >= c.open)
                ? const Color(0xFF2ECC71).withOpacity(0.5)
                : const Color(0xFFE74C3C).withOpacity(0.5),
            width: 0.8,
            spacing: 0,
          ),
        ],

        // 🧭 Chart Interactions
        zoomPanBehavior: ZoomPanBehavior(
          enablePanning: true,
          enablePinching: true,
          enableDoubleTapZooming: true,
          enableMouseWheelZooming: true,
          zoomMode: ZoomMode.x,
        ),

        trackballBehavior: TrackballBehavior(
          enable: true,
          activationMode: ActivationMode.singleTap,
          tooltipAlignment: ChartAlignment.near,
          tooltipDisplayMode: TrackballDisplayMode.groupAllPoints,
          tooltipSettings: const InteractiveTooltip(
            enable: true,
            color: Colors.black87,
            textStyle: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      );
    });
  }

  // 🔹 REPLAY CONTROLS
  Widget _buildReplayControls(HomeController controller) {
    return Container(
      color: const Color(0xFF0E0E0E),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Obx(() => IconButton(
                onPressed: controller.togglePlayPause,
                icon: Icon(
                  controller.isPlaying.value
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_fill,
                  color: Colors.white,
                  size: 32,
                ),
              )),
              IconButton(
                onPressed: () {
                  controller.pause();
                  controller.seekToIndex(0);
                },
                icon: const Icon(Icons.first_page, color: Colors.white),
              ),
              IconButton(
                onPressed: () {
                  controller.pause();
                  controller.seekToIndex(controller.candles.length - 1);
                },
                icon: const Icon(Icons.last_page, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Obx(() {
                final sp = controller.playbackSpeed.value;
                return DropdownButton<double>(
                  dropdownColor: Colors.grey[900],
                  value: sp,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(
                        value: 0.5,
                        child: Text('0.5x', style: TextStyle(color: Colors.white))),
                    DropdownMenuItem(
                        value: 1.0,
                        child: Text('1x', style: TextStyle(color: Colors.white))),
                    DropdownMenuItem(
                        value: 2.0,
                        child: Text('2x', style: TextStyle(color: Colors.white))),
                    DropdownMenuItem(
                        value: 4.0,
                        child: Text('4x', style: TextStyle(color: Colors.white))),
                  ],
                  onChanged: (v) {
                    if (v != null) controller.setPlaybackSpeed(v);
                  },
                );
              }),
              const Spacer(),
              Obx(() {
                if (controller.candles.isEmpty) return const SizedBox();
                return Text(
                  '${controller.currentIndex.value + 1}/${controller.candles.length}',
                  style: const TextStyle(color: Colors.white70),
                );
              }),
            ],
          ),
          Obx(() {
            final total = controller.candles.isNotEmpty
                ? controller.candles.length - 1
                : 0;
            final cur =
            controller.currentIndex.value.toDouble().clamp(0.0, total.toDouble());
            return Slider.adaptive(
              min: 0,
              max: total <= 0 ? 1 : total.toDouble(),
              value: cur,
              onChanged: (v) {
                controller.pause();
                controller.seekToIndex(v.round());
              },
              activeColor: Colors.white,
              inactiveColor: Colors.white24,
            );
          }),
        ],
      ),
    );
  }
}
