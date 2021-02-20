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
                  child: Padding(
                      padding: EdgeInsets.fromLTRB(24, 20, 24, 24),
                      child: StreamBuilder(
                          stream: Api.onMessage,
                          initialData: null,
                          builder: (context, snapshot) {
                            return ListView.builder(
                              shrinkWrap: true,
                              itemCount: Api.messageQueue.length,
                              itemBuilder: (context, index) {
                                MapEntry<DateTime, String> entry =
                                    Api.messageQueue.elementAt(index);
                                return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('[${entry.key}] ',
                                          style: TextStyle(
                                              color: theme.buttonColor)),
                                      Flexible(
                                          child: Text(entry.value,
                                              style: TextStyle(
                                                  color: theme.primaryColor)))
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
