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

char value;

boolean sysNotArmed;
boolean doSwipe;
boolean swipeComplete;
boolean sendSig = false;

#include <Servo.h>
Servo camServo;

boolean doCamSwipe;
boolean camLimitsHit;


#include <AsyncDelay.h>

AsyncDelay delay_s;

const int nextProcessStartDelayForProcessing = 3000; // 3 sec



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

  //  pinMode(motorSigPin, OUTPUT);
  //  digitalWrite(motorSigPin, LOW);
}


int sketchNum = 1;
bool pinTypeAssigned = false;
bool swipeLeft, swipeRight;
int dirSelector = 0;

void loop() {
  for (uint8_t i = 0; i < NUM_BTNS; i++) {
    buttons[i].check();
  }

  if (Serial.available()) {
    value = Serial.read();

    if (value == '2' /* processing sketch 1 for tik-tok */) {
      sketchNum = 1;

      pinTypeAssigned = false;

      if (!pinTypeAssigned) {
        pinMode(motorSigPin, OUTPUT);
        digitalWrite(motorSigPin, LOW);
        pinTypeAssigned = true;
      }
    }

    if (value == '3' /* processing sketch 2 for env watch */) {
      sketchNum = 2;

      pinTypeAssigned = false;

      if (!pinTypeAssigned) {
        camServo.attach(motorSigPin);
        pinTypeAssigned = true;
      }
    }

    if (value == '1') {     /* if it receives signal to do a swipe */
      if (sketchNum == 1) { /* if it is processing sketch 1 for tik-tok */
        if (!doSwipe) {
          doSwipe = true;
          doCamSwipe = false;
          swipeComplete = false;
        }
      }
      if (sketchNum == 2) { /* if it is processing sketch 2 for env watch */
        if (!doCamSwipe) {
          doCamSwipe = true;
          doSwipe = false;
          camLimitsHit = false;
        }
      }
    }
  }

  //-------------------------------------------//
  //----------- Tik-Tok Swipper Part ----------//
  //-------------------------------------------//
  if (sketchNum == 1) {
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
  }
  //------------------------*******************************************-------------------//


  //-------------------------------------------//
  //------ Env Scanning Cam Swipper Part ------//
  //-------------------------------------------//
  if (sketchNum == 2) {
    if (doCamSwipe) {
      // pick randomly left or right
      dirSelector = int(random(2));
      if (dirSelector == 0) {
        swipeLeft = true;
        swipeRight = false;
      }
      if (dirSelector == 1) {
        swipeLeft = false;
        swipeRight = true;
      }

      if (swipeLeft) {
        // Set motion in one direction
        if (!camLimitsHit) camServo.write(81);
      }
      if (swipeRight)
        // Set motion in another direction
        if (!camLimitsHit) camServo.write(99);
    }
    doCamSwipe = false;
  }

  if (camLimitsHit) {
    // stop immediately
    camServo.write(90);
    // and after a certain delay
    delay(100);
    // reverse the direction
    // if it was going left, then now go right
    if (swipeLeft) camServo.write(99);
    // if it was going right, then now go left
    if (swipeRight) camServo.write(81);

    // after a random delay
    /*-- WORK ON THE RANGE HERE --*/
    delay(int(random(300, 600)));
    // Stop the motor
    camServo.write(90);

    // start the delay to send sig to processing
    delay_s.start(nextProcessStartDelayForProcessing, AsyncDelay::MILLIS);

    sendSig = true;
    camLimitsHit = false;
  }


  //------------------------*******************************************-------------------//


  if (delay_s.isExpired() && sendSig) {
    Serial.println("s");
    sendSig = false;
  }

}



void handleEvent(AceButton* button, uint8_t eventType, uint8_t buttonState) {
  uint8_t id = button->getId();
  uint8_t buttonPin = INFOS[id].buttonPin;

  switch (eventType) {
    case AceButton::kEventLongPressed:
      if (buttonPin == BUTTON_PIN) {
        if (sketchNum == 1) {
          doSwipe = true;
          swipeComplete = false;
        }
        if (sketchNum == 2) {
          doCamSwipe = true;
          camLimitsHit = true;
        }
      }
      if (buttonPin == LIMIT_BUTTON_PIN) {
        if (sketchNum == 1) swipeComplete = true;
        if (sketchNum == 2) camLimitsHit = true;
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
        if (sketchNum == 1) {
          doSwipe = true;
          swipeComplete = false;
        }
        if (sketchNum == 2) {
          doCamSwipe = true;
          camLimitsHit = true;
        }
      }
      if (buttonPin == LIMIT_BUTTON_PIN) {
        if (sketchNum == 1) swipeComplete = true;
        if (sketchNum == 2) camLimitsHit = true;
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
