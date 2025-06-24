import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/session_summary.dart';
import '../models/behavior.dart';
import '../services/report_service.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({Key? key}) : super(key: key);

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final ReportService _service = ReportService();

  List<SessionSummary> _sessions = [];
  String? _selectedSessionId;
  List<Behavior> _behaviors = [];

  bool _loadingSessions = true;
  bool _loadingBehaviors = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() => _loadingSessions = true);
    try {
      final list = await _service.fetchSessions();
      setState(() {
        _sessions = list;
        if (list.isNotEmpty) {
          _selectedSessionId = list.first.id;
          _loadBehaviors(list.first.id);
        }
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loadingSessions = false);
    }
  }

  Future<void> _loadBehaviors(String sessionId) async {
    setState(() {
      _selectedSessionId = sessionId;
      _loadingBehaviors = true;
      _behaviors = [];
    });
    try {
      final list = await _service.fetchBehaviors(sessionId);
      setState(() => _behaviors = list);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loadingBehaviors = false);
    }
  }

  Widget _buildChartOrMessage() {
    if (_loadingBehaviors) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_behaviors.isEmpty) {
      return const Center(child: Text('Nessuna predizione.'));
    }

    return SizedBox(
      height: 300,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 2,
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                interval: (_behaviors.length > 5)
                    ? (_behaviors.length / 5)
                    : 1,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt().clamp(0, _behaviors.length - 1);
                  final dt = _behaviors[idx].timestamp.toLocal();
                  final txt = '${dt.hour}:${dt.minute.toString().padLeft(2,'0')}';
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Transform.rotate(
                      angle: -1.5708, // -90°
                      child: Text(txt, style: const TextStyle(fontSize: 10)),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 60,
                getTitlesWidget: (value, meta) {
                  const style = TextStyle(fontSize: 9);
                  Widget txt;
                  switch (value.toInt()) {
                    case 0:
                      txt = const Text('CAUTO', style: style);
                      break;
                    case 1:
                      txt = const Text('NORMALE', style: style);
                      break;
                    case 2:
                      txt = const Text('AGGRESSIVO', style: style);
                      break;
                    default:
                      txt = const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Transform.rotate(
                      angle: -1.5708, // -90°
                      child: txt,
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(_behaviors.length, (i) {
                return FlSpot(i.toDouble(), _behaviors[i].numericValue.toDouble());
              }),
              isCurved: false,
              barWidth: 2,
              color: Colors.blueAccent,
              dotData: FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Sessioni'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadSessions,
        child: _error != null
            ? Center(child: Text('Errore: $_error'))
            : _loadingSessions && _sessions.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            if (_sessions.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Nessuna sessione trovata.'),
              )
            else
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButton<String>(
                      value: _selectedSessionId,
                      items: _sessions
                          .map((s) => DropdownMenuItem(
                        value: s.id,
                        child: Text(
                          '${s.startTime.toLocal()} → ${s.endTime.toLocal()}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ))
                          .toList(),
                      onChanged: (id) {
                        if (id != null) _loadBehaviors(id);
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(height: 300, child: _buildChartOrMessage()),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}