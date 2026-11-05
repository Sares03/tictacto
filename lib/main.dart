import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import './constants.dart';

void main() {
  runApp(
    MaterialApp(
      title: 'Tic-Tac-Toe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0XFF331449),
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    ),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late String symbol;
  late List<String> symbolList;
  late List<List<String>> symbolMatrix;
  late int currentIdx;
  late bool isGameOver;
  late MediaQueryData media;
  late double deviceWidth;
  late double deviceHeight;
  late Map<String, Widget> iconMap;
  late ThemeData theme;
  late ConfettiController _controllerCenter;
  bool isDarkTheme = false;

  @override
  void initState() {
    super.initState();
    _controllerCenter = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _initialize();
  }

  @override
  void dispose() {
    _controllerCenter.dispose();
    super.dispose();
  }

  void _initialize() {
    isGameOver = false;

    symbolList = List.generate(9, (_) => '');
    symbol = Constants.symbolX;
    currentIdx = -1;

    symbolMatrix = [];
    for (var i = 0; i < Constants.size; ++i) {
      symbolMatrix.add(
        List.generate(Constants.size, (_) => ''),
      );
    }
  }

  Path drawStar(Size size) {
    // Method to convert degree to radians
    double degToRad(double deg) => deg * (pi / 180.0);

    const numberOfPoints = 5;
    final halfWidth = size.width / 2;
    final externalRadius = halfWidth;
    final internalRadius = halfWidth / 2.5;
    final degreesPerStep = degToRad(360 / numberOfPoints);
    final halfDegreesPerStep = degreesPerStep / 2;
    final path = Path();
    final fullAngle = degToRad(360);
    path.moveTo(size.width, halfWidth);

    for (double step = 0; step < fullAngle; step += degreesPerStep) {
      path.lineTo(halfWidth + externalRadius * cos(step),
          halfWidth + externalRadius * sin(step));
      path.lineTo(halfWidth + internalRadius * cos(step + halfDegreesPerStep),
          halfWidth + internalRadius * sin(step + halfDegreesPerStep));
    }
    path.close();

    return path;
  }

  String _getSymbol() {
    String currSymbol = symbol;

    setState(() {
      if (currSymbol == Constants.symbolX) {
        symbol = Constants.symbolO;
      } else {
        symbol = Constants.symbolX;
      }
    });

    return currSymbol;
  }

  _initializeSymbols() {
    iconMap = {
      Constants.symbolX: Icon(
        Icons.close,
        size: deviceWidth < deviceHeight
            ? deviceWidth * 0.15
            : deviceHeight * 0.15,
        color: isDarkTheme
            ? theme.colorScheme.inversePrimary
            : theme.colorScheme.primary,
      ),
      Constants.symbolO: Icon(
        Icons.radio_button_off_rounded,
        size: deviceWidth < deviceHeight
            ? deviceWidth * 0.13
            : deviceHeight * 0.13,
        color: isDarkTheme
            ? theme.colorScheme.surface
            : theme.colorScheme.secondary,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    media = MediaQuery.of(context);
    deviceWidth = media.size.width;
    deviceHeight = media.size.height;
    theme = Theme.of(context);

    _initializeSymbols();

    return Scaffold(
      backgroundColor: isDarkTheme
          ? theme.colorScheme.onBackground
          : theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: isDarkTheme
            ? theme.colorScheme.primary
            : theme.colorScheme.inversePrimary,
        title: Text(
          'Tic-Tac-Toe',
          style: TextStyle(
            color: isDarkTheme
                ? theme.colorScheme.inversePrimary
                : theme.colorScheme.onBackground,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Restart Game',
            onPressed: () {
              setState(() {
                _initialize();
              });
            },
            icon: Icon(
              Icons.refresh,
              color: isDarkTheme
                  ? theme.colorScheme.inversePrimary
                  : theme.colorScheme.onBackground,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: deviceWidth < deviceHeight
                          ? deviceWidth * 0.7
                          : deviceHeight * 0.6,
                      child: GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: Constants.size,
                        children: List.generate(
                          Constants.size * Constants.size,
                          (index) => Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isDarkTheme
                                    ? theme.colorScheme.inversePrimary
                                    : theme.colorScheme.onBackground,
                              ),
                            ),
                            child: InkWell(
                              onTap: !isGameOver &&
                                      symbolList[index].trim().isEmpty
                                  ? () {
                                      setState(() {
                                        currentIdx = index;
                                      });

                                      symbolList[index] = _getSymbol();

                                      if (_isGameOver()) {
                                        _showSnackBar(
                                            context, symbolList[currentIdx]);
                                        return;
                                      }
                                    }
                                  : null,
                              child: Center(
                                child: symbolList[index] == ''
                                    ? null
                                    : iconMap[symbolList[index]],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        top: deviceWidth < deviceHeight
                            ? deviceWidth * 0.04
                            : deviceHeight * 0.04,
                      ),
                      child: Center(
                        child: Text(
                          isGameOver
                              ? 'The Winner is ${symbolList[currentIdx]}!'
                              : '',
                          style: TextStyle(
                            fontSize: deviceWidth < deviceHeight
                                ? deviceWidth * 0.08
                                : deviceHeight * 0.08,
                            color: isDarkTheme
                                ? theme.colorScheme.onSecondary
                                : theme.colorScheme.onBackground,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: ConfettiWidget(
                confettiController: _controllerCenter,
                blastDirectionality: BlastDirectionality
                    .explosive, // don't specify a direction, blast randomly
                shouldLoop:
                    true, // start again as soon as the animation is finished
                colors: const [
                  Colors.green,
                  Colors.blue,
                  Colors.pink,
                  Colors.orange,
                  Colors.purple
                ], // manually specify the colors to be used
                createParticlePath: drawStar, // define a custom shape/path.
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Switch Theme',
        backgroundColor: isDarkTheme
            ? theme.colorScheme.primary
            : theme.colorScheme.inversePrimary,
        onPressed: () {
          setState(() {
            isDarkTheme = !isDarkTheme;
          });
        },
        child: Icon(
          Icons.lightbulb_outline,
          color: isDarkTheme
              ? theme.colorScheme.inversePrimary
              : theme.colorScheme.onBackground,
        ),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String winner) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('The Winner is $winner!'),
        duration: const Duration(
          seconds: 3,
        ),
        action: SnackBarAction(
          label: 'CLOSE',
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  bool _isGameOver() {
    int row = currentIdx ~/ Constants.size;
    int col = currentIdx % Constants.size;

    symbolMatrix[row][col] = symbolList[currentIdx];

    if (_rowWin(row, col, symbolList[currentIdx]) ||
        _colWin(row, col, symbolList[currentIdx]) ||
        _primaryDiagonalWin(row, col, symbolList[currentIdx]) ||
        _secondaryDiagonalWin(row, col, symbolList[currentIdx])) {
      setState(() {
        isGameOver = true;
        _controllerCenter.play();
        Future.delayed(const Duration(seconds: 3)).then(
          (value) => _controllerCenter.stop(),
        );
      });
      return true;
    }

    return false;
  }

  bool _rowWin(int row, int col, String symbol) {
    int count = 1;
    int currRow = row - 1;

    while (currRow >= 0) {
      if (symbolMatrix[currRow][col] == '' ||
          symbolMatrix[currRow][col] != symbol) return false;
      currRow--;
      count++;
    }

    currRow = row + 1;
    while (currRow < Constants.size) {
      if (symbolMatrix[currRow][col] == '' ||
          symbolMatrix[currRow][col] != symbol) return false;
      currRow++;
      count++;
    }

    return count == Constants.size;
  }

  bool _colWin(int row, int col, String symbol) {
    int count = 1;
    int currCol = col - 1;

    while (currCol >= 0) {
      if (symbolMatrix[row][currCol] == '' ||
          symbolMatrix[row][currCol] != symbol) {
        return false;
      }
      currCol--;
      count++;
    }

    currCol = col + 1;
    while (currCol < Constants.size) {
      if (symbolMatrix[row][currCol] == '' ||
          symbolMatrix[row][currCol] != symbol) return false;
      currCol++;
      count++;
    }

    return count == Constants.size;
  }

  bool _primaryDiagonalWin(int row, int col, String symbol) {
    int count = 1;
    int currRow = row + 1;
    int currCol = col + 1;
    while (currRow < Constants.size && currCol < Constants.size) {
      if (symbolMatrix[currRow][currCol] == '' ||
          symbolMatrix[currRow][currCol] != symbol) return false;
      currRow++;
      currCol++;
      count++;
    }

    currRow = row - 1;
    currCol = col - 1;
    while (currRow >= 0 && currCol >= 0) {
      if (symbolMatrix[currRow][currCol] == '' ||
          symbolMatrix[currRow][currCol] != symbol) return false;
      currRow--;
      currCol--;
      count++;
    }

    return count == Constants.size;
  }

  bool _secondaryDiagonalWin(int row, int col, String symbol) {
    int count = 1;
    int currRow = row + 1;
    int currCol = col - 1;

    while (currRow < Constants.size && currCol >= 0) {
      if (symbolMatrix[currRow][currCol] == '' ||
          symbolMatrix[currRow][currCol] != symbol) return false;
      currRow++;
      currCol--;
      count++;
    }

    currRow = row - 1;
    currCol = col + 1;
    while (currRow >= 0 && currCol < Constants.size) {
      if (symbolMatrix[currRow][currCol] == '' ||
          symbolMatrix[currRow][currCol] != symbol) return false;
      currRow--;
      currCol++;
      count++;
    }

    return count == Constants.size;
  }
}
