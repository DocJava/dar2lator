library calculation;

import '../logger/app_logger.dart';
import 'dart:html';
import 'dart:math';

import '../util/dartulator_button/dartulator_button.dart';
import '../util/dartulator_strings.dart';


//precedence is rated low to high
enum Precedence { I, II, III, IV, V }

enum Shade { LIGHT, DARK, BLUE }

abstract class CalculationComponent implements Function {
  static bool usingDegrees = false;

  final Precedence _precedenceLevel;
  final List<Function> _events = [];
  bool _isHidden = false;

  CalculationComponent(this._precedenceLevel);

  bool hasLessPrecedenceThan(CalculationComponent other) =>
      _precedenceLevel.index < other._precedenceLevel.index;

  String getCalculationDisplayText() {
    if (_isHidden) {
      return "";
    }
    return _getCalculationDisplayText();
  }

  String _getCalculationDisplayText() => getButtonText();

  String getButtonText();

  Shade getShade();

  String getShadeString() {
    switch (getShade()) {
      case Shade.BLUE:
        return "blue";
      case Shade.LIGHT:
        return "light";
      case Shade.DARK:
        return "dark";
    }
    return "";
  }

  call();

  printType() => logToConsole(runtimeType);

  @override
  String toString() => getButtonText();

  Element createDartButton() {
    var attributes = {"shade": getShadeString()};
    if (isBold()) {
      attributes["bold"] = "";
    }

    return new DartulatorButton(getButtonText(), fireEvents, attributes);
  }

  void addEvent(Function event) {
    _events.add(event);
  }

  void fireEvents(MouseEvent e) {
    logToConsole("firing events for: $runtimeType");
    for (Function event in _events) {
      event();
    }
  }

  set isHidden(bool value) {
    _isHidden = value;
  }

  bool get isHidden => _isHidden;

  bool get canStartEquation => true;

  bool isBold() => false;

  bool enclosesPreviousSection() => false;

  String preOpeningTag() => "";

  String preClosingTag() => "";

  bool enclosesNextSection() => false;

  String postOpeningTag() => "";

  String postClosingTag() => "";

  String prePostClosingTag() => "";
}

abstract class UnaryCalculation extends CalculationComponent {
  UnaryCalculation(Precedence precedenceLevel) : super(precedenceLevel);

  num _calculate(num x);

  @override
  num call([num x]) => _calculate(x);

  @override
  Shade getShade() => Shade.DARK;
}

abstract class BinaryCalculation extends CalculationComponent {
  BinaryCalculation(Precedence precedenceLevel) : super(precedenceLevel);

  num _calculate(num x, num y);

  @override
  num call([num x, num y]) => _calculate(x, y);

  @override
  Shade getShade() => Shade.DARK;
}

abstract class TrigCalculation extends UnaryCalculation {
  TrigCalculation(Precedence precedenceLevel) : super(precedenceLevel);

// switch the answer to degrees if need be
  @override
  num call([num x]) {
    if (CalculationComponent.usingDegrees) {
      x *= PI / 180;
    }
    return _calculate(x);
  }

  @override
  String postOpeningTag() => "$parenthesis_open";

  @override
  String postClosingTag() => "$parenthesis_close";

  @override
  bool enclosesNextSection() => true;
}

abstract class ArcTrigCalculation extends UnaryCalculation {
  ArcTrigCalculation(Precedence precedenceLevel) : super(precedenceLevel);

// switch the answer to degrees if need be
  @override
  num call([num x]) {
    num value = _calculate(x);
    if (CalculationComponent.usingDegrees) {
      value *= 180 / PI;
    }
    return value;
  }

  @override
  String postOpeningTag() => "$parenthesis_open";

  @override
  String postClosingTag() => "$parenthesis_close";

  @override
  bool enclosesNextSection() => true;
}

class Number extends CalculationComponent {
  num value;
  String numString = "";

  Number(this.value, {this.numString = null}) : super(Precedence.V) {
    if (numString == null) {
      numString = "${this.value}";
    }
  }

  bool get isDouble => numString.contains(decimal);

