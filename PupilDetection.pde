/* This software requires two libraries: OpenCV and Video Library for Processing.

In order to add libraries,
select Sketch->Library->Add Library from Menubar 
and search for "OpenCV for Processing" and 
"Video: GStreamer-based video library for Processing" 
and install these two libraries, respectively.

*/

import processing.video.*;
import gab.opencv.*;
import java.awt.Rectangle;
import java.awt.Point;

Capture cam;
int fps = 30;
PImage inputFrame;

CircleDetector pupilDetector1;
CircleDetector pupilDetector2;

public OpenCV cvEye;
public Rectangle[] eyes;

String inputType  =   "camera"; //camera, image, folder, test
int inputWidth    =   640;
int inputHeight   =   480;
  
void setup()
{
  if( inputType == "camera" )
  {
    String [] cams = Capture.list();
    println( cams );
    
    cam = new Capture( this, inputWidth, inputHeight, fps );
    cam.start();
    inputFrame = cam.get(); 
  }
  else if( inputType == "image" )
  {
    inputFrame = loadImage( "lena.jpg" );//Test image
  }
  else if( inputType == "folder" || inputType == "test" )
  {
    inputFrame = loadImage( "bioId PNG/BioID_0000.png" );//Default image
  }
  
  if( inputFrame != null )
  {
    cvEye = new OpenCV( this, inputFrame );
    cvEye.loadCascade( "haarcascade_mcs_eyepair_big.xml" );
    
    inputWidth  = inputFrame.width;
    inputHeight = inputFrame.height;
    
    //size( inputWidth, inputHeight ); //Processing 2
    surface.setSize( inputWidth, inputHeight ); //Processing 3
    
    println( "setup..." );
    
    pupilDetector1 = new CircleDetector();
    pupilDetector2 = new CircleDetector();
  }
}

int curImageNum = 0;

Point massCenter1, massCenter2;

void draw()
{
  if( inputType == "image" )
  {
    srcImage();
  }
  else if( inputType == "camera" )
  {
    srcCam();
  }
  else if( inputType == "folder" )
  {
    updateImg( curImageNum );
    image( inputFrame, 0, 0 );
    long start = System.currentTimeMillis();
    print( "Error: " + calcErr( getGroundTruth( curImageNum, true ), searchEyePair( getEyeRects2( curImageNum, true ) ) ) + "\t" );
    long end = System.currentTimeMillis();
    println("Elapsed time: "+(end-start)+"ms.");
    ++curImageNum;
    noLoop();
  }
  else if( inputType == "test" )
  {
    long start = System.currentTimeMillis();
    traversePics();
    long end = System.currentTimeMillis();
    println("Elapsed time: "+(end-start)+"ms.");
    
    noLoop();
    return;
  }
}

void updateImg( int picNum )
{
  inputFrame = requestImage( getImgName( picNum ) );
  
  while( inputFrame.width == 0 )
  { 
    //Wait until frame gets loaded.
    println();  //Do nothing.
  }
  
  loop();  //Call draw() and screen inputFrame
}

void srcImage()
{
  if( inputFrame != null )
  {
    image( inputFrame, 0, 0 );
  
    long start = System.currentTimeMillis();
    getEyeRects( true );
    searchEyePair( getEyeRects( false ) );
    long end = System.currentTimeMillis();
    println("Elapsed time: "+(end-start)+"ms.");
  }
  
  noLoop();
}

void srcCam()
{
  if( cam.available() == true )
  {
    cam.read();
    inputFrame = cam.get();
    image( inputFrame, 0, 0 );
    long start = System.currentTimeMillis();
    searchEyePair( getEyeRects( true ) );
    long end = System.currentTimeMillis();
    println("Elapsed time: "+(end-start)+"ms.");
  }
}
 
void mousePressed()
{
 if( inputType == "folder" )
 {
   if( mouseButton == LEFT && curImageNum <= 1520 )
     loop();  //Call draw
   else if( mouseButton == RIGHT && curImageNum >= 2 )
   {
     --curImageNum;
     --curImageNum;
     loop();
   }
 }
}

