// Input Parameters -- see the paper for more explanations 
final int   a_0 = 20;
final float gamma = 5;
final float deltaT = .1;
final float damping = 1e-7;
final int   nbRepulsionSteps = 3;
final int   nbJacobiIterations = 10;
      float gravityForce = 10;                  // WARNING: in Processing a positive y value means "downwards"
      float thickRatio = .15;                   // "Thickness ratio" of the water volume [0-1]

// Repulsion
final float repulsionRadius = sqrt(a_0*a_0*2.0/(sqrt(3)*gamma));

// Solid particles on the walls
final int nbSolidParticlesPerCell = (int)(2*(a_0/repulsionRadius));

// Droplet                                  
final int dropNbParticles = 45;//150;
final int dropRadius = 25;//50;

// Floating Ball
Ball myBall = null;
final int ballRadius = 40;

// User interactions -- see the last part of the "draw" function for keyboard usage
//                   -- see the applyPressureAndAdvect function in Particle.pde for mouse usage
int lastFrameKeyPressed = 0;
boolean damBreak  = false;   
boolean vortexMode = false; 
boolean useBall = false;    
float originalThickRatio = thickRatio;
float originalGravityForce = gravityForce;

// Position of a cell in the water volume
final int isEmpty = 0;
final int hasOneEmptyNeighbor = 1;
final int isInside = 2;

int nbSolidParticles, nbFluidParticles;
ArrayList<Particle> particles = new ArrayList<Particle>();
int nbCols, nbRows, nbCells;
Cell[] cells;

// Initialization
void setup() {
  size(640, 640);                              // This defines variables width and height
                                                // Make sure these values are divisible by a_0 !
  nbCols = width / a_0;
  nbRows = height / a_0;
  nbSolidParticles = nbCols*2*nbSolidParticlesPerCell + nbRows*2*nbSolidParticlesPerCell; 
  nbFluidParticles = (int)(nbCols * nbRows * gamma * thickRatio);
  nbCells = nbCols*nbRows;
  cells = new Cell[nbCells];
  int i, j, k, ind;
  ind = 0;

  // Creation of solid particles on the walls
  for (i = 0; i < nbCols; i++) 
    for (k = 0; k < nbSolidParticlesPerCell; k++) {
      particles.add(new Particle(ind));
      particles.get(ind).isWall = true;
      particles.get(ind).curPos.y = 0;
      particles.get(ind++).curPos.x = i*a_0 + k*a_0/(float)nbSolidParticlesPerCell; 
      particles.add(new Particle(ind));
      particles.get(ind).isWall = true;
      particles.get(ind).curPos.y = height-(a_0/100.0);
      particles.get(ind++).curPos.x = i*a_0 + k*a_0/(float)nbSolidParticlesPerCell;
    }    

  for (i = 0; i < nbRows; i++) 
    for (k = 0; k < nbSolidParticlesPerCell; k++) {
      particles.add(new Particle(ind));
      particles.get(ind).isWall = true;
      particles.get(ind).curPos.x = 0;
      particles.get(ind++).curPos.y = i*a_0 + k*a_0/(float)nbSolidParticlesPerCell; 
      particles.add(new Particle(ind));
      particles.get(ind).isWall = true;
      particles.get(ind).curPos.x = width-(a_0/100.0);
      particles.get(ind++).curPos.y = i*a_0 + k*a_0/(float)nbSolidParticlesPerCell;
    }    

  // Fluid particles
  for (i = 0; i < nbFluidParticles; i++) particles.add(new Particle(ind++));

  // Cells
  for (j = 0; j < nbRows; j++) 
    for (i = 0; i < nbCols; i++) cells[(j*nbCols)+i] = new Cell(i, j);

  // Ball
  if (useBall) myBall = new Ball();

  println("Press SPACE to add droplet / 'd': dam break flood / 'r': fluid at rest");
  println("      'v': mixing fluids / 'b': add/remove ball / Use the mouse to push");
}

