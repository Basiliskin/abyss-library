import 'package:abbys/component/badge/badges.dart';
import 'package:abbys/service/common.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';

const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
Random _rnd = Random();

String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
    length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1).toLowerCase()}";
  }
}

class ListFilter {
  final String value;
  final String label;
  ListFilter(this.value, this.label);
  filtered(Map data) {
    if (value != "") return containString(data, value);
    if (label != "") return containLabel(data, label);
    return true;
  }

  isEmpty() {
    return value == "" && label == "";
  }

  propertyContainString(Map data, String name, String text) {
    bool found = false;
    if (data.containsKey(name)) {
      final v = data[name];
      if (v is List) {
        v.forEach((element) {
          if (found == false && element is String) {
            found = element.indexOf(text) >= 0;
          }
        });
      } else if (v is String) {
        found = v.indexOf(text) >= 0;
      }
    }
    return found;
  }

  bool containString(Map data, String text) {
    bool found = false;
    data.forEach((k, v) =>
        {if (found == false) found = propertyContainString(data, k, text)});
    return found;
  }

  bool containLabel(Map data, String text) {
    return propertyContainString(data, "label", text);
  }

  getAttribute(Map data, String name, String defaultValue) {
    return data.containsKey(name) ? data[name] : defaultValue;
  }

  mapLabels(Map data, Map<String, int> dic) {
    if (data.containsKey("label")) {
      List labels = data["label"];
      labels.forEach((element) {
        if (dic.containsKey(element))
          dic[element] += 1;
        else
          dic[element] = 1;
      });
    }
  }
}

class ListIntValue {
  final String name;
  final int value;
  ListIntValue(this.name, this.value);
  get title {
    return toBeginningOfSentenceCase(name);
  }
}

abstract class ListItem {
  /// The title line to show in a list item.
  Widget buildItem(BuildContext context);
  bool containString(String text);
  bool propertyContainString(String name, String text);
  mapLabels(Map<String, int> dic);
  itemData();
  setData(Map data);
  getAttribute(String name, String defaultValue);
}

class ListItemComponent extends StatelessWidget {
  final Map data;
  final Function(String) searchByLabel;
  final Function(Map) setFavorite;
  ListItemComponent({Key key, this.data, this.searchByLabel, this.setFavorite})
      : super(key: key);

  Widget buildDesc(BuildContext context) {
    List labels = data.containsKey("label") ? data["label"] : [];
    double containerHeight = 32.0;
    String description = data.containsKey("description")
        ? data["description"]
        : "no description";
    String name = data.containsKey("title") ? data["title"] : "undefined";
    List<Widget> children = <Widget>[];
    final isFavorite = safeGet(data, 'isFavorite', false);
    final title = Flexible(
        child: Text(
      toBeginningOfSentenceCase(name),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 14.0,
        color: Colors.black,
        //backgroundColor: LIST_HEADER_COLOR,
        decoration: TextDecoration.underline,
        fontWeight: FontWeight.bold,
      ),
    ));
    final badge = Badge(
        alignment: Alignment(1.3, 0.3),
        badgeColor: isFavorite ? STAR_COLOR : STAR_NOT_COLOR,
        shape: BadgeShape.circle,
        borderRadius: 10,
        toAnimate: false,
        badgeContent: Icon(Icons.star));

    int time = safeGet(data, 'time', 0);
    DateTime dd = new DateTime.fromMicrosecondsSinceEpoch(time);
    String formattedDate =
        time != 0 ? DateFormat('yyyy-MM-dd hh:mm').format(dd) : "";

    children.add(Row(
      children: [
        GestureDetector(onTap: () => {setFavorite(data)}, child: badge),
        Padding(padding: EdgeInsets.only(right: 10)),
        title
      ],
    ));
    children.add(Padding(padding: EdgeInsets.only(bottom: 10)));
    children.add(Text(
      formattedDate,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 10.0,
        color: Colors.black54,
        fontWeight: FontWeight.bold,
      ),
    ));

    children.add(Padding(padding: EdgeInsets.only(bottom: 10)));
    children.add(Text(
      description,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 10.0,
        color: Colors.black54,
        fontWeight: FontWeight.bold,
      ),
    ));

    double cWidth = MediaQuery.of(context).size.width * 0.8;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(children: <Widget>[
                Container(
                  width: cWidth,
                  child: new Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: children),
                )
              ]),
            ],
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
                height: containerHeight,
                child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: labels.length,
                    itemBuilder: (context, index) {
                      final badge = Badge(
                          badgeColor: index % 2 != 0
                              ? LABEL_ODD_COLOR
                              : LABEL_EVEN_COLOR,
                          shape: BadgeShape.square,
                          borderRadius: 10,
                          toAnimate: false,
                          badgeContent: Text(
                              toBeginningOfSentenceCase(labels[index]),
                              style: TextStyle(color: Colors.black)));

                      return Row(children: <Widget>[
                        Padding(
                            padding: EdgeInsets.only(left: 5.0, right: 5.0)),
                        GestureDetector(
                            onTap: () => {searchByLabel(labels[index])},
                            child: badge)
                      ]);
                    })),
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(2.0),
      padding: const EdgeInsets.all(3.0),
      decoration: BoxDecoration(border: Border.all(color: LIST_BORDER_COLOR)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: SizedBox(
          height: DLIST_ITEM_HEIGHT,
          width: DLIST_ITEM_WIDTH,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 5.0),
                  child: buildDesc(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ListItemData implements ListItem {
  final Map data;
  final Function(String) searchByLabel;
  final Function(Map) setFavorite;
  getAttribute(String name, String defaultValue) {
    return data.containsKey(name) ? data[name] : defaultValue;
  }

  itemData() {
    return data;
  }

  setData(Map d) {
    data.removeWhere((key, value) => true);
    d.forEach((key, value) {
      data[key] = value;
    });
  }

  ListItemData(this.data, this.searchByLabel, this.setFavorite);

  Widget buildItem(BuildContext context) {
    return ListItemComponent(
        data: data, searchByLabel: searchByLabel, setFavorite: setFavorite);
  }

  mapLabels(Map<String, int> dic) {
    if (data.containsKey("label")) {
      List labels = data["label"];
      labels.forEach((element) {
        if (dic.containsKey(element))
          dic[element] += 1;
        else
          dic[element] = 1;
      });
    }
  }

  bool propertyContainString(String name, String text) {
    bool found = false;
    if (data.containsKey(name)) {
      final v = data[name];
      if (v is List) {
        v.forEach((element) {
          if (found == false && element is String) {
            found = element.indexOf(text) >= 0;
          }
        });
      } else if (v is String) {
        found = v.indexOf(text) >= 0;
      }
    }
    return found;
  }

  bool containString(String text) {
    bool found = false;
    data.forEach(
        (k, v) => {if (found == false) found = propertyContainString(k, text)});
    return found;
  }
}
