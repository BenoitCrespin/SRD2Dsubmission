class Ball {
  PVector pos, velocity;
  float radius;
  int indexFirstP = 0;              // Index of the first solid particle in the particles list
  int nbParticles = 0;
  float myGravity = gravityForce;

  Ball() {
    pos = new PVector(width/2, height-height/3);
    radius = ballRadius;
    velocity = new PVector(0, 0);
    coverWithSolidParticles();
  }

  void removeSolidParticles() {
   while (nbParticles > 0) {
      particles.remove(indexFirstP);
      nbParticles--;
    }
  }

  void coverWithSolidParticles() {
    removeSolidParticles();
    indexFirstP = particles.size();
    nbParticles = 0;
    int cpt = particles.size();    
    float aDelta = (radius*TWO_PI/pow(2, 11));
    for (float angle = 0; angle < TWO_PI; angle += aDelta) {
      Particle p = new Particle(cpt++);
      p.isBall = true;
      PVector nPos = PVector.fromAngle(angle);
      nPos.mult(radius);
      nPos.add(pos);
      p.curPos = nPos.copy();
      p.velocity = velocity.copy();
      particles.add(p);
      nbParticles++;
    }
  }

  void repel(Particle p) {
    if ((p.isBall) || (p.isWall)) return;
    PVector diff = p.curPos.copy();
    diff.sub(pos);
    if (diff.mag() < radius) {
      diff.normalize();
      diff.mult(radius*1.1);
      diff.add(pos);
      p.curPos = diff.copy();
    }
  }

  void displace() {
    // Compute velocity of the ball based on its solid particles' velocities
    for (int k = indexFirstP; k < (indexFirstP + nbParticles); k++) {
      Particle solidP = particles.get(k);
      if (solidP.isTouched) {
        PVector dirP = solidP.velocity.copy() ;
        dirP.sub(velocity);
        dirP.mult(deltaT);
        velocity.add(dirP);
        if (solidP.curPos.y > this.pos.y)
          myGravity--;                            // Buoyancy effect
      }
    }
    // Update velocity and re-initialize gravity for the next step
    velocity.y += (myGravity*deltaT*deltaT);
    myGravity = gravityForce;
    // Compute new position
    velocity.mult(0.999);
    PVector nPos = velocity.copy();
    nPos.mult(deltaT);
    nPos.add(pos);
    if (nPos.x < radius) {nPos.x = radius; velocity.x *= 0;}
    if (nPos.x > width-radius) {nPos.x = width-radius; velocity.x *= 0;}
    if (nPos.y < 0) {nPos.y = 0; velocity.y *= 0;}
    if (nPos.y > height-radius) {nPos.y = height-radius; velocity.y = 0;}
    pos = nPos.copy();
    // Recompute solid particles
    coverWithSolidParticles();
  }
}
