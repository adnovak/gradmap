# gradmap
gravity gradient computing tool Developed for GKU under open license in MATLAB R2023B. Processing designed for CG5 measurements. Standard gradient processing method and non-linear function included.
Drift approximation using 1st or 2nd degree polynomial incorrporated within processing. Optionally, gravity differences can be estimated using the application when gravity gradient is of no desire.

System requirements: 
- MATLAB R2023B or later with: Statistics toolbox recommended (however not required)
- 4 GB of RAM

Funcionality:
Access via GUI or command line. GUI available in English language. Check testfile.txt to get an idea of data arrangement within sheet.

Widgets can be sorted into three groups:
1. Input data information, where user provides information on how the datasheet is arranged, path to file where the data is stored and other.
2. Processing information, where defines type of gradient processing, and additional information on the adjustment process.
3. Output data part is where user creates a report file, which is mandatory along with an option to store summary - useful when multiple files are processed and graphic output.

GUI user manual:

Input data window
input data widget enables arbitrary number of files to be selected (processed) as long as the input data characteristics are met for all the files such as:
number of header lines - defines lines to be skipped when reading data from file(s)
height units -  metres or centimetres
instrument specific precision, which can either be set or left at default 5.
standard deviation scaling - defines whether SD provided within the file refers to a 60 second gravity estimate or individual a 1 Hz readings

Processing window
number of measured positions - how many positions were included in the measuring process
rejection threshold - threshold where solution is flagged as rejected. This provides a warning for the operator that something has occured in the process of measurement and desired precision may not have been reached.
gradient format - user has the option to use standard gradient estimating procedure, where gravity difference is scaled by the vertical distance or 
significance level - statistical significance determines the result of statistic tests performed within the processing - outlier testing and other aspects.
calibration factor - enables user to provide a specific calibration factor and scale gravity gradient in addition to standard scale factor.

Output data window
create report file - creates a file where processing data is stored for each individual data file.
store processing figures - when checked, figures depecting drift approximation is created and stored.
save gravity differences instead - when checked, standard campaign processing is performed resulting in gravity differences and their standard deviation instead of gravity gradient.

Additional information:
Currently working on a python version to bypass matlab license requirement.
Have fun.