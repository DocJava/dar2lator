// Copyright (c) 2017, DJ. All rights reserved. Use of this source code

// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import 'calculation_components/calculation_components.dart';
import 'logger/app_logger.dart';
import 'util/dartulator_strings.dart' show answer;
import 'util/equation_processor.dart';

class AppHandler {

  final List<List<CalculationComponent>> basicTable = [
    [
      new ParenthesisOpen(),
      new ParenthesisClose(),
      new PercentCalculation(),
      new Clear()
    ],
    [new Seven(), new Eight(), new Nine(), new DivisionCalculation()],
    [new Four(), new Five(), new Six(), new MultiplicationCalculation()],
    [new One(), new Two(), new Three(), new SubtractionCalculation()],
    [new Zero(), new DecimalNumber(), new Equals(), new AdditionCalculation()]
  ];

  final List<List<CalculationComponent>> unToggledAdvancedTable = [
    [new Radians(), new Degrees(), new FactorialCalculation()],
    [new Inverse(), new SineCalculation(), new NaturalLogCalculation()],
    [new Pi(), new CosineCalculation(), new LogCalculation()],
    [new NaturalE(), new TangentCalculation(), new SqrtCalculation()],
    [new Answer(), new EXPCalculation(), new SquaredCalculation()]
  ];

  final List<List<CalculationComponent>> toggledAdvancedTable = [
    [new Radians(), new Degrees(), new FactorialCalculation()],
    [new Inverse(), new ArcSineCalculation(), new BaseECalculation()],
    [new Pi(), new ArcCosineCalculation(), new BaseTenCalculation()],
    [new NaturalE(), new ArcTangentCalculation(), new SquaredCalculation()],
    [new RandomNumber(), new EXPCalculation(), new NthRootCalculation()]
  ];


  final List<CalculationComponent> calcs = [new EquationStarter()];

  final currentlyBold = new Radians();

  bool processingZeros = false;
  bool toggled = false;

  List<String> closingDisplayList = [];
  List<String> closingDisplayPreList = [];

  Number previousAnswerValue = new Zero();
  String answerDisplay = "Ans = 0";
  bool previousAnswerUpdateNeeded = false;

  List<CalculationComponent> equationItems = [new EquationStarter()];

  final TableElement basicTableElement;
  final TableElement advancedTableElement;

  Function _updateClosingDisplay;

  Function _updateCalculationDisplay;

  Function _updateAnswerDisplay;

  String get closingDisplay {
    String result = "";
    //decreasing
    for (int index = closingDisplayList.length - 1; index >= 0;
    index--) {
      result += closingDisplayPreList[index] + closingDisplayList[index];
    }
    logToConsole("closing display: $result");
    return result;
  }

  CalculationComponent get last => equationItems.last;

  bool get isEquationStarted =>
      last is EquationStarter && last is! ResultNumber;

  List<List<CalculationComponent>> get advancedTable =>
      toggled ? toggledAdvancedTable : unToggledAdvancedTable;

  bool get currentlyHandlingNumber => last is Number && last is! ResultNumber;

  AppHandler(this.basicTableElement,
      this.advancedTableElement,
      closingParenthesisUpdater,
      calculationDisplayUpdater,
      answerDisplayUpdater) {
    _updateAnswerDisplay = () => answerDisplayUpdater(answerDisplay);
    _updateCalculationDisplay =
        () => calculationDisplayUpdater(calculationDisplay);
    _updateClosingDisplay = () =>
        closingParenthesisUpdater(closingDisplay);


    addEventsToTables();
    populateTable(basicTableElement, basicTable);
    populateTable(advancedTableElement, advancedTable);
  }

  void updateDisplays() {
    _updateCalculationDisplay();
    _updateClosingDisplay();
    _updateAnswerDisplay();
  }

  void addEventsToTables() {
    Iterable flatten(List table) => table.expand((i) => i);

    void addEvents(CalculationComponent component) {
      component.addEvent(handleCalculationComponent(component));
    }

    flatten(basicTable).forEach(addEvents);
    flatten(toggledAdvancedTable).forEach(addEvents);
    flatten(unToggledAdvancedTable).forEach(addEvents);
  }

  void populateTable(TableElement table,
      List<List<CalculationComponent>> data,
      [bool resetTable = false]) {
    if (resetTable ?? false) {
      table.innerHtml = "";
    }

    for (List<CalculationComponent> row in data) {
      TableRowElement tableRowElement = table.addRow();

      for (CalculationComponent component in row) {
        TableCellElement cellElement = tableRowElement.addCell();
        cellElement.append(component.createDartButton());
      }
    }
  }

