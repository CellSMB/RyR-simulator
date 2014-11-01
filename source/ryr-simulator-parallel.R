# Modified/corrected/commented by Vijay Rajagopal
#                             - added split in radial versus axial distance of RyR cluster to Z-disc
#                             - added termination criteria
#                             - corrected and validated code
# Corrected by Cameron Walker 
#                            - sped up (looping removed where possible)
#                            - torus metric edge correction implemented
#                            - quantiles added to Energy 
#                            - iterative updating of metrics implemented
#implemented by Gregory Bass
#                            - parallelising simulator
#                            - created settings file

# Original ideas developed in collaboration with Evan Blumgart 02/02/11 (refer to Masters thesis from University of Auckland, 2011)


# This code implements the Reconstruction Algorithm using the mean and quantiles of the axial and radial distances of RyR clusters from the z-discs and the nearest neighbour distances of the RyR clusters as modelling metrics.
# FUTURE FEATURE: Can also using distance function and nearest neighbour distance variances as metrics

#The code first reads in the RyR and z-disk data from an experiment and calculates the nearest neighbour and distance functions. 
#This is then set up as the target statistic that the reconstruction algorithm must recreate on a new z-disk dataset from a different experiement 
#with no RyRs on it. It basically assumes that the RyR characteristics of the first experimental data is typical of the distribution in these cells. This assumption was validated in recent paper (submitted DATE)

#################
#options(warn=2) - uncomment this for debugging purposes
##################

###################################################
#CHANGE THIS TO POINT TO WHERE YOUR local machine ryr-simulator github source directory is.
###################################################

t1 <- proc.time()  # tic

setwd("/Users/vrajagopal/RyR-Simulator/source")

source("settings.R")
path=getwd()
source(paste(path,"/nnd-calculators.R",sep="")) #additional functions for calculating nearest-neighborhood distances.

# Additional paths for input and output files. Master is the cell from which statistics are extracted. Target is the cell onto which RyR clusters will be simulated
#path2="/../input-files/master-cell/"
#path3="/../output-files/target-cell/"
#path4="/../input-files/target-cell/"

# read in the coordinates of all the observed RyR's inside sampling box of the experimental data (master cell) - stored in a file X.txt (read in micron and pixel versions)
X=read.csv(paste(path2,"X_micron.txt",sep=""),header=T)
X_pix=read.csv(paste(path2,"X_pixel.txt",sep=""),header=T)

# read in whole RyR data cloud of the experimental data stored in a file allX.txt
allX=read.csv(paste(path2,"allX_micron.txt",sep=""),header=T)
allX_pix=read.csv(paste(path2,"allX_pixel.txt",sep=""),header=T)

# read in non-myofibril voxels of the experimental data stored in a file W.txt
W=read.csv(paste(path2,"W_micron.txt",sep=""),header=T) 
w=read.csv(paste(path2,"W_pixel.txt",sep=""),header=T)

# read in distance function of voxels in W for the experimental data. stored in a file d.txt
drad=read.csv(paste(path2,"d_radial_micron.txt",sep=""),header=T) #Radial distance from given voxel (W) to z-disk
daxi=read.csv(paste(path2,"d_axial_micron.txt",sep=""),header=T) #Axial distance from given voxel (W) to z-disk

# define box boundaries of the experimental data that we are using to calculate nearest neighbour and distance function statistics.
#note that directions x1, y1 and z1 have different meanings in different image processing/stats processing codes. So, when reading a file into this code
#be aware what coordinate system was used in the code that generated that image and the coordinate system used in this code.
l=apply(W,2,min)
u=apply(W,2,max)
vol_obsBox <- prod(u-l)

#Would like to use allX and X, but do not have any of the distance information
# for allX, so will treat X as allX and take a smaller block within X as X
u_block = 0.9*(u-(u-l)/2)+(u-l)/2
l_block = 0.9*(l-(u-l)/2)+(u-l)/2
block = apply( X,1,function(z){all((l_block<=z)&(z<=u_block))} )
X_block = X[block,]
allX = X
allX_pix=X_pix
X=X_block

# read in voxel resolution
voxres = read.csv(paste(path2,"voxel_resolution_micron.txt",sep=''),header=T) 

#resx = 0.035
#resy = 0.035
#resz = 0.035
#res <- c(resx,resy,resz)
res <- c(voxres[,1],voxres[,2],voxres[,3])

#set up look up table of axial and radial distances from each available voxel for RyR cluster simulation to z-disc
Drad = array(dim=c(max(w[,1]),max(w[,2]),max(w[,3]))) 
Drad[as.matrix(w)]<-drad$d 
Daxi = array(dim=c(max(w[,1]),max(w[,2]),max(w[,3]))) 
Daxi[as.matrix(w)]<-daxi$d 

