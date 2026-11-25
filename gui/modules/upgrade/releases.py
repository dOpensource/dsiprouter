#!/usr/bin/env python3
"""
Find the releases of the tracked repo that the installed version can be upgraded to\n
Only the standard library is used, the dsiprouter CLI runs this file directly and the GUI imports it
"""

from __future__ import annotations

import argparse
import dataclasses
import decimal
import json
import os
import re
import subprocess
import sys
import tempfile
import urllib.error
import urllib.request

# releases are tagged v<version>-rel, pre-releases v<version>-beta (alpha and rc are handled the same, a number can follow)
RELEASE_TAG_REGEX = re.compile(r'v([0-9]{1,4}\.[0-9]{1,6})-(rel|(alpha|beta|rc)([0-9]{0,4}))')
VERSION_REGEX = re.compile(r'[0-9]{1,4}\.[0-9]{1,6}')
# only https repos are tracked, the upgrade runs the files it downloads
REPO_URL_REGEX = re.compile(r'https://[A-Za-z0-9._~%@:/+-]{1,2000}')
GITHUB_REPO_REGEX = re.compile(r'https://(?:[^/@]+@)?github\.com/([A-Za-z0-9._-]+)/([A-Za-z0-9._-]+?)(?:\.git)?/?')
GITHUB_RELEASES_URL = 'https://api.github.com/repos/{owner}/{repo}/releases'
# git is limited to the https transport, whatever the url of the repo redirects or is rewritten to
GIT_CMD = ('git', '-c', 'protocol.allow=never', '-c', 'protocol.https.allow=always')
NETWORK_TIMEOUT = 60
RELEASES_PAGE_SIZE = 100
RELEASES_MAX_PAGES = 10
# newer releases than this are not checked
MAX_CANDIDATES = 50
SETTINGS_MAX_SIZE = 64 * 1024


class ReleasesError(Exception):
    """ The releases of the tracked repo could not be determined """


@dataclasses.dataclass(frozen=True)
class Release:
    tag: str
    version: str
    prerelease: bool

    @property
    def sort_key(self) -> tuple:
        match = RELEASE_TAG_REGEX.fullmatch(self.tag)
        stage = match.group(3) or 'rel'
        # a release sorts after the pre-releases of its version
        return decimal.Decimal(self.version), stage == 'rel', stage, int(match.group(4) or 0)


def isValidRepoUrl(repo_url: str) -> bool:
    """ Whether upgrades can be tracked from the repo """
    return isinstance(repo_url, str) and REPO_URL_REGEX.fullmatch(repo_url) is not None


def parseReleaseTag(tag: str) -> Release | None:
    """ Parse a tag of the tracked repo, None if the tag is not a release """
    match = RELEASE_TAG_REGEX.fullmatch(tag)
    if match is None:
        return None
    return Release(tag=tag, version=match.group(1), prerelease=match.group(2) != 'rel')


def githubReleasesUrl(repo_url: str) -> str | None:
    """ Releases API of a repo hosted on github.com, None for other repos """
    match = GITHUB_REPO_REGEX.fullmatch(repo_url)
    if match is None:
        return None
    return GITHUB_RELEASES_URL.format(owner=match.group(1), repo=match.group(2))


def runGit(args: list[str], cwd: str | None = None) -> str:
    """ Run a git command without prompting for credentials """
    env = dict(os.environ, GIT_TERMINAL_PROMPT='0')
    try:
        proc = subprocess.run([*GIT_CMD, *args], cwd=cwd, env=env, stdin=subprocess.DEVNULL, capture_output=True,
            text=True, errors='replace', timeout=NETWORK_TIMEOUT, check=True)
    except subprocess.TimeoutExpired as ex:
        raise ReleasesError(f"git {args[0]} timed out") from ex
    except subprocess.CalledProcessError as ex:
        raise ReleasesError(f"git {args[0]} failed: {ex.stderr.strip()[-500:]}") from ex
    except OSError as ex:
        raise ReleasesError(f"git could not be run: {ex}") from ex
    return proc.stdout


def listReleaseTags(repo_url: str) -> list[Release]:
    """ List the release and pre-release tags of the repo """
    releases = []
    for line in runGit(['ls-remote', '--tags', '--refs', '--', repo_url]).splitlines():
        ref = line.partition('\t')[2]
        release = parseReleaseTag(ref[len('refs/tags/'):]) if ref.startswith('refs/tags/') else None
        if release is not None:
            releases.append(release)
    return releases


def fetchPrereleaseTags(release_api_url: str) -> set[str]:
    """ Tags of the releases published as a pre-release or draft, from a releases API in the GitHub format """
    if not release_api_url.startswith('https://'):
        raise ReleasesError('the releases API must be an https url')

    tags = set()
    for page in range(1, RELEASES_MAX_PAGES + 1):
        request = urllib.request.Request(f"{release_api_url}?per_page={RELEASES_PAGE_SIZE}&page={page}",
            headers={'Accept': 'application/vnd.github+json', 'User-Agent': 'dsiprouter'})
        try:
            with urllib.request.urlopen(request, timeout=NETWORK_TIMEOUT) as response:
                releases = json.load(response)
        except (urllib.error.URLError, TimeoutError, ValueError) as ex:
            raise ReleasesError(f"could not retrieve the releases of the repo: {ex}") from ex
        if not isinstance(releases, list):
            raise ReleasesError('the releases API returned an unexpected response')
        for release in releases:
            if isinstance(release, dict) and (release.get('prerelease') or release.get('draft')):
                tags.add(str(release.get('tag_name')))
        if len(releases) < RELEASES_PAGE_SIZE:
            break
    return tags


