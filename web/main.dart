import 'dart:html';

import 'app_handler.dart';

AppHandler appHandler;

final NodeValidatorBuilder _validateHtml = new NodeValidatorBuilder.common()
  ..allowElement('panel',
      attributes: ['aria-label', 'elevation', 'raised'])..allowElement('div',
      attributes: ['raised'])..allowElement('sup');

Element select(text) => querySelector(text);

main() async {
  String appTemplate = await HttpRequest.getString("htmls/app.html");

  Function makeUpdaterFor(String selector) {
    Element element = select(selector);
    return (text) =>
        element.setInnerHtml(text, validator: _validateHtml);
  }

  select('#output')?.innerHtml = "";
  select('#app_start')?.innerHtml = "";
  select('#my_app')?.setInnerHtml(appTemplate, validator: _validateHtml);

  TableElement basicTableElement = select('#dartulator_basic');
  TableElement advancedTableElement = select('#dartulator_advanced');

  if (basicTableElement != null && advancedTableElement != null) {
    appHandler = new AppHandler(basicTableElement,
        advancedTableElement,
        makeUpdaterFor("#closingParenthesis"),
        makeUpdaterFor("#calculation_display"),
        makeUpdaterFor("#answer"));
  } else {
    select('#output')?.innerHtml =
    "THE SKY IS FALLING!!  Sorry this app is not currently working";
  }
}