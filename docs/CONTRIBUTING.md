## Contribution Guide

## Core Architecture Principles

- Installation should be less then 10 minutes
- Someone with basic SIP knowledge hould be able to configure it and place a test call within 10 minutes
- The API structure should follow the Web URI

### File Structure

### Modules

#### Structure

Our module architecture has been loosely defined for a while, but we now want to define the structure and start moving all modules into this structure.  
Each module should have these components:

| Component | Location | Purpose |
| --------- | -------- | ------- |
| module.js | gui/static/js/ | Contains the UI Javascript for a module |
| module.css | gui/static/css/ | Contains the Cascading Style Sheets for a module |
| module.py | gui/modules/module | Contains the Python scripts |

For example, this is what the "***Domain***" module looks like:

| Component | Location | Purpose |
| --------- | -------- | ------- |
| domain.js | gui/static/js/ | Contains the UI Javascript for a module |
| domain.css | gui/static/css/ | Contains the Cascading Style Sheets for a module |
| domain*.py | gui/modules/domain/ | Contains the Python scripts |
| domain*.sql | gui/modules/domain/ | SQL Scripts for installing the database table structure fro the module |

#### Packaging

Modules not installed during dSIPRouter install should be packaged in a zipfile with an install script. The install script should place the components defined 
the [Structure](#structure) section into their proper locations.




#### Auto-discovery 

Modules should be automatically discoverable.  This means that a new module should become automatically available from the UI without restarting the UI


### API Structure 

Todo: Assigned to Tyler

### Useability
 - Web Interface
 - Command Line
 - 

### Development Environment

### dsiprouter.sh

- Do not put platform specific commands in this file.  Use the component/OS distribution/version.sh file to place those commands.

For example, if we need to install the Letsencrypt OS package so that it can be used for Kamailio on debian, then you would
place it in the kamailio/debian/9.sh and kamailio/debian/10.sh file
