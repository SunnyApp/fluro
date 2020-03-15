/*
 * fluro
 * Created by Yakka
 * https://theyakka.com
 * 
 * Copyright (c) 2019 Yakka, LLC. All rights reserved.
 * See LICENSE for distribution and usage details.
 */
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';

import '../components/demo/demo_simple_component.dart';
import '../components/home/home_component.dart';
import '../helpers/color_helpers.dart';

final rootHandler = (BuildContext context, Map<String, dynamic> params) => HomeComponent();

final demoRouteHandler = (BuildContext context, Map<String, dynamic> params) {
  String message = params["message"] as String;
  String colorHex = params["color_hex"] as String;
  String result = params["result"] as String;
  Color color = Color(0xFFFFFFFF);
  if (colorHex != null && colorHex.length > 0) {
    color = Color(ColorHelpers.fromHexString(colorHex));
  }
  return DemoSimpleComponent(message: message, color: color, result: result);
};

final demoFunctionHandler = (BuildContext context, Map<String, dynamic> params) {
  String message = params["message"] as String;
  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(
          "Hey Hey!",
          style: TextStyle(
            color: const Color(0xFF00D6F7),
            fontFamily: "Lazer84",
            fontSize: 22.0,
          ),
        ),
        content: Text("$message"),
        actions: <Widget>[
          Padding(
            padding: EdgeInsets.only(bottom: 8.0, right: 8.0),
            child: FlatButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text("OK"),
            ),
          ),
        ],
      );
    },
  );
};

/// Handles deep links into the app
/// To test on Android:
///
/// `adb shell am start -W -a android.intent.action.VIEW -d "fluro://deeplink?path=/message&mesage=fluro%20rocks%21%21" com.theyakka.fluro`
final deepLinkHandler = (BuildContext context, Map<String, dynamic> params) {
  String colorHex = params["color_hex"] as String;
  String result = params["result"] as String;
  Color color = Color(0xFFFFFFFF);
  if (colorHex != null && colorHex.length > 0) {
    color = Color(ColorHelpers.fromHexString(colorHex));
  }
  return DemoSimpleComponent(message: "DEEEEEP LINK!!!", color: color, result: result);
};
