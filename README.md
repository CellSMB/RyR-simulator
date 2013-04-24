ryr-simulator
=============
An R-statistics package script for simulating anatomically realistic distributions of RyR clusters around mitochondria and the contractile machinery. 

**Applications/Packages required:**

R-statistics package available from www.r-project.org
MATLAB      

**FOLDER INFORMATION**
input-files/: 

master-cell/

 - directory consisting of all the input files necessary for generating statistics on nearest neighborhood distances between RyR clusters and axial and radial distances of RyR clusters from the z-disc. Folder currently contains data extracted from Cell 1 of submitted paper.

target-cell/

 - directory of same input files as those in master-cell but with information from target cell onto which RyR clusters must be simulated. Folder currently contains data extracted from Cell 1 of submitted paper.

output-files/:

target-cell/

 - The RyR cluster patterns simulated on the target cell along with the histograms of the observed ryr cluster nearest-neighborhood distances and the axial and radial distances to the z-discs. Current simulations reconstruct RyR cluster distributions on Cell 1 from the observed data on Cell 1 from submitted paper.

source:

contains all the source files for running in R.

*ryr-simulator.R*: The main program to run the RyR cluster simulator. 
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
NOTE: CHANGE PATH TO LOCAL MACHINE PATH OF THE ryr-simulator/source DIRECTORY ON LINE NUMBER 28
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

*nnd-calculators.R*: A bunch of calculators of nearest-neighborhood distances; currently using CGW version which measures torus distance. 