def fetchUpgradeDepends(repo_url: str, releases: list[Release]) -> dict[str, list[str]]:
    """
    Get the versions each release can be upgraded from, from the upgrade settings in the repo at the tag of the release\n
    A release without valid upgrade settings is left out
    """
    depends = {}
    if len(releases) == 0:
        return depends

    with tempfile.TemporaryDirectory() as repo_dir:
        runGit(['init', '--quiet', '--bare', repo_dir])
        runGit(['remote', 'add', 'origin', repo_url], cwd=repo_dir)
        refspecs = [f"+refs/tags/{release.tag}:refs/tags/{release.tag}" for release in releases]
        fetch_cmd = ['fetch', '--quiet', '--no-tags', '--depth', '1']
        try:
            # only the files that are read are downloaded when the server supports it
            runGit(['config', 'remote.origin.promisor', 'true'], cwd=repo_dir)
            runGit(['config', 'remote.origin.partialclonefilter', 'blob:none'], cwd=repo_dir)
            runGit([*fetch_cmd, '--filter=blob:none', 'origin', *refspecs], cwd=repo_dir)
        except ReleasesError:
            runGit(['config', 'remote.origin.promisor', 'false'], cwd=repo_dir)
            runGit([*fetch_cmd, 'origin', *refspecs], cwd=repo_dir)

        for release in releases:
            settings_path = f"resources/upgrade/v{release.version}/settings.json"
            # a release without upgrade settings can not be upgraded to
            if len(runGit(['ls-tree', '--name-only', f"refs/tags/{release.tag}", '--', settings_path], cwd=repo_dir)) == 0:
                continue
            settings_json = runGit(['show', f"refs/tags/{release.tag}:{settings_path}"], cwd=repo_dir)
            try:
                upgrade_settings = json.loads(settings_json[:SETTINGS_MAX_SIZE])
            except ValueError:
                continue
            if not isinstance(upgrade_settings, dict) or upgrade_settings.get('version') != release.version:
                continue
            versions = upgrade_settings.get('depends')
            if isinstance(versions, str):
                versions = [versions]
            if isinstance(versions, list) and all(isinstance(version, str) for version in versions):
                depends[release.tag] = versions
    return depends


def getSupportedReleases(repo_url: str, current_version: str, track_prereleases: bool = False,
        release_api_url: str | None = None) -> list[Release]:
    """
    Get the releases the installed version can be upgraded to, oldest first

    :param repo_url:            repo the releases are tracked from
    :param current_version:     version that is installed
    :param track_prereleases:   whether pre-releases are included
    :param release_api_url:     releases API (GitHub format) of a repo that is not hosted on github.com
    :raises ReleasesError:      if the releases could not be determined
    """
    if not isValidRepoUrl(repo_url):
        raise ReleasesError('the upgrade repo must be an https url')
    if VERSION_REGEX.fullmatch(current_version) is None:
        raise ReleasesError('the installed version is not a valid version')

    release_api_url = githubReleasesUrl(repo_url) or release_api_url
    prerelease_tags = fetchPrereleaseTags(release_api_url) if release_api_url else set()

    # one tag per version, a release replaces the pre-releases of its version
    candidates = {}
    for release in sorted(listReleaseTags(repo_url), key=lambda x: x.sort_key):
        if release.tag in prerelease_tags:
            release = dataclasses.replace(release, prerelease=True)
        if release.prerelease and not track_prereleases:
            continue
        if decimal.Decimal(release.version) > decimal.Decimal(current_version):
            candidates[decimal.Decimal(release.version)] = release
    newest = [candidates[version] for version in sorted(candidates)][-MAX_CANDIDATES:]

    depends = fetchUpgradeDepends(repo_url, newest)
    return [release for release in newest if current_version in depends.get(release.tag, [])]


def main() -> int:
    parser = argparse.ArgumentParser(description='List the release tags the installed version can be upgraded to, oldest first')
    parser.add_argument('--repo', required=True, help='https url of the repo releases are tracked from')
    parser.add_argument('--current', required=True, help='version that is installed')
    parser.add_argument('--prereleases', action='store_true', help='include pre-releases')
    parser.add_argument('--release-api', default=None, help='releases API (GitHub format) of a repo not hosted on github.com')
    args = parser.parse_args()

    try:
        releases = getSupportedReleases(args.repo, args.current, args.prereleases, args.release_api)
    except ReleasesError as ex:
        print(str(ex), file=sys.stderr)
        return 1
    for release in releases:
        print(release.tag)
    return 0


if __name__ == '__main__':
    sys.exit(main())
