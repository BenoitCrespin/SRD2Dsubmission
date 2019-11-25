class Cell {
  PVector pos, avgVelocity;
  int nbParticlesInCell;
  int i, j;              // Coordinates in the grid
  ArrayList<Particle> listMovingParticles = new ArrayList<Particle>();
  ArrayList<Particle> listWallParticles = new ArrayList<Particle>();
  float divergence, pressure, prevPressure;
  PVector pressureGradient = new PVector(0, 0);
  float densityRatio = 1.0;
  int positionInFluid;
  float alphaCell = 0;
    
  void initCell() {
    listMovingParticles.clear();
  }

  Cell(int i, int j) {
    this.i = i; 
    this.j = j;
    pos = new PVector(i*a_0 + a_0/2, j*a_0 + a_0/2);
    initCell();
  }
  
  // Compute position in fluid and density ratio
  void computePositionInFluidAndDensity () {
    positionInFluid = isInside;
    densityRatio = listMovingParticles.size();
    float nbNonEmpty = (float)gamma;
    if (listMovingParticles.size() == 0) positionInFluid = isEmpty;
    else
      for (int ipos = -1; ipos <= 1; ipos++)
        for (int jpos = -1; jpos <= 1; jpos++) {
          if ( (this.i+ipos < 0) || (this.i+ipos >= nbCols) || (this.j+jpos < 0) || (this.j+jpos >= nbRows)) continue;
          if ( (ipos == 0) && (jpos == 0) ) continue;
          if ( (ipos != 0) && (jpos != 0) ) continue;
          Cell cj = cells[this.i+ipos+(this.j+jpos)*nbCols];
          if (cj.listMovingParticles.size() == 0) positionInFluid = hasOneEmptyNeighbor;
          densityRatio += cj.listMovingParticles.size();
          nbNonEmpty += (float)gamma;
        }
    densityRatio /= nbNonEmpty;    
  }
  
  void computeAlphaAndAvgVel () {

    avgVelocity = new PVector(0, 0);
    nbParticlesInCell = listMovingParticles.size();
    for (Particle p : listMovingParticles) avgVelocity.add(p.velocity);    
    if (nbParticlesInCell > 0) avgVelocity.div(nbParticlesInCell);

    computePositionInFluidAndDensity ();
    
    alphaCell = ((int)random(2) == 1) ? -alpha : alpha;
  }

  void computeDivergence() {
        
    divergence = 0.0;
    if (this.i+1 < nbCols) divergence += cells[this.i+1+this.j*nbCols].avgVelocity.x;
    if (this.i-1 >= 0) divergence -= cells[this.i-1+this.j*nbCols].avgVelocity.x;
    if (this.j+1 < nbRows) divergence += cells[this.i+(this.j+1)*nbCols].avgVelocity.y;
    if (this.j-1 >= 0) divergence -= cells[this.i+(this.j-1)*nbCols].avgVelocity.y;

    divergence *= ((-2.0 * a_0 * densityRatio) / deltaT);
    prevPressure = pressure = divergence*0.25;
  }    

  void computeOneJacobiIteration() {
    pressure = divergence;
    
    if (positionInFluid != isInside) 
    { 
      pressure = 0.0;
      return;
    }
    
    if (this.i+2 < nbCols)  pressure += cells[this.i+2+this.j*nbCols].prevPressure;
    else                    pressure += cells[(nbCols-1)+this.j*nbCols].prevPressure;
    if (this.i-2 >= 0)      pressure += cells[this.i-2+this.j*nbCols].prevPressure;
    else                    pressure += cells[0+this.j*nbCols].prevPressure;
    if (this.j+2 < nbRows)  pressure += cells[this.i+(this.j+2)*nbCols].prevPressure;
    else                     pressure += cells[this.i+(nbRows-1)*nbCols].prevPressure;
    if (this.j-2 >= 0)      pressure += cells[this.i+(this.j-2)*nbCols].prevPressure;
    else                    pressure += cells[this.i+0*nbCols].prevPressure;

    pressure *= 0.25;
}    

  void computePressureGradient() {
    float dpx = 0, dpy = 0;
    if (this.i+1 < nbCols)  dpx = cells[this.i+1+this.j*nbCols].pressure;
    else                    dpx = cells[(nbCols-1)+this.j*nbCols].pressure;
    if (this.i-1 >= 0)      dpx -= cells[this.i-1+this.j*nbCols].pressure;
    else                    dpx -= cells[0+this.j*nbCols].pressure;
    if (this.j+1 < nbRows)  dpy = cells[this.i+(this.j+1)*nbCols].pressure;
    else                     dpy = cells[this.i+(nbRows-1)*nbCols].pressure;
    if (this.j-1 >= 0)      dpy -= cells[this.i+(this.j-1)*nbCols].pressure;
    else                    dpy -= cells[this.i+0*nbCols].pressure;
   
    pressureGradient = new PVector(dpx, dpy);
    pressureGradient.mult(deltaT/(2*a_0*densityRatio));
  }    
}