int pn=0;
void keyPressed()
{
  // If the key is between 'A'(65) to 'Z' and 'a' to 'z'(122)
  if(key =='s' ||key =='S'){
      save("bioIdSamp_"+pn+".jpg");
  }
  ++pn;
}
  
int currThruth;
void traversePics()
{
  float err;
  float d002 = 0.0f;
  float d005 = 0.0f;
  float d010 = 0.0f;
  float d015 = 0.0f;
  float d020 = 0.0f;
  float d025 = 0.0f;
  float nf   = 0.0f;
  Rectangle tempArea;
  int nA=0;
  
  for( int currThruth = 0; currThruth < 1521; currThruth++ )
  {  //1521
    inputFrame = loadImage( getImgName( currThruth ) );
    
    tempArea = getEyeRects2( currThruth, false );
    if(tempArea==null){
      println("No area found! Pic no: "+currThruth);
      ++nA;
    }
    else{
      err = calcErr( getGroundTruth( currThruth, false ), searchEyePair( tempArea ) );
      
      err = (int) (err * 100);
      err = err / 100;
      
      if( err <= 0.02f )
        ++d002;
      if( err <= 0.05f )
        ++d005;
      if( err <= 0.10f )
        ++d010;
      if( err <= 0.15f )
        ++d015;
      if( err <= 0.20f )
        ++d020;
      if( err <= 0.25f )
        ++d025;
      else
        nf++;
        
      println( "Picture " + ( currThruth + 1 ) + " was processed!" ); 
    }
  }
  
  d002 /= (float)(1521-nA);
  d005 /= (float)(1521-nA);
  d010 /= (float)(1521-nA);
  d015 /= (float)(1521-nA);
  d020 /= (float)(1521-nA);
  d025 /= (float)(1521-nA);
  nf   /= (float)(1521-nA);
  
  println( "e < 0.02f: %" + d002 * 100 );
  println( "e < 0.05f: %" + d005 * 100 );
  println( "e < 0.10f: %" + d010 * 100 );
  println( "e < 0.15f: %" + d015 * 100 );
  println( "e < 0.20f: %" + d020 * 100 );
  println( "e < 0.25f: %" + d025 * 100 );
  println( "e > 0.25f: %" + nf   * 100 );
  println("Out of "+(1521-nA)+" bioId images.");
  println("Number of skipped photos: "+nA);
}

float calcErr( int[] truth, int[] calculated )
{
  float maxDistance   = max( dist( truth[0], truth[1], calculated[0], calculated[1] ), dist( truth[2], truth[3], calculated[2], calculated[3] ) ); 
  float truthDistance = dist( truth[0], truth[1], truth[2], truth[3] );
  float err = maxDistance / truthDistance; 
  
  return err;
}

String getTxtName( int num )
{
  if( num > 999 )
    name = "" + num;
  else if( num > 99 )
    name = "0" + num;
  else if( num > 9 )
    name = "00" + num;
  else if( num > -1 )
    name = "000" + num;
  else
    name = "invalid number!!!! " + num;
  
  fullName = "bioId PNG/BioID_" + name + ".eye";
  
  return fullName;
}

int maxArea;
int maxInd;
int currArea;

