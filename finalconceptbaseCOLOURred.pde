import processing.pdf.*;


//imports Kinect lib
import SimpleOpenNI.*;

//defines variable for kinect object
SimpleOpenNI kinect;

//to store positions
float x, y, z;
//int peopleNum;
PVector[] currentPos;
PVector[] allPos;
PVector[] linePos1;
PVector[] linePos2;
int count = 0;

int peopleNum = 0;
int userId;
float inches;
int timeInterval = 300;

int timer = 0;

void setup() {

  //set the display size to full screen
  size(displayWidth, displayHeight);
  //set background to white 
  background(255);
  //set frame rate
  frameRate(30);
  noCursor();

  //declares new kinect object
  kinect = new SimpleOpenNI(this);

  //enable depth image
  kinect.enableDepth();
  //enable user detection
  kinect.enableUser();

  //array to store all of the xy positions 
  allPos = new PVector[10000];
  //arrays to store start and end positions of all of the lines 
  linePos1 = new PVector[10000];
  linePos2 = new PVector[10000];
}

void draw() {

  background(255);

  println(timer);

  if (timer % 18000 == 0) {
    beginRecord(PDF, "lines" + frameCount + ".pdf");
  }

  //if ( frameCount % 60 == 0) {
  //THIS DRAWS ALL OF THE PREVIOUS LINES
  //for however many values we have
  //if(frameCount >= 60){ 
  for (int b = linePos1.length-1; b > count-1; b--) {
    //and as long as their value is NOT null
    if (linePos1[b]!=null) {

      //STYLING
      //THIS IS WHERE WE DRAW THE PREVIOUS LINES
      strokeWeight(2);
      stroke(0, 100);
      line(linePos1[b].x, linePos1[b].y, linePos2[b].x, linePos2[b].y);
    }
  }

  //THIS DRAWS ALL OF THE PREVIOUS ELLIPSES
  //for however many values we have that are NOT null
  for (int w = allPos.length-1; w > peopleNum-1; w--) {
    if (allPos[w]!=null) {

      //STYLING
      //THIS IS WHERE WE DRAW THE PREVIOUS ELLIPSES
      //strokeWeight(prevCircSW);
      noStroke();
      fill(163, 24, 24, 75);
      ellipse(allPos[w].x, allPos[w].y, allPos[w].z/2, allPos[w].z/2);
      fill(255, 75);
      ellipse(allPos[w].x, allPos[w].y, 2, 2);
    }
  } 
  //}


  //now set the counter back to zero ready for the next loop
  count = 0;

  //updates depth image
  kinect.update();

  //draws depth image - if we don't need this comment out 
  //image(kinect.depthImage(),0,0,displayWidth,displayHeight);

  //array to store depth values
  int[] depthValues = kinect.depthMap();

  //access all users currently available to us 
  IntVector userList = new IntVector();
  kinect.getUsers(userList);

  //sets variable peopleNum to the number of people currently detected by the kinect
  peopleNum = int(userList.size());
  println("there are " + peopleNum + " people here");

  //set an array which is that size 
  currentPos = new PVector[peopleNum];

  //for every user detected, do this 
  for (int i = 0; i<userList.size (); i++) {

    //get the userId
    userId = userList.get(i);

    //declare PVector position to store x/y position 
    PVector position = new PVector();

    //get the position
    kinect.getCoM(userId, position);
    kinect.convertRealWorldToProjective(position, position);

    //calculate depth
    //find the position of the center of mass *640 to give us a number to find in depth array
    //this also gives us the x/y values for each user
    int comPosition = int(position.x) + (int(position.y) * 640);    
    //locate it in the depth array
    int comDepth = depthValues[comPosition];
    //calculate distance in inches
    inches = comDepth / 25.4;
    //map inches to 255 for a depth value to use with colour density
    z = map(inches, 0, 196, 0, 255);
    //if the value comes up more than 255 (an unusable no) make it 255 so we can use it
    if (z >= 255) {
      z = 254;
    }

    z = (255-z)/4;

    //map x and y coordinates to full screen
    x = map(position.x, 0, 640, 0, displayWidth);
    y = map(position.y, 0, 480, 0, displayHeight);

    currentPos[i] = new PVector (x, y, z);

    //println("Person" + i);
    //println("X =" + x);
    //println("Y = " + y);

    //store all of these xy positions in an array so we can draw them again in future
    //move them along one so that there is space at the start for a new value 
    if (timer % timeInterval == 0) {
      for (int n = allPos.length-1; n > 0; n--) {
        allPos[n] = allPos[n-1];
      }  
      //add a new value at the begining 
      allPos[0] = new PVector (x, y, z);
    }
  }




  //now check if any of the CURRENT ellipses are close to each other
  //if(frameCount >= 60){
  for (int f = 0; f < currentPos.length; f++) {    
    for (int j = 0; j < currentPos.length-1; j++) {
      if ((currentPos[j]!=null) && (currentPos[f]!=null)) {
        if ((currentPos[f].x > 0.0) && (currentPos[j].y > 0.0)) {  
          //if they are
          if (dist(currentPos[f].x, currentPos[f].y, currentPos[j].x, currentPos[j].y) < 1000) {     

            //if ((currentPos[f].z <= currentPos[j].z + 50) && (currentPos[f].z >= currentPos[j].z - 50)) {
            //for each line increase count by one
            count++;
            //STYLING
            //THIS IS WHERE WE DRAW THE CURRENT LINES

            strokeWeight(2);
            stroke(0);

            line(currentPos[f].x, currentPos[f].y, currentPos[j].x, currentPos[j].y);          

            //println("drawing a line between" + currentPos[f].x + " " + currentPos[f].y + " " + currentPos[j].x + " " + currentPos[j].y);

            //store all of the line positions in an array so we can use them later 
            //move them along so that we can add new values at the begining of the array
            if (timer % timeInterval == 0) {
              for (int n = linePos1.length-1; n > 0; n--) {
                linePos1[n] = linePos1[n-1];
                linePos2[n] = linePos2[n-1];
              }          
              //store them
              linePos1[0] = new PVector (currentPos[f].x, currentPos[f].y);
              linePos2[0] = new PVector (currentPos[j].x, currentPos[j].y);
            }
          }
        }
        // }
      }
    }
  }


  for (int i = 0; i<userList.size (); i++) {
    //STYLING
    //THIS IS WHERE WE DRAW THE CURRENT ELLIPSES

    //noFill();

    //strokeWeight(currentCircSW);
    //stroke(currentCircS);
    noStroke();
    fill(163, 24, 24);
    ellipse(currentPos[i].x, currentPos[i].y, currentPos[i].z/2, currentPos[i].z/2);
    fill(255, 255, 255);
    ellipse(currentPos[i].x, currentPos[i].y, 3, 3);
  }

  //THIS DRAWS ALL OF THE CURRENT LINES
  //for however many values we have 
  for (int b = 0; b <= count-1; b++) {
    //and as long as their value is NOT null
    if (linePos1[b]!=null) {
      //stroke(0);
      //strokeWeight(5);
      //line(linePos1[b].x, linePos1[b].y, linePos2[b].x, linePos2[b].y);
    }
  }

  //THIS DRAWS ALL OF THE CURRENT ELLIPSES
  //for however many values we have that are NOT null
  for (int w = 0; w <= peopleNum-1; w++) {
    if (allPos[w]!=null) {
      if ((allPos[w].x > 0.0) && (allPos[w].y > 0.0)) {
        //stroke(0);
        //strokeWeight(5);
        //draw the ellipses
        //ellipse(allPos[w].x, allPos[w].y, allPos[w].z/12, allPos[w].z/12);
      }
    }
  }

  //this allows us to draw a line every x amount of frames 
  timer++;
  endRecord();
}

