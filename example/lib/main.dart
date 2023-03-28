import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bugly/flutter_bugly.dart';

void main() => FlutterBugly.postCatchedException(() => runApp(MyApp()));

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: HomePage());
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _platformVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
    const buglyIosAppId = '1190fcf697';
    const buglyAndroidAppId = '7f0f0ad7ec';
    FlutterBugly.init(
      androidAppId: buglyAndroidAppId, //"your app id",
      iOSAppId: buglyIosAppId, //"your app id",
      isDebug: true,
      reportDelay: 5000,
    ).then((_result) {
      setState(() {
        _platformVersion = _result.message;
        print(_result.appId);
      });
    });

    FlutterBugly.setUserId("user id");
    FlutterBugly.putUserData(key: "key", value: "value");
    int tag = 9527;
    FlutterBugly.setUserTag(tag);
  }

  @override
  void dispose() {
    FlutterBugly.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plugin example app')),
      body: GestureDetector(
        onTap: () {
          if (Platform.isAndroid) {}
        },
        child: Center(
          child: Text('init result: $_platformVersion\n'),
        ),
      ),
      persistentFooterButtons: [
        ElevatedButton(
          onPressed: () {
            FlutterBugly.uploadException(
              message: 'this is a other test bug',
              detail: 'this is a test detail',
            );
          },
          child: Text('create a bug'),
        ),
        ElevatedButton(
            onPressed: () {
              FlutterBugly.setDeviceId('user deviceId');
            },
            child: Text('setDeviceId')),
        ElevatedButton(
            onPressed: () {
              FlutterBugly.setDeviceModel('user deviceModel');
            },
            child: Text('setDeviceModel')),
        ElevatedButton(
            onPressed: () {
              FlutterBugly.setUserId('test userId');
            },
            child: Text('setUserId')),
      ],
    );
  }
}
