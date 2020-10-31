import 'package:abbys/component/wave.progress.dart';
import 'package:abbys/service/common.dart';
import 'package:abbys/service/db.dart';
import 'package:abbys/service/route.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class StartScreen extends StatefulWidget {
  final DbService service;
  StartScreen(this.service);
  @override
  _StartScreenState createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  bool _loaded = false;
  _load() async {
    try {
      await widget.service.reload();
      Map res = await widget.service.load();
      if (res != null)
        Navigator.pushReplacementNamed(context, Routes.homeScreen,
            arguments: res);
      else
        await Fluttertoast.showToast(
            msg: "Loading failed!",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.TOP,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.redAccent[100],
            textColor: Colors.black,
            fontSize: 16.0);
      //Navigator.pushNamed(context, Routes.homeScreen, arguments: res),
      //await _service.save(res)
    } catch (e) {
      await Fluttertoast.showToast(
          msg: "Failed to Load Data",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.redAccent[100],
          textColor: Colors.black,
          fontSize: 16.0);
    }
  }

  reload() {
    if (_loaded == false) {
      setState(() {
        _loaded = true;
      });

      return new Future.delayed(
          const Duration(seconds: 1), () async => {await _load()});
    }
  }

  @override
  Widget build(BuildContext context) {
    reload();
    return Scaffold(
        appBar: AppBar(
          title: Text("Loading..."),
        ),
        body: Center(
          child: Column(children: [
            Expanded(
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                  WaveProgress(
                      180.0, PROGRESSBAR_COLOR, PROGRESSBAR_COLOR, 40.0)
                ]))
          ]),
        ));
  }
}
