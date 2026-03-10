import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/storage/db_health_helper.dart';
import '../../models/health_models.dart';

class ExerciseTracking extends StatefulWidget {
  const ExerciseTracking({super.key});

  @override
  State<ExerciseTracking> createState() => _ExerciseTrackingState();
}

class _ExerciseTrackingState extends State<ExerciseTracking> {
  final Completer<GoogleMapController> _controller = Completer();
  final List<LatLng> _pathPoints = [];
  bool _isTracking = false;
  StreamSubscription<Position>? _positionStream;
  double _totalDistance = 0;
  DateTime? _startTime;

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(39.9042, 116.4074), // Beijing
    zoom: 14.4746,
  );

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _toggleTracking() async {
    if (_isTracking) {
      await _stopTracking();
    } else {
      await _startTracking();
    }
  }

  Future<void> _startTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    setState(() {
      _isTracking = true;
      _pathPoints.clear();
      _totalDistance = 0;
      _startTime = DateTime.now();
    });

    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5,
          ),
        ).listen((Position position) {
          LatLng point = LatLng(position.latitude, position.longitude);
          if (_pathPoints.isNotEmpty) {
            _totalDistance += Geolocator.distanceBetween(
              _pathPoints.last.latitude,
              _pathPoints.last.longitude,
              position.latitude,
              position.longitude,
            );
          }
          setState(() {
            _pathPoints.add(point);
          });
          _moveCamera(point);
        });
  }

  Future<void> _stopTracking() async {
    await _positionStream?.cancel();
    _positionStream = null;

    // Save to DB
    if (_startTime != null) {
      final session = ExerciseSession(
        startTime: _startTime!.toIso8601String(),
        endTime: DateTime.now().toIso8601String(),
        distance: _totalDistance,
        pathPoints: jsonEncode(
          _pathPoints
              .map((e) => {'lat': e.latitude, 'lng': e.longitude})
              .toList(),
        ),
        gmtCreate: DateTime.now().toIso8601String(),
      );
      await DBHealthHelper().insertExerciseSession(session);
    }

    setState(() {
      _isTracking = false;
    });
  }

  Future<void> _moveCamera(LatLng point) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLng(point));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('运动追踪 / Exercise Tracking')),
      body: (Platform.isWindows || Platform.isMacOS || Platform.isLinux)
          ? Center(
              child: Padding(
                padding: EdgeInsets.all(20.sp),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map_outlined, size: 80.sp, color: Colors.grey),
                    SizedBox(height: 20.sp),
                    Text(
                      '地图追踪目前仅支持手机端 (Android / iOS)\nWindows/桌面端暂不支持地图显示',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 20.sp),
                    const Text('功能开发中，敬请期待...'),
                  ],
                ),
              ),
            )
          : Stack(
              children: [
                GoogleMap(
                  mapType: MapType.normal,
                  initialCameraPosition: _initialPosition,
                  onMapCreated: (GoogleMapController controller) {
                    _controller.complete(controller);
                  },
                  polylines: {
                    Polyline(
                      polylineId: const PolylineId('path'),
                      points: _pathPoints,
                      color: Colors.blue,
                      width: 5,
                    ),
                  },
                  myLocationEnabled: true,
                ),
                Positioned(
                  bottom: 20.sp,
                  left: 20.sp,
                  right: 20.sp,
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.sp),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStat(
                                '距离 (m)',
                                _totalDistance.toStringAsFixed(0),
                              ),
                              _buildStat('点数', _pathPoints.length.toString()),
                            ],
                          ),
                          SizedBox(height: 10.sp),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isTracking
                                  ? Colors.red
                                  : Colors.green,
                              minimumSize: Size(double.infinity, 45.sp),
                            ),
                            onPressed: _toggleTracking,
                            child: Text(
                              _isTracking ? '停止追踪' : '开始运动',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12.sp, color: Colors.grey),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