  @override
  String getButtonText() => numString;

  Number append(Number other) {
    var myString = toString();
    var otherString = other.toString();
    return new Number(0, numString: myString + otherString);
  }

  Number detach() {
    if (numString.length == 1 || isSymbol()) {
      return new EquationStarter();
    }

    String subbedString = numString.substring(0, numString.length - 1);

    return new Number(0, numString: subbedString);
  }

  bool isSymbol() => false;

  @override
  num call() => num.parse(numString);

  @override
  Shade getShade() => Shade.LIGHT;

  @override
  String toString() => numString;
}

abstract class ViewChangingComponent extends CalculationComponent {
  ViewChangingComponent() : super(Precedence.V);

  @override
  void call() => throw new Exception("This function does not return a number");

  @override
  _getCalculationDisplayText() => "";

  @override
  Shade getShade() => Shade.DARK;
}

class AdditionCalculation extends BinaryCalculation {
  AdditionCalculation() : super(Precedence.I);

  @override
  bool get canStartEquation => false;

  @override
  num _calculate(num x, num y) => x + y;

  @override
  String getButtonText() => add;
}

class ArcCosineCalculation extends ArcTrigCalculation {
  ArcCosineCalculation() : super(Precedence.V);

  @override
  num _calculate(num x) => acos(x);

  @override
  String _getCalculationDisplayText() => arccos_string;

  @override
  String getButtonText() => arccos_button_display;
}

class ArcSineCalculation extends ArcTrigCalculation {
  ArcSineCalculation() : super(Precedence.V);

  @override
  num _calculate(num x) => asin(x);

  @override
  String _getCalculationDisplayText() => arcsin_string;

  @override
  String getButtonText() => arcsin_button_display;
}

class ArcTangentCalculation extends ArcTrigCalculation {
  ArcTangentCalculation() : super(Precedence.V);

  @override
  num _calculate(num x) => atan(x);

  @override
  String _getCalculationDisplayText() => arctan_string;

  @override
  String getButtonText() => arctan_button_display;
}

class BaseTenCalculation extends UnaryCalculation {
  BaseTenCalculation() : super(Precedence.V);

  @override
  num _calculate(num exponent) => pow(10, exponent);

  @override
  String _getCalculationDisplayText() => "10";

  @override
  String getButtonText() => baseTen_button_display;

  @override
  String postOpeningTag() => "<sup>$parenthesis_open";

  @override
  String postClosingTag() => "$parenthesis_close</sup>";

  @override
  String prePostClosingTag() => "<sup>";

  @override
  bool enclosesNextSection() => true;
}

class BaseECalculation extends UnaryCalculation {
  BaseECalculation() : super(Precedence.V);

  @override
  num _calculate(num exponent) => pow(E, exponent);

  @override
  String _getCalculationDisplayText() => "e";

  @override
  String getButtonText() => baseE_button_display;

  @override
  String postOpeningTag() => "<sup>$parenthesis_open";

  @override
  String postClosingTag() => "$parenthesis_close</sup>";

  @override
  String prePostClosingTag() => "<sup>";

  @override
  bool enclosesNextSection() => true;
}

class CosineCalculation extends TrigCalculation {
  CosineCalculation() : super(Precedence.V);

  @override
  num _calculate(num x) => cos(x);

  @override
  String getButtonText() => cosine;
}

class DivisionCalculation extends BinaryCalculation{
  DivisionCalculation() : super(Precedence.II);

  @override
  bool get canStartEquation => false;

  @override
  String getButtonText() => "/";

  @override
  num _calculate(num x, num y) => x / y;
}

class ExponentCalculation extends BinaryCalculation {
  ExponentCalculation() : super(Precedence.IV);

  @override
  bool get canStartEquation => false;

  @override
  num _calculate(num x, num y) => pow(x, y);

  @override
  String _getCalculationDisplayText() => exponent_symbol;

  @override
  String getButtonText() => exponent_button_display;

  @override
  String postOpeningTag() => "<sup>$parenthesis_open";

  @override
  String postClosingTag() => "$parenthesis_close</sup>";

