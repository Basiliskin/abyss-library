import 'dart:io';
import 'dart:typed_data';

import 'package:abbys/service/common.dart';
import 'package:abbys/service/db.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:image_picker/image_picker.dart';

class BinaryImage extends StatelessWidget {
  final Uint8List data;

  BinaryImage(this.data);
  @override
  Widget build(BuildContext context) {
    return Image.memory(
      data,
      fit: BoxFit.fitWidth,
      width: 120,
      height: 60,
    );
  }
}

class DriverImageComponent extends StatefulWidget {
  final String fileId;
  final DbService service;
  final Function(String) onRemove;
  final Function(bool) isLoading;
  DriverImageComponent(
      this.fileId, this.service, this.onRemove, this.isLoading);
  @override
  _DriverImageComponentState createState() => _DriverImageComponentState();
}

class _DriverImageComponentState extends State<DriverImageComponent> {
  Uint8List _data;
  bool isLoaded = false;

  _removeImage() async {
    widget.isLoading(true);
    try {
      bool res = await widget.service.removeFileById(widget.fileId);
      if (res) {
        widget.onRemove(widget.fileId);
      }
    } catch (e) {
      widget.onRemove(widget.fileId);
    }
    widget.isLoading(false);
  }

  @override
  void initState() {
    super.initState();
  }

  saveImage() async {
    if (_data != null) {
      File file = await widget.service.getTemporayFile(widget.fileId);
      await file.writeAsBytes(_data);

      final result = await ImageGallerySaver.saveFile(file.path);
      await file.delete();
      await Fluttertoast.showToast(
          msg: "File saved -> $result",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.blueAccent[100],
          textColor: Colors.black,
          fontSize: 16.0);
    }
  }

  _downloadImage() async {
    final data = await widget.service.downloadFileById(widget.fileId);
    if (data != null) {
      setState(() {
        _data = data;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoaded == false) {
      setState(() {
        isLoaded = true;
        _downloadImage();
      });
    }
    final comp = _data != null ? BinaryImage(_data) : Container();
    List<Widget> items = [];
    items.add(comp);
    if (_data != null)
      items.add(Container(
        height: 32.0,
        width: 32.0,
        child: FittedBox(
          child: FloatingActionButton(
            child: Icon(Icons.delete),
            onPressed: () => _removeImage(),
          ),
        ),
      ));
    return Row(children: <Widget>[
      Padding(padding: EdgeInsets.only(left: 5.0, right: 5.0)),
      GestureDetector(
          onTap: () => {saveImage()},
          child: Stack(alignment: Alignment.bottomRight, children: items))
    ]);
  }
}

class ImageField extends StatefulWidget {
  final Map item;

  final DbService service;
  final Function _handleChanged;
  final Function(bool) isLoading;
  final picker = ImagePicker();
  ImageField(this.item, this.service, this._handleChanged, this.isLoading);
  @override
  _ImageFieldState createState() => _ImageFieldState();
  updateItem(value) {
    item["value"] = new List<String>.from(value);
    _handleChanged(item);
  }

  List<String> getList() {
    List labels = safeGet(item, "value", []);
    return List<String>.from(labels);
  }
}

class _ImageFieldState extends State<ImageField> {
  List<String> imgList;

  _init() {
    imgList = widget.getList();
  }

  @override
  void initState() {
    _init();
    super.initState();
  }

  @override
  void reassemble() {
    super.reassemble();
  }

  _image(String src) {
    if (src != null) {
      return DriverImageComponent(
          src, widget.service, _removeImage, widget.isLoading);
    } else {
      return Row(children: [
        Center(
            child: Container(
          child: FittedBox(
            child: FloatingActionButton(
              backgroundColor: BUTTON_COLOR,
              child: Icon(
                Icons.add,
                color: Colors.black,
              ),
              onPressed: () => _addImage(),
            ),
          ),
        ))
      ]);
    }
  }

  _removeImage(fileId) async {
    setState(() => {imgList.remove(fileId), widget.updateItem(imgList)});
  }

  _addImage() async {
    final pickedFile = await widget.picker.getImage(source: ImageSource.camera);
    widget.isLoading(true);
    if (pickedFile != null) {
      File image = File(pickedFile.path);
      String fileId = await widget.service.uploadToFolder('abyss-image', image);
      if (fileId != null)
        setState(() => {imgList.add(fileId), widget.updateItem(imgList)});
      print(fileId);
    } else {
      print('No image selected.');
    }
    widget.isLoading(false);
  }

  _content(BuildContext context) {
    List<String> images = [null];
    images.addAll(imgList);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
                child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      String imageUrl = images[index];

                      return _image(imageUrl);
                    })),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        child: SafeArea(
            child: Column(children: <Widget>[
      Container(width: 320, height: 80, child: _content(context))
    ])));
  }
}
