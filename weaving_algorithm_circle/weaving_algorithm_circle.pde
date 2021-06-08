//------------------------------------------------------
// circular weaving algorithm
// normanburtonfree@gmail.com 2021-06-05
// based on work by Petros Vrellis (http://artof01.com/vrellis/works/knit.html)
//------------------------------------------------------
import controlP5.*;
// points around the circle
final int numberOfPoints = 256;
// self-documenting
final int numberOfLinesToDrawPerFrame = 2;
// how thick are the threads?
final float lineWeight = 1;  // default 1
final float stringAlpha = 25; // 0...255 with 0 being totally transparent.
// ignore N nearest neighbors to this starting point
final int skipNeighbors=10;
// make picture bigger than what is visible for more accuracy
final int upScale=1;
//the number if the lines
final int limitlines = 6000;
// convenience colors.  RGBA. 
// Alpha is how dark is the string being added.  1...255 smaller is lighter.
// Messing with the alpha value seems to make a big difference!

final color maroon   = color(128, 0, 0,stringAlpha);
final color brown   = color(  170,   110,   40,stringAlpha);
final color olive    = color(  128, 128, 0,stringAlpha);
final color teal = color(0,   128,   128,stringAlpha);
final color navy  = color(0, 0,   128,stringAlpha);
final color black = color(0,0,0,stringAlpha);
final color red   = color(230, 25, 75,stringAlpha);
final color orange   = color(  245,   130,   48,stringAlpha);
final color yellow    = color(  255, 255, 25,stringAlpha);
final color lime = color(210,   245,   60,stringAlpha);
final color green  = color(60, 180,   75,stringAlpha);
final color cyan = color(70,240,240,stringAlpha);
final color blue   = color(0, 130, 200,stringAlpha);
final color purple   = color(  145,   30,   180,stringAlpha);
final color magenta    = color(  240, 50, 230,stringAlpha);
final color grey = color(128,   128,   128,stringAlpha);
final color pink  = color(250, 190,   212,stringAlpha);
final color apricot = color(255,215,180,stringAlpha);
final color beige   = color(255, 250, 200,stringAlpha);
final color mint   = color(  170,   255,   195,stringAlpha);
final color lavender    = color(  220, 190, 255,stringAlpha);
final color white = color(255,   255,   255,stringAlpha);
//------------------------GUI--------------------------
ControlP5 cp5;
//rectangle or circle
RadioButton r;
//width and height of the image
public int m_width = 500;
public int m_height = 500;
public int m_radius = 200;
//the nubmer of the  points
public int number_point = 0;
//the number if the lines
public int number_lines = 0;
//the thickness of the line
public int thickness = 0;
//the position of the button
public int rectX,rectY;
//the size of the Button
public int rectSize = 90;
//the opacity
public int intensity = 25;
//decide the shape
boolean m_shape = true;// if true->circle false->rectangle
//input the imgae flag;
int i = 0;
boolean image_flag = false;
int t = 0;
boolean play_flag = false;
//color list
CheckBox checkbox;
PImage colorImage;

//------------------------------------------------------

// WeavingThread class tracks a thread as it is being woven around the nails.
class WeavingThread {
  // thread color (hex value)
  public color c;
  // thread color name (human readable)
  public String name;
  // last nail reached
  public int currentPoint;
};

// for tracking the best place to put the next weaving thread.
class BestResult {
  // nails
  public int bestStart,bestEnd;
  // score
  public float bestValue;
  
  public BestResult( int a, int b, float v) {
    bestStart=a;
    bestEnd=b;
    bestValue=v;
  }
};

// for re-drawing the end result quickly.
class FinishedLine {
  // nails
  public int start,end;
  // hex color
  public color c;
  
  public FinishedLine(int s,int e,color cc) {
    start=s;
    end=e;
    c=cc;
  }
};

//------------------------------------------------------

// finished lines in the weave.
ArrayList<FinishedLine> finishedLines = new ArrayList<FinishedLine>(); 

// threads actively being woven
ArrayList<WeavingThread> threads = new ArrayList<WeavingThread>();

// stop when totalLinesDrawn==totalLinesToDraw
int totalLinesDrawn=0;

// diameter of weave
float diameter;

// can we start weaving yet?!
boolean ready;

