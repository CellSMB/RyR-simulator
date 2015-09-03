RyR-simulator
=============
An R-statistics package script for simulating anatomically realistic distributions of RyR clusters around mitochondria and the contractile machinery. Published in PLoS Computational Biology: http://journals.plos.org/ploscompbiol/article?id=10.1371/journal.pcbi.1004417. 

Visitors interested in using the finite element geometric model (and associated FE reaction-diffusion simulation codes) can obtain all the codes and mesh inputs at https://github.com/vraj004/cardiac_ecc 

**required Applications/Packages**
----------------------------------

R - statistics package available from <http://www.r-project.org>

MATLAB - optional: only used for point pattern visualization     

**FOLDER INFORMATION**
----------------------

input-files/: 

master-cell/

 - directory consisting of all the input files necessary for generating statistics on nearest neighborhood distances between RyR clusters and axial and radial distances of RyR clusters from the z-disc. Folder currently contains data extracted from Cell 1 of submitted paper.

target-cell/

 - directory of same input files as those in master-cell but with information from target cell onto which RyR clusters must be simulated. Folder currently contains data extracted from Cell 1 of submitted paper.

target-tomo-cell/
 - directory of input files of an electron tomogram derived image stack of myofibrils and mitochondria for RyR cluster simulation.

output-files/:

target-cell/

 - The RyR cluster patterns simulated on the target cell along with the histograms of the observed ryr cluster nearest-neighborhood distances and the axial and radial distances to the z-discs. Current simulations reconstruct RyR cluster distributions on Cell 1 from the observed data on Cell 1 from submitted paper.

target-tomo-cell/

 - directory of output files of RyR cluster distributions on a tomogram-derived template of myofibrils and mitochondria.
  
source/:

contains all the source files for running in R.

*ryr-simulator.R*: The main program to run the RyR cluster simulator. 

*ryr-simulator-parallel.R*: The main program to run the RyR cluster simulator with parallel processing. 

*nnd-calculators.R*: A bunch of calculators of nearest-neighborhood distances; currently using CGW version which measures torus distance. 

**EXPERIMENTAL DATA**
---------------------
The electron microscopy data and confocal microscopy data used for this study have been shared online at https://dx.doi.org/10.4225/49/55B622EBE2D4C

RUNNING ONE OF THE SCRIPTS
--------------------------

The main program is the script ryr-simulator.R . To run the script we recommend using the `source()` command at the R prompt:

    source('/path-to-distribution/RyR-simulator/source/ryr-simulator.R', chdir = TRUE)

*NOTE*:  

1. replace `/path-to-distribution/RyR-simulator` with the proper path to the top level directory of the RyR-simulator distribution
2. *IMPORTANT*: use the `chdir = TRUE` option of the source command - otherwise it will not work!

This procedure has been tested on OS X with R 2.15.0 GUI 1.51 (Leopard build 64-bit (6148)) and R 3.0.1 "Good Sport" which is current as of this writing. You can obtain R for OS X at <http://cran.r-project.org/bin/macosx/>. Again, on OS X you can just drag ryr-simulator.R from the Finder into the command line window of the R app and it will automagically generate the proper `source()` command at the prompt.
 
