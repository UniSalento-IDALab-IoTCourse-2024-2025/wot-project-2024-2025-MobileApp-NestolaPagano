import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../models/behavior.dart';
import '../services/report_service.dart';

class SessionDetailScreen extends StatefulWidget {
  final String sessionId;
  final DateTime startTime;

  final void Function()? onBack;

  SessionDetailScreen({
    Key? key,
    required this.sessionId,
    required this.startTime,
    this.onBack,
  }) : super(key: key);

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  final ReportService _service = ReportService();
  List<Behavior> _behaviors = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBehaviors();
  }

  Future<void> _loadBehaviors() async {
    try {
      final list = await _service.fetchBehaviors(widget.sessionId);
      setState(() {
        _behaviors = list;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Andamento stile di guida"),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey.shade300,
            height: 1.0,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildChart(),
    );
  }

  Widget _buildChart() {
    if (_behaviors.isEmpty) {
      return const Center(child: Text("Nessuna predizione."));
    }

    final points = List<_BehaviorPoint>.generate(
      _behaviors.length,
          (i) {
        final b = _behaviors[i];
        final x = i.toDouble();
        return _BehaviorPoint(x, b.numericValue, timestamp: b.timestamp);
      },
    );

    final chartWidth = (_behaviors.length * 40).clamp(300, 3000).toDouble();
    final ScrollController scrollController = ScrollController();
    final shownTimes = <String>{};
    final timeFormat = DateFormat.Hm();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Card(
          color: const Color(0xFFFDFDFD),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: ScrollbarTheme(
              data: ScrollbarThemeData(
                thumbColor: WidgetStateProperty.all(Colors.grey.shade400),
                trackColor: WidgetStateProperty.all(Colors.grey.shade200),
                radius: const Radius.circular(12),
                thickness: WidgetStateProperty.all(6),
              ),
              child: Scrollbar(
                controller: scrollController,
                thumbVisibility: true,
                trackVisibility: true,
                thickness: 3,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  controller: scrollController,
                  child: SizedBox(
                    width: chartWidth,
                    height: 550,
                    child: SfCartesianChart(
                      plotAreaBorderWidth: 1,
                      primaryXAxis: NumericAxis(
                        edgeLabelPlacement: EdgeLabelPlacement.shift,
                        interval: (_behaviors.length > 5)
                            ? (_behaviors.length / 5).floorToDouble()
                            : 1,
                        majorGridLines: const MajorGridLines(width: 0.5),
                        minorGridLines: const MinorGridLines(width: 0.25, dashArray: [2, 2]),
                        axisLine: const AxisLine(width: 1),
                        axisLabelFormatter: (args) {
                          final idx = args.value.round().clamp(0, _behaviors.length - 1);
                          final dt = _behaviors[idx].timestamp.subtract(const Duration(hours: 2));
                          final formatted = timeFormat.format(dt);
                          if (shownTimes.contains(formatted)) {
                            return ChartAxisLabel('', const TextStyle(fontSize: 10));
                          } else {
                            shownTimes.add(formatted);
                            return ChartAxisLabel(formatted, const TextStyle(fontSize: 10));
                          }
                        },
                      ),
                      primaryYAxis: NumericAxis(
                        minimum: 0,
                        maximum: 2,
                        interval: 1,
                        majorGridLines: const MajorGridLines(width: 0.5),
                        minorGridLines: const MinorGridLines(width: 0.25, dashArray: [2, 2]),
                        axisLine: const AxisLine(width: 1),
                        axisLabelFormatter: (args) {
                          switch (args.value.toInt()) {
                            case 0:
                              return ChartAxisLabel('CAUTO', const TextStyle(fontSize: 10));
                            case 1:
                              return ChartAxisLabel('NORMALE', const TextStyle(fontSize: 10));
                            case 2:
                              return ChartAxisLabel('AGGRESSIVO', const TextStyle(fontSize: 10));
                            default:
                              return ChartAxisLabel('', const TextStyle(fontSize: 10));
                          }
                        },
                      ),
                      series: <LineSeries<_BehaviorPoint, double>>[
                        LineSeries<_BehaviorPoint, double>(
                          dataSource: points,
                          xValueMapper: (d, _) => d.x,
                          yValueMapper: (d, _) => d.y,
                          color: Theme.of(context).primaryColor,
                          width: 1,
                          markerSettings: const MarkerSettings(isVisible: false),
                          dataLabelSettings: const DataLabelSettings(isVisible: false),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BehaviorPoint {
  final double x;
  final double y;
  final DateTime timestamp;

  _BehaviorPoint(this.x, this.y, {required this.timestamp});
}