#number of measures to compare
numMeasures = 9
#number of simulation patterns to generate.
#numPatterns = 119 set in settings

# compute the observed measures for distance (radial, axial and nearest-neighborhood)
obsdrad <- Drad[as.matrix(allX_pix)]
oDistRadMeasure=numeric(numMeasures)
oDistRadMeasure[1] <- mean(obsdrad)
oDistRadMeasure[2] <- sd(obsdrad) 
oDistRadMeasure[3:9] <- quantile(obsdrad,seq(0.125,0.875,length=7))

#axial distances
obsdaxi <- Daxi[as.matrix(allX_pix)]
oDistAxiMeasure=numeric(numMeasures)
oDistAxiMeasure[1] <- mean(obsdaxi)
oDistAxiMeasure[2] <- sd(obsdaxi) 
oDistAxiMeasure[3:9] <- quantile(obsdaxi,seq(0.125,0.875,length=7))

####replaced X with allX - July 22nd 2012
####introduced allX_pix instead of using res - Oct 23 2012
# compute mean of observed measures for nearest neigbour distance
#obsNNd = findObsNNDist_CGW(X,allX,l,u) # correct for this data - can't simulate all X as W is too small
#nearest neighborhood distances.
obsNNd = findObsNNDist_CGW(allX,allX,l,u)
oNNdMeasure=numeric(numMeasures)
oNNdMeasure[1] <- mean(obsNNd)
oNNdMeasure[2] <- sd(obsNNd) 
oNNdMeasure[3:9] <- quantile(obsNNd,seq(0.125,0.875,length=7))

#set up histogram parameters
filename="master_cell"
main = "Master Cell"
#breaks in distance for each distance type
nndbreaks = c(0,0.2,0.4,0.6,0.8,1.0,1.2,1.4,1.8)  # this was missing 1.0
radbreaks = c(0,0.2,0.4,0.6,0.8,1.0)      # this was missing 1.0
axibreaks = c(-1.0,-0.8,-0.6,-0.4,-0.2,0.0,0.2,0.4,0.8,1.0)

# Start PNG device driver to save output to figure.png
png(filename=paste(path3,filename,"_obsdrad.png",sep=""), height=295, width=300, 
 bg="white")

 hist(obsdrad,breaks=radbreaks,xlab="Radial Distance of RyR cluster from Z-disc",main=main)
 dev.off()
png(filename=paste(path3,filename,"_obsdaxi.png",sep=""), height=295, width=300, 
 bg="white")

 hist(obsdaxi,breaks=axibreaks,xlab="Axial Distance of RyR cluster from Z-disc",main=main)
 dev.off()
png(filename=paste(path3,filename,"_obsnnd.png",sep=""), height=295, width=300, 
 bg="white")

 hist(obsNNd,breaks=nndbreaks,xlab="Nearest Neighbour Distances for RyR clusters",main=main)
 dev.off()

oldVol_obsBox = vol_obsBox

#####introduce intensity factor - October 11 2012
 factor = 1 #no change of intensity
# factor = 0.7 #70% intensity

###FOLOWING USED IF CHANGING CELL - commented out here
##read in info for vijay's cell
##w = read.table(paste(path3,"Cell10_available_lowres_myo_mito_stack_correct_2012.txt",sep=""),header=T)
W=read.csv(paste(path4,"W_micron.txt",sep=""),header=T) 
w = read.csv(paste(path4,"W_pixel.txt",sep=""),header=T)
#W = (w - 1)*res
##d = read.table(paste(path3,"Cell10_dFunc_avs_lowres_myo_mito_stack_correct_2012.txt",sep=""),header=T)
drad = read.csv(paste(path4,"d_radial_micron.txt",sep=""),header=T)
Drad = array(dim=c(max(w[,1]),max(w[,2]),max(w[,3]))) 
#D = array(dim=u/res+1)
Drad[as.matrix(w)]<-abs(drad$d)
#
daxi = read.csv(paste(path4,"d_axial_micron.txt",sep=""),header=T)
Daxi = array(dim=c(max(w[,1]),max(w[,2]),max(w[,3]))) 
#D = array(dim=u/res+1)
Daxi[as.matrix(w)]<-abs(daxi$d)
#

l=apply(W,2,min)
u=apply(W,2,max)
vol_obsBox <- prod(u-l)
u_block = 0.9*(u-(u-l)/2)+(u-l)/2
l_block = 0.9*(l-(u-l)/2)+(u-l)/2

#u_block = 0.9*(u-l)
#l_block = 0.1*(u-l)

######################################
############ Cluster code ############
######################################

