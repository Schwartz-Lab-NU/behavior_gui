import 'package:flutter/material.dart';

class SettingsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: settings.length,
      itemBuilder: (context, i) {
        return ExpansionTile(
            // backgroundColor: Colors.black,
            title: Text(settings[i].title,
                style: TextStyle(color: Theme.of(context).buttonColor)),
            children: <Widget>[
              Column(children: _buildListChildren(settings[i], context))
            ]);
      },
    );
  }

  _buildListChildren(Setting setting, BuildContext context) {
    List<Widget> contents = [];
    for (String content in setting.contents) {
      contents.add(ListTile(
        title: Text(
          content,
          style: TextStyle(color: Theme.of(context).primaryColor),
        ),
        leading: Icon(setting.icon, color: Theme.of(context).primaryColor),
      ));
    }
    return contents;
  }
}

class Setting {
  final String title;
  List<String> contents = [];
  final IconData icon;

  Setting(this.title, this.contents, this.icon);
}

List<Setting> settings = [
  Setting('Acquisition', ['nCameras', 'nMicrophones'], Icons.work),
  Setting(
      'Video', ['Frame Capture Rate', 'Frame Display Rate'], Icons.videocam),
  Setting('Audio', ['Sensitivity', 'Gain'], Icons.mic),
  Setting('Post-Processing', ['waitTime', 'nWorkers'], Icons.computer)
];
