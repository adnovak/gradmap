# gradmap
gravity gradient computing tool
Developed for GKU under open license in MATLAB R2023B. Processing designed for CG5 measurements.
Standard gradient processing method and non-linear function included.



Drift approximation using 1st or 2nd degree polynomial incorrporated within processing. 

Access via GUI or command line. GUI available in English language.
Check testfile.txt to get an idea of data arrangement within sheet.

**Input Data**
Tool enables arbitrary number of files to be selected (processed) as long as the input data characteristics are met for all the files such as:

- Number of header lines to be skipped when reading data from file(s)
- Height units: metres/centemetres
- instrument specific precision, which can either be or left at default 5.
- standard deviation scaling - defines whether SD provided within the file refers to a 60 second gravity estimate or individual a 1 Hz readings










Currently working on a python version to provide to bypass matlab license requirement.

Have fun.
