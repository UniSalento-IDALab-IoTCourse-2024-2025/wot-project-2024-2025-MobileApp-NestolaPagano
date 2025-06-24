import 'dart:math';
import 'dart:typed_data';

import '../models/sensor_data.dart';

class ThingyBleParser {
  final List<double> gravity = [0.0, 0.0, 0.0];
  final List<double> uiAccel  = [0.0, 0.0, 0.0];
  final List<double> uiGyro   = [0.0, 0.0, 0.0];

  static const double gravityAlpha   = 0.8;
  static const double uiAlpha        = 0.1;
  static const double accelThreshold = 0.05;
  static const double gyroThreshold  = 0.01;

  SensorData parse(List<int> data) {
    final b = ByteData.sublistView(Uint8List.fromList(data));

    final ax = b.getInt16(0, Endian.little) / 1000.0 * 9.80665;
    final ay = b.getInt16(2, Endian.little) / 1000.0 * 9.80665;
    final az = b.getInt16(4, Endian.little) / 1000.0 * 9.80665;

    gravity[0] = gravityAlpha * gravity[0] + (1 - gravityAlpha) * ax;
    gravity[1] = gravityAlpha * gravity[1] + (1 - gravityAlpha) * ay;
    gravity[2] = gravityAlpha * gravity[2] + (1 - gravityAlpha) * az;

    final lx = ax - gravity[0];
    final ly = ay - gravity[1];
    final lz = az - gravity[2];

    final gx = b.getInt16(6, Endian.little) / 10.0 * (pi / 180);
    final gy = b.getInt16(8, Endian.little) / 10.0 * (pi / 180);
    final gz = b.getInt16(10, Endian.little) / 10.0 * (pi / 180);

    uiAccel[0] += uiAlpha * (lx - uiAccel[0]);
    uiAccel[1] += uiAlpha * (ly - uiAccel[1]);
    uiAccel[2] += uiAlpha * (lz - uiAccel[2]);
    uiGyro[0]  += uiAlpha * (gx - uiGyro[0]);
    uiGyro[1]  += uiAlpha * (gy - uiGyro[1]);
    uiGyro[2]  += uiAlpha * (gz - uiGyro[2]);

    final axF = uiAccel[0].abs() < accelThreshold ? 0.0 : uiAccel[0];
    final ayF = uiAccel[1].abs() < accelThreshold ? 0.0 : uiAccel[1];
    final azF = uiAccel[2].abs() < accelThreshold ? 0.0 : uiAccel[2];
    final gxF = uiGyro[0].abs() < gyroThreshold   ? 0.0 : uiGyro[0];
    final gyF = uiGyro[1].abs() < gyroThreshold   ? 0.0 : uiGyro[1];
    final gzF = uiGyro[2].abs() < gyroThreshold   ? 0.0 : uiGyro[2];

    return SensorData(
      accelX: axF,
      accelY: ayF,
      accelZ: azF,
      gyroX: gxF,
      gyroY: gyF,
      gyroZ: gzF,
    );
  }
}