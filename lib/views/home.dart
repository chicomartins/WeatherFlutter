import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_android/geolocator_android.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> hours = [];
  List<String> temperatures = [];
  String current = "";
  Position? _currentposition;

  @override
  void initState() {
    super.initState();
    _getLocationWeather();
  }

  Future<void> _getLocationWeather() async {
    try {
      Position position = await _determinePosition();
      setState(() {
        _currentposition = position;
      });
      await getWeather(position.latitude, position.longitude);
    } catch (e) {}
  }

  Future<void> getWeather(double latitude, double longitude) async {
    var url =
        "https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&hourly=temperature_2m&current=temperature_2m&timezone=America%2FSao_Paulo&forecast_days=1";
    try {
      final uri = Uri.parse(url);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        setState(() {
          current = json["current"]["temperature_2m"].toString();
          hours = List<String>.from(json["hourly"]["time"]);
          temperatures = json["hourly"]["temperature_2m"]
              .map<String>((e) => e.toString())
              .toList();
        });
      }
    } catch (e) {}
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Os serviços de localização estão desativados.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Permissão de localização negada.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Permissões permanentemente negadas. Vá para as configurações e ative.');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  String _getHour(String hour) {
    return hour.substring(hour.length - 5);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(""),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Temperatura atual:",
                style: TextStyle(fontSize: 40, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              temperatures.isNotEmpty
                  ? Text(
                "${current}°C",
                style: TextStyle(fontSize: 100, color: Colors.blue),
                textAlign: TextAlign.center,
              )
                  : CircularProgressIndicator(),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Temperaturas durante o dia:",
                style: TextStyle(fontSize: 20, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: hours.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 5,
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Hora: ${_getHour(hours[index])}",
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                        SizedBox(height: 5),
                        Text(
                          "${temperatures[index]}°C",
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.orangeAccent),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}