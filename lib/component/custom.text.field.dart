import 'package:abbys/component/json.form/json_schema.dart';
import 'package:abbys/service/common.dart';
import 'package:clipboard_manager/clipboard_manager.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

typedef CustomTextFieldCallback = dynamic Function(dynamic value);

class CustomTextField extends StatefulWidget {
  final int maxLines;
  final bool readOnly;
  final bool copyButton;
  final String initialValue;
  final InputDecoration decoration;
  final FocusNode focusNode;
  final CustomTextFieldCallback onChanged;
  final bool obscureText;
  final CustomTextFieldCallback validator;
  final TextInputType keyboardType;
  final JsonSchemaType fieldType;

  CustomTextField(
      {maxLines = 1,
      readOnly = false,
      initialValue,
      decoration,
      focusNode,
      onChanged,
      obscureText = false,
      validator,
      copyButton = false,
      keyboardType = TextInputType.text,
      fieldType = JsonSchemaType.Input})
      : this.maxLines = maxLines,
        this.readOnly = readOnly,
        this.initialValue = initialValue,
        this.decoration = decoration,
        this.focusNode = focusNode,
        this.onChanged = onChanged,
        this.obscureText = obscureText,
        this.validator = validator,
        this.keyboardType = keyboardType,
        this.copyButton = copyButton,
        this.fieldType = fieldType;
  @override
  _CustomTextFieldState createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText;
  TextEditingController myController;
  _handleChange() {
    return widget.onChanged(myController.text);
  }

  _init() {
    //if (myController != null) myController.dispose();
    myController = TextEditingController(text: widget.initialValue);
    myController.addListener(_handleChange);
  }

  @override
  void initState() {
    _init();
    super.initState();
  }

  @override
  void reassemble() {
    _init();
    super.reassemble();
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is removed from the
    // widget tree.
    myController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    InputDecoration decoration = widget.decoration;
    if (widget.copyButton) {
      decoration = InputDecoration(
          suffixIcon: widget.fieldType == JsonSchemaType.Password
              ? IconButton(
                  icon: Icon(_obscureText ?? widget.obscureText
                      ? Icons.visibility
                      : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _obscureText = !(_obscureText ?? widget.obscureText);
                    });
                  },
                )
              : IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      myController.text = "";
                    });
                  },
                ),
          prefixIcon: IconButton(
            icon: Icon(Icons.list),
            onPressed: () {
              ClipboardManager.copyToClipBoard(myController.text)
                  .then((result) async {
                await Fluttertoast.showToast(
                    msg: "Copied to Clipboard",
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.TOP,
                    timeInSecForIosWeb: 1,
                    backgroundColor: BUTTON_COLOR,
                    textColor: Colors.black,
                    fontSize: 16.0);
              });
            },
          ));
    }
    return TextFormField(
        controller: myController,
        readOnly: widget.readOnly,
        decoration: decoration,
        maxLines: widget.maxLines,
        focusNode: widget.focusNode,
        obscureText: _obscureText ?? widget.obscureText,
        validator: (String v) => widget.validator(v));
  }
}