// Main iteration loop
void draw() {
  background(#FFFFFF);

  //###########################################################################################
  // Local repulsion step
  for (Cell c : cells) c.initCell();
  for (int k = 0; k < nbRepulsionSteps; k++) { 
    for (Particle p : particles) p.assignForRepulsion();
    for (Particle p : particles) p.computeRepulsion();
    for (Cell c : cells) c.computePositionInFluidAndDensity();    
    for (Particle p : particles) p.applyRepulsion();
    for (Cell c : cells) c.initCell();
  }
  for (Particle p : particles) p.assign();

  // SRD collision step
  for (Cell c : cells) c.computeAlphaAndAvgVel();
  for (Particle p : particles) p.applySRDandGravity();

  // Local pressure step
  for (Cell c : cells) c.computeDivergence();    
  for (int k = 0; k < nbJacobiIterations; k++) { 
    for (Cell c : cells) c.computeOneJacobiIteration();
    for (Cell c : cells) c.prevPressure = c.pressure;
  }
  for (Cell c : cells) c.computePressureGradient();
  for (Particle p : particles) p.applyPressureAndAdvect();

  if (myBall != null) myBall.displace();
  //###########################################################################################
  
  // Rendering
  for (int x = 0; x <= width; x += a_0) {
    stroke(0); 
    noFill();
    line(x, 0, x, height);
  }
  for (int y = 0; y <= height; y += a_0) {
    stroke(0); 
    noFill();
    line(0, y, width, y);
  }
  for (Particle p : particles) {
    noStroke();
    fill(p.c);
    ellipse(p.curPos.x, p.curPos.y, 4, 4);
  }
  if (myBall != null) {
    stroke(50, 50, 204);
    noFill();
    ellipse(myBall.pos.x, myBall.pos.y, ballRadius*2, ballRadius*2);
  }

  // Keyboard interaction
  if ((keyPressed) && (frameCount > lastFrameKeyPressed + 40)) {
    lastFrameKeyPressed = frameCount;
    if ((key == ' ') && (! vortexMode)) addDroplet();   // SPACE: add droplet
    else if (key == 'd') {                              // 'd': dam break flood
      damBreak = true; vortexMode = false;
      updateFluidParticles(originalThickRatio, originalGravityForce);
    }
    else if (key == 'r') {                              // 'r': fluid at rest
      damBreak = false; vortexMode = false;
      updateFluidParticles(originalThickRatio, originalGravityForce);
    }
    else if (key == 'v') {                              // 'v': mixing fluids 
      vortexMode = true; damBreak = false; 
      updateFluidParticles(1.0, 0);
    }
    else if ((key == 'b') && (! vortexMode)) {          // 'b': add/remove ball
      if (myBall == null) myBall = new Ball();
      else {
        myBall.removeSolidParticles();
        myBall = null;
      }
    }
  }

}

void addDroplet() {
  int maxI = particles.size()+dropNbParticles;
  float cx = random(dropRadius, width-dropRadius);
  for (int i = particles.size(); i < maxI; i++) {
    Particle p = new Particle(i);
    float angle = random(TWO_PI);
    float radius = random(dropRadius);
    p.curPos.x = cx + radius*cos(angle);
    p.curPos.y = height/4 + radius*sin(angle);
    p.velocity.x = 0;
    p.velocity.y = height/8;
    particles.add(p);
    nbFluidParticles++;
  }
}

void updateFluidParticles(float newThickRatio, float newGravityForce) {
  if (myBall != null) {
    myBall.removeSolidParticles();
    myBall = null;
  }
  for (int i = 0; i < nbFluidParticles; i++)
    particles.remove(nbSolidParticles);
  // Create new fluid particles
  thickRatio = newThickRatio;
  gravityForce = newGravityForce;
  nbFluidParticles = (int)(nbCols * nbRows * gamma * thickRatio);
  int ind = nbSolidParticles;
  for (int i = 0; i < nbFluidParticles; i++) { 
    particles.add(new Particle(ind++));
  } 
}
