class Particle {
  PVector curPos, velocity;
  PVector nextPos;             // used for repulsion
  //int cellIndex;
  Cell myCell;
  color c;
  int index;                   // Index in the particles list
  boolean isWall = false;      // 'true' for solid particles on the walls
  boolean isBall = false;      // 'true' for solid particles on the ball
  boolean isTouched = false;   // 'true' for solid particles on the ball touching fluid particles

  ArrayList<Particle> neighbours = new ArrayList<Particle>();

  Particle(int index) {
    this.index = index;
    if (damBreak)
      curPos = new PVector(random(width)*thickRatio, random(height));
    else 
    curPos = new PVector(random(width), random(height*(1-thickRatio), height));
    velocity = new PVector(0, 0);
    velocity.mult(random(a_0));
    c = color(random(0, 250), random(0, 250), random(0, 250));
    if (vortexMode) {
      if (curPos.y > height/2) c = color(10, 10, 200);
      else c = color(10, 200, 10);
    } else c = color(10, 10, 200);
    isWall = false;
  }

  void associateToCell(PVector pos) {
    int cellIndex = ((int)(pos.y/a_0))*nbCols + ((int)(pos.x/a_0));     
    if ((cellIndex<0) || (cellIndex>=nbCols*nbRows)) {
      println("Index error for: ", pos);
      cellIndex = 0;
    }
    myCell = cells[cellIndex];
    myCell.listMovingParticles.add(this);
  }

  void assign() {
    if (! isWall) associateToCell(curPos);
  }

  void assignForRepulsion() {
    associateToCell(curPos);
  }

  void applyBoundaryConditions() {
    if (curPos.x < 0) {
      curPos.x = 0; 
      if (velocity.x < 0) velocity.x *= -.1;
    }
    if (curPos.x >= width) {
      curPos.x = width-(a_0/100.0); 
      if (velocity.x > 0) velocity.x *= -.1;
    }
    if (curPos.y < 0) {
      curPos.y = 0; 
      if (velocity.y < 0) velocity.y *= -.1;
    }
    if (curPos.y >= height) {
      curPos.y = height-(a_0/100.0); 
      if (velocity.x > 0) velocity.y *= -.1;
    }
  }

  void computeRepulsion() {
    if (isWall) return;

    neighbours.clear();
    for (int ipos = -1; ipos <= 1; ipos++)
      for (int jpos = -1; jpos <= 1; jpos++) {
        if ( (myCell.i+ipos < 0) || (myCell.i+ipos >= nbCols) || 
          (myCell.j+jpos < 0) || (myCell.j+jpos >= nbRows)) continue;
        Cell cj = cells[myCell.i+ipos+(myCell.j+jpos)*nbCols];
        for (Particle p : cj.listMovingParticles) {
          if ((this.isBall) && (p.isBall)) continue;
          if ((p != this) && (curPos.dist(p.curPos) <= a_0))
            neighbours.add(p);
        }
      }

    nextPos = new PVector(0, 0);
    isTouched = false;
    for (Particle p : neighbours) {
      if ((p != this) && (curPos.dist(p.curPos) <= repulsionRadius)) {
        isTouched = true;
        PVector diff = curPos.copy();
        diff.sub(p.curPos);
        float repFactor = diff.mag()/repulsionRadius;
        repFactor = (1 - repFactor); 
        diff.normalize();
        diff.mult(0.5*repFactor*repulsionRadius);
        nextPos.add(diff);
      }
    }
  }

  void applyRepulsion() {
    if (isWall) return;
    if (myBall != null) myBall.repel(this);

    float density = myCell.densityRatio;
    if (myCell.positionInFluid == isInside) density = 1; 
    nextPos.mult(density);
    if (! isBall) curPos.add(nextPos);
    nextPos.mult(deltaT); 
    velocity.add(nextPos);
    applyBoundaryConditions();
  }

  void applySRDandGravity() {
    if ((isWall)||(isBall)) return;
    
    PVector oldVel = velocity.copy();
    velocity = myCell.avgVelocity.copy();
    oldVel.sub(myCell.avgVelocity);
    float alpha = myCell.alphaCell;
    oldVel.rotate(alpha);      
    velocity.add(oldVel);
    velocity.y += gravityForce*deltaT*deltaT;
  }


  void applyPressureAndAdvect() {

    if ((isWall)||(isBall)) return;

    PVector dirP = velocity.copy();
    dirP.sub(myCell.pressureGradient);
    float interp = myCell.densityRatio;
    if (interp > 1) interp = 1;
    velocity.lerp(dirP, interp); 

    // Mouse control
    if (mousePressed == true) {
      PVector m = new PVector(mouseX, mouseY);
      if (curPos.dist(m) < 100)
        velocity.add(PVector.mult(PVector.sub(m, new PVector(pmouseX, pmouseY)), 
          (1 - (curPos.dist(m)/(100.0)))));
    }

    // Damping
    velocity.mult(1 - damping);

    // Displace
    curPos.add(velocity.x*deltaT, velocity.y*deltaT);
    applyBoundaryConditions();
  }
}