// set true to start paused.  click the mouse in the screen to pause/unpause.
boolean paused=false;

// make this true to pause after every frame.
boolean singleStep=false;

// nail locations
float [] px = new float[numberOfPoints];
float [] py = new float[numberOfPoints];

// distance from nail n to nail n+m
float [] lengths = new float[numberOfPoints];

// image user wants converted
PImage img;

Octree tree = new Octree();

// image user wants converted
PImage quantizedImage;

PImage sobelImage;

// place to store visible progress fo weaving.
// also used for finding next best thread.
PGraphics dest; 
PGraphics test;
// which results to draw on screen.
int showImage;

long startTime;

// if all threads are tested and they're all terrible, move every thread one nail to the CCW and try again.
// if this repeats for all nails?  there are no possible lines that improve the image, stop.
int moveOver = 0;

boolean finished=false;

// center of image for distance tests
float center;
  
// a list of all nail pairs already visited.  I don't want the app to put many
// identical strings on the same two nails, so WeavingThread.done[] tracks 
// which pairs are finished.
public char [] done = new char[numberOfPoints*numberOfPoints];

// cannot be more than this number.
final int totalLinesToDraw=(int)(sq(numberOfPoints-skipNeighbors*2)/2);

//------------------------------------------------------
int blocksize;
// run once on start.
void setup() {
  // make the window.  must be (h*2,h+20)
  size(1000 ,1000);
  colorImage = loadImage("color.jpg");
  blocksize = 500;
  initial();

  
  
  ready=false;
  //selectInput("Select an image file","inputSelected");
}

