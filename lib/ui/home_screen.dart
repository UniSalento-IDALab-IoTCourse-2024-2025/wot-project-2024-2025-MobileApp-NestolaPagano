import 'package:app/ui/session_detail_screen.dart';
import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'report_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  String? _selectedSessionId;
  DateTime? _selectedStartTime;

  void _openSessionDetail(String sessionId, DateTime startTime) {
    setState(() {
      _selectedSessionId = sessionId;
      _selectedStartTime = startTime;
      _currentIndex = 1;
    });
  }

  void _closeSessionDetail() {
    setState(() {
      _selectedSessionId = null;
      _selectedStartTime = null;
    });
  }


  late final List<Widget> _basePages;

  @override
  void initState() {
    super.initState();
    _basePages = [
      const SensorDashboard(),
      _buildReportPage(),
      const ProfileScreen(),
    ];
  }

  Widget _buildReportPage() {
    if (_selectedSessionId != null && _selectedStartTime != null) {
      return SessionDetailScreen(
        sessionId: _selectedSessionId!,
        startTime: _selectedStartTime!,
        onBack: _closeSessionDetail,
      );
    } else {
      return ReportScreen(
        onOpenSession: _openSessionDetail,
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _basePages[0],
          _buildReportPage(),
          _basePages[2],
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (int idx) {
          setState(() {
            _currentIndex = idx;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Report',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profilo',
          ),
        ],
      ),
    );
  }
}