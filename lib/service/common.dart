import 'dart:convert';
import 'package:flutter/material.dart';

const THEME_COLOR = 0xFFe0cc8d;
const LIST_HEADER_COLOR = Color(THEME_COLOR);
const PROGRESSBAR_COLOR = Color(THEME_COLOR);
const BUTTON_COLOR = Color(THEME_COLOR);
const LABEL_ODD_COLOR = Color(0xFFe0d9c3);
const LABEL_EVEN_COLOR = Color(0xFFe0cc8d);
const LIST_BORDER_COLOR = Color(0xFFe0cc8d);

safeGet(Map data, String key, dynamic defaultValue) {
  final keys = key.split('.');
  return keys.fold(
          data,
          (previousValue, element) =>
              previousValue != null && previousValue.containsKey(element)
                  ? previousValue[element]
                  : null) ??
      defaultValue;
}

final JsonEncoder encoder = new JsonEncoder.withIndent('  ');

prettyJson(Map<dynamic, dynamic> obj) {
  try {
    String res = encoder.convert(obj);
    return res;
  } catch (e) {
    return "$e";
  }
}
