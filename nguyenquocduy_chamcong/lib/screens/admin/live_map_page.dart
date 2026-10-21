import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../api.dart';
import '../../widgets.dart';

/// Admin xem vị trí nhân viên đang chia sẻ + vòng geofence của văn phòng. Tự làm mới mỗi 8 giây.
class LiveMapPage extends StatefulWidget {
  const LiveMapPage({super.key});
  @override
  State<LiveMapPage> createState() => _LiveMapPageState();
}

class _LiveMapPageState extends State<LiveMapPage> {
  Map<String, dynamic>? _site;
  List<dynamic> _people = [];
  bool _loaded = false;
  String? _error;
  Timer? _timer;
  final MapController _map = MapController();

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 8), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final r = await Api.get('locations') as Map;
      if (!mounted) return;
      setState(() {
        _site = r['site'] == null ? null : Map<String, dynamic>.from(r['site'] as Map);
        _people = (r['people'] as List?) ?? [];
        _loaded = true;
        _error = null;
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loaded = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final siteLatLng = _site == null
        ? const LatLng(37.4219983, -122.084)
        : LatLng((_site!['latitude'] as num).toDouble(), (_site!['longitude'] as num).toDouble());

    return Scaffold(
      appBar: AppBar(title: const Text('Vị trí nhân viên'), actions: [
        IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        IconButton(onPressed: () => _map.move(siteLatLng, 16), icon: const Icon(Icons.my_location)),
      ]),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              if (_error != null) Container(width: double.infinity, color: const Color(0xFFFEF2F2), padding: const EdgeInsets.all(8), child: Text(_error!, style: const TextStyle(color: kDanger))),
              Expanded(
                flex: 3,
                child: FlutterMap(
                  mapController: _map,
                  options: MapOptions(initialCenter: siteLatLng, initialZoom: 16),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.nguyenquocduy.chamcong',
                    ),
                    if (_site != null)
                      CircleLayer(circles: [
                        CircleMarker(
                          point: siteLatLng,
                          radius: (_site!['radiusMeters'] as num).toDouble(),
                          useRadiusInMeter: true,
                          color: kPrimary.withOpacity(0.15),
                          borderColor: kPrimary,
                          borderStrokeWidth: 2,
                        ),
                      ]),
                    MarkerLayer(markers: [
                      Marker(
                        point: siteLatLng,
                        width: 44,
                        height: 44,
                        child: const Icon(Icons.business, color: kPrimaryDark, size: 36),
                      ),
                      for (final p in _people)
                        Marker(
                          point: LatLng((p['latitude'] as num).toDouble(), (p['longitude'] as num).toDouble()),
                          width: 110,
                          height: 62,
                          child: Column(children: [
                            const Icon(Icons.person_pin_circle, color: kDanger, size: 36),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black12)),
                              child: Text('${p['name']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                            ),
                          ]),
                        ),
                    ]),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: _people.isEmpty
                    ? const EmptyState(icon: Icons.location_off, text: 'Chưa có nhân viên nào đang chia sẻ vị trí')
                    : ListView(
                        padding: const EdgeInsets.all(12),
                        children: [
                          for (final p in _people)
                            AppCard(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(10),
                              onTap: () => _map.move(LatLng((p['latitude'] as num).toDouble(), (p['longitude'] as num).toDouble()), 17),
                              child: Row(children: [
                                const Icon(Icons.person_pin_circle, color: kDanger),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text('${p['name']} (${p['code']})', style: const TextStyle(fontWeight: FontWeight.w700)),
                                    Text('Cập nhật ${fmtTime(p['updatedAt'])}', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                                  ]),
                                ),
                                StatusChip(
                                  '${p['distanceToSite']} m',
                                  (p['distanceToSite'] as num?) != null && (p['distanceToSite'] as num) <= ((_site?['radiusMeters'] as num?) ?? 0) ? kOk : const Color(0xFFD97706),
                                ),
                              ]),
                            ),
                        ],
                      ),
              ),
            ]),
    );
  }
}
