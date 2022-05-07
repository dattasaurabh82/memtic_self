boolean auto = true;  //<>//

int delayForSysArming = 10000;       // 10 sec
int delayForSysTypeSel = 15000;      // 15 sec
int delayForSendingStartSig = 20000; // 20 sec
String sysType = "tiktok_cam"; // tiktok_cam[2] or public_cam[3]

int eachProcessDelay = 600000;             // 10 mins
//int eachProcessDelay = 180000;               // 6 mins
//int eachProcessDelay = 60000;              // 1 mins

boolean retainGIF = true;

//-----------------------
import com.dhchoi.CountdownTimer;
import com.dhchoi.CountdownTimerService;

CountdownTimer timerFirstSysArming;
CountdownTimer timerFirstSendStartSig;
CountdownTimer timerFirstSysSelection;

CountdownTimer oneProcessTimer;

boolean initProcess = true; 
boolean sendStartProcessSig = true; 
boolean startSigSent, prevInitProcessState;
//-----------------------



import java.util.concurrent.TimeUnit;
import java.util.Date;
long timeOutSec = 180; // time out value, in sec, for download process calls

import processing.video.*;
Capture cam;



PImage camshot;
String ActiveDir = "";
String rawImage = "raw.png";
String RawImgPath = "";


// For linux the python path is as below
String pythonPath = "/usr/bin/python3";

String cap_find_py_script = "get_img_cap_deepai.py";
String imgDataJSONFile = "img_data.json";
String jsonFilePath = "";
boolean canLoadImageInfo = false;

JSONObject raw_image_info_json;

StringList CAPTIONS; 
ArrayList<int[]> BOUNDING_BOXES = new ArrayList<int[]>();



PImage snapShotImg;

// GUI related
int camWidth = 640;
int camHeight = 480;
int H_GAP = 10; // adjust according to screens
int V_GAP = 0;  // agjust according to screens
int debugWindowWidth = 500;
int indicatorSize = 50;
int markerWidth=20;
int markerHeight = 20;


import controlP5.*;
ControlP5 cp5;

Textarea myTextarea;
int c = 0;
Println console;

String gif_find_py_script = "get_gif.py";
String gifDataJSONFile = "giphy_response.json";
String gifJSONFilePath = "";
boolean searchGIPHY = false;
String rawGIF_uri = "";
String gifFile = "gif.mp4";
String gifFilePath = "";

String curlPath = "/usr/bin/curl";


int randSeed=0;

boolean runPythonScript = false;
boolean startProcess = false;

import processing.serial.*;
Serial finger;  


boolean armSys = false;

import mqtt.*;
MQTTClient client;
String ClientID = "NUC_Processing";
String BrokerAddr = "mqtt://192.168.10.61:1560";
String subs_topic = "PI_TV";
String pubs_topic = "NUC_SERVER";


PFont sysFont;


PrintWriter log;
String logFile = "sketch_log.txt";
int passCounter = 0;

