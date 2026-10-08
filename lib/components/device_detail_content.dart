import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:nexiotcombo/constants.dart';

class DeviceDetailContent extends StatelessWidget {
  const DeviceDetailContent({
    Key? key,
    required this.deviceId,
    required this.onClose,
  }) : super(key: key);

  final String deviceId;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── 서브 헤더 ──────────────────────────────────────
        Container(
          color: secondaryColor,
          padding: const EdgeInsets.symmetric(
              horizontal: defaultPadding, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.monitor, color: accentColor, size: 18),
              const SizedBox(width: 8),
              Text(
                'device.detail_title'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onClose,
                child: Image.asset('assets/icons/ic_nav_back.png',
                    width: 28, height: 28),
              ),
            ],
          ),
        ),
        // ── 본문 ──────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 디바이스 ID 카드
                _infoCard(
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'device.node_label'.tr(),
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 11),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ID: $deviceId',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _labelChip('BLE'),
                              const SizedBox(width: 6),
                              _labelChip('WiFi'),
                            ],
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white12),
                        ),
                        child: const Icon(Icons.sensors,
                            color: Colors.white38, size: 24),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 센서 데이터 3열
                Row(
                  children: [
                    Expanded(
                        child: _sensorCard(
                            Icons.thermostat_outlined, '--.-', '°C',
                            'device.temperature'.tr())),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _sensorCard(
                            Icons.water_drop_outlined, '--', '%',
                            'device.humidity'.tr())),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _sensorCard(
                            Icons.battery_full_outlined, '--.-', 'V',
                            'device.voltage'.tr())),
                  ],
                ),
                const SizedBox(height: 12),

                // 상태 정보
                _infoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('device.status'.tr(),
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                              child: _statusRow(Icons.bluetooth,
                                  'device.ble_status'.tr(), '--')),
                          Expanded(
                              child: _statusRow(Icons.timer_outlined,
                                  'device.uptime'.tr(), '--')),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 차트 플레이스홀더
                _infoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('device.realtime_trend'.tr(),
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12)),
                      const SizedBox(height: 12),
                      Container(
                        height: 120,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text('Chart',
                              style: TextStyle(
                                  color: Colors.white24, fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 액션 버튼들
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.6,
                  children: [
                    _actionBtn(Icons.settings_outlined,
                        'device.action_settings'.tr(), accentBlueColor),
                    _actionBtn(Icons.tune_outlined,
                        'device.action_control'.tr(), accentBlueColor),
                    _actionBtn(Icons.restart_alt_outlined,
                        'device.action_reset'.tr(), Colors.redAccent),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoCard({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: secondaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: child,
      );

  Widget _sensorCard(
          IconData icon, String value, String unit, String label) =>
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: secondaryColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: accentColor),
            const SizedBox(height: 6),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                        color: accentColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: ' $unit',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(label,
                style:
                    const TextStyle(color: Colors.white38, fontSize: 10)),
          ],
        ),
      );

  Widget _statusRow(IconData icon, String label, String value) => Row(
        children: [
          Icon(icon, size: 14, color: Colors.white38),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 10)),
              Text(value,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      );

  Widget _actionBtn(IconData icon, String label, Color color) =>
      Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );

  Widget _labelChip(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white24),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(text,
            style: const TextStyle(color: Colors.white38, fontSize: 10)),
      );
}
