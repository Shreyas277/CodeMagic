import 'dart:convert';
import 'package:open_file/open_file.dart';
import 'package:archive/archive.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FirstScreen(),
    );
  }
}

class FirstScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fullscreen background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/ambiator.png', // Replace with your image asset
              fit: BoxFit.cover,
            ),
          ),
          // Button overlay
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SecondScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // Button color
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Enter',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SecondScreen extends StatefulWidget {
  @override
  _SecondScreenState createState() => _SecondScreenState();
}

class _SecondScreenState extends State<SecondScreen> {
  final TextEditingController locationController = TextEditingController();
  final TextEditingController geoCoordinatesController =
  TextEditingController();

  // Function to send location data to API
  Future<void> sendLocationPostRequest(
      String locationName, BuildContext context) async {
    final url = Uri.parse("https://api-ambiator.onrender.com/get-coordinates");

    final data = {"location_name": locationName};

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print("Place: $responseData");
        final latitude = responseData['latitude'];
        final longitude = responseData['longitude'];

        // Navigate to third screen if success
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ThirdScreen(
                locationName: locationName,
                latitude: latitude,
                longitude: longitude,
              )),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error: ${response.statusCode}, ${response.body}"),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Request failed: $e"),
        backgroundColor: Colors.red,
      ));
    }
  }

  // Function to send coordinates data to API
  Future<void> sendCoordinatesPostRequest(
      double latitude, double longitude, BuildContext context) async {
    final url = Uri.parse("https://api-ambiator.onrender.com/get-place");

    final data = {"latitude": latitude, "longitude": longitude};

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print("Place: $responseData");
        final placeName = responseData['place_name'];
        // Navigate to third screen if success
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ThirdScreen(
                locationName: placeName,
                latitude: latitude,
                longitude: longitude,
              )),
        );
      } else {
        print("Error: ${response.statusCode}, ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error: ${response.statusCode}, ${response.body}"),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Request failed: $e"),
        backgroundColor: Colors.red,
      ));
    }
  }

  bool _isValidCoordinates(String input) {
    final regex = RegExp(r'^-?\d+(\.\d+)?,\s*-?\d+(\.\d+)?$');
    if (!regex.hasMatch(input)) {
      return false; // Format is invalid
    }

    final parts = input.split(',').map((e) => e.trim()).toList();
    final latitude = double.tryParse(parts[0]);
    final longitude = double.tryParse(parts[1]);

    if (latitude == null || longitude == null) {
      return false;
    }

    // Check latitude and longitude ranges
    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  // List of locations (City, State)
  final List<Map<String, String>> locations = [
    {
      "city": "Mumbai",
      "state": "Maharashtra",
      "coordinates": "19.0760, 72.8777"
    },
    {
      "city": "Hyderabad",
      "state": "Telangana",
      "coordinates": "17.385044, 78.486671"
    },
    {
      "city": "Bangalore",
      "state": "Karnataka",
      "coordinates": "12.9716, 77.5946"
    },
    {
      "city": "Chennai",
      "state": "Tamil Nadu",
      "coordinates": "13.0827, 80.2707"
    },
    {"city": "Pune", "state": "Maharashtra", "coordinates": "18.5204, 73.8567"},
    {
      "city": "Kolkata",
      "state": "West Bengal",
      "coordinates": "22.5726, 88.3639"
    },
    {"city": "Delhi", "state": "Delhi", "coordinates": "28.7041, 77.1025"},
    {"city": "Jaipur", "state": "Rajasthan", "coordinates": "26.9124, 75.7873"}
    // Add more cities as needed
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Location 📌'),
        backgroundColor: Colors.pink.shade50, // Light pink background
        elevation: 0,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Select City',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ...locations.map((location) {
              return ListTile(
                title: Text('${location["city"]}, ${location["state"]}'),
                onTap: () {
                  setState(() {
                    // Set the selected city and coordinates
                    locationController.text =
                    '${location["city"]}, ${location["state"]}';
                    geoCoordinatesController.text = location["coordinates"]!;
                  });
                  Navigator.pop(context); // Close the drawer
                },
              );
            }).toList(),
          ],
        ),
      ), // Placeholder for the navigation drawer
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Location Name Input
            Text(
              'Location Name',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: locationController,
              decoration: InputDecoration(
                hintText: 'City, State',
                filled: true,
                fillColor: Colors.grey.shade200,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            SizedBox(height: 16),

            Text(
              'OR',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            SizedBox(height: 16),

            // Geo Coordinates Input
            Text(
              'Geo Coordinates🌍',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: geoCoordinatesController,
              decoration: InputDecoration(
                hintText: 'Latitude, Longitude',
                filled: true,
                fillColor: Colors.grey.shade200,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            SizedBox(height: 16),

            Text(
              'OR',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            SizedBox(height: 16),

            // Map Placeholder
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/images/map.png', // Replace with your image path
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: 24),

            // Calculate Comfort Button
            ElevatedButton(
              onPressed: () {
                // Check if location input is provided
                if (locationController.text.isNotEmpty) {
                  sendLocationPostRequest(
                      locationController.text.trim(), context);
                } else if (geoCoordinatesController.text.isNotEmpty) {
                  final input = geoCoordinatesController.text.trim();
                  if (!_isValidCoordinates(input)) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                        'Invalid Geo Coordinates! Enter in the format "Latitude, Longitude" with valid ranges.',
                      ),
                      backgroundColor: Colors.red,
                    ));
                  } else {
                    final parts =
                    input.split(',').map((e) => e.trim()).toList();
                    final latitude = double.tryParse(parts[0]);
                    final longitude = double.tryParse(parts[1]);
                    if (latitude != null && longitude != null) {
                      sendCoordinatesPostRequest(latitude, longitude, context);
                    }
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Please provide input before proceeding!'),
                    backgroundColor: Colors.red,
                  ));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Calculate Comfort',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ThirdScreen extends StatelessWidget {
  final String locationName;
  final double latitude;
  final double longitude;

  ThirdScreen({
    required this.locationName,
    required this.latitude,
    required this.longitude,
  });

  Future<Map<String, dynamic>> fetchRZoneData() async {
    final url = Uri.parse("https://api-ambiator.onrender.com/process-weather-data");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "coordinates": [latitude, longitude],
          "place_name": locationName,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['rzone'];
      } else {
        throw Exception('Failed to fetch data. Error: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Failed to fetch data. Error: $error');
    }
  }

  Future<void> downloadAndExtractFiles(BuildContext context) async {
    final String url = "https://api-ambiator.onrender.com/get-files-weather";

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "coordinates": [latitude, longitude],
          "place_name": locationName,
        }),
      );

      if (response.statusCode == 200) {
        final Directory appDocDir = await getApplicationDocumentsDirectory();
        final String zipFilePath = '${appDocDir.path}/weather_data.zip';
        final File zipFile = File(zipFilePath);
        await zipFile.writeAsBytes(response.bodyBytes);

        final List<int> bytes = zipFile.readAsBytesSync();
        final Archive archive = ZipDecoder().decodeBytes(bytes);

        final List<File> extractedFiles = [];
        for (final file in archive) {
          final String fileName = file.name;
          final List<int> data = file.content as List<int>;
          final File extractedFile = File('${appDocDir.path}/$fileName');
          await extractedFile.writeAsBytes(data);
          extractedFiles.add(extractedFile);
        }
        final fileCount = extractedFiles.length;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(' $fileCount Files extracted successfully.')),
        );

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Extracted Files'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: extractedFiles.map((file) {
                  return ElevatedButton(
                    onPressed: () async {
                      final String filePath = file.path;
                      await OpenFile.open(filePath);
                    },
                    child: Text('Open ${file.uri.pathSegments.last}'),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download file. Status: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'AMBIATOR Performance',
          style: TextStyle(color: Colors.blue.shade900),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchRZoneData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final rzone = snapshot.data!;
            final chartData = <MonthData>[];

            rzone.forEach((month, values) {
              chartData.add(MonthData(month, values[0], values[1], values[2]));
            });

            return Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SfCartesianChart(
                      primaryXAxis: CategoryAxis(labelRotation: 45),
                      primaryYAxis: NumericAxis(),
                      title: ChartTitle(
                          text: 'Comfort Hours Supply Air Temperatures',
                          textStyle: TextStyle(color: Colors.black)),
                      legend: Legend(
                          isVisible: true, position: LegendPosition.bottom),
                      margin: EdgeInsets.all(10),
                      series: <CartesianSeries<MonthData, String>>[
                        StackedColumnSeries<MonthData, String>(
                          dataSource: chartData,
                          xValueMapper: (MonthData data, _) => data.month,
                          yValueMapper: (MonthData data, _) => data.discomfort,
                          name: 'Discomfort',
                          color: Colors.blueGrey.shade900,
                        ),
                        StackedColumnSeries<MonthData, String>(
                          dataSource: chartData,
                          xValueMapper: (MonthData data, _) => data.month,
                          yValueMapper: (MonthData data, _) => data.moderate,
                          name: 'Moderate',
                          color: Colors.deepPurple.shade400,
                        ),
                        StackedColumnSeries<MonthData, String>(
                          dataSource: chartData,
                          xValueMapper: (MonthData data, _) => data.month,
                          yValueMapper: (MonthData data, _) => data.comfort,
                          name: 'Comfort',
                          color: Colors.deepPurple.shade200,
                        ),
                      ],
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => downloadAndExtractFiles(context),
                  child: Text('Download and Extract Files'),
                ),
              ],
            );
          } else {
            return Center(child: Text('No data available.'));
          }
        },
      ),
    );
  }
}


class MonthData {
  final String month;
  final int comfort;
  final int moderate;
  final int discomfort;

  MonthData(this.month, this.comfort, this.moderate, this.discomfort);
}