void setup() {
  prepareExitHandler();

  fullScreen();
  noCursor();

  //---------------- LOG METHOD ------------------//
  log = createWriter(logFile); // refreshes everytime a sketch runs, lazy method !!
  //----------------------------------------------//

  background(0);

  // ------ Serial related ------ //
  // For debugging serial port
  // String[] serialPorts = Serial.list();
  // printArray(serialPorts);
  try {
    // On linux it shows up like this below
    String portName = "/dev/ttyACM0";

    finger = new Serial(this, portName, 115200);
    finger.bufferUntil('\n');
  }
  catch (Exception e) {
    println(e);
  }


  // ------ Camera related ------ //
  String[] cameras = Capture.list();
  if (cameras == null) {
    println("Failed to retrieve the list of available cameras, exiting...");
    exit();
  } else if (cameras.length == 0) {
    println("There are no cameras available for capture.");
  } else {
    // println("Available cameras:");
    // printArray(cameras);
    // For linux
    cam = new Capture(this, cameras[0]);

    cam.start();
  }

  // ------- GUI related ------- //
  cp5 = new ControlP5(this);
  cp5.enableShortcuts();
  myTextarea = cp5.addTextarea("txt")
    .setPosition(camWidth + H_GAP+camWidth + H_GAP + 10, V_GAP)
    .setSize(debugWindowWidth, camHeight)
    .setFont(createFont("Ubuntu Mono", 18))
    .setLineHeight(18)
    .setColor(color(255, 255, 0))
    .setBorderColor(color(255))
    .setColorBackground(color(0, 100))
    .setColorForeground(color(255, 100))
    ;

  console = cp5.addConsole(myTextarea);

  cp5.addBang("EXIT_BTN")
    .setPosition(camWidth + H_GAP + camWidth + H_GAP + 10 + debugWindowWidth + H_GAP, height-35)
    .setSize(indicatorSize, indicatorSize/2)
    .setColorForeground(0xffaa0000)
    .setColorBackground(0xff660000)
    .setColorActive(0xffff0000)
    .setTriggerEvent(Bang.RELEASE)
    .setFont(createFont("Ubuntu Mono", 18))
    .setLabel("EXIT")
    ;

  cp5.getController("EXIT_BTN").getCaptionLabel().getStyle().marginLeft = cp5.getController("EXIT_BTN").getWidth()/2 - 17;
  cp5.getController("EXIT_BTN").getCaptionLabel().getStyle().marginTop = -(cp5.getController("EXIT_BTN").getHeight()/2+15);

  sysFont = loadFont("NeusaNextStd-CompactRegular-18.vlw");
  textFont(sysFont, 18);


  // ---- MQTT related ---- //
  try {
    client = new MQTTClient(this);
    client.connect(BrokerAddr, ClientID);
  }
  catch (Exception e) {
    println(e);
  }


  if (auto) {
    // arm the system by opening up serial channel for motor to receive signal
    timerFirstSysArming = CountdownTimerService.getNewCountdownTimer(this).configure(1, delayForSysArming).start();
    // send to serial '2' for tiktok or '3' for camera eye
    timerFirstSysSelection = CountdownTimerService.getNewCountdownTimer(this).configure(1, delayForSysTypeSel).start();
    // start the process automatically
    timerFirstSendStartSig = CountdownTimerService.getNewCountdownTimer(this).configure(1000, delayForSendingStartSig).start();
  }

  oneProcessTimer = CountdownTimerService.getNewCountdownTimer(this).configure(1, eachProcessDelay);
}



boolean captionAPITimedOut, giphyTimedOut = false;
;
String stdOut = "";
String oldStdOut = "";

void draw() {
  background(0);

  // Mouse pointer, later to be used for hitting EXIT button
  noStroke();
  fill(120);
  ellipse(mouseX, mouseY, 5, 5);

  noStroke();

  // System active indicator
  if (armSys) {
    // green
    fill(0, 255, 0);
  } else {
    // red
    fill(255, 0, 0);
  }
  rect(camWidth + H_GAP + camWidth + H_GAP + 10 + debugWindowWidth + H_GAP, V_GAP, indicatorSize, indicatorSize);

  // Time left countdown text
  fill(255);
  text(timerCallbackInfo, camWidth + H_GAP + camWidth + H_GAP + 10 + debugWindowWidth + H_GAP, V_GAP + indicatorSize + 40);


  noFill();
  strokeWeight(1);
  stroke(255, 0, 0);


  if (cam.available() == true) {
    cam.read();
  }

  // Live camera view
  image(cam, 0, V_GAP, camWidth, camHeight-5);
  // Live camera frame
  rect(0, V_GAP, camWidth, camHeight - 5);
  // Snapshot image frame
  rect(camWidth + H_GAP, V_GAP, camWidth, camHeight - 5);
  // Console frame
  noFill();
  rect(camWidth + H_GAP+camWidth + H_GAP, V_GAP, debugWindowWidth, camHeight - 5);

  if (snapShotImg!=null && BOUNDING_BOXES.size()>0) {
    image(snapShotImg, camWidth + H_GAP, V_GAP, camWidth, camHeight-5);
    drawBoundingBoxes(BOUNDING_BOXES);
  }

  // Frame labels
  noStroke();
  fill(255, 255, 0);
  rect(2, V_GAP+2, 90, 20);
  fill(0);
  text("CAM 0 FEED", 6, V_GAP + 16);

  fill(255);
  rect(camWidth + H_GAP + 2, V_GAP+2, 130, 20);
  fill(0);
  text("ANALYSIS WINDOW", camWidth + H_GAP + 6, V_GAP + 16);


  if (!stdOut.equals(oldStdOut)) {
    println(stdOut);
    oldStdOut = stdOut;
  }

  //------------------ MENTION AUTO START OF PROCESSES ---------------//
  // PRINT ONCE, FOR EVERY TIMER, THAT INITIATES A METHOD 
  // AND THAT TIMER HAS STARTED
  if (timerFirstSysArming.isRunning() && auto) {
    stdOut = "MOTOR CHANNEL OPENING: in " + str(delayForSysArming/1000) + " SEC.";
  }
  if (timerFirstSendStartSig.isRunning() && auto) {
    stdOut = "SENDING SIGNAL TO AUTO-START: in " + str(delayForSendingStartSig/1000) + " SEC.";
  }
  //------------------------------------------------------------------//


  if (startProcess) {
    // do all the stuff here in this func.
    thread("extractImgData");
    startProcess= false;
  }
}





