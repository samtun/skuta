import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() {
  runApp(const SkutaApp());
}

class SkutaApp extends StatelessWidget {
  const SkutaApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      color: Colors.lightBlue,
      home: StreamBuilder<BluetoothState>(
          stream: FlutterBluePlus.instance.state,
          initialData: BluetoothState.unknown,
          builder: (c, snapshot) {
            final state = snapshot.data;
            if (state == BluetoothState.on) {
              return const MainScreen();
            }
            return BluetoothOffScreen(state: state);
          }),
    );
  }
}

class BluetoothOffScreen extends StatelessWidget {
  const BluetoothOffScreen({Key? key, this.state}) : super(key: key);

  final BluetoothState? state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.bluetooth_disabled,
              size: 200.0,
              color: Colors.white,
            ),
            Text(
              'Bluetooth Adapter is ${state != null ? state.toString().substring(15) : 'not available'}.',
              style: const TextStyle(color: Colors.white),
            ),
            ElevatedButton(
              onPressed: Platform.isAndroid
                  ? () => FlutterBluePlus.instance.turnOn()
                  : null,
              child: const Text('TURN ON'),
            ),
          ],
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final BluetoothDevice _device = BluetoothDevice.fromId(
    "D3:36:39:34:13:2C",
    name: "HW_2888500",
    type: BluetoothDeviceType.le,
  );

  final String _serviceUuid = "0000f1f0-0000-1000-8000-00805f9b34fb";
  final String _receiveCharacteristicUuid =
      "0000f1f2-0000-1000-8000-00805f9b34fb";
  final String _sendCharacteristicUuid = "0000f1f1-0000-1000-8000-00805f9b34fb";

  final Color _brightColor = const Color.fromARGB(255, 255, 233, 190);
  final Color _darkColor = const Color.fromARGB(255, 118, 62, 142);
  final Color _backgroundColor = const Color.fromARGB(255, 61, 61, 61);

  int _batteryLevel = 0;
  int _controlTemp = 0;
  bool _connectionButtonPressed = false;

  final List<IconData> _batteryIcons = [
    Icons.battery_0_bar, // 0 - 12.5
    Icons.battery_1_bar, // 12.5 - 25
    Icons.battery_2_bar, // 25 - 37.5
    Icons.battery_3_bar, // 37.5 - 50
    Icons.battery_4_bar, // 50 - 62.5
    Icons.battery_5_bar, // 62.5 - 75
    Icons.battery_6_bar, // 75 - 87.5
    Icons.battery_std, // 87.5 - 100
    Icons.battery_std, // 100 - needed for the 8th index
  ];

  Widget _createInfoTexts() => Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          RotatedBox(
            quarterTurns: 1,
            child: _batteryIcon(),
          ),
          _createInfoText("$_batteryLevel%", 80),
          const SizedBox(
            height: 64,
          ),
          Icon(
            Icons.thermostat,
            color: _brightColor,
            size: 48,
          ),
          _createInfoText(
            "$_controlTemp°C",
            42,
          ),
        ],
      );

  Icon _batteryIcon() {
    return Icon(
      _batteryIcons[_batteryLevel ~/ 12.5],
      color: _brightColor,
      size: 200,
    );
  }

  Widget _createInfoText(text, double fontSize) => Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          color: _brightColor,
          fontWeight: FontWeight.bold,
        ),
      );

  Widget _buildBatteryDisplay(List<BluetoothService> services) {
    try {
      var service =
          services.firstWhere((s) => s.uuid.toString() == _serviceUuid);
      var receiveCharacteristic = service.characteristics
          .firstWhere((c) => c.uuid.toString() == _receiveCharacteristicUuid);
      return StreamBuilder<List<int>>(
        stream: receiveCharacteristic.value,
        initialData: receiveCharacteristic.lastValue,
        builder: (c, snapshot) {
          if (_batteryLevel != 0) {
            return _createInfoTexts();
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            var sendCharacteristic = service.characteristics.firstWhere(
                (c) => c.uuid.toString() == _sendCharacteristicUuid);
            Future.delayed(const Duration(milliseconds: 500), () async {
              await receiveCharacteristic.setNotifyValue(true);
              await sendCharacteristic
                  .write([165, 2, 253, 90], withoutResponse: true);
            });
          } else if (snapshot.connectionState == ConnectionState.active) {
            final value = snapshot.data;
            if (value != null && value.isNotEmpty && value[6] == 0) {
              _batteryLevel = value[5];
              _controlTemp = value[14];
              return _createInfoTexts();
            }
          }
          return _loadingIndicator();
        },
      );
    } catch (e) {
      debugPrint('Failed to init receive characteristic');
    }
    return _loadingIndicator();
  }

  void _connectToDevice() async {
    if (_connectionButtonPressed) {
      return;
    }

    try {
      setState(() {
        _connectionButtonPressed = true;
      });
      await _device.connect(timeout: const Duration(seconds: 3));
    } catch (e) {
      debugPrint("Failed to connect to device.");
    }

    setState(() {
      _connectionButtonPressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: const Alignment(-0.96, -0.97),
            stops: const [0.0, 0.2, 0.2, 1],
            colors: [
              Colors.white.withAlpha(5),
              Colors.white.withAlpha(5),
              Colors.transparent,
              Colors.transparent,
            ],
            tileMode: TileMode.repeated,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomLeft,
              end: const Alignment(-0.96, 0.97),
              stops: const [0.0, 0.2, 0.2, 1],
              colors: [
                Colors.white.withAlpha(5),
                Colors.white.withAlpha(5),
                Colors.transparent,
                Colors.transparent,
              ],
              tileMode: TileMode.repeated,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(32, 82, 12, 48),
          child: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                  image: AssetImage("assets/skuta_banner.png"),
                  fit: BoxFit.fitHeight,
                  alignment: Alignment.centerLeft),
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 148),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  StreamBuilder<BluetoothDeviceState>(
                    stream: _device.state,
                    initialData: BluetoothDeviceState.connecting,
                    builder: (c, snapshot) {
                      Widget? element;

                      if (_connectionButtonPressed) {
                        return _loadingIndicator();
                      }

                      if (snapshot.data == BluetoothDeviceState.disconnected) {
                        element =
                            _createButton(context, 'CONNECT', _connectToDevice);
                      } else if (snapshot.data ==
                          BluetoothDeviceState.connected) {
                        _device.discoverServices();
                        element = StreamBuilder<List<BluetoothService>>(
                          stream: _device.services,
                          initialData: const [],
                          builder: (c, snapshot) => _buildBatteryDisplay(
                              snapshot.data != null ? snapshot.data! : []),
                        );
                      } else {
                        element = _loadingIndicator();
                      }

                      return element;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _loadingIndicator() {
    return Center(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 0, 0),
            child: CircularProgressIndicator(
              color: _darkColor,
              strokeWidth: 12,
            ),
          ),
          CircularProgressIndicator(
            color: _brightColor,
            strokeWidth: 8,
          ),
        ],
      ),
    );
  }

  Widget _createButton(
      BuildContext context, String text, VoidCallback? onPressed) {
    return MaterialButton(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(80.0),
      ),
      onPressed: onPressed,
      padding: const EdgeInsets.all(0.0),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _brightColor,
              _darkColor,
            ],
          ),
          borderRadius: const BorderRadius.all(Radius.circular(80.0)),
        ),
        child: Container(
          constraints: const BoxConstraints(minWidth: 88.0, minHeight: 68.0),
          // min sizes for Material buttons
          alignment: Alignment.center,
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black),
          ),
        ),
      ),
    );
  }
}
