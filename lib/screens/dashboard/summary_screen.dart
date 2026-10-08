import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:nexiotcombo/constants.dart';

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({Key? key}) : super(key: key);

  // ── 임시 데이터 ────────────────────────────────────────
  static const int _total = 100;
  static const int _normal = 98;
  static const int _fault = 1;
  static const int _maintenance = 1;

  static const _recentLogs = [
    _LogEntry('0023', '2026-10-08 12:01', true),
    _LogEntry('0047', '2026-10-08 11:58', true),
    _LogEntry('0012', '2026-10-08 11:55', false),
    _LogEntry('0061', '2026-10-08 11:50', true),
    _LogEntry('0005', '2026-10-08 11:44', false),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(defaultPadding),
      child: Column(
        children: [
          // ── 파이 차트 ──────────────────────────────────
          _buildPieSection(),
          const SizedBox(height: defaultPadding),
          // ── 운영 통계 카드 ─────────────────────────────
          _buildStatsRow(),
          const SizedBox(height: defaultPadding),
          // ── 최종 접속 기록 ─────────────────────────────
          _buildRecentLogs(),
        ],
      ),
    );
  }

  // ── 파이 차트 섹션 ────────────────────────────────────
  Widget _buildPieSection() {
    return Column(
      children: [
        Text(
          'summary.operation_rate'.tr(),
          style: const TextStyle(
              color: Colors.white70, fontSize: 13),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 60,
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
          ),
        ),
        const SizedBox(height: 12),
        // 범례
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legend(const Color(0xFF00C897), 'summary.normal'.tr()),
            const SizedBox(width: 16),
            _legend(Colors.redAccent, 'summary.fault'.tr()),
            const SizedBox(width: 16),
            _legend(const Color(0xFFFFB800), 'summary.maintenance'.tr()),
          ],
        ),
      ],
    );
  }

  Widget _legend(Color color, String label) => Row(
        children: [
          Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                  color: color, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.white54, fontSize: 12)),
        ],
      );

  // ── 운영 통계 카드 ────────────────────────────────────
  Widget _buildStatsRow() {
    return Row(
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
  }

  Widget _statCard(String label, int value, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
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
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 11)),
            ],
          ),
        ),
      );

  // ── 최종 접속 기록 ────────────────────────────────────
  Widget _buildRecentLogs() {
    return Container(
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Text(
              'summary.recent_connections'.tr(),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          ..._recentLogs.map((log) => _logRow(log)),
        ],
      ),
    );
  }

  Widget _logRow(_LogEntry log) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
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