String timerCallbackInfo = "";

void onTickEvent(CountdownTimer t, long timeLeftUntilFinish) {
  if (t == oneProcessTimer) {
    timerCallbackInfo = timeLeftUntilFinish/1000 + " SEC.";
  }
}


void onFinishEvent(CountdownTimer t) {
  if (t == timerFirstSysArming) {
    if (!armSys) {
      armSys = true;
      //println("MOTOR CHANNEL OPENED: ", armSys);
      stdOut = "MOTOR CHANNEL OPENED: True";
    }
  }

  if (t == timerFirstSysSelection) {
    if (armSys) {
      sysType = "tiktok_cam"; // public_cam='3' or tiktok_cam='2'
      if (sysType.equals("tiktok_cam")) {
        finger.write('2'); // for tiktok system
        stdOut = "SYSTEM: TIKTOK CAM";
      }
      if (sysType.equals("public_cam")) {
        finger.write('3'); // for env camera sys
        stdOut = "SYSTEM: PUBLIC CAM";
      }
    }
  }

  if (t == timerFirstSendStartSig) {
    fromKeyBoard = false;
    if (armSys) {
      snapShotImg = null;
      startProcess = true;
      //println("PROCESS STARTED: ", startProcess);
      stdOut = "PROCESS STARTED: True";
      // clear out the bounding boxes data array list 
      BOUNDING_BOXES.clear();
    }
  }

  // when the designated delay ends
  if (t == oneProcessTimer) {
    snapShotImg = null;
    startProcess = true;
    // clear out the bounding boxes data array list 
    BOUNDING_BOXES.clear();
  }
}



boolean fromKeyBoard;
void keyPressed() {
  if (key=='c'|| key=='C') {
    fromKeyBoard = true;
    snapShotImg = null;
    startProcess = true;
    // clear out the bounding boxes data array list 
    BOUNDING_BOXES.clear();
  }

  if (key == ESC) { 
    println("exit pressed");
    log.flush();
    log.close();
    exit();
  }
}



String val;
boolean toogleTimer;
void serialEvent( Serial finger) {
  val = finger.readStringUntil('\n');
  if (val != null) {
    val = trim(val);


    if (val.equals("e")) {
      armSys = true;
    }
    if (val.equals("d")) {
      armSys = false;
      oneProcessTimer.stop(CountdownTimer.StopBehavior.STOP_AFTER_INTERVAL);
    }

    if (val.equals("s")) {
      fromKeyBoard = false;
      if (armSys) {
        // start the timer and wait for designated delay
        oneProcessTimer.start();
      }
    }
  }
}


boolean  gifDownloaded = false;

void extractImgData() {
  passCounter++;

  //console.clear();
  stdOut = "Capturing camera image";
  camshot = cam.get();
  camshot.save(rawImage);

  stdOut = "Image captured!";
  logStuff("Image captured!");


  ActiveDir = sketchPath() + "/";

  RawImgPath = ActiveDir + rawImage;

  String pyScriptPath = ActiveDir + cap_find_py_script;

  jsonFilePath = ActiveDir + imgDataJSONFile;

  String cmd[] = {pythonPath, pyScriptPath, RawImgPath, jsonFilePath};

  stdOut = "Processing Image to get captions from Images";
  logStuff("PASS "+ str(passCounter) + " IMAGES WAS TAKEN. HITTING AI API TO GET CAPTIONS..");

  if (ranCommandSuccsfully(cmd)) {
    jsonFilePath = ActiveDir + imgDataJSONFile;
    loadAndParseJSON(jsonFilePath);

    // Load the image
    snapShotImg = loadImage(rawImage);
    //---------------------------------------------//
    //draw bounding boxes (in the draw, it's drawing)
    //---------------------------------------------//
    // 1. get a random caption.
    // 2. hight-light the bounding box from which the caption was referred to. 
    // 3. search giphy with that caption for a gif 
    // 4. Download the first GIF. 
    getGIF(CAPTIONS);
  } else {
    gifDownloaded = false;
    //  stdOut = "RES TO REQ: 404";
    stdOut = "ERROR!";

    // clear out the bounding boxes data array list as no data was found
    BOUNDING_BOXES.clear();

    client.publish(pubs_topic, "scene_recognition_failed");

    // could not parse data and find a random GIF, so moving on
    scrollNext();
  }
}