Rectangle getEyeRects( boolean draw )
{
  currArea  =  0;
  maxArea   =  0;
  maxInd    = -1;
  cvEye.loadImage( inputFrame );
  eyes = cvEye.detect();
    
  noFill();
  stroke( 0, 255, 0 );
  strokeWeight( 1 );
  
  for( int i = 0; i < eyes.length; i++ )
  {
    if( inputType == "folder" || inputType == "test" )
      if (checkTrueEyeRect(eyes[i])) { // Works only with BioId!!!
        if( draw )
        {
          rect( eyes[i].x, eyes[i].y, eyes[i].width / 2, eyes[i].height );
          rect( eyes[i].x + eyes[i].width / 2, eyes[i].y, eyes[i].width / 2, eyes[i].height );
        }
        return eyes[i];
      }
      
    currArea = eyes[i].width * eyes[i].height;
    if( currArea > maxArea )
    {
      maxArea = currArea;
      maxInd = i;
    }
  }
  
  //In bioId, return null if no area mathing with ground thruth. 
  if( inputType == "folder" || inputType == "test" )
    return null;
  
  if( maxInd == -1 )
    return null;
  
  massCenter1 = getMassCenter( eyes[maxInd].x + eyes[maxInd].width / 2, eyes[maxInd].y, eyes[maxInd].width / 2, eyes[maxInd].height ); //Right eye socket
  massCenter2 = getMassCenter( eyes[maxInd].x, eyes[maxInd].y, eyes[maxInd].width / 2, eyes[maxInd].height ); //Left eye socket
  
  stroke(255,255,0);
  strokeWeight( 5 );
  
  point( massCenter1.x, massCenter1.y );
  point( massCenter2.x, massCenter2.y );
    
  if( draw )
  {
    noFill();
    stroke( 0, 255, 0 );
    strokeWeight( 1 );
    
    rect( eyes[maxInd].x, eyes[maxInd].y, eyes[maxInd].width / 2, eyes[maxInd].height );
    rect( eyes[maxInd].x + eyes[maxInd].width / 2, eyes[maxInd].y, eyes[maxInd].width / 2, eyes[maxInd].height );
  }
  
  return eyes[maxInd];
}

Rectangle getEyeRects2( int picNum, boolean draw )
{
  int [] eyeCenters = getGroundTruth( picNum, false );
  
  float rightX  = eyeCenters[0]; //RX
  float rightY  = eyeCenters[1]; //RY
  float leftX   = eyeCenters[2]; //LX
  float leftY   = eyeCenters[3]; //LY
    
  Rectangle rect = new Rectangle();
  
  rect.x       = (int) ( leftX - 0.4000f * (rightX - leftX) );
  rect.y       = (int) ( leftY - 0.2075f * (rightX - leftX) );
  rect.width   = (int) ( 1.9000f * (rightX - leftX) );
  rect.height  = (int) ( 0.4500f * (rightX - leftX) );
  
  if( rect.x < 0 )
    rect.x = 0;
  if( rect.y < 0 )
    rect.y = 0;
  if( rect.width < 0 )
    rect.width = 0;
  if( rect.height < 0 )
    rect.height = 0;
   
  massCenter1 = getMassCenter( rect.x + rect.width / 2, rect.y, rect.width / 2, rect.height ); //Right eye socket
  massCenter2 = getMassCenter( rect.x, rect.y, rect.width / 2, rect.height ); //Left eye socket
  
  noFill();
  stroke( 0, 255, 0 );
  strokeWeight( 1 );
  
  if( draw )
  {
    rect( rect.x, rect.y, rect.width / 2, rect.height );
    rect( rect.x + rect.width / 2, rect.y, rect.width / 2, rect.height );
    
    stroke(255,255,0);
    strokeWeight( 5 );
  
    point( massCenter1.x, massCenter1.y );
    point( massCenter2.x, massCenter2.y );
  }

  return rect;
}

//search pupil on right and left sides of eye pair area
int [] searchEyePair( Rectangle eye ) //Returns found centers.
{
  NumPair tempN;
  
  int[] centers= new int[4];
  
  if( eye != null )
  {
    int halfWidth = (int) eye.width / 2;
    
    pupilDetector1.srcImg = inputFrame;
    pupilDetector2.srcImg = inputFrame;
    
    pupilDetector1.pupilRadius = (int) (  ( (float) eye.height ) / 6.0f  ) + 1;
    pupilDetector2.pupilRadius = (int) (  ( (float) eye.height ) / 6.0f  ) + 1;
    
    tempN      = pupilDetector1.rangeDetect( eye.x + halfWidth, eye.y, massCenter1.x, massCenter1.y, halfWidth, eye.height );  //Right
    centers[0] = tempN.x; //RX
    centers[1] = tempN.y; //RY
    
    tempN      = pupilDetector2.rangeDetect( eye.x, eye.y, massCenter2.x, massCenter2.y, halfWidth, eye.height );  //Left
    centers[2] = tempN.x; //LX
    centers[3] = tempN.y; //LY
    
    
  }
  
  return centers;
}

