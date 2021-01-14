# Contribution Guide

This guide will provide you with the tools to start developing on the dSIPRouter platform and contributing back to the community.

## Getting Started

First we will get our dev environment setup.
We recommend you create a local or cloud hosted VM for your dev environment.

1. Clone the branch you would like to work on and create a feature branch for your changes.
In this example we want to add support for **Ubuntu 20.04** to the **master** branch.

    ```bash
    git clone -b master https://github.com/dOpensource/dsiprouter.git /opt/dsiprouter
    cd /opt/dsiprouter
    git checkout -b feature-ubuntu-20.04
    ```

2. Install dSIPRouter with dev options.
You may need different flags depending on where you deploy (servernat, etc..)

    ```bash
    ./dsiprouter.sh install -all -servernat -with_dev
    ```

    This will run through the entire install process, then configure your git environment for the dsiprouter repo.
    For the rest of this walkthrough assume your starting location is in project root (default `/etc/dsiprouter`).

3. Make your changes..
Then prior to commit make sure you reset any defaults in `settings.py` or `kamailio_dsiprouter.cfg`.
You should **not** be commiting the generated versions from `/etc/dsiprouter`, this will include changes to the defaults.
Instead you should check which changes you need to keep by runnning diff:

    ```bash
    diff /etc/dsiprouter/gui/settings.py /opt/dsiprouter/gui/settings.py
    ```

    You should be able to pick out which changes were generated on install and which changes you need to keep.
    You can then merge the changes you need into the project source files.

4. Then commit, and push the changes to your feature branch.

    ```bash
    git add -A
    git commit
    git push
    ```

   This will run the git hooks setup earlier and automatically do the following:
   - update python dependencies in requirements.txt
   - update the changelog doc
   - update the contributors doc
   - resolve git references in your commit message

   If your committing to a different remote (i.e. not origin), then you need to let our hooks know beforehand.
   This is useful if you forked dsiprouter, or you have a secondary upstream/downstream remote:

   ```bash
   git commit --remote=upstream
   git push upstream
   ```

5. Create a Pull Request on Github (or Merge Request if on gitlab).
See the [Github Docs](https://help.github.com/en/github/collaborating-with-issues-and-pull-requests/creating-a-pull-request) for more information.

## Core Architecture Principles

- Installation should be less then 10 minutes
- Someone with basic SIP knowledge should be able to configure it and place a test call within 10 minutes
- The API structure should follow the Web UI

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

Modules not installed during dSIPRouter install should be packaged in a zipfile with an install script.
The install script should place the components defined in the [Structure](#structure) section into their proper locations.

#### Auto-discovery

Modules should be automatically discoverable.
This means that a new module should become automatically available from the UI without restarting the UI

### API Structure

Todo: Assigned to Tyler

### Useability

 - Web GUI
 - REST API
 - CLI Commands

### Development Environment

### dsiprouter.sh

- Do not put platform specific commands in this file.  Use the component/OS distribution/version.sh file to place those commands.

For example, if we need to install the Letsencrypt OS package so that it can be used for Kamailio on debian, then you would
place it in the kamailio/debian/9.sh and kamailio/debian/10.sh file