  @override
  String prePostClosingTag() => "<sup>";

  @override
  bool enclosesNextSection() => true;
}

class FactorialCalculation extends UnaryCalculation {
  FactorialCalculation() : super(Precedence.IV);

  num gamma(num x) {
    return sqrt(2 * PI / x) *
        pow((1 / E) * (x + 1 / (12 * x - 1 / (10 * x))), x);
  }

  @override
  bool get canStartEquation => false;

  @override
  num _calculate(num x) {
    if (x.toString().contains(".")) {
      return gamma(x + 1);
    }

    int total = 1;
    while (x > 1) {
      total *= x--;
    }
    return total;
  }

  @override
  String _getCalculationDisplayText() => factorial_symbol;

  @override
  String getButtonText() => factorial;
}

class LogCalculation extends UnaryCalculation {
  LogCalculation() : super(Precedence.V);

  @override
  num _calculate(num x) => log(x) / log(10);

  @override
  String getButtonText() => logOfX;
}

class MultiplicationCalculation extends BinaryCalculation {

  MultiplicationCalculation() : super(Precedence.II);

  @override
  bool get canStartEquation => false;

  @override
  num _calculate(num x, num y) => x * y;

  @override
  String getButtonText() => multiply;
}

class NaturalLogCalculation extends UnaryCalculation {
  NaturalLogCalculation() : super(Precedence.V);

  @override
  num _calculate(num x) => log(x);

  @override
  String getButtonText() => naturalLog;
}

class NthRootCalculation extends BinaryCalculation {
  NthRootCalculation() : super(Precedence.V);

  @override
  bool get canStartEquation => false;

  @override
  bool enclosesNextSection() => true;

  @override
  bool enclosesPreviousSection() => true;

  @override
  num _calculate(num root, num exponent) => pow(root, 1 / exponent);

  @override
  String _getCalculationDisplayText() =>
      preClosingTag() + "$sqrtSymbol" + postOpeningTag();

  @override
  String getButtonText() => nthroot_button_display;

  @override
  String preOpeningTag() => "<sup>$parenthesis_open";

  @override
  String preClosingTag() => "$parenthesis_close</sup>";

  @override
  String postOpeningTag() => "$parenthesis_open";

  @override
  String postClosingTag() => "$parenthesis_close";
}

class PercentCalculation extends BinaryCalculation {
  PercentCalculation() : super(Precedence.IV);

  @override
  num _calculate(num x, num y) => x * .01;

  @override
  String getButtonText() => percent_symbol;
}

class SineCalculation extends TrigCalculation {
  SineCalculation() : super(Precedence.V);

  @override
  num _calculate(num x) => sin(x);

  @override
  String getButtonText() => sine;
}

class SubtractionCalculation extends BinaryCalculation {
  SubtractionCalculation() : super(Precedence.I);

  @override
  bool get canStartEquation => false;

  @override
  num _calculate(num x, num y) => x - y;

//  @override
//  CalculationType getType() => CalculationType.ADVANCED;


  @override
  String getButtonText() => subtract;
}

class SquaredCalculation extends UnaryCalculation {
  SquaredCalculation() : super(Precedence.V);

  @override
  bool get canStartEquation => false;

  @override
  num _calculate(num base) => pow(base, 2);

  @override
  String _getCalculationDisplayText() => squared_calculation_display;

  @override
  String getButtonText() => squared_button_display;
}

class SqrtCalculation extends UnaryCalculation {
  SqrtCalculation() : super(Precedence.V);

  @override
  num _calculate(num x) => sqrt(x);

  @override
  String getButtonText() => sqrtSymbol;

  @override
  String postOpeningTag() => "$parenthesis_open";

  @override
  String postClosingTag() => "$parenthesis_close";

  @override
  bool enclosesNextSection() => true;
}

class TangentCalculation extends TrigCalculation {
  TangentCalculation() : super(Precedence.V);

  @override
  num _calculate(num x) => tan(x);

  @override
  String getButtonText() => tangent;
}

class EXPCalculation extends BinaryCalculation {
  EXPCalculation() : super(Precedence.V);