String line;
boolean ranCommandSuccsfully(String _cmd[]) {
  Process p = exec(_cmd);
  try {
    if (p.waitFor(timeOutSec, TimeUnit.SECONDS)) {
      return true;
    } else {
      return false;
    }
  } 
  catch (InterruptedException e) { 
    return false;
  }
}




void loadAndParseJSON(String _jsonFilePath) {
  raw_image_info_json = loadJSONObject(_jsonFilePath);

  JSONArray captions = raw_image_info_json.getJSONObject("output").getJSONArray("captions");

  CAPTIONS = new StringList();
  JSONArray boundingBox;

  for (int i=0; i<captions.size(); i++) {
    JSONObject captionData = captions.getJSONObject(i);

    String caption = captionData.getString("caption");
    CAPTIONS.append(caption);

    boundingBox = captionData.getJSONArray("bounding_box");

    BOUNDING_BOXES.add(boundingBox.getIntArray());
  }


  stdOut = "Found Captions from Image";
  logStuff("PASS "+ str(passCounter) +" API HIT SUCCESSFUL, FOUND CAPTIONS FROM IMAGES");
}

void drawBoundingBoxes(ArrayList<int[]> _BOUNDING_BOXES) {
  for (int id=0; id<_BOUNDING_BOXES.size(); id++) {
    int[] boundingBox=_BOUNDING_BOXES.get(id);

    noFill();

    if (id == randSeed) {
      strokeWeight(2);
      stroke(255, 0, 0);
      rect(camWidth + H_GAP + boundingBox[0] + 2, boundingBox[1] + V_GAP + 2, boundingBox[2] - 2, boundingBox[3] - 2);

      noStroke();
      fill(255, 0, 0);
      rect(camWidth + H_GAP + boundingBox[0] + 2, boundingBox[1] + V_GAP + 2, markerWidth, markerHeight);

      fill(255);
      text(id, camWidth + H_GAP + boundingBox[0] + 2, boundingBox[1] + 22);
    } else {
      strokeWeight(1);
      stroke(255, 255, 0);
      rect(camWidth + H_GAP + boundingBox[0] + 2, boundingBox[1] + V_GAP + 2, boundingBox[2] - 2, boundingBox[3] - 2);

      noStroke();
      fill(255, 255, 0);
      rect(camWidth + H_GAP + boundingBox[0] + 2, boundingBox[1] + V_GAP + 2, markerWidth, markerHeight);

      fill(30);
      text(id, camWidth + H_GAP + boundingBox[0] + 2, boundingBox[1] + 22);
    }
  }
}




void getGIF(StringList _CAPTIONS) {
  // Pick a random caption (given we have a captions array)
  randSeed = int(random(0, _CAPTIONS.size()-1));
  stdOut = str(randSeed);
  String selectedCaption = _CAPTIONS.get(randSeed);

  logStuff("PASS "+ str(passCounter) + " RANDOM CAPTION: " + selectedCaption);

  // Hit giphy with that search
  ActiveDir = sketchPath() + "/";

  stdOut = "searching for \"" + selectedCaption + "\" in GIPHY.com";

  String scriptPath = ActiveDir + gif_find_py_script;
  String search_term = "\"" + selectedCaption + "\"";
  gifJSONFilePath = ActiveDir + gifDataJSONFile;

  //pythonPath + pyScriptPath + "\"" + selectedCaption + "\"" + gifJSONFilePath
  String cmd[] = {pythonPath, scriptPath, search_term, gifJSONFilePath};

  // Search for 1 gif in the command (in python file)
  if (ranCommandSuccsfully(cmd)) {
    stdOut = "RES TO REQ: OK";
    stdOut = "gif data saved as" + imgDataJSONFile;
    stdOut = "searching for GIF link in json file returned by GIPHY...";

    rawGIF_uri = searchGIF_URL(gifJSONFilePath);

    stdOut = "Found gif link:" + rawGIF_uri;
    stdOut = "Downloading gif...";


    // Send signal to kill current running OMX player
    client.publish(pubs_topic, "downloading");

    logStuff("PASS "+ str(passCounter) +" DOWNLOADING GIF and KILLING OMX-PLAYER in PI");

    // Download it
    downLoadGif(rawGIF_uri);
  } else {
    stdOut = "RES TO REQ: 404";
    stdOut = "RES TO REQ: 404";

    logStuff("PASS "+ str(passCounter) +" RES TO REQ: 404 and KILLING OMX-PLAYER in PI");

    //--------------------------//
    // Load a default error gif //
    //--------------------------//
    gifDownloaded = false;

    client.publish(pubs_topic, "download_failed");

    // If could not parse data and find a random GIF, so moving on
    scrollNext();
  }
}


