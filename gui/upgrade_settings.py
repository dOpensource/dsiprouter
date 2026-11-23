# dSIPRouter upgrade settings
#
# Upgrades are run as root from the repo set here
# The installed copy of this file (/etc/dsiprouter/upgrade_settings.py) can only be changed by root
# The dSIPRouter GUI reads these settings to list the available releases, it can not change them
# Each setting is one line in the format: NAME = value

# repo that releases are tracked from for upgrades, must be an https url
# releases are tagged v<version>-rel, a release can be upgraded to when its upgrade settings list the installed version
GIT_REPO_URL = 'https://github.com/dOpensource/dsiprouter.git'
# releases API (GitHub format) used to find the releases that are published as a pre-release
# only needed when the repo is not hosted on github.com, for repos on github.com it is derived from GIT_REPO_URL
GIT_RELEASE_URL = ''
# whether upgrades to beta releases are offered (pre-releases on GitHub and tags like v0.794-beta)
GIT_TRACK_BETA_RELEASES = False
