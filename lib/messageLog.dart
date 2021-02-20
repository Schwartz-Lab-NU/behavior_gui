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
            children: [
              SizedBox(
                  height: 500,
                  width: 750,
                  child: Expanded(
                      child: StreamBuilder(
                          stream: Api.onMessage,
                          initialData: null,
                          builder: (context, snapshot) {
                            return ListView.builder(
                              itemCount: Api.messageQueue.length,
                              itemBuilder: (context, index) {
                                MapEntry<DateTime, String> entry =
                                    Api.messageQueue[index];
                                return Row(children: [
                                  Text('[${entry.key}] ',
                                      style:
                                          TextStyle(color: theme.buttonColor)),
                                  Text(entry.value,
                                      style:
                                          TextStyle(color: theme.primaryColor))
                                ]);
                              },
                            );
                          })))
            ]
            //   Api.messageQueue.map<Widget>((text) {
            //     return SimpleDialogOption(
            //         // onPressed: () => Navigator.pop(context),
            //         child: Row(children: [
            //       Text('[${text.key}] ',
            //           style: TextStyle(color: theme.buttonColor)),
            //       Text(text.value, style: TextStyle(color: theme.primaryColor))
            //     ]));
            //   }).toList(),
            );
      });
}
