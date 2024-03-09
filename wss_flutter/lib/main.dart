import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'constants.dart' as constants;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: constants.appTitle,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          color: Colors.green[400],
        ),
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final String esp32IP = constants.ipaddress;
  late WebSocketChannel channel;
  String humidity = 'N/A';
  String temperature = 'N/A';
  Map<String, bool> deviceStatus = {'led': false, 'buzzer': false};

  @override
  void initState() {
    super.initState();
    channel = IOWebSocketChannel.connect('ws://$esp32IP/ws');
    channel.stream.listen((message) {
      List<String> data = message.split(',');
      setState(() {
        temperature = data[0];
        humidity = data[1];
      });
    });
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(constants.appTitle),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _buildControlButton('LED', 'led'),
            _buildControlButton('Buzzer', 'buzzer'),
            SizedBox(height: 40),
            _buildSensorData(constants.humidityLabel, '$humidity%', Colors.black),
            _buildSensorData(constants.tempLabel, '$temperature°C', Colors.black),
          ],
        ),
      ),
    );
  }

  ElevatedButton _buildControlButton(String label, String device) {
    return ElevatedButton(
      onPressed: () {
        String command = '$device/';
        if (deviceStatus[device]!) {
          command += 'off';
        } else {
          command += 'on';
        }
        _sendCommand(command);
        setState(() {
          deviceStatus[device] = !deviceStatus[device]!;
        });
      },
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(_getButtonColor(device)),
      ),
      child: Text(
        '${deviceStatus[device]! ? constants.turnOn : constants.turnOff} $label',
        style: TextStyle(fontSize: 30),
      ),
    );
  }

  Widget _buildSensorData(String title, String data, Color textColor) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Text(
          data,
          style: TextStyle(fontSize: 25, color: textColor, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Color _getButtonColor(String device) {
    return deviceStatus[device]! ? Colors.green[300]! : Colors.red[300]!;
  }

  void _sendCommand(String command) {
    channel.sink.add(command);
  }
}
