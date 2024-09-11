import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:dash_bubble/dash_bubble.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool _isOverlayOn = false;
  String _catFact = '';

  @override
  void initState() {
    super.initState();
    _checkOverlayPermission(); // Check for overlay permission on init
  }

  Future<void> _checkOverlayPermission() async {
    bool hasPermission = await DashBubble.instance.hasOverlayPermission();
    if (!hasPermission) {
      await DashBubble.instance.requestOverlayPermission();
    }
  }

  Future<void> _startOrStopBubble(bool isOn) async {
    if (isOn) {
      bool hasPermission = await DashBubble.instance.hasOverlayPermission();
      if (!hasPermission) {
        hasPermission = await DashBubble.instance.requestOverlayPermission();
      }

      if (hasPermission) {
        // Starting the DashBubble with basic options
        await DashBubble.instance.startBubble(
          bubbleOptions: BubbleOptions(
            bubbleIcon: 'bubble_icon', // Make sure this exists in res/drawable
            enableClose: true,
            startLocationX: 100,
            startLocationY: 100,
            bubbleSize: 60,
            opacity: 1.0,
            enableBottomShadow: true,
            keepAliveWhenAppExit: true,
          ),
          notificationOptions: NotificationOptions(
            id: 101,
            title: 'Bubble Active',
            body: 'DashBubble is running',
            icon: 'bubble_icon', // Notification icon in drawable folder
          ),
          onTap: _showOverlayDialog,
        );

        // Now the bubble is on, show a placeholder widget for interaction
         // Show the overlay when bubble is active
      } else {
        // Handle when permission is denied
        print('Overlay permission denied!');
      }
    } else {
      // Stopping the DashBubble
      await DashBubble.instance.stopBubble();
    }
  }

  // Function to show dialog box with gesture detector to act as a tap listener
  void _showOverlayDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController _messageController = TextEditingController();

        return GestureDetector(
          onTap: () {
            Navigator.of(context).pop(); // Close dialog on tap
            _showExpandedDialog(); // Open expanded dialog
          },
          child: AlertDialog(
            title: Text('Bubble Tapped!'),
            content: Text('Tap here to expand and get cat facts.'),
            actions: <Widget>[
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                },
                child: Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }

  // Function to show the expanded dialog with the text field and buttons
  void _showExpandedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController _messageController = TextEditingController();

        return AlertDialog(
          title: Text('Overlay Expanded'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: _messageController,
                decoration: InputDecoration(hintText: "Type your message here..."),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  String fact = await _fetchCatFact();
                  setState(() {
                    _catFact = fact;
                  });
                  Navigator.of(context).pop();
                  _showCatFactDialog(fact); // Show fact in a new dialog
                },
                child: Text('Get Cat Fact'),
              ),
            ],
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // Function to show a dialog with the cat fact
  void _showCatFactDialog(String fact) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Cat Fact'),
          content: Text(fact),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // Function to fetch cat fact from API
  Future<String> _fetchCatFact() async {
    final response = await http.get(Uri.parse('https://catfact.ninja/fact'));
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return jsonResponse['fact'];
    } else {
      return 'Failed to load cat fact';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Overlay App'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'overlay app',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
            Text(
              'now overlay window is ${_isOverlayOn ? "on" : "off"}',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            Switch(
              value: _isOverlayOn,
              onChanged: (value) async {
                setState(() {
                  _isOverlayOn = value;
                });
                await _startOrStopBubble(_isOverlayOn);
              },
              activeTrackColor: Colors.green,
              activeColor: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
