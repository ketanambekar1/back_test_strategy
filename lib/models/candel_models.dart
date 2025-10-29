class Candle {
  final DateTime time;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  Candle({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  factory Candle.fromList(List<dynamic> json) {
    return Candle(
      time: DateTime.parse(json[0] as String),
      open: (json[1] as num).toDouble(),
      high: (json[2] as num).toDouble(),
      low: (json[3] as num).toDouble(),
      close: (json[4] as num).toDouble(),
      volume: (json[5] as num).toDouble(),
    );
  }
}
