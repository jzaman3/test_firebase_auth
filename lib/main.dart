import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(MessagingApp());
}

class MessagingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FCM Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MessagingHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MessagingHomePage extends StatefulWidget {
  @override
  State<MessagingHomePage> createState() => _MessagingHomePageState();
}

class _MessagingHomePageState extends State<MessagingHomePage> {
  late FirebaseMessaging _messaging;
  String? _fcmToken;
  List<String> _notificationHistory = [];

  @override
  void initState() {
    super.initState();
    initFirebaseMessaging();
  }

  void initFirebaseMessaging() async {
    _messaging = FirebaseMessaging.instance;

    // Get the FCM token
    _messaging.getToken().then((token) {
      setState(() {
        _fcmToken = token;
      });
      print("FCM Token: $token");
    });

    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Message Received: ${message.notification?.title}");
      print("Data: ${message.data}");

      String body = message.notification?.body ?? "No message body";
      String type = message.data['notificationType'] ?? 'regular';
      Color bgColor = type == 'important' ? Colors.red : Colors.blue;
      String title = type == 'important' ? "🔥 Important Notification" : "🔔 Regular Notification";

      setState(() {
        _notificationHistory.add("$title: $body");
      });

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: bgColor,
          title: Text(title, style: TextStyle(color: Colors.white)),
          content: Text(body, style: TextStyle(color: Colors.white)),
          actions: [
            TextButton(
              child: Text("OK", style: TextStyle(color: Colors.white)),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    });

    // Message when app is opened via a notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("Notification clicked!");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Firebase Messaging"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("FCM Token (copy to send test):", style: TextStyle(fontWeight: FontWeight.bold)),
            SelectableText(_fcmToken ?? "Loading..."),
            SizedBox(height: 20),
            Text("Notification History:", style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: _notificationHistory.length,
                itemBuilder: (context, index) => ListTile(
                  title: Text(_notificationHistory[index]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
