# ESA_Extended
The Extended Electrographic Seizure Analyzer is a modified version of the Electrographic Seizure Analyzer first developed by the Krook-Magnuson lab at the University of Minnesota.

## Additional Features
- Custom channel selection for channel-level analysis
	- Display of 4 channels at a time in GUI
- Manual threshold adjustment per channel
- Speedups in threshold determination and event detection
	- Primarily through use of MATLAB parallel computing toolbox
- User-defined selection and separation of detected events upon visual inspection of highlighted time series into various categories and saved into separate spreadsheets accordingly:
	- True events
	- Non-events
	- Events containing noise
	- Possible short events

# External Libraries
The following external libraries are used by the Extended ESA:

  - EEGLAB (version 13.6.5b)
    - Link: https://sccn.ucsd.edu/eeglab/download.php

# Documentation
The documentation for the base methods and functionality of the Electrographic Seizure Analyzer can be found at the KM lab public repository within the document entitled *User Guide  Electrographic Seizure Analyzer.pdf*
  - Repository Link: https://github.com/KM-Lab/Electrographic-Seizure-Analyzer 


