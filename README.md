# MIT-Cell-Analysis
this is to process data provided by [MIT CELL TESTING](https://fsae.mit.edu/blog/2019/10/30/my19-cell-cycling):

Analysis:

Cycle Dependence:

Since all of the cells were cylced for less than 100 times, I assumed the test where independent of each other (life time >1000 cycles for these batteries, 
and there is little change between them) given that assumption, the data was vertically concatenated and fit as one data set per given temperature.

Data Extraction:

The peakfilter function looks through the code for large current spikes and samples the data around it, If passed a "voltage" analysis 
all the data surrounding the spikes is removed, whereas an "IR" analysis removes all the data except the spikes.
The spikes are used to find purely Ohmic resistance (although that was not feasible since the sample times of the data is ~0.1s,
too slow to ignore a transient response) this script analyzes the data 0.3 seconds before and after the interupt (this was justified from data inspection,
and can be repeated with the inspectSteps option)

More details on the method to find internal resistance: it is called current interrupt more info can be found on the [link](https://www.batterypoweronline.com/articles/how-to-measure-battery-internal-resistance-using-the-current-interrupt-method/):


Where the raw data came from, [BIG THANKS](https://www.dropbox.com/s/d4dsaprr3kaxp7z/MIT%20Motorsports%20Cell%20Data%202019.zip?dl=0)