void initial(){
  background(color(120));
  cp5 = new ControlP5(this);
  //set the radio button if it is rectangle or circle
  r = cp5.addRadioButton("radioButton")
         .setPosition(20,100)
         .setSize(20,20)
         .setColorForeground(color(200,0,0))
         .setColorActive(color(255))
         .setColorLabel(color(255))
         .setItemsPerRow(5)
         .setSpacingColumn(100)
         .addItem("Rectangle",1)
         .addItem("Circle",2)
         ;
  //set the width and height and radius of the image       
  cp5.addNumberbox("m_width")
     .setPosition(20,160)
     .setSize(100,20)
     .setRange(0,1000)
     .setScrollSensitivity(10)
     .setDirection(Controller.HORIZONTAL)
     .setValue(500)
     ;
  
  cp5.addNumberbox("m_height")
     .setPosition(20,220)
     .setSize(100,20)
     .setRange(0,1000)
     .setScrollSensitivity(10) // set the sensitifity of the numberbox
     .setDirection(Controller.HORIZONTAL) // change the control direction to left/right
     .setValue(500)
     ;  
     
  cp5.addNumberbox("m_radius")
     .setPosition(140,160)
     .setSize(100,20)
     .setRange(0,1000)
     .setScrollSensitivity(1) // set the sensitifity of the numberbox
     .setDirection(Controller.HORIZONTAL) // change the control direction to left/right
     .setValue(250)
     ;     
  //set the number of the point at the border
  cp5.addNumberbox("number_point")
     .setPosition(300,100)
     .setSize(100,20)
     .setRange(0,1000)
     .setScrollSensitivity(10) // set the sensitifity of the numberbox
     .setDirection(Controller.HORIZONTAL) // change the control direction to left/right
     .setValue(256)
     ; 
  //set the number of the point at the border
  cp5.addNumberbox("number_lines")
     .setPosition(300,160)
     .setSize(100,20)
     .setRange(0,10000)
     .setScrollSensitivity(500) // set the sensitifity of the numberbox
     .setDirection(Controller.HORIZONTAL) // change the control direction to left/right
     .setValue(0)
     ;   
  //set the intensity of the line
  cp5.addNumberbox("intensity")
     .setPosition(300,220)
     .setSize(100,20)
     .setRange(1,100)
     .setScrollSensitivity(5) // set the sensitifity of the numberbox
     .setDirection(Controller.HORIZONTAL) // change the control direction to left/right
     .setValue(25)
     ;     
  //set the Button
  cp5.addButton("Play")
     .setValue(1)
     .setPosition(300,280)
     .setSize(150,19)
     ;
  //set the input image button
   cp5.addButton("InputImage")
     .setValue(2)
     .setPosition(20,280)
     .setSize(150,19)
     ;   
   //select color
  checkbox = cp5.addCheckBox("checkBox")
                .setPosition(20, 350)
                .setColorForeground(color(120))
                .setColorActive(color(255))
                .setColorLabel(color(255))
                .setSize(20, 20)
                .setItemsPerRow(4)
                .setSpacingColumn(40)
                .setSpacingRow(20)
                .addItem("Maroon", 0)
                .addItem("Brown", 1)
                .addItem("Olive", 2)
                .addItem("Teal", 3)
                .addItem("Navy", 4)
                .addItem("Black", 5)
                .addItem("Red", 6)
                .addItem("Orange", 7)
                .addItem("Yellow", 8)
                .addItem("Lime", 9)
                .addItem("Green", 10)
                .addItem("Cyan", 11)
                .addItem("Blue", 12)
                .addItem("Purple", 13)
                .addItem("Margenta", 14)
                .addItem("Grey", 15)
                .addItem("Pink", 16)
                .addItem("Apricot", 17)
                .addItem("Beige", 18)
                .addItem("Mint", 19)
                .addItem("Lavender", 20)
                .addItem("White", 21)
                ;

}
void inputSelected(File selection) {
  if(selection == null) {
    exit();
    return;
  }
  if(image_flag==true){
  // load the image
  img = loadImage(selection.getAbsolutePath());
  
  // crop image to square
 
  int min_length = img.width <= img.height ? img.width : img.height;
  img = img.get(0,0,min_length,min_length);
  println(min_length);
  img.resize(min_length,min_length);
  // resize to fill window
  //img.resize();
  img.loadPixels();
  
  quantizedImage = img.copy();
  sobelImage = img.copy();
  sobelFilter(img,sobelImage);
  sobelImage.filter(BLUR,2);
  sobelImage.filter(BLUR,2);
  sobelImage.loadPixels();
  
  precalculateDistances(sobelImage);
  
  dest = createGraphics(img.width,img.height);
  println(dest,width);
  // the last number is the number of colors in the final palette.
  tree.quantize(quantizedImage,22);
  
  setBackgroundColor();
  
  // smash the image to grayscale
  //img.filter(GRAY);

  // find the size of the circle and calculate the points around the edge.
  diameter = ( img.width > img.height ) ? img.height : img.width;
  float radius = (diameter/2)-1;
  
  center=height*(float)upScale/2.0f;

  int i;
  for (i=0; i<numberOfPoints; ++i) {
    float d = PI * 2.0 * i/(float)numberOfPoints;
    px[i] = img.width /2 + cos(d) * radius;
    py[i] = img.height/2 + sin(d) * radius;
  }

  // a lookup table because sqrt is slow.
  for (i=0; i<numberOfPoints; ++i) {
    float dx = px[i] - px[0];
    float dy = py[i] - py[0];
    lengths[i] = sqrt(dx*dx+dy*dy);
  }
  
 // if(tree.heap.size()==0) 
  {
    threads.add(startNewWeavingThread(maroon,"maroon"));
    threads.add(startNewWeavingThread(black,"black"));
    threads.add(startNewWeavingThread(pink,"pink"));
    threads.add(startNewWeavingThread(magenta,"magenta"));
    threads.add(startNewWeavingThread(yellow,"yellow"));
    threads.add(startNewWeavingThread(blue,"blue"));
    threads.add(startNewWeavingThread(white,"white"));
      //  threads.add(startNewWeavingThread(maroon,"maroon"));
      //  threads.add(startNewWeavingThread(brown,"brown"));
      //  threads.add(startNewWeavingThread(olive,"olive"));
      //  threads.add(startNewWeavingThread(teal,"teal"));
       // threads.add(startNewWeavingThread(navy,"navy"));
       // threads.add(startNewWeavingThread(black,"black"));
       // threads.add(startNewWeavingThread(red,"red"));
      //  threads.add(startNewWeavingThread(orange,"orange"));
      //  threads.add(startNewWeavingThread(yellow,"yellow"));
      //  threads.add(startNewWeavingThread(lime,"lime"));
      //  threads.add(startNewWeavingThread(green,"green"));
      //  threads.add(startNewWeavingThread(cyan,"cyan"));
      //  threads.add(startNewWeavingThread(blue,"blue"));
      //  threads.add(startNewWeavingThread(purple,"purple"));
      //  threads.add(startNewWeavingThread(magenta,"magenta"));
      //  threads.add(startNewWeavingThread(grey,"grey"));
      //  threads.add(startNewWeavingThread(pink,"pink"));
       // threads.add(startNewWeavingThread(apricot,"apricot"));
       // threads.add(startNewWeavingThread(beige,"beige"));
      //  threads.add(startNewWeavingThread(mint,"mint"));
      //  threads.add(startNewWeavingThread(lavender,"lavender"));
       // threads.add(startNewWeavingThread(white,"white"));
    //threads.add(startNewWeavingThread(apricot,"apricot"));
  } /*else {
    while(tree.heap.size()>0) {
      OctreeNode n = tree.heap.remove(0);
      color c=color(n.r,n.g,n.b,stringAlpha);
      threads.add(startNewWeavingThread(c,n.r+","+n.g+","+n.b));
    }
  }*/
  image_flag=false;
  println("Input image success");
  }
  
}
void controlEvent(ControlEvent theEvent){
   if (theEvent.isFrom(checkbox)) {
     for (int i=0;i<checkbox.getArrayValue().length;i++) {
        int n = (int)checkbox.getArrayValue()[i];
        if(n==1) {
          //myColorBackground += checkbox.getItem(i).internalValue();
        }
      }
    }
}
void InputImage(){
  i+=1;
  if (i!=1){
    image_flag = true;
    selectInput("Select an image file","inputSelected");
  }

}

