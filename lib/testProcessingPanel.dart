import 'package:flutter/material.dart';

class ShrinkGrow extends StatefulWidget {
  final IconData icon;
  final Color color;
  ShrinkGrow(this.icon, this.color);

  @override
  _ShrinkGrowState createState() => _ShrinkGrowState();
}

class _ShrinkGrowState extends State<ShrinkGrow>
    with SingleTickerProviderStateMixin {
  AnimationController controller;
  Animation animation;

  @override
  void initState() {
    super.initState();

    controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 500))
          ..forward()
          ..repeat(reverse: true);

    // animation =
    animation = Tween(begin: .7, end: 1.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
        scale: animation, child: Icon(widget.icon, color: widget.color));
  }
}

List<Widget> _buildCells(List<Widget> children) {
  return children.map<Widget>((child) {
    return SizedBox(child: Center(child: child), width: 120, height: 20);
  }).toList();
}

Widget _buildHeader(Color titleColor) {
  return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: _buildCells(
          <Widget>[Text('SESSION', style: TextStyle(color: titleColor))] +
              _processingSteps.keys.map<Widget>((title) {
                return Text(title, style: TextStyle(color: titleColor));
              }).toList()));
}

Widget _buildRow(
    String session, BuildContext context, List<List<bool>> completed) {
  int i = 0;
  Color completeColor = Theme.of(context).buttonColor;
  Color incompleteColor = Theme.of(context).unselectedWidgetColor;

  return Padding(
      padding: EdgeInsets.fromLTRB(0, 8, 0, 8),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: _buildCells(<Widget>[
                Text(session,
                    style: TextStyle(color: Theme.of(context).primaryColor)),
              ] +
              _processingSteps.values.map<Widget>((icons) {
                List<Widget> children = List.filled(icons.length, null);
                for (int j = 0; j < icons.length; j++) {
                  if (completed[i][j] == null) {
                    children[j] = ShrinkGrow(icons[j], incompleteColor);
                  } else {
                    children[j] = Icon(icons[j],
                        color:
                            completed[i][j] ? completeColor : incompleteColor);
                  }
                }
                i += 1;

                return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: children);
              }).toList())));
}

void _showDialog(BuildContext context) async {
  int currentlyProcessing = 12;

  await showDialog(
      context: context,
      builder: (BuildContext context) {
        ThemeData theme = Theme.of(context);
        return AlertDialog(
            title: Center(
                child: Text('Processing Status',
                    style: TextStyle(color: theme.primaryColor))),
            content:
                // Padding(
                //     padding: EdgeInsets.fromLTRB(24, 20, 24, 36),
                //     child:
                SizedBox(
                    width: 750,
                    child: Expanded(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                      _buildHeader(theme.buttonColor),
                      Expanded(
                        // height: 500,
                        child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: 15,
                            itemBuilder: (BuildContext ctx, int index) {
                              List<List<bool>> completed =
                                  List.filled(_processingSteps.length, null);

                              for (int i = 0;
                                  i < _processingSteps.length;
                                  i++) {
                                int nValues =
                                    _processingSteps.values.toList()[i].length;
                                List<bool> thisCompleted =
                                    List.filled(nValues, true);
                                for (int j = 0; j < nValues; j++) {
                                  if (index >= 12) {
                                    thisCompleted[j] = false;
                                  }
                                  if ((index == 12) && (i == 0)) {
                                    if (j < 1) {
                                      thisCompleted[j] = true;
                                    } else if (j == 1) {
                                      thisCompleted[j] = null;
                                    }
                                  }
                                }

                                completed[i] = thisCompleted;
                              }
                              return _buildRow('mouse $index', ctx, completed);
                            }),
                      ),
                      SizedBox(height: 10),
                      SizedBox(
                          height: 50,
                          child: Center(
                              child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              SizedBox(
                                  width: 250,
                                  child: CheckboxListTile(
                                      title: Text('Enable DeepSqueak',
                                          style: TextStyle(
                                              color: theme.primaryColor)),
                                      value: false,
                                      checkColor: theme.buttonColor,
                                      activeColor: theme.backgroundColor,
                                      onChanged: (running) => debugPrint(
                                          'ds ${running ? "on" : "false"}'))),
                              SizedBox(
                                  width: 250,
                                  child: CheckboxListTile(
                                      title: Text('Enable DeepLabCut',
                                          style: TextStyle(
                                              color: theme.primaryColor)),
                                      value: true,
                                      checkColor: theme.buttonColor,
                                      activeColor: theme.backgroundColor,
                                      onChanged: (running) => debugPrint(
                                          'dlc ${running ? "on" : "false"}')))
                            ],
                          )))
                    ])))
            // ),
            );
      });
}

Map<String, List<IconData>> _processingSteps = {
  'CALIBRATION': [
    Icons.file_copy,
    Icons.blur_on,
    Icons.center_focus_weak,
    Icons.qr_code_scanner,
  ],
  'DEEPSQUEAK': [Icons.graphic_eq],
  'DEEPLABCUT': [Icons.scatter_plot, Icons.view_in_ar],
  'MIGRATION': [Icons.cloud_done, Icons.save]
};

class DialogButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
        child: TextButton(
      child: Text('press me'),
      onPressed: () => _showDialog(context),
    ));
  }
}

void main() {
  runApp(MaterialApp(
      home: Scaffold(body: DialogButton()),
      theme: ThemeData(
        brightness: Brightness.dark,
        backgroundColor: Colors.white,
        dialogBackgroundColor: Colors.white,
        primaryColor: Color.fromARGB(255, 50, 50, 50),
        accentColor: Colors.cyan,
        buttonColor: Colors.lightBlue,
        unselectedWidgetColor: Colors.grey,
      )));
}
