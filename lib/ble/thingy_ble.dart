import 'dart:typed_data';
import '../models/sensor_data.dart';

class ThingyBleParser {
  final List<double> gravity = [0.0, 0.0, 0.0];
  final List<double> accel  = [0.0, 0.0, 0.0];
  final List<double> gyro   = [0.0, 0.0, 0.0];

  static const double gravityAlpha   = 0.8;
  static const double alpha        = 0.1;
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

    final gx = b.getInt16(6, Endian.little);
    final gy = b.getInt16(8, Endian.little);
    final gz = b.getInt16(10, Endian.little);

    accel[0] += alpha * (lx - accel[0]);
    accel[1] += alpha * (ly - accel[1]);
    accel[2] += alpha * (lz - accel[2]);
    gyro[0]  += alpha * (gx - gyro[0]);
    gyro[1]  += alpha * (gy - gyro[1]);
    gyro[2]  += alpha * (gz - gyro[2]);

    final axF = accel[0].abs() < accelThreshold ? 0.0 : accel[0];
    final ayF = accel[1].abs() < accelThreshold ? 0.0 : accel[1];
    final azF = accel[2].abs() < accelThreshold ? 0.0 : accel[2];
    final gxF = gyro[0].abs() < gyroThreshold   ? 0.0 : gyro[0];
    final gyF = gyro[1].abs() < gyroThreshold   ? 0.0 : gyro[1];
    final gzF = gyro[2].abs() < gyroThreshold   ? 0.0 : gyro[2];

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