  void invertView() {
    logToConsole("toggling : $toggled");
    toggled = !toggled;
    updateAdvancedTableView();
  }

  void updateAdvancedTableView() {
    logToConsole("updateing advanced table view");
    populateTable(advancedTableElement, advancedTable, true);
  }

  void updatePreviousAnswer() {
    answerDisplay = '$answer = ${previousAnswerValue}';
    logToConsole("updating previous answer to $answerDisplay");
    updateDisplays();
  }

  bool moveIsNotValid(CalculationComponent component) {
    bool isNotValid() {
      //if we are doing the EXP calc, make sure we only allow numbers
      if (processingZeros) {
        logToConsole("processingZeros is true");
        //2018 update:
        if (component is Number &&
            (component is DecimalNumber || component.isSymbol())) {
          return true;
        }
        if (component is! Number || (component as Number).isSymbol()) {
          return true;
        }
      }

      //  closing empty parenthesis and there are no parenthesis to close
      if (component is ParenthesisClose && closingDisplayList.isEmpty) {
        return true;
      }

      // closing parenthesis and nothing is in the last ParenthesisOpen
      if (component is ParenthesisClose && last is ParenthesisOpen) {
        return true;
      }

      //starting an operation without a number
      if (last.enclosesNextSection() && !component.canStartEquation) {
        return true;
      }

      //trying to add E without a number
      if (component is EXPCalculation) {
        CalculationComponent lastItem = last;
        if (lastItem is! Number || (lastItem as Number).isSymbol()) {
          return true;
        }
      }

      //trying to make a double a double example: 2.34.5
      if (component is DecimalNumber &&
          last is Number &&
          (last as Number).isDouble) {
        logToConsole("trying to add a decimal to a double");
        return true;
      }

      //all checks passed
      return false;
    }

    bool result = isNotValid();
    if (result) {
      logToConsole('determined $component was not a valid move');
    }
    return result;
  }

  void handleNumber(Number item, { String displayOverride}) {
    logToConsole('determined $item was a number');

    if (item is Answer) {
      item = new Answer(0, "${previousAnswerValue()}");
    } else if (item is RandomNumber) {
      item = new RandomNumber();
    }

    if (last is EquationStarter || last is ResultNumber) {
      equationItems.removeLast();
    } else {
      bool lastWasNumber = last is Number;
      bool lastWasSymbol = lastWasNumber ? (last as Number).isSymbol() : false;

      if (moveIsNotValid(item)) {
        return;
        //5pi really should be 5 * pi
      } else if ((item.isSymbol() && lastWasNumber) || lastWasSymbol ||
          last is ParenthesisClose) {
        addHiddenItem(new MultiplicationCalculation());
      } else if (lastWasNumber) {
        logToConsole('increasing number value and exiting');
        Number number = equationItems.removeLast();
        item = number.append(item);
      }
    }

    addItem(item);
  }

  void addHiddenItem(CalculationComponent item) {
    addItem(item..isHidden = true);
  }

  void addItem(CalculationComponent item) {
    String hidden = item.isHidden ? "hidden" : "";
    logToConsole("adding $hidden Item: $item:${item.runtimeType}");

    if (item is ParenthesisClose) {
      item = new ParenthesisClose(closingDisplayList.removeLast());
      closingDisplayPreList.removeLast();
    } else if (item.enclosesNextSection()) {
      closingDisplayList.add(item.postClosingTag());
      closingDisplayPreList.add(item.prePostClosingTag());
    }

    processingZeros = item is EXPCalculation;
    equationItems.add(item);
    updateDisplays();
  }

  //remove one digit (or decimal) from number
  void removeLastNumber() {
    Number number = equationItems.removeLast();

    if (number is ResultNumber) {
      logToConsole("last number was a result number");
      return;
    }

    Number result = number.detach();
    if (result is! EquationStarter) {
      equationItems.add(result);
    }
  }

  void removeLast() {
    do {
      if (last.enclosesNextSection()) {
        closingDisplayList.removeLast();
        closingDisplayPreList.removeLast();
      }

      if (last is Number) {
        removeLastNumber();
      } else {
        equationItems.removeLast();
      }
      if (equationItems.isEmpty) {
        break;
      } else if (!last.isHidden) {
        break;
      }
    } while (equationItems.isNotEmpty && last.isHidden);

    if (equationItems.isEmpty) {
      logToConsole("equation list was empty");
      equationItems.add(new EquationStarter());
    }

    updateDisplays();
  }