String searchGIF_URL(String _jsonFilePath) {
  String _uri_="";

  // Scrap the json file for proper gif url
  JSONObject raw_json = loadJSONObject(_jsonFilePath);
  JSONObject meta_data = raw_json.getJSONArray("data").getJSONObject(0);
  JSONObject images_data = meta_data.getJSONObject("images");
  JSONObject image_link = images_data.getJSONObject("looping");
  String original_video_link = image_link.getString("mp4");
  _uri_= original_video_link;

  return _uri_;
}



void downLoadGif(String _uri) {
  // curl https://media1.giphy.com/media/14aA4UahC14QQE/giphy.mp4 --output gif.mp4 ;; open gif.mp4
  String curl = curlPath;
  String output_tag = "--output";

  // For linux, save it outside the sketch book so that we can expose the folder via a webserver
  String outputfilePath = "/home/nuc/GIF/" + gifFile;

  String cmd[] = {curl, _uri, output_tag, outputfilePath};

  if (ranCommandSuccsfully(cmd)) {
    gifDownloaded = true;

    stdOut = "GIF has been downloaded!";
    logStuff("PASS "+ str(passCounter) +" GIF DOWNLOADED");

    if (retainGIF) {
      stdOut = "Retaining a copy of the gif...";

      String cp_gif_name = str(day())+"-"+str(month())+"-"+str(year())+"--"+str(hour())+"-"+str(minute())+"-"+str(second())+".mp4";
      String cp_gif_path =  "/home/nuc/GIF/" + cp_gif_name;
      String cp_cmd[] = {"cp", outputfilePath, cp_gif_path};
      if (ranCommandSuccsfully(cp_cmd)) {
        stdOut = cp_gif_name + " has been archived";
      } else {
        stdOut = cp_gif_name + " could not be created or copied over!!";
      }
    }

    scrollNext();
  } else {
    gifDownloaded = false;

    stdOut = "ERROR in downloading GIF!\n";
    logStuff("PASS "+ str(passCounter) +" GIF FAILED DOWNLOADING, SCOLLING ANYWAYS");

    client.publish(pubs_topic, "download_failed");

    scrollNext();
  }
}


void scrollNext() {
  if (gifDownloaded) {
    // SEND MQTT MESSAGE TO PLAY GIF and restart OMX Player: 
    client.publish(pubs_topic, "play");

    logStuff("Sending mqtt msg to pi: " + pubs_topic + "/" + "play");
  }

  // -------------------------------------------------------------------- //
  // -------- Send signal to finger to scroll for next pic  ture -------- //
  // -------------------------------------------------------------------- //
  if (!fromKeyBoard) {
    if (armSys) {
      try {
        finger.write('1');

        stdOut = "scroll now\n";

        oneProcessTimer.start();

        logStuff("PASS "+ str(passCounter) +" complete!");
      }
      catch (Exception e) {
        stdOut = "ERROR writing to serial\n";

        logStuff("PASS "+ str(passCounter) +" failed @serial com!");
      }
    }
  }
}


void logStuff(String msg) {
  String log_msg = str(day())+":"+str(month())+":"+str(year())+"-"+str(hour())+":"+str(minute())+":"+str(second())+ "  " + msg;
  log.println(log_msg);
  log.flush();
}


void clientConnected() {
  stdOut = "NET & SYS READY!";
  client.subscribe(subs_topic);
  client.publish(pubs_topic, "mount");
}

void connectionLost() {
  stdOut = "NET [MQTT CONN>] lost";
}

void messageReceived(String topic, byte[] payload) {
  //println("new message: " + topic + " - " + new String(payload));
  if (topic.equals(subs_topic)) {
    String PL = new String(payload);
    stdOut = PL;
    stdOut = "";
  }
}



public void EXIT() {
  println("exit pressed");
  log.flush();
  log.close();
  exit();
}


private void prepareExitHandler () {
  Runtime.getRuntime().addShutdownHook(new Thread(new Runnable() {
    public void run () {
      System.out.println("SHUTDOWN HOOK");

      // Application exit code here
      println("exitting");
      log.flush();
      log.close();
      exit();
    }
  }
  ));
}
