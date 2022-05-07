const int motorSigPin = 5;

#include <AceButton.h>
using namespace ace_button;

const uint8_t NUM_BTNS = 3;

const int BUTTON_PIN = 4;
const int LIMIT_BUTTON_PIN = 6;
const int ARMING_BUTTON_PIN = 7;
const int RXLED = 17;


struct Info {
  const uint8_t buttonPin;
};

Info INFOS[NUM_BTNS] = {
  {BUTTON_PIN},
  {LIMIT_BUTTON_PIN},
  {ARMING_BUTTON_PIN}
};

AceButton buttons[NUM_BTNS];

void handleEvent(AceButton*, uint8_t, uint8_t);

boolean sysNotArmed;
boolean doSwipe;
boolean swipeComplete;
char value;
boolean sendSig = false;



#include <AsyncDelay.h>

AsyncDelay delay_s;

const int nextProcessStartDelayForProcessing = 600000; // 10 min



void setup() {
  Serial.begin(115200);

  pinMode(RXLED , OUTPUT);
  digitalWrite(RXLED , LOW);

  for (uint8_t i = 0; i < NUM_BTNS; i++) {
    pinMode(INFOS[i].buttonPin, INPUT_PULLUP);
    buttons[i].init(INFOS[i].buttonPin, HIGH, i);
  }

  ButtonConfig* buttonConfig = ButtonConfig::getSystemButtonConfig();
  buttonConfig->setEventHandler(handleEvent);
  buttonConfig->setFeature(ButtonConfig::kFeatureClick);
  buttonConfig->setFeature(ButtonConfig::kFeatureLongPress);

  pinMode(motorSigPin, OUTPUT);
  digitalWrite(motorSigPin, LOW);
}



void loop() {
  for (uint8_t i = 0; i < NUM_BTNS; i++) {
    buttons[i].check();
  }

  if (Serial.available()) {
    value = Serial.read();
    if (value == '1') {
      if (!doSwipe) {
        doSwipe = true;
        swipeComplete = false;
      }
    }
  }


  if (doSwipe) {
    if (!swipeComplete) digitalWrite(motorSigPin, HIGH);
    doSwipe = false;
  }


  if (swipeComplete) {
    delay(100); // play with this value here
    digitalWrite(motorSigPin, LOW);

    delay_s.start(nextProcessStartDelayForProcessing, AsyncDelay::MILLIS);

    sendSig = true;
    swipeComplete = false;
  }

  //  Serial.println("out side loop");

  if (delay_s.isExpired() && sendSig) {
    Serial.println("s");
    sendSig = false;
  }


}



void handleEvent(AceButton* button, uint8_t eventType, uint8_t buttonState) {
  uint8_t id = button->getId();
  uint8_t buttonPin = INFOS[id].buttonPin;

  switch (eventType) {
    case AceButton::kEventClicked:
      if (buttonPin == BUTTON_PIN) {
        doSwipe = true;
        swipeComplete = false;
      }
      if (buttonPin == LIMIT_BUTTON_PIN) {
        swipeComplete = true;
      }
      if (buttonPin == ARMING_BUTTON_PIN) {
        sysNotArmed = !sysNotArmed;
        if (sysNotArmed) {
          Serial.println("e");
          digitalWrite(RXLED , HIGH);
        } else {
          Serial.println("d");
          digitalWrite(RXLED , LOW);
        }
      }
    case AceButton::kEventLongPressed:
      if (buttonPin == BUTTON_PIN) {
        doSwipe = true;
        swipeComplete = false;
      }
      if (buttonPin == LIMIT_BUTTON_PIN) {
        swipeComplete = true;
      }
      if (buttonPin == ARMING_BUTTON_PIN) {
        sysNotArmed = !sysNotArmed;
        if (sysNotArmed) {
          Serial.println("e");
          digitalWrite(RXLED , HIGH);
        } else {
          Serial.println("d");
          digitalWrite(RXLED , LOW);
        }
      }
    case AceButton::kEventPressed:
      if (buttonPin == BUTTON_PIN) {
        doSwipe = true;
        swipeComplete = false;
      }
      if (buttonPin == LIMIT_BUTTON_PIN) {
        swipeComplete = true;
      }
      if (buttonPin == ARMING_BUTTON_PIN) {
        sysNotArmed = !sysNotArmed;
        if (sysNotArmed) {
          Serial.println("e");
          digitalWrite(RXLED , HIGH);
        } else {
          Serial.println("d");
          digitalWrite(RXLED , LOW);
        }
      }
      break;
  }
}