void Play(int value){
  t+=1;
  if(t%2==0){
    r.hide();
    cp5.hide();
    play_flag=true;
  }
}

void setBackgroundColor() {
  float r=0,g=0,b=0;
  
  // find average color of image
  float size=img.width*img.height;
  int i;
  for(i=0;i<size;++i) {
    color c=img.pixels[i];
    r+=red(c);
    g+=green(c);
    b+=blue(c);
  }
  r/=size;
  g/=size;
  b/=size;
  
  
  if(tree.heap.size()>0) {
    OctreeNode n = tree.heap.remove(tree.heap.size()-1);
    r=n.r;
    g=n.g;
    b=n.b;
  }
  
  dest.beginDraw();
  dest.background(255,255,255                   );
  dest.endDraw();
}


// setup a new WeavingThread and place it on the best pair of nails.
WeavingThread startNewWeavingThread(color c,String name) {
  WeavingThread wt = new WeavingThread();
  wt.c=c;
  wt.name=name;

  // find best start
  int bestI=0, bestJ=1; 
  float bestScore = Float.MAX_VALUE;
  int i,j;
  for(i=0;i<numberOfPoints;++i) {
    for(j=i+1;j<numberOfPoints;++j) {
      float score = scoreLine(i,j,wt); 
      if(bestScore>score) {
        bestScore = score;
        bestI=i;
        bestJ=j;
      }
    }
  }
  
  drawLine(wt,bestI,bestJ);
  
  return wt;
}

void mouseReleased() {
  paused = paused ? false : true;
}

void keyReleased() {
  if(key=='1') showImage=0;
  if(key=='2') showImage=1;
  if(key=='3') showImage=2;
  if(key=='4') showImage=3;
  
  println(key);
}

