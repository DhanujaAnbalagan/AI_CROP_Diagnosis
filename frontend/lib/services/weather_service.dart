import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class WeatherData {
  final double temperature;
  final String condition;
  final int humidity;
  final String icon;

  WeatherData({
    required this.temperature,
    required this.condition,
    required this.humidity,
    required this.icon,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      temperature: (json['main']['temp'] as num).toDouble(),
      condition: json['weather'][0]['main'],
      humidity: json['main']['humidity'] as int,
      icon: _getIconForCondition(json['weather'][0]['main']),
    );
  }

  static String _getIconForCondition(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear': return '☀️';
      case 'clouds': return '☁️';
      case 'rain': return '🌧️';
      case 'snow': return '❄️';
      case 'thunderstorm': return '⛈️';
      case 'drizzle': return '🌦️';
      default: return '🌤️';
    }
  }
}

class WeatherService {
  static const String _apiKey = 'YOUR_WEATHER_API_KEY'; // Placeholder key
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  static Future<WeatherData> fetchWeather(Position position) async {
    try {
      final url = Uri.parse('$_baseUrl?lat=${position.latitude}&lon=${position.longitude}&appid=$_apiKey&units=metric');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return WeatherData.fromJson(json.decode(response.body));
      } else {
        // Fallback to mock data if API fails (API key missing)
        return _getMockWeather();
      }
    } catch (e) {
      return _getMockWeather();
    }
  }

  static WeatherData _getMockWeather() {
    return WeatherData(
      temperature: 28.5,
      condition: 'Sunny',
      humidity: 65,
      icon: '☀️',
    );
  }
}