  @override
  bool get canStartEquation => false;

  @override
  num _calculate(num multiplier, num exponent) =>
      multiplier * pow(10, exponent);

  @override
  String getButtonText() => zerosShort;
}

class Zero extends Number {
  Zero() : super(0);
}

class One extends Number {
  One() : super(1);
}

class Two extends Number {
  Two() : super(2);
}

class Three extends Number {
  Three() : super(3);
}

class Four extends Number {
  Four() : super(4);
}

class Five extends Number {
  Five() : super(5);
}

class Six extends Number {
  Six() : super(6);
}

class Seven extends Number {
  Seven() : super(7);
}

class Eight extends Number {
  Eight() : super(8);
}

class Nine extends Number {
  Nine() : super(9);
}

class Pi extends Number {
  Pi() : super(PI);

  @override
  String getButtonText() => pi;

  @override
  bool isSymbol() => true;
}

class NaturalE extends Number {
  NaturalE() : super(E);

  @override
  String getButtonText() => naturalE;

  @override
  bool isSymbol() => true;
}

class Answer extends Number {
  Answer([previousAnswer = 0, String numString = null])
      : super(previousAnswer, numString: numString);

  @override
  String getButtonText() => answer;

//
//  @override
//  CalculationType getType() => CalculationType.ADVANCED;

  @override
  Shade getShade() => Shade.DARK;

//  @override
//  bool isSymbol() => true;
}

class Equals extends ViewChangingComponent {
  Equals() : super();

  @override
  String getButtonText() => equals;

  @override
  Shade getShade() => Shade.BLUE;
}

class RandomNumber extends Number {
  RandomNumber() : super(makeRandom());

  static num makeRandom() => new Random().nextDouble();

  @override
  String getButtonText() => random;

//
//  @override
//  CalculationType getType() => CalculationType.ADVANCED;

  @override
  Shade getShade() => Shade.DARK;
}

class Radians extends ViewChangingComponent {
  Radians() : super();

  @override
  void call() => CalculationComponent.usingDegrees = false;

  @override
  String getButtonText() => radians;

  @override
  bool isBold() => !CalculationComponent.usingDegrees;
}

class Degrees extends ViewChangingComponent {
  Degrees() : super();

  @override
  void call() => CalculationComponent.usingDegrees = true;

  @override
  String getButtonText() => degrees;

  @override
  bool isBold() => CalculationComponent.usingDegrees;
}

class Inverse extends ViewChangingComponent {
  Inverse() : super();

  @override
  Shade getShade() => Shade.LIGHT;

  @override
  String getButtonText() => inverse;
}

class Clear extends ViewChangingComponent {
  Clear() : super();

  @override
  String getButtonText() => clear;
}

class ParenthesisOpen extends CalculationComponent {
  ParenthesisOpen() : super(Precedence.V);

  @override
  String getButtonText() => parenthesis_open;

  @override
  void call() => throw new Exception("This function does not return a number");

  @override
  Shade getShade() => Shade.DARK;
}

class ParenthesisClose extends CalculationComponent {
  final String alternateText;

  ParenthesisClose([this.alternateText = parenthesis_close]) : super(Precedence.V);

  @override
  String _getCalculationDisplayText() => alternateText;

  @override
  String getButtonText() => parenthesis_close;

  @override
  void call() => throw new Exception("This function does not return a number");

  @override
  Shade getShade() => Shade.DARK;
}

class DecimalNumber extends Number {
  DecimalNumber() : super(.1);

  @override
  String getButtonText() => decimal;

  @override
  Shade getShade() => Shade.LIGHT;

  @override
  String toString() => decimal;
}

class EquationStarter extends Zero {
  @override
  String _getCalculationDisplayText() => "0";
}


class ResultNumber extends Number {
  ResultNumber(num number) : super(number);
}

class CalculationError extends ResultNumber {
  CalculationError() : super(0);

  @override
  String _getCalculationDisplayText() => "#Error";
}


class NaNError extends CalculationError {
  NaNError() : super();

  @override
  String _getCalculationDisplayText() => "#NaN";
}