  bool startingNegativeNumber(CalculationComponent item) {
    if (item is! SubtractionCalculation) return false;

    if (last.toString() != '0' &&
        !isEquationStarted) return false;

    return !currentlyHandlingNumber;
  }

  Function handleCalculationComponent(CalculationComponent item) =>
          () {
        logToConsole("item: $item, last:${last.runtimeType}");
        if (item is! Inverse && toggled) {
          //after non inverse button click, display reverts to original
          invertView();
        }

        //starting something new, or attempting to, show previous answer
        if (previousAnswerUpdateNeeded) {
          updatePreviousAnswer();
          previousAnswerUpdateNeeded = false;
        }

        if (item is ViewChangingComponent) {
          handleViewChangingComponent(item);
        } else if (item is Number) {
          handleNumber(item);
        } else {
          //if this contains anything that is not a number
          handleGenericComponent(item);
        }
      };

  void handleGenericComponent(CalculationComponent component) {
    logToConsole("handling generic item $component");
    if (moveIsNotValid(component)) {
      return;
    }

    if ((last is EquationStarter || last is ResultNumber) &&
        component.canStartEquation) {
      equationItems.removeLast();
    } else if (last is Number && component.canStartEquation) {
      addHiddenItem(new MultiplicationCalculation());
    }

    addItem(component);
  }

  void handleClear() {
    if (last is EXPCalculation) {
      processingZeros = false;
    }

    if (last is EquationStarter) {
      previousAnswerValue = new Zero();
    } else {
      removeLast();
    }
  }

  void clearAndUpdateEquationVariables() {
    equationItems.clear();
    closingDisplayPreList.clear();
    closingDisplayList.clear();

    equationItems.add(new EquationStarter());
    updateDisplays();
  }

  //todo this only needs to be updated to this extent if:
  // we remove, or something encloses previous
  String get calculationDisplay {
    List<String> calculationDisplayList = [""];
    void _addOpeningTagOnLeftSide(int currentIndex,
        CalculationComponent currentItem) {
      int previousIndex = currentIndex;
      while (true) {
        CalculationComponent previousItem = equationItems[previousIndex];
        if (previousItem.enclosesNextSection() || previousIndex == 0) {
          calculationDisplayList[0] += currentItem.preOpeningTag();
          return;
        }
        previousIndex -= 1;
      }
    }


    for (var index = 0; index < equationItems.length; index ++) {
      CalculationComponent item = equationItems[index];
      calculationDisplayList.add(item.getCalculationDisplayText());

      if (item.enclosesNextSection()) {
        calculationDisplayList.add(item.postOpeningTag());
      }

      if (item.enclosesPreviousSection()) {
        _addOpeningTagOnLeftSide(index, item);
      }
    }

    String result;

    if (calculationDisplayList.isEmpty) {
      result = "0";
    } else {
      result = calculationDisplayList.join("");
    }

    logToConsole("current calculator display is $result");

    return result;
  }

  void handleEquals() {
    //close out the parenthesis
    while (closingDisplayList.isNotEmpty) {
      addItem(new ParenthesisClose());
    }

    processingZeros = false;

    answerDisplay = "$calculationDisplay = ";
    updateDisplays();

    //apply magic
    ResultNumber calculationResult = EquationProcessor.process(equationItems);
    clearAndUpdateEquationVariables();

    //if total value returned an Error
    if (calculationResult is CalculationError) {
      logToConsole("we have a $calculationResult");
      previousAnswerValue = new Zero();
    } else {
      num calculationValue = calculationResult();
      logToConsole("we got a result $calculationValue");
      //this fixes precision issues sqrt(2)*sqrt(2) = 2.000000000004
      if (calculationResult.isDouble) {
        String calculationValueString = calculationValue.toStringAsFixed(10);
        calculationResult = new ResultNumber(num.parse(calculationValueString));
      }

      previousAnswerValue = calculationResult;
    }

    equationItems[0] = calculationResult;

    previousAnswerUpdateNeeded = true;
    updateDisplays();
  }

  void handleViewChangingComponent(CalculationComponent component) {
    logToConsole("handling advanced item: $component");

    if (component is Radians || component is Degrees) {
      component();
      updateAdvancedTableView();
    } else if (component is Inverse) {
      invertView();
    } else if (component is Clear) {
      handleClear();
    } else if (component is Equals) {
      handleEquals();
    }
  }
}