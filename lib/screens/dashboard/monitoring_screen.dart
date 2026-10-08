import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nexiotcombo/constants.dart';

class MonitoringScreen extends StatefulWidget {
  const MonitoringScreen({Key? key, this.onDeviceSelected}) : super(key: key);

  final ValueChanged<String>? onDeviceSelected;

  @override
  State<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen> {
  bool _summaryMode = false;
  int _currentPage = 0;
  double _cardRowHeight = 0;

  final ScrollController _scrollCtrl = ScrollController();

  final List<_DeviceState> _devices = List.generate(
    65,
    (i) => _DeviceState(id: (i + 1).toString().padLeft(4, '0')),
  );

  int get _itemsPerPage => _summaryMode ? badgePerSummaryPage : cardsPerSummaryPage;
  // 전체 페이지: 전체 항목 / 페이지당 항목
  int get _totalPages => (_devices.length / _itemsPerPage).ceil();

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
    if (_cardRowHeight <= 0) return;
    // 2열이므로 페이지당 cardsPerSummaryPage/2 행
    final rowsPerPage = _itemsPerPage ~/ 2;
    final pageHeight = rowsPerPage * _cardRowHeight;
    final page = (_scrollCtrl.offset / pageHeight).floor();
    final clamped = page.clamp(0, _totalPages - 1);
    if (clamped != _currentPage) setState(() => _currentPage = clamped);
  }

  void _toggleMode(bool compact) {
    _scrollCtrl.jumpTo(0);
    setState(() {
      _summaryMode = compact;
      _currentPage = 0;
    });
  }

  void _goPage(int delta) {
    if (_cardRowHeight <= 0) return;
    final rowsPerPage = _itemsPerPage ~/ 2;
    final pageHeight = rowsPerPage * _cardRowHeight;
    final target = ((_currentPage + delta) * pageHeight)
        .clamp(0.0, _scrollCtrl.position.maxScrollExtent);
    _scrollCtrl.animateTo(target,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        _buildControls(),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // 카드 높이 계산 (2열, spacing 12, padding 16*2)
              final cardWidth = (constraints.maxWidth - defaultPadding * 2 - 12) / 2;
              final newRowHeight = cardWidth / 0.9 + 12; // +mainAxisSpacing
              if (newRowHeight != _cardRowHeight) {
                WidgetsBinding.instance.addPostFrameCallback(
                    (_) => setState(() => _cardRowHeight = newRowHeight));
              }
              return SingleChildScrollView(
                controller: _scrollCtrl,
                padding: const EdgeInsets.all(defaultPadding),
                child: _summaryMode ? _buildCompactGrid() : _buildDetailGrid(),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── 서브 헤더 (화면명 + 페이지 네비게이션) ───────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      color: secondaryColor,
      padding: const EdgeInsets.only(
          left: defaultPadding, right: defaultPadding + 8, top: 10, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 화면명(SVG아이콘) + 페이지 네비게이션
          Row(
            children: [
              SvgPicture.asset(
                'assets/icons/menu_task.svg',
                colorFilter: const ColorFilter.mode(
                    Colors.white70, BlendMode.srcIn),
                width: 16,
                height: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'menu.monitoring'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              _pageArrow(Icons.keyboard_arrow_up,
                  _currentPage > 0 ? () => _goPage(-1) : null),
              const SizedBox(width: 6),
              Text(
                '${_currentPage + 1} / $_totalPages',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              _pageArrow(Icons.keyboard_arrow_down,
                  _currentPage < _totalPages - 1 ? () => _goPage(1) : null),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pageArrow(IconData icon, VoidCallback? onTap) {
    final active = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          border: Border.all(
            color: active ? Colors.white38 : Colors.white12,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 18,
          color: active ? Colors.white70 : Colors.white24,
        ),
      ),
    );
  }

  // ── 컨트롤 바 ──────────────────────────────────────────
  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: defaultPadding, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.06))),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _toggleMode(!_summaryMode),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: Checkbox(
                    value: _summaryMode,
                    onChanged: (v) => _toggleMode(v ?? false),
                    activeColor: accentBlueColor,
                    side: const BorderSide(color: Colors.white38),
                    materialTapTargetSize:
                        MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'summary.compact'.tr(),
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 상세 카드 그리드 (기본) ───────────────────────────
  Widget _buildDetailGrid() {
    final items = _devices;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => GestureDetector(
        onTap: () => widget.onDeviceSelected?.call(items[index].id),
        child: _DeviceCard(
          device: items[index],
          onToggle: (val) => setState(() => items[index].isOn = val),
        ),
      ),
    );
  }

  // ── 요약 그리드 (compact) ────────────────────────────
  Widget _buildCompactGrid() {
    final items = _devices;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 1.8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final d = items[index];
        return Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: d.isOn
                ? accentBlueColor.withValues(alpha: 0.15)
                : secondaryColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: d.isOn ? accentBlueColor : Colors.white12,
              width: 0.8,
            ),
          ),
          child: Text(
            d.id,
            style: TextStyle(
              color: d.isOn ? accentBlueColor : Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      },
    );
  }
}

// ── 데이터 모델 ────────────────────────────────────────
class _DeviceState {
  final String id;
  bool isOn;
  _DeviceState({required this.id, this.isOn = false});
}

// ── 상세 카드 ─────────────────────────────────────────
class _DeviceCard extends StatelessWidget {
  const _DeviceCard({required this.device, required this.onToggle});

  final _DeviceState device;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ── 상단 ──
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    device.id,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.bolt,
                      size: 16,
                      color: device.isOn ? accentColor : Colors.white24),
                  const SizedBox(width: 4),
                  const Icon(Icons.bluetooth,
                      size: 14, color: Colors.white24),
                ],
              ),
              const SizedBox(height: 8),
              _sensorRow(Icons.thermostat_outlined, '--', '°C'),
              const SizedBox(height: 3),
              _sensorRow(Icons.water_drop_outlined, '--', '%'),
              const SizedBox(height: 3),
              _sensorRow(Icons.battery_full_outlined, '--', 'V'),
            ],
          ),
          // ── 하단 ──
          Row(
            children: [
              Transform.scale(
                scale: 0.8,
                alignment: Alignment.centerLeft,
                child: Switch(
                  value: device.isOn,
                  onChanged: onToggle,
                  activeColor: accentBlueColor,
                  inactiveThumbColor: Colors.white38,
                  inactiveTrackColor: Colors.white12,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              Text(
                device.isOn ? 'ON' : 'OFF',
                style: TextStyle(
                  color: device.isOn ? accentBlueColor : Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'CTRL',
                    style: TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sensorRow(IconData icon, String value, String unit) {
    return Row(
      children: [
        Icon(icon, size: 13, color: Colors.white38),
        const SizedBox(width: 4),
        Text('$value $unit',
            style:
                const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}
