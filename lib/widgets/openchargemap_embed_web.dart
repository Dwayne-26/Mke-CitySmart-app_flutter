// Web-only embed for OpenChargeMap using an iframe.
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui; // for platformViewRegistry on web

import 'package:flutter/material.dart';

bool _ocmRegistered = false;

Widget buildOpenChargeMapEmbed(void Function() onOpenExternal) {
  if (!_ocmRegistered) {
    // Register a view factory once for the iframe.
    ui.platformViewRegistry.registerViewFactory(
      'openchargemap-embed',
      (int viewId) {
        final iframe = html.IFrameElement()
          ..src = 'https://map.openchargemap.io/?mode=embedded'
          ..style.border = '0'
          ..allow = 'geolocation'
          ..height = '500'
          ..width = '100%';
        return iframe;
      },
    );
    _ocmRegistered = true;
  }

  return SizedBox(
    height: 500,
    child: const HtmlElementView(viewType: 'openchargemap-embed'),
  );
}
