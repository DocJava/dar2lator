import '../calculation_components/calculation_components.dart';
import '../logger/app_logger.dart';

class EquationProcessor {

  // modified from https://www.tutorialspoint.com/javaexamples/data_intopost.htm
  static ResultNumber process(List<CalculationComponent> equationList) {
    List<CalculationComponent> calculations = new List();
    List<CalculationComponent> postfixList = [];

    void _handleCalculation(CalculationComponent newCalculation) {
      logToConsole("handling calculation of ${newCalculation.runtimeType}");
      while (calculations.isNotEmpty) {
        CalculationComponent lastCalculation = calculations.removeLast();

        logToConsole("last calculation: ${lastCalculation.runtimeType}");

        if (lastCalculation.hasLessPrecedenceThan(newCalculation)) {
          calculations.add(lastCalculation);
          break;
        }

        postfixList.add(lastCalculation);
      }

      calculations.add(newCalculation);
    }

    void _handleParenthesis() {
      while (calculations.isNotEmpty) {
        var last = calculations.removeLast();
        if (last is ParenthesisOpen)
          break;
        else
          postfixList.add(last);
      }
    }

    ResultNumber _convert() {
      for (CalculationComponent equationItem in equationList) {
        if (equationItem is Number) {
          postfixList.add(equationItem);
        } else if (equationItem is ParenthesisOpen) {
          calculations.add(equationItem);
        } else if (equationItem is ParenthesisClose) {
          _handleParenthesis();
        } else {
          _handleCalculation(equationItem);
        }
      }

      while (calculations.isNotEmpty) {
        postfixList.add(calculations.removeLast());
      }

      logToConsole("postfix list : $postfixList");

      return _calculate(postfixList);
    }

    try {
      return _convert();
    } catch (exception) {
      logToConsole("issues while calculating: $exception");
      return new CalculationError();
    }
  }

  //modified from http://kevinyavno.com/blog/?p=52
  static ResultNumber _calculate(List<CalculationComponent> infixList) {
    List<num> tempNumberList = new List();

    for (CalculationComponent infixItem in infixList) {
      if (infixItem is Number) {
        logToConsole("number found : ${infixItem()}");
        tempNumberList.add(infixItem());
        continue;
      }

      CalculationComponent calculate = infixItem;
      num x = tempNumberList.removeLast();

      if (calculate is UnaryCalculation) {
        logToConsole("unary calculation: ${calculate.runtimeType} for number $x");
        tempNumberList.add(calculate(x));
      } else if (calculate is BinaryCalculation) {
        logToConsole("binary calculation: ${calculate.runtimeType} for number $x");
        num y = tempNumberList.removeLast();
        logToConsole("and also using $y");
        tempNumberList.add(calculate(y, x));
      } else {
        logToConsole("no clue what this is: ${calculate.runtimeType}");
        throw UnsupportedError;
      }

      logToConsole("current state of number list: $tempNumberList");
    }

    num result = tempNumberList.removeLast();
    if (result.toString().contains("NaN")) {
      return new NaNError();
    }

    return new ResultNumber(result);
  }
}