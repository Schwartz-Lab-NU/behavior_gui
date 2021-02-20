import 'package:flutter/material.dart';
import 'api.dart';

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
  void dispose() {
    controller.dispose();
    super.dispose();
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

Widget _buildHeader(Color titleColor, List<String> columns) {
  return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: _buildCells(columns.map<Widget>((title) {
        return Text(title, style: TextStyle(color: titleColor));
      }).toList()));
}

Widget _buildRow(String session, BuildContext context,
    List<List<bool>> completed, List<List<ProcessTag>> tags) {
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
              tags.map<Widget>((tagGroup) {
                List<Widget> children = List.filled(tagGroup.length, null);
                for (int j = 0; j < tagGroup.length; j++) {
                  if (completed[i][j] == null) {
                    children[j] = ShrinkGrow(tagGroup[j].icon, incompleteColor);
                  } else {
                    children[j] = Icon(tagGroup[j].icon,
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
                    height: 500,
                    // child: Expanded(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      _buildHeader(theme.buttonColor, ProcessingStatus.columns),
                      _Table(),
                      SizedBox(height: 10),
                      SizedBox(
                          height: 50,
                          child: Center(
                              child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              SizedBox(
                                  width: 250,
                                  // child: _CheckBox('Enable DeepSqueak')
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
                    ])) //)
            // ),
            );
      });
}

class _Table extends StatefulWidget {
  @override
  _TableState createState() => _TableState();
}

class _TableState extends State<_Table> {
  ScrollController _scrollController = ScrollController();
  bool _done = false;
  int _length = ProcessingStatus().length;
  ProcessingStatus _processingStatus = ProcessingStatus();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
              _scrollController.position.maxScrollExtent &&
          !_done) {
        print('reached end of page');
        Future.wait([
          ProcessingStatus.next(15),
          Future.delayed(Duration(seconds: 1)),
        ]).then((_) {
          print('new status length: ${_processingStatus.length}');
          setState(() {
            _done = _processingStatus.length < _length + 15;
            _length = _processingStatus.length;
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    List<List<ProcessTag>> tags = ProcessingStatus.processTags.sublist(1);
    return Expanded(
      // height: 500,
      child: ListView.builder(
          controller: _scrollController,
          shrinkWrap: true,
          itemCount: _length + 1,
          itemBuilder: (BuildContext ctx, int index) {
            if (index == _length) {
              if (_done) {
                return Container();
              } else {
                print('returning progress wheel');
                return SizedBox(
                    height: 36,
                    child: Center(
                        child: LinearProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(ctx).buttonColor),
                    )));
              }
            }

            // List<List<bool>> completed =
            //     List.filled(_processingSteps.length, null);

            // for (int i = 0; i < _processingSteps.length; i++) {
            //   int nValues = _processingSteps.values.toList()[i].length;
            //   List<bool> thisCompleted = List.filled(nValues, true);
            //   for (int j = 0; j < nValues; j++) {
            //     if (index >= 12) {
            //       thisCompleted[j] = false;
            //     }
            //     if ((index == 12) && (i == 0)) {
            //       if (j < 1) {
            //         thisCompleted[j] = true;
            //       } else if (j == 1) {
            //         thisCompleted[j] = null;
            //       }
            //     }
            //   }

            //   completed[i] = thisCompleted;
            // }
            return _buildRow(_processingStatus[index].key, ctx,
                _processingStatus[index].value, tags);
          }),
    );
  }
}

class _CheckBox extends StatefulWidget {
  _CheckBox(this.title, this.listenable, this.callback);
  final String title;
  final Stream<bool> listenable;
  final void Function(bool) callback;

  @override
  _CheckBoxState createState() => _CheckBoxState();
}

class _CheckBoxState extends State<_CheckBox> {
  bool _isChecked = false;

  @override
  void initState() {
    super.initState();
    widget.listenable.listen((isRunning) {
      setState(() {
        _isChecked = isRunning;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    return CheckboxListTile(
        title: Text(widget.title, style: TextStyle(color: theme.primaryColor)),
        value: _isChecked,
        checkColor: theme.buttonColor,
        activeColor: theme.backgroundColor,
        onChanged: widget.callback);
  }
}

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
  ProcessingStatus();
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