library(foreach)
library(doSNOW)
# assigning threads to separate cores
#numCores = parallel:::detectCores()-1  now set in settings.R
cl <- makeCluster(numCores, type="SOCK")
registerDoSNOW(cl)

######################################
######################################
######################################

# Read in the number of rows from the sampling box data
# This is the number of points that the algorithm will try to simulate on the new cell geometry
N= 123 #floor((length(allX$x)/oldVol_obsBox)*vol_obsBox*factor)
#X_target=read.csv(paste(path4,"X_micron.txt",sep=""),header=T)
#N = nrow(X_target)

sim_convgdE = numeric(numPatterns)
zdisc_indxs <- which(daxi$d==0.0,arr.ind=FALSE)
#for (j in 1:numPatterns) {   # used for single node processing
sim_convgdE<-foreach (j = 1:numPatterns) %dopar% {   # used for parallel processing

        # define initial simulated point pattern and data structures
        simX=matrix(0,nrow=N,ncol=3) 
        #just wanting to restrict to picking pixels at z-disc to reduce computational cost. Easy to pick for tomo_schnieder because z-disc is strict plane.
        #below two commented lines used in the more general case
        #ptsIndex=sample(1:length(W$x),N)
        #simX=as.matrix(W[ptsIndex,])
        zdiscsample = sample(1:length(zdisc_indxs),N)
        ptsIndex = zdisc_indxs[zdiscsample]
        simX = as.matrix(W[ptsIndex,])
        avail=(1:length(W$x))[-ptsIndex]

        simdrad=Drad[as.matrix(w[ptsIndex,])]
        simDistRadMeasure=numeric(numMeasures)
        simDistRadMeasure[1] <- mean(simdrad)
        simDistRadMeasure[2] <- sd(simdrad) 
        simDistRadMeasure[3:9] <- quantile(simdrad,seq(0.125,0.875,length=7))

        simdaxi=Daxi[as.matrix(w[ptsIndex,])]
        simDistAxiMeasure=numeric(numMeasures)
        simDistAxiMeasure[1] <- mean(simdaxi)
        simDistAxiMeasure[2] <- sd(simdaxi) 
        simDistAxiMeasure[3:9] <- quantile(simdaxi,seq(0.125,0.875,length=7))
        
        simNNd = findObsNNDist_CGW(simX,simX,l,u)
        indSimNNd= findWhichObsNNDist_CGW(simX,simX,l,u)
        simNNdMeasure=numeric(numMeasures)
        simNNdMeasure[1] <- mean(simNNd)
        simNNdMeasure[2] <- sd(simNNd) 
        simNNdMeasure[3:9] <- quantile(simNNd,seq(0.125,0.875,length=7))

        #E <- sum((c(oDistRadMeasure[1:numMeasures],oDistAxiMeasure[1:numMeasures],oNNdMeasure[1:numMeasures])-#c(simDistRadMeasure[1:numMeasures],simDistAxiMeasure[1:numMeasures],simNNdMeasure[1:numMeasures]))^2)
        #testing without radial distance measure matching.
        E <- sum((c(oDistAxiMeasure[1:numMeasures],oNNdMeasure[1:numMeasures])-c(simDistAxiMeasure[1:numMeasures],simNNdMeasure[1:numMeasures]))^2)

    propE<-E;
    cat(propE)
        propSimDistRadMeasure=numeric(numMeasures)
        propSimDistAxiMeasure=numeric(numMeasures)
        propSimNNdMeasure=numeric(numMeasures)
        i=0;
        #etol=0.0005 set up in settings file now
        #numIter=500000 set up in settings file now
        while((i<=numIter)&&(propE>etol) ) {
#        while((propE>0.00005) ) {
                  i=i+1;
              if (i%%100 == 0) {
                 cat(i,E,"\n")
              }
              draw1=sample(1:length(avail),1) #draw from sample of available point indices
              draw2=sample(1:length(ptsIndex),1) #draw from index of ryr points currently estimated
              propSimX = simX  #set up proposed sim array strucure
              propIndSimNNd = indSimNNd #indices of nearest neighbors
              propSimX[draw2,]= as.matrix(W[avail[draw1],]) #put in coordinates of randomly chosen new point into proposed sim
              propSimNNd = simNNd 
              #which points had removed point as nearest
              gone=which(sapply(indSimNNd,function(z){match(draw2,z)})>0)
              #find distance from each remaining point to new point
              ndt = findObsNNDist_CGW(as.matrix(propSimX[-draw2,]),t(as.matrix(propSimX[draw2,])),l,u) #find nearest neighbor distances between prop sim x's points to new point draw2
              #if new point is nearer than nearest, update
              propSimNNd[-draw2] = apply(cbind(propSimNNd[-draw2],ndt),1,min)
              propIndSimNNd[-draw2][which(propSimNNd[-draw2]==ndt)]=draw2
              #store distance of nearest point to new point
              propSimNNd[draw2] = min(ndt)
              propIndSimNNd[draw2] = which.min(ndt)
              #recalculate nearest point for any pts which had removed point as nearest
              if (length(gone)>0) {
                 for (k in 1:length(gone)) {
                         #cat("test1",propSimNNd[gone[k]],"\n")
                    propSimNNd[gone[k]] = findObsNNDist_CGW(t(as.matrix(propSimX[gone[k],])),as.matrix(propSimX[-gone[k],]),l,u)
                    #cat("test2",propSimNNd[gone[k]],"\n")
                    propIndSimNNd[gone[k]] = findWhichObsNNDist_CGW(t(as.matrix(propSimX[gone[k],])),as.matrix(propSimX[-gone[k],]),l,u)
                    #cat("test3",propIndSimNNd[gone[k]],"\n")
                 }
              }
              propSimdrad = simdrad
            propSimdrad[draw2] = Drad[as.matrix(w[avail[draw1],])]
                propSimDistRadMeasure[1] <- mean(propSimdrad)
                propSimDistRadMeasure[2] <- sd(propSimdrad) 
                propSimDistRadMeasure[3:9] <- quantile(propSimdrad,seq(0.125,0.875,length=7))

              propSimdaxi = simdaxi
            propSimdaxi[draw2] = Daxi[as.matrix(w[avail[draw1],])]
                propSimDistAxiMeasure[1] <- mean(propSimdaxi)
                propSimDistAxiMeasure[2] <- sd(propSimdaxi) 
                propSimDistAxiMeasure[3:9] <- quantile(propSimdaxi,seq(0.125,0.875,length=7))

                propSimNNdMeasure[1] <- mean(propSimNNd)
                propSimNNdMeasure[2] <- sd(propSimNNd) 
                propSimNNdMeasure[3:9] <- quantile(propSimNNd,seq(0.125,0.875,length=7))

                #propE = sum((c(oDistRadMeasure[1:numMeasures],oDistAxiMeasure[1:numMeasures],oNNdMeasure[1:numMeasures])-c(propSimDistRadMeasure[1:numMeasures],propSimDistAxiMeasure[1:numMeasures],propSimNNdMeasure[1:numMeasures]))^2)
                propE = sum((c(oDistAxiMeasure[1:numMeasures],oNNdMeasure[1:numMeasures])-c(propSimDistAxiMeasure[1:numMeasures],propSimNNdMeasure[1:numMeasures]))^2)
                if (propE < E) { # no probability of non-acceptance
                    cat(propE,"\n")
                        E <- propE  
                        simDistRadMeasure <- propSimDistRadMeasure # this is the new accepted simulated distance function mean
                        simDistAxiMeasure <- propSimDistAxiMeasure # this is the new accepted simulated distance function mean
                        simNNdMeasure <- propSimNNdMeasure # this is the new accepted simulated mean distances mean
                        simX <- propSimX # this is the new accepted simulated point pattern
                        temp = ptsIndex[draw2]
                    ptsIndex[draw2] = avail[draw1]
                    avail[draw1] = temp
                    simdrad = propSimdrad
                    simdaxi = propSimdaxi
                    simNNd = propSimNNd
                        indSimNNd = propIndSimNNd
                }
        }
        if(1){
                
                write(t(simX),file=paste(path3,"simPP",j,".txt",sep=""),ncolumns=3,sep='\t')
                write(t(ptsIndex),file=paste(path3,"simPP",j,"_pixel.txt",sep=""),ncolumns=1,sep='\t')
                return(E)
        }
        else j=j-1
}
#t2 <- proc.time()
#print(t2-t1)
#write out the list of final E values for the each of the converged patterns
write.table(sim_convgdE,file=paste(path3,"sim_convgdE",".txt",sep=""),sep='\t',row.names=FALSE,col.names=FALSE)
for (j in 1:numPatterns) {
   P=read.table(paste(path3,"simPP",j,".txt",sep=""),header=F)
   block = apply( P,1,function(z){all((l_block<=z)&(z<=u_block))} )
   P_block = P[block,]
   write(t(P_block),file=paste(path3,"simPP_block",j,".txt",sep=""),ncolumns=3,sep='\t')
}

stopCluster(cl)  # stop cluster code, return resource allocation control to PC

t2 <- proc.time()    # toc

#write out elapsed time and number of cores used
cat(c({t2-t1}[3],"seconds","\n"),file=paste(path3,"elapsed_time",".txt"),sep=' ')  # write elapsed time to file
cat(c(numCores, "cores"), file=paste(path3,"elapsed_time",".txt"),sep=' ',append=TRUE)  # write number of cores to file
