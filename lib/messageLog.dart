import 'package:flutter/material.dart';
import 'api.dart';

void showMessageLog(BuildContext context) async {
  await showDialog(
      context: context,
      builder: (BuildContext context) {
        ThemeData theme = Theme.of(context);
        return SimpleDialog(
          title: Center(
              child: Text('Message Log',
                  style: TextStyle(color: theme.buttonColor))),
          children: Api.messageQueue.map<Widget>((text) {
            return SimpleDialogOption(
                // onPressed: () => Navigator.pop(context),
                child: Row(children: [
              Text('[${text.key}] ',
                  style: TextStyle(color: theme.buttonColor)),
              Text(text.value, style: TextStyle(color: theme.primaryColor))
            ]));
          }).toList(),
        );
      });
}
