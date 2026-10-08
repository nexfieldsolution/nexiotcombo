import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:nexiotcombo/constants.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({Key? key}) : super(key: key);

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  // ── 임시 데이터 ────────────────────────────────────────
  static const int _total = 100;
  static const int _normal = 98;
  static const int _fault = 1;
  static const int _maintenance = 1;

  static const double _logRowHeight = 41.0;
  static const int _logsPerPage = 5;

  static const _recentLogs = [
    _LogEntry('0023', '2026-10-08 12:01', true),
    _LogEntry('0047', '2026-10-08 11:58', true),
    _LogEntry('0012', '2026-10-08 11:55', false),
    _LogEntry('0061', '2026-10-08 11:50', true),
    _LogEntry('0005', '2026-10-08 11:44', false),
    _LogEntry('0023', '2026-10-08 12:01', true),
    _LogEntry('0047', '2026-10-08 11:58', true),
    _LogEntry('0012', '2026-10-08 11:55', false),
    _LogEntry('0061', '2026-10-08 11:50', true),
    _LogEntry('0005', '2026-10-08 11:44', false),
    _LogEntry('0023', '2026-10-08 12:01', true),
    _LogEntry('0047', '2026-10-08 11:58', true),
    _LogEntry('0012', '2026-10-08 11:55', false),
    _LogEntry('0061', '2026-10-08 11:50', true),
    _LogEntry('0005', '2026-10-08 11:44', false),
    _LogEntry('0023', '2026-10-08 12:01', true),
    _LogEntry('0047', '2026-10-08 11:58', true),
    _LogEntry('0012', '2026-10-08 11:55', false),
    _LogEntry('0061', '2026-10-08 11:50', true),
    _LogEntry('0005', '2026-10-08 11:44', false),
    _LogEntry('0023', '2026-10-08 12:01', true),
    _LogEntry('0047', '2026-10-08 11:58', true),
    _LogEntry('0012', '2026-10-08 11:55', false),
    _LogEntry('0061', '2026-10-08 11:50', true),
    _LogEntry('0005', '2026-10-08 11:44', false),
    _LogEntry('0023', '2026-10-08 12:01', true),
    _LogEntry('0047', '2026-10-08 11:58', true),
    _LogEntry('0012', '2026-10-08 11:55', false),
    _LogEntry('0061', '2026-10-08 11:50', true),
    _LogEntry('0005', '2026-10-08 11:44', false),
  ];

  int get _totalPages => (_recentLogs.length / _logsPerPage).ceil();

  int _currentPage = 0;
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    const pageHeight = _logsPerPage * _logRowHeight;
    final page = (_scrollCtrl.offset / pageHeight).floor()
        .clamp(0, _totalPages - 1);
    if (page != _currentPage) setState(() => _currentPage = page);
  }

  void _goPage(int delta) {
    const pageHeight = _logsPerPage * _logRowHeight;
    final target = ((_currentPage + delta) * pageHeight)
        .clamp(0.0, _scrollCtrl.position.maxScrollExtent);
    _scrollCtrl.animateTo(target,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── 파이차트 영역 — 유동 높이 ────────────────────
        Expanded(
          flex: 35,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, defaultPadding),
            child: Row(
              children: [
                Expanded(child: _buildPieChart()),
                const SizedBox(width: 8),
                _buildLegend(),
              ],
            ),
          ),
        ),
        // ── 통계 카드 — 고정 높이 ─────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: defaultPadding, vertical: 10),
          child: _buildStatsRow(),
        ),
        // ── 최종 접속 기록 — 유동 높이 ───────────────────
        Expanded(
          flex: 65,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                defaultPadding, 0, defaultPadding, defaultPadding),
            child: Container(
              decoration: BoxDecoration(
                color: secondaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 타이틀 + 페이지 네비게이션 — 스크롤 고정
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 8, 8),
                    child: Row(
                      children: [
                        Text(
                          'summary.recent_connections'.tr(),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        _pageArrow(Icons.keyboard_arrow_up,
                            _currentPage > 0 ? () => _goPage(-1) : null),
                        const SizedBox(width: 6),
                        Text(
                          '${_currentPage + 1} / $_totalPages',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12),
                        ),
                        const SizedBox(width: 6),
                        _pageArrow(Icons.keyboard_arrow_down,
                            _currentPage < _totalPages - 1
                                ? () => _goPage(1)
                                : null),
                        const SizedBox(width: 4),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white12, height: 1),
                  // 로그 목록 — 스크롤
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollCtrl,
                      itemCount: _recentLogs.length,
                      itemExtent: _logRowHeight,
                      itemBuilder: (_, i) => _logRow(_recentLogs[i]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _pageArrow(IconData icon, VoidCallback? onTap) {
    final active = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          border: Border.all(
              color: active ? Colors.white38 : Colors.white12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon,
            size: 16,
            color: active ? Colors.white70 : Colors.white24),
      ),
    );
  }

  // ── 파이 차트 ──────────────────────────────────────────
  Widget _buildPieChart() => LayoutBuilder(
        builder: (context, constraints) {
          final spaceRadius =
              (constraints.maxHeight * 0.35).clamp(20.0, 65.0);
          return Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: spaceRadius,
                  sections: [
                    PieChartSectionData(
                      value: _normal.toDouble(),
                      color: const Color(0xFF00C897),
                      radius: 30,
                      showTitle: false,
                    ),
                    PieChartSectionData(
                      value: _fault.toDouble(),
                      color: Colors.redAccent,
                      radius: 30,
                      showTitle: false,
                    ),
                    PieChartSectionData(
                      value: _maintenance.toDouble(),
                      color: const Color(0xFFFFB800),
                      radius: 30,
                      showTitle: false,
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(_normal / _total * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'summary.normal_rate'.tr(),
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ],
          );
        },
      );

  // ── 범례 ──────────────────────────────────────────────
  Widget _buildLegend() => Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const SizedBox(height: 8),
            _legend(const Color(0xFF00C897), 'summary.normal'.tr()),
            const SizedBox(height: 8),
            _legend(Colors.redAccent, 'summary.fault'.tr()),
            const SizedBox(height: 8),
            _legend(const Color(0xFFFFB800), 'summary.maintenance'.tr()),
          ],
        ),
      );

  Widget _legend(Color color, String label) => Row(
        children: [
          Container(
              width: 10,
              height: 10,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.white54, fontSize: 12)),
        ],
      );

  // ── 운영 통계 카드 ────────────────────────────────────
  Widget _buildStatsRow() => Row(
        children: [
          _statCard('summary.total'.tr(), _total, Colors.white70),
          const SizedBox(width: 8),
          _statCard('summary.normal'.tr(), _normal, const Color(0xFF00C897)),
          const SizedBox(width: 8),
          _statCard('summary.fault'.tr(), _fault, Colors.redAccent),
          const SizedBox(width: 8),
          _statCard('summary.maintenance'.tr(), _maintenance,
              const Color(0xFFFFB800)),
        ],
      );

  Widget _statCard(String label, int value, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: secondaryColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(
                '$value',
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 11)),
            ],
          ),
        ),
      );

  Widget _logRow(_LogEntry log) => Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: log.connected
                        ? const Color(0xFF00C897)
                        : Colors.redAccent,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'ID: ${log.deviceId}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  log.time,
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
        ],
      );
}

class _LogEntry {
  final String deviceId;
  final String time;
  final bool connected;
  const _LogEntry(this.deviceId, this.time, this.connected);
}
