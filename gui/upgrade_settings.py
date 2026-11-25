# dSIPRouter upgrade settings
#
# Upgrades are run as root from the repo set here
# The installed copy of this file (/etc/dsiprouter/upgrade_settings.py) can only be changed by root
# The dSIPRouter GUI reads these settings to find the latest release, it can not change them
# Each setting is one line in the format: NAME = value

# where upgrades will be pulled from, must be an https url
GIT_REPO_URL = 'https://github.com/dOpensource/dsiprouter.git'
GIT_RELEASE_URL = 'https://api.github.com/repos/dOpensource/dsiprouter/releases'