int getPixel( int x, int y )
{
  if( x < 0 )
    x = 0;
  if( x > inputFrame.width - 1 )
    x = inputFrame.width - 1;
  if( y < 0 )
    y = 0;
  if( y > inputFrame.height - 1 )
    y = inputFrame.height - 1;
    
  return inputFrame.pixels[ y * inputFrame.width + x ];
}
  
Point getMassCenter( int eyeSocketX, int eyeSocketY, int eyeSocketWidth, int eyeSocketHeight )
{
    float mean = 0.0f;
    
    for( int x = eyeSocketX; x < eyeSocketX + eyeSocketWidth; x++ )
    {
      for( int y = eyeSocketY; y < eyeSocketY + eyeSocketHeight; y++ )
      {
        float intensity = brightness( getPixel(x, y) );
        mean += intensity;
      }
    }
    
    mean /= eyeSocketWidth * eyeSocketHeight;
    
    float sumX = 0.0f;
    float sumY = 0.0f;
    
    float sumOfLowIntensities = 0.0f;
       
    for( int x = eyeSocketX; x < eyeSocketX + eyeSocketWidth; x++ )
    {
      for( int y = eyeSocketY; y < eyeSocketY + eyeSocketHeight; y++ )
      {
        float intensity = brightness( getPixel(x, y) );
        float variance = abs( mean - intensity );
        
        sumX += (255.0f - variance) * x;
        sumY += (255.0f - variance) * y;
        
        sumOfLowIntensities += (255.0f - variance);
        
      }
    }
    
    int massCenterX = (int)(sumX / sumOfLowIntensities);
    int massCenterY = (int)(sumY / sumOfLowIntensities);
    
    return new Point( massCenterX, massCenterY );
}


String name;
String fullName;

String getImgName( int num )
{
  if( num > 999 )
    name = "" + num;
  else if( num > 99 )
    name = "0" + num;
  else if( num > 9 )
    name = "00" + num;
  else if( num > -1 )
    name = "000" + num;
  else
    name = "invalid number!!!! " + num;
    
  fullName = "bioId PNG/BioID_" + name + ".png";
  
  return fullName;
}
  
BufferedReader in;
String line;
String [] truthS = new String[4]; //LX, LY, RX, RY
int [] truth = new int[4];

int [] getGroundTruth( int i, boolean draw )
{
  try
  {
    in = createReader( getTxtName( i ) );
    in.readLine();
    line = in.readLine();
    truthS = line.split( "\t" );  //Split tab character
      
    truth[0] = parseInt( truthS[0] );  //RX
    truth[1] = parseInt( truthS[1] );  //RY
    truth[2] = parseInt( truthS[2] );  //LX
    truth[3] = parseInt( truthS[3] );  //LY
    
    in.close();
  }
  catch( IOException e )
  {
    e.printStackTrace();
  }
  
  if( draw )
  {
    stroke( 0, 255, 255 );
    strokeWeight( 3 );
    point( truth[0], truth[1] );
    point( truth[2], truth[3] );
  }
  
  return truth;
}

int[] tempEyePos=new int[4];
int tempC=0;
boolean checkTrueEyeRect(Rectangle cand) {
  tempEyePos = getGroundTruth(currThruth, false);
  if (tempC < tempEyePos[0] && tempC < tempEyePos[2]
      && tempEyePos[0] < cand.x && tempEyePos[2] < cand.x)
    return false;
  tempC = cand.y + cand.height;
  if (tempC < tempEyePos[1] && tempC < tempEyePos[3]
      && tempEyePos[1] < cand.y && tempEyePos[3] < cand.y)
    return false;
  return true;
}
