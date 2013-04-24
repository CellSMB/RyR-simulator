# Written by Evan I. Blumgart 30th Nov. 2010
#Further modified by Cameron Walker, Vijay Rajagopal
# This function simulates 3D spatial point process data within a sampling brick
# according to the observed intensity and covariates. In this case, the point
# process represents Ryanodine Receptors (RyR's) in rat ventricular muscle,
# where the covariate is the locations of Z-disks. Contraints on nearest
# neighbour distances is also enforced. Edge correction is not implemented in
# the algorithm, thus the input data must have a buffer zone.
#
# Inputs: x, y, z - Cartesian coordinates of events after edge correction
#         xl, xu, yl, yu, zl, zu - dimensions of sampling brick
#         n - event count
#         R - data frame containing coordinates of all events inside brick
#         X - data frame containing coordinates of all events
#         W - data frame containing coordinates of all           # non-myofibril voxels
#	    d - distance function

# calculates observed nearest-neighbours
findObsNNDist <- function(R,X) {  ##removed M,xl,xu,yl,yu,zl,zu
obsNNDist <- c()
for (i in 1:length(R$x)) {  
  cat('point',i,"\n")                                    ##was 1 to n, should be 1:length(R$x) ?
  obsNNcur <- 1000
  for (j in 1:length(X$x)) {
    if ((R$x[i] != X$x[j]) | (R$y[i] != X$y[j]) | (R$z[i] != X$z[j])) { # exclude NN of length 0 - CGW: changed && to |
      obsNN <- sqrt((R$x[i]-X$x[j])^2 + (R$y[i]-X$y[j])^2 + (R$z[i]-X$z[j])^2)
      if (obsNN < obsNNcur) {
        obsNNcur <- obsNN
      }
    }
  }
  obsNNDist[i] <- obsNNcur
}
return(obsNNDist)
}

findObsNNDist_CGWold <- function(R,X,l,u) { #Torus edge corrected
  apply(outer(1:dim(R)[1],1:dim(X)[1],function(r,x){
      sqrt( (R[r,1]-X[x,1])^2+
            (R[r,2]-X[x,2])^2+
            (R[r,3]-X[x,3])^2)}),
          1,function(x){min(x[x>0])})
}

findObsNNDist_CGW <- function(R,X,l,u) { #Torus edge corrected
  apply(outer(1:(dim(R)[1]),1:(dim(X)[1]),function(r,x){
      sqrt( (pmin(abs(R[r,1]-X[x,1]),u[1]-l[1]-abs(R[r,1]-X[x,1])))^2+
            (pmin(abs(R[r,2]-X[x,2]),u[2]-l[2]-abs(R[r,2]-X[x,2])))^2+
            (pmin(abs(R[r,3]-X[x,3]),u[3]-l[3]-abs(R[r,3]-X[x,3])))^2)}),
          1,function(x){min(x[x>0])})
}

findWhichObsNNDist_CGW <- function(R,X,l,u) {
  apply(outer(1:dim(R)[1],1:dim(X)[1],function(r,x){
      sqrt( (pmin(abs(R[r,1]-X[x,1]),u[1]-l[1]-abs(R[r,1]-X[x,1])))^2+
            (pmin(abs(R[r,2]-X[x,2]),u[2]-l[2]-abs(R[r,2]-X[x,2])))^2+
            (pmin(abs(R[r,3]-X[x,3]),u[3]-l[3]-abs(R[r,3]-X[x,3])))^2)}),
          1,function(x){which(x==min(x[x>0]))})
}

findDist_CGW <- function(R,X) {
  out=apply(outer(1:dim(R)[1],1:dim(X)[1],function(r,x){sqrt((R[r,1]-X[x,1])^2+(R[r,2]-X[x,2])^2+(R[r,3]-X[x,3])^2)}),
          1,function(x){
         nnD=min(x[x>0]);nnInd=which(x==nnD);c(nnD,nnInd)})
}

findDist <- function(R,X) { #CGW - speed up the simulation by identifying legal points
  outer(1:dim(R)[1],1:dim(X)[1],function(r,x){sqrt((R[r,1]-X[x,1])^2+(R[r,2]-X[x,2])^2+(R[r,3]-X[x,3])^2)})
}

# find nearest neighbour distance for proposal event
findNNDist <- function(xp, yp, zp, simRyRx, simRyRy, simRyRz) {
  NNcur = 1000
  whichNN <- 0
  for (j in 1:length(simRyRx)) {
    NN <- sqrt((xp-simRyRx[j])^2 + (yp-simRyRy[j])^2 + (zp-simRyRz[j])^2)
    if (NN < NNcur) {
      whichNN <- j
      NNcur = NN
    }
  }
  return(c(NNcur,whichNN))
}

# simulateRyR <- function(x,y,z,n,xl,xu,yl,yu,zl,zu,X,M) {

