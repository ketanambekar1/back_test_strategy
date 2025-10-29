import 'package:back_test_strategy/screen/home/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'trading_view_chart.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    // Put the controller (will call fetch on init)
    Get.put(HomeController());

    return const TradingViewChart();
  }
}
