import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  TextEditingController userController = TextEditingController();

  TextEditingController titleController = TextEditingController();

  TextEditingController bodyController = TextEditingController();
  String? mToken = "";
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    getToken();
    initInfo();
  }

  void getToken() async {
    await FirebaseMessaging.instance.getToken().then((token) {
      setState(() {
        mToken = token;
        print("---> my token is ${mToken}");
      });
      saveToken(token!);
    });
  }

  void saveToken(String token) async {
    await FirebaseFirestore.instance.collection("Tokens").doc("user1").set(
      {
        "token": token,
      },
    );
  }

  void initInfo() {
    var androidInitialization =
        const AndroidInitializationSettings("@mipmap/ic_launcher");
    var iosInitialization = const DarwinInitializationSettings();
    var initializationSettings = InitializationSettings(
        android: androidInitialization, iOS: iosInitialization);
    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
    );

    FirebaseMessaging.onMessage.listen((event) async {
      //
      BigTextStyleInformation bigTextStyleInformation = BigTextStyleInformation(
        event.notification!.body.toString(),
        htmlFormatBigText: true,
        contentTitle: event.notification!.title.toString(),
        htmlFormatContentTitle: true,
      );
      //
      AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
        "channelId",
        "channelName",
        styleInformation: bigTextStyleInformation,
        importance: Importance.high,
        priority: Priority.max,
        playSound: true,
      );
      //
      NotificationDetails notificationDetails = NotificationDetails(
          android: androidNotificationDetails,
          iOS: const DarwinNotificationDetails());
      //
      await flutterLocalNotificationsPlugin.show(0, event.notification?.title,
          event.notification?.body, notificationDetails);
    });
  }

  void sentPushMessage(String token, String title, String body) async {
    try {
      await http.post(Uri.parse("https://fcm.googleapis.com/fcm/send"),
          headers: {
            "Content-Type": "application/json",
            "Authorization":
                "key=AAAAsR92O7I:APA91bESERrExUBsSfvgeLfNF2uHEMWURE1n4a-wVJuLERG6f2Hy7oocfl_j3lt9Gvaq-xO6cxVuNbiOM7cT0A0JHUeYzFH1xab2DrA8_OlvBAU5pOYLgH1EWBEniwHcuURdlfsfZXOg"
          },
          body: jsonEncode({
            "notification": {
              "title": title,
              "text": body,
              "android_channel_id": "channelId",
              "click_action": "OPEN_ACTIVITY_1"
            },
            "data": {"body": body, "title": title},
            "to": token
          }));
    } catch (e) {
      if (kDebugMode) {
        print("---> error notification");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          TextField(
            controller: userController,
          ),
          TextField(
            controller: titleController,
          ),
          TextField(
            controller: bodyController,
          ),
          ElevatedButton(
              onPressed: () async {
                String name = userController.text.trim();
                String title = titleController.text.trim();
                String body = bodyController.text.trim();
                if (name != '') {
                  DocumentSnapshot snap = await FirebaseFirestore.instance
                      .collection("Tokens")
                      .doc(name)
                      .get();
                  String token = snap['token'];
                  sentPushMessage(token, title, body);
                }
              },
              child: Text("Push"))
        ],
      ),
    );
  }
}
