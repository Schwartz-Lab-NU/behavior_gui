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
    return SizedBox(child: Center(child: child), width: 100, height: 20);
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

Widget _buildRow(String session, List<Color> colors, int animating) {
  int i = 0;
  return Padding(
      padding: EdgeInsets.fromLTRB(0, 8, 0, 8),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: _buildCells(<Widget>[
                Text(session, style: TextStyle(color: colors[0])),
              ] +
              _processingSteps.values.map<Widget>((icon) {
                i += 1;
                if (i == animating) {
                  return ShrinkGrow(icon, colors[i]);
                }
                return Icon(icon, color: colors[i]);
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
                    width: 700,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      _buildHeader(theme.buttonColor),
                      SizedBox(
                        height: 500,
                        child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: 15,
                            itemBuilder: (BuildContext ctx, int index) {
                              List<Color> colors;
                              int animating;
                              if (index < currentlyProcessing) {
                                colors = [theme.primaryColor] +
                                    List<Color>.filled(4, theme.buttonColor);
                                // List<Color>.filled(4, Colors.lightBlue);
                              } else if (index == currentlyProcessing) {
                                colors = [theme.primaryColor] +
                                    List<Color>.filled(2, theme.buttonColor) +
                                    List<Color>.filled(
                                        2, theme.unselectedWidgetColor);
                                animating = 3;
                              } else {
                                colors = [theme.primaryColor] +
                                    List<Color>.filled(
                                        4, theme.unselectedWidgetColor);
                              }
                              return _buildRow(
                                  'mouse $index', colors, animating);
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
                    ]))
            // ),
            );
      });
}

Map<String, IconData> _processingSteps = {
  'UNDISTORTED': Icons.qr_code_scanner,
  'DEEPSQUEAK': Icons.graphic_eq,
  'DEEPLABCUT': Icons.scatter_plot,
  'UPLOADED': Icons.cloud_done
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