void draw() {
  if(play_flag==true){
  startTime=millis();
  ready=true;
  play_flag=false;
  println("Press input Button success");
  }
  if(!ready) 
     {
       image(colorImage,300 ,350);
       return;
     }
  
  // if we aren't done
  if (!finished) {
    if (!paused) {
      dest.loadPixels();
      BestResult[] br = new BestResult[threads.size()];
      
      // draw a few at a time so it looks interactive.
      for(int i=0; i<numberOfLinesToDrawPerFrame; ++i) {
        // find the best thread for each color
        for(int j=0;j<threads.size();++j) {
          br[j]=findBest(threads.get(j));
        }
        // of the threads tested, which is best?  The one with the lowest score.
        float v = br[0].bestValue;
        int best = 0;

        for(int j=1;j<threads.size();++j) {
          if( v > br[j].bestValue ) {
            v = br[j].bestValue;
            best = j;
          }
        }
        /*if(v>0) {
          println("v="+v+" moveover="+moveOver);
          moveOver++;
          if(moveOver==numberOfPoints) {
            // finished!    
            calculationFinished();
          } 
        }
        drawLine(threads.get(best),br[best].bestStart,br[best].bestEnd);
        */
        if(v>0) {
          println("v="+v+" moveover="+moveOver);
          moveOver++;
          if(moveOver==numberOfPoints || totalLinesDrawn>limitlines ||moveOver >10  ) {
            // finished!    
            calculationFinished();
          } else {
            // the best line is actually making the picture WORSE.
            // move all threads one nail CCW and try again. 
            for(WeavingThread wt : threads ) { 
              wt.currentPoint = (wt.currentPoint+1) % numberOfPoints; 
            }
          }
        } else {
          //println("v="+v
          if(totalLinesDrawn>limitlines)
              calculationFinished();
          moveOver=0;
          // draw that best line.
          drawLine(threads.get(best),br[best].bestStart,br[best].bestEnd);
        }
      }
      if (singleStep) paused=true;
    }
  } else {
    // finished!    
    calculationFinished();
     
  }
  
  switch(showImage) {
  case 0: image(dest, 0, 0, width, height); break;
  case 1: image(img , 0, 0, width, height); break;
  case 2: image(quantizedImage, 0, 0, width, height); break;
  case 3: image(sobelImage, 0, 0, width, height); break;
  } 
  drawProgressBar();
}

void drawProgressBar() {
  float percent = (float)totalLinesDrawn / (float)totalLinesToDraw;

  strokeWeight(10);  // thick
  stroke(0,0,255,255);
  line(10, 5, (width-10), 5);
  if(paused) {
    stroke(255,0,0,255);
  } else {
    stroke(0,255,0,255);
  }
  line(10, 5, (width-10)*percent, 5);
}


// stop drawing and ask user where (if) to save CSV.
void calculationFinished() {
  if(finished) return;
  
  finished=true;
  
  long endTime=millis();
  println("Time = "+ (endTime-startTime)+"ms");
  
  /*PGraphics  imgs = createGraphics(dest.width,dest.height);
  for (int x = 0; x < dest.width; ++x) {
     for (int y = 0; y < dest.height; ++y) {
        int i = y*img.width+x;
        color pixel_color = dest.pixels[i];
        imgs.pixels[i] = color(red(pixel_color),green(pixel_color),blue(pixel_color));
        }
        
  }
  //tint(255, 255);  // Display at full opacity
  imgs.beginDraw();
  imgs.endDraw();*/
  selectOutput("Select a destination CSV file","outputSelected");
}

// write the file if requested
void outputSelected(File output) {
  if(output==null) {
    return;
  }
  // write the file
  PrintWriter writer = createWriter(output.getAbsolutePath());
  writer.println("Color, Start, End");
  for(FinishedLine f : finishedLines ) {
    
    writer.println(getThreadName(f.c)+", "
                  +f.start+", "
                  +f.end+", ");
  }
  writer.close();
}


String getThreadName(color c) {
  for( WeavingThread w : threads ) {
    if(w.c == c) {
      return w.name;
    }
  }
  return "??";
}


// a weaving thread starts at wt.currentPoint.  for all other points Pn, look at the line 
// between here and all other points Ln(Pn).  
// The Ln with the lowest score is the best fit.
BestResult findBest(WeavingThread wt) {
  int i, j;
  float bestValue = Float.MAX_VALUE;
  int bestStart = 0;
  int bestEnd = 0;

  // starting from the last line added
  i=wt.currentPoint;

  //for(i=wt.currentPoint-2;i<wt.currentPoint+2;++i)
  // uncomment this line to compare all starting points, not just the current starting point.  O(n*n) slower.
  //for(i=0;i<numberOfPoints;++i)
  {
    // start, made safe in case we're doing the all-nails-to-all-nails test.
    int iSafe = (i+numberOfPoints)%numberOfPoints;
    
    // the range of ending nails cannot include skipNeighbors.
    int end0 = iSafe+1+skipNeighbors;
    int end1 = iSafe+numberOfPoints-skipNeighbors;
    for (j=end0; j<end1; ++j) {
      int nextPoint = j % numberOfPoints;
      if(isDone(iSafe,nextPoint)) {
        continue;
      }
      float score = scoreLine(iSafe,nextPoint,wt);
      if ( bestValue > score ) {
        bestValue = score;
        bestStart = iSafe;
        bestEnd = nextPoint;
      }
    }
  }
  
  return new BestResult( bestStart, bestEnd, bestValue );
}


