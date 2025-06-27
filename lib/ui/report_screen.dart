import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../models/session_summary.dart';
import '../models/behavior.dart';
import '../services/report_service.dart';

class ReportScreen extends StatefulWidget {
  final void Function(String sessionId, DateTime startTime)? onOpenSession;
  const ReportScreen({Key? key, this.onOpenSession}) : super(key: key);

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final ReportService _service = ReportService();
  final Set<String> _shownDates = {};

  List<SessionSummary> _sessions = [];
  String? _selectedSessionId;

  List<Behavior> _behaviors = [];
  List<double>  _averageValues = [];

  bool _loadingSessions    = true;
  bool _loadingBehaviors   = false;
  bool _loadingAverage     = true;
  bool _loadingMaintenance = false;

  double? _maintenanceScore;
  bool   _maintenanceReliable = true;

  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _loadingSessions = true);
    try {
      _sessions = await _service.fetchSessions();

      if (_sessions.isNotEmpty) {
        _selectedSessionId = _sessions.first.id;
        _behaviors = await _service.fetchBehaviors(_selectedSessionId!);
        _averageValues = await _computeAverage(_sessions);

        int totalMinutes = 0;
        for (final s in _sessions) {
          final detail = await _service.fetchSessionDetail(s.id);
          totalMinutes += detail.endTime.difference(detail.startTime).inMinutes;
        }

        final updatedUser = await _service.updateMaintenanceUrgency();
        _maintenanceScore = updatedUser.maintenanceUrgency;


        _maintenanceReliable = totalMinutes >= 30;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() {
        _loadingSessions = false;
        _loadingBehaviors = false;
        _loadingAverage = false;
        _loadingMaintenance = false;
      });
    }
  }

  Future<List<double>> _computeAverage(List<SessionSummary> sessions) async {
    final temp = <double>[];
    for (var s in sessions) {
      final bs = await _service.fetchBehaviors(s.id);
      if (bs.isEmpty) {
        temp.add(1.0);
      } else {
        final sum = bs.map((b) => b.numericValue).reduce((a, b) => a + b);
        temp.add(sum / bs.length);
      }
    }
    return temp;
  }

  Widget _singleSessionTab() {
    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
        itemCount: _sessions.length,
        separatorBuilder: (_, __) => const Divider(height: 1, thickness: 0.5),
        itemBuilder: (_, index) {
          final session = _sessions[index];
          return Material(
            color: Colors.white,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              title: Text(
                formatDateItalian(session.startTime),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                'Durata: ${session.endTime.difference(session.startTime).inMinutes} minuti',
                style: const TextStyle(fontWeight: FontWeight.w400),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {
                widget.onOpenSession?.call(session.id, session.startTime);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _averageSessionTab() {
    if (_loadingAverage) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_sessions.isEmpty) {
      return const Center(child: Text('Nessuna sessione.'));
    }
    if (_averageValues.isEmpty) {
      return const Center(child: Text('Nessun dato medio.'));
    }

    final ScrollController scrollController = ScrollController();
    final dateFormat = DateFormat('dd/MM');
    _shownDates.clear();

    final chartPoints = List<_AveragePoint>.generate(
      _sessions.length,
          (i) => _AveragePoint(
        x: i.toDouble(),
        y: _averageValues[i],
        date: _sessions[i].startTime,
      ),
    );

    final chartWidth = (_sessions.length * 50).clamp(300, 3000).toDouble();

    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: ListView(
        children: [
          const SizedBox(height: 36),
          Padding(
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
                          height: 500,
                          child: SfCartesianChart(
                            plotAreaBorderWidth: 1,
                            primaryXAxis: NumericAxis(
                              edgeLabelPlacement: EdgeLabelPlacement.shift,
                              interval: (_sessions.length > 5)
                                  ? (_sessions.length / 5).floorToDouble()
                                  : 1,
                              majorGridLines: const MajorGridLines(width: 0.5),
                              minorGridLines: const MinorGridLines(width: 0.25, dashArray: [2, 2]),
                              axisLine: const AxisLine(width: 1),
                              axisLabelFormatter: (args) {
                                final idx = args.value.round().clamp(0, _sessions.length - 1);
                                final formatted = dateFormat.format(_sessions[idx].startTime);
                                if (_shownDates.contains(formatted)) {
                                  return ChartAxisLabel('', const TextStyle(fontSize: 10));
                                } else {
                                  _shownDates.add(formatted);
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
                                  case 0: return ChartAxisLabel('CAUTO', const TextStyle(fontSize: 10));
                                  case 1: return ChartAxisLabel('NORMALE', const TextStyle(fontSize: 10));
                                  case 2: return ChartAxisLabel('AGGRESSIVO', const TextStyle(fontSize: 10));
                                  default: return ChartAxisLabel('', const TextStyle(fontSize: 10));
                                }
                              },
                            ),
                            series: <LineSeries<_AveragePoint, double>>[
                              LineSeries<_AveragePoint, double>(
                                dataSource: chartPoints,
                                xValueMapper: (d, _) => d.x,
                                yValueMapper: (d, _) => d.y,
                                color: Theme.of(context).primaryColor,
                                width: 1,
                                markerSettings: const MarkerSettings(isVisible: true),
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
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _maintenanceTab() {
    if (_loadingMaintenance) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_maintenanceScore == null) {
      return const Center(child: Text('Nessuna predizione manutenzione.'));
    }

    final pct = (_maintenanceScore! * 100).round();
    final score = _maintenanceScore!;
    final ThemeData theme = Theme.of(context);

    Color color;
    String label;
    IconData icon;

    if (score > 0.95) {
      color = Colors.red;
      label = 'Manutenzione urgente richiesta';
      icon = Icons.warning;
    } else if (score > 0.75) {
      color = Colors.orange;
      label = 'Manutenzione consigliata entro 7 giorni';
      icon = Icons.report_problem;
    } else {
      color = Colors.green;
      label = 'Manutenzione da eseguire come da programma';
      icon = Icons.check_circle;
    }

    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 36),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Center(
                        child: Card(
                          elevation: 6,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          color: const Color(0xFFFDFDFD),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Urgenza Manutenzione',
                                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w400),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 48),
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SizedBox(
                                      width: 160,
                                      height: 160,
                                      child: CircularProgressIndicator(
                                        value: score,
                                        strokeWidth: 14,
                                        color: color,
                                        backgroundColor: color.withOpacity(0.2),
                                      ),
                                    ),
                                    Text(
                                      '$pct%',
                                      style: theme.textTheme.headlineMedium?.copyWith(color: color, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 32),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(icon, color: color),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        label,
                                        style: theme.textTheme.bodyLarge?.copyWith(color: color, fontWeight: FontWeight.w500),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                                if (!_maintenanceReliable) ...[
                                  const SizedBox(height: 32),
                                  Card(
                                    color: Colors.orange.shade50,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: const BorderSide(color: Colors.orange, width: 1),
                                    ),
                                    elevation: 0,
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.info_outline, color: Colors.orange),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              'Predizione non affidabile: le sessioni totali sono troppo brevi per un’analisi accurata.',
                                              style: TextStyle(
                                                color: Colors.orange.shade800,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          );
        },
      ),

    );
  }


  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Report'),
          centerTitle: true,
          elevation: 0,
          bottom: const TabBar(tabs: [
            Tab(text: 'Sessioni'),
            Tab(text: 'Stile medio'),
            Tab(text: 'Manutenzione'),
          ]),
        ),
        body: TabBarView(
          children: [
            _singleSessionTab(),
            _averageSessionTab(),
            _maintenanceTab(),
          ],
        ),
      ),
    );
  }
  String formatDateItalian(DateTime date) {
    final days = ['Lunedì', 'Martedì', 'Mercoledì', 'Giovedì', 'Venerdì', 'Sabato', 'Domenica'];
    final months = ['Gen', 'Feb', 'Mar', 'Apr', 'Mag', 'Giu', 'Lug', 'Ago', 'Set', 'Ott', 'Nov', 'Dic'];

    final dayName = days[date.weekday - 1];
    final monthName = months[date.month - 1];

    return '$dayName ${date.day} $monthName ${date.year} – ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _AveragePoint {
  final double x;
  final double y;
  final DateTime date;

  _AveragePoint({required this.x, required this.y, required this.date});
}