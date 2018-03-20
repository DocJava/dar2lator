import 'dart:html';

class DartulatorButton extends ButtonElement {

  factory DartulatorButton(String innerHtml, Function fireEvent,
      [Map<String, String> attributes]) {
    ButtonElement button = new ButtonElement();

    button.innerHtml = innerHtml;
    button.setAttribute("raised", "");
    attributes?.forEach((key, value) => button.setAttribute(key, value));
    button.onClick.listen(fireEvent);

    return button;
  }
}
