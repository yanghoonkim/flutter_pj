import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:mnist/brain.dart';
import 'package:mnist/drawing_painter.dart';
import 'constants.dart';

class RecognizerScreen extends StatefulWidget {
  final String title;

  const RecognizerScreen({super.key, required this.title});

  @override
  State<RecognizerScreen> createState() => _RecognizerScreenState();
}

class _RecognizerScreenState extends State<RecognizerScreen> {
  List<Offset?> points = <Offset?>[];
  AppBrain brain = AppBrain();
  List<BarChartGroupData> chartItems = <BarChartGroupData>[];
  String headerText = 'Header placeholder';
  String footerText = 'Footer placeholder';

  void _resetText() {
    headerText = kWaitingForInputHeaderString;
    footerText = kWaitingForInputFooterString;
  }

  void _setTextForGuess(String guess) {
    headerText = "";
    footerText = kGuessingInputString + guess;
  }

  void _cleanDrawing() {
    points = <Offset?>[];
    _resetText();
    setState(() {});
  }

  void _buildBarChartInfo({List predictions = const []}) {
    chartItems = <BarChartGroupData>[];
    // create as many barGroups as outputs our predictions has
    for (var i = 0; i < kModelOutputSize; i++) {
      var barGroup = _makeGroupData(i, 0);
      chartItems.add(barGroup);
    }

    // for each one of our predictions, attach the probability to the right index
    var len = predictions.length;
    for (var i = 0; i < len; i++) {
      chartItems[i] = _makeGroupData(i, predictions[i]);
    }
  }

  BarChartGroupData _makeGroupData(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: kBarColor,
          width: kBarWidth,
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 1,
            color: kBarBackgroundColor,
          ),
        )
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    brain.loadModel();
    _buildBarChartInfo();
    _resetText();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.blue,
      ),
      body: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.all(16),
                alignment: Alignment.center,
                child: Text(
                  headerText,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  width: 3,
                  color: Colors.blue,
                ),
              ),
              child: Builder(builder: (context) {
                return GestureDetector(
                  onPanStart: (details) {
                    setState(() {
                      RenderBox renderBox =
                          context.findRenderObject() as RenderBox;
                      points
                          .add(renderBox.globalToLocal(details.globalPosition));
                    });
                  },
                  onPanUpdate: (details) {
                    setState(() {
                      RenderBox renderBox =
                          context.findRenderObject() as RenderBox;
                      points
                          .add(renderBox.globalToLocal(details.globalPosition));
                    });
                  },
                  onPanEnd: (details) async {
                    points.add(null);

                    var item = await brain.processCanvasPoints(points);
                    var item_ = item[0];
                    print(item_.reduce(
                        (double value, double element) => value + element));

                    int maxIdx = 0;
                    double maxVal = item_[0];
                    for (int i = 1; i < item_.length; i++) {
                      if (item_[i] > maxVal) {
                        maxVal = item_[i];
                        maxIdx = i;
                      }
                    }

                    print(maxIdx);

                    _buildBarChartInfo(predictions: item_);
                    _setTextForGuess(maxIdx.toString());
                    setState(() {});
                    //List predictions = await brain.processCanvasPoints(points);
                    //print(predictions);
                    //print(points);
                  },
                  child: ClipRRect(
                    child: CustomPaint(
                      size: const Size(kCanvasSize, kCanvasSize),
                      painter: DrawingPainter(
                        offsetPoints: points,
                      ),
                    ),
                  ),
                );
              }),
            ),
            Text(footerText, style: Theme.of(context).textTheme.headlineMedium),
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.all(16),
                alignment: Alignment.center,
                child: BarChart(
                  BarChartData(
                    titlesData: FlTitlesData(
                      show: true,
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) =>
                              Text(value.toInt().toString()),
                        ),
                      ),
                    ),
                    barGroups: chartItems,
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(show: false),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _cleanDrawing();
          _buildBarChartInfo();
        },
        tooltip: 'Clean image',
        child: const Icon(Icons.delete),
      ),
    );
  }
}