// commit the new line to the destination image (our results so far)
// also remember the details for later.
void drawLine(WeavingThread wt,int a,int b) {
  //println(totalLinesDrawn+" : "+wt.name+"\t"+bestStart+"\t"+bestEnd+"\t"+maxValue);
  
  drawToDest(a, b, wt.c);
  setDone(a,b);
  totalLinesDrawn++;
  println(totalLinesDrawn);
  // move to the end of the line.
  wt.currentPoint = b;
}


// draw thread on screen.
void drawToDest(int start, int end, color c) {
  dest.beginDraw();
  println(alpha(c));
  dest.stroke(c);
  dest.strokeWeight(lineWeight);
  dest.line((float)px[start], (float)py[start], (float)px[end], (float)py[end]);
  dest.endDraw();
  
  finishedLines.add(new FinishedLine(start,end,c));
}


void setDone(int a,int b) {
  if(b<a) {
    int c=b;
    b=a;
    a=c;
  }
  int index = a*numberOfPoints+b;
  done[index]=1;
}


boolean isDone(int a,int b) {
  if(b<a) {
    int c=b;
    b=a;
    a=c;
  }
  int index = a*numberOfPoints+b;
  return done[index]!=0;
}


/**
 * Measure the change if thread wt were put here.
 * A line begins at point S and goes to point E.  The difference D=E-S.
 * I want to test at all points i of N along the line, or pN = S + (D*i/N).  
 * (i/N will always be 0...1)
 *
 * There is score A, the result so far: the difference between the original 
 * and the latest image.  A perfect match would be zero.  It is never a negative value.
 * There is score B, the result if latest were changed by the new thread.
 * We are looking for the score that improves the drawing the most.
 */
float scoreLine(int startPoint,int endPoint,WeavingThread wt) {
  // S
  float sx=px[startPoint];
  float sy=py[startPoint];
  // D
  float dx = px[endPoint] - sx;
  float dy = py[endPoint] - sy;
  // N
  float N = lengths[(int)abs(endPoint-startPoint)] /upScale;
  

  color cc = wt.c;
  float ccAlpha = (alpha(cc)/255.0);
  //float ccAlpha = (5/255.0);
 // println(ccAlpha);
  
  float errorBefore=0;
  float errorAfter=0;

  int w = img.width;
  for(float i=0; i<N; i++) {
    float iN = i/N; 
    int px = (int)(sx + dx * iN);
    int py = (int)(sy + dy * iN);
    int addr = py*w + px;
    
    // color of original picture
    color original = img.pixels[addr];
    // color of weave so far
    color current = dest.pixels[addr];
    // color of weave if changed by the thread in question.
    color newest = lerpColor(current,cc,ccAlpha);
    
    // how wrong is dest?
    float oldError = scoreColors(original,current);
    // how wrong will dest be with the new thread?
    float newError = scoreColors(original,newest );

    float numerator = 1.0;
    color sobelColor = sobelImage.pixels[addr];//*
    // color sobelColor = img.pixels[addr];
    float sobelx = red(sobelColor)/255.0;
    float sobely = blue(sobelColor)/255.0;
    float sobelz = green(sobelColor);
    float dot = abs(sobelx + sobely);
    numerator = (1.0+dot);//*/
    float cd = pow(sobelz,3);
    
    // make sure we can't have a divide by zero.
    float r = numerator / (0.01+cd);
    //float r = 1.0; 
    
    errorBefore += oldError * r;
    errorAfter  += newError * r;
  }
  
  // if errorAfter is less than errorBefore, result will be <0.
  // if error is identical, number will be 0.
  // if error is worse, result will be >0
  return (errorAfter-errorBefore);//*diameter/N;
}

// the square of the linear distance between two colors in RGB space.
float scoreColors(color c0,color c1) {
  float r = red(  c0)-red(  c1);
  float g = green(c0)-green(c1);
  float b = blue( c0)-blue( c1);
  return (r*r + g*g + b*b);
}
