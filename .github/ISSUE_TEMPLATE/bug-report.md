---
name: Bug Report
about: Report unexpected program behavior to help us improve
title: "[BUG] Your Issue Name Here"
labels: bug, needs validation
assignees: ''

---

**Describe the bug**
A clear and concise description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Go to '...'
2. Click on '....'
3. Scroll down to '....'
4. See error

**Expected behavior**
A clear and concise description of what you expected to happen.

**Screenshots**
If applicable, add screenshots to help explain your problem.  
Add any applicable logs as well; such as an `dsiprouter.log`, or `kamailio.log`, etc...

**Server Info:**
 - OS: *output from* `uname -a`
 - Distro: *output from* `cat /etc/os-release`
 - dSIPRouter Version: *output from* `dsiprouter version`  
*If not on a release version include the branch name and last commit id*
 - Kamailio Version: *output from* `kamailio -v`
 - RTPengine Version: *output from* `rtpengine -v`
 - Python Package Versions: *if applicable, include output from* `/opt/dsiprouter/venv/bin/python -m pip freeze`

**Client Info:**
 - Device: *e.g. Polycom VVX 350, Lenovo Thinkpad X1, ..*
 - OS: *e.g. Windows 11, Ubuntu 22.04, ..*
 - Client Software: *e.g. Mozilla Firefox 103.0, Zoiper 5.5.13, ..*

**Additional context**
Add any other context about the problem here.
