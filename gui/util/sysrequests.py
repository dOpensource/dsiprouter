"""
Requests for the actions the dsiprouter user can not perform itself\n
A request is one line written to a FIFO only the dsiprouter user can write to\n
The FIFOs belong to the dsip-request systemd units, systemd starts the handler of a request as root
"""

import os
import select
import stat
import time

REQUESTS_DIR = '/run/dsiprouter-requests'
REQUEST_NAMES = ('restart', 'upgrade', 'provisioner')
# created by systemd when the handler of a request starts and removed when it stops
REQUEST_HANDLER_DIR = '/run/dsip-request-{name}'
# seconds to wait for systemd to start the handler, so a request that was just filed shows as ongoing
REQUEST_PICKUP_TIMEOUT = 5
# written by the handler of the upgrade request
UPGRADE_LOG = '/var/log/dsiprouter/upgrade.log'
UPGRADE_EXITCODE = UPGRADE_LOG + '.exitcode'


def requestPath(name):
    """
    Get the path of the queue a request is written to

    :param name:        name of the request
    :type name:         str
    :return:            path of the FIFO
    :rtype:             str
    :raises ValueError: if there is no handler for the request
    """

    if name not in REQUEST_NAMES:
        raise ValueError('unknown request: {}'.format(name))
    return os.path.join(REQUESTS_DIR, name)


def fileRequest(name, content):
    """
    File a request

    :param name:        name of the request
    :type name:         str
    :param content:     data the handler of the request needs, one line
    :type content:      str
    :raises ValueError: if there is no handler for the request or the content can not be sent as one request
    :raises OSError:    if the request could not be written, the request handlers are not installed or not running
    """

    request_path = requestPath(name)
    data = content.encode('utf-8') + b'\n'
    # larger writes to a FIFO are not atomic, the handler could read part of a request
    if len(content) == 0 or '\n' in content or len(data) > select.PIPE_BUF:
        raise ValueError('{} request can not be sent as one line of at most {} bytes'.format(name, select.PIPE_BUF))

    # opening fails right away when systemd is not listening on the queue, writing fails when the queue is full
    request_fd = os.open(request_path, os.O_WRONLY | os.O_NONBLOCK | os.O_NOFOLLOW)
    try:
        if not stat.S_ISFIFO(os.fstat(request_fd).st_mode):
            raise OSError('{} is not a request queue'.format(request_path))
        os.write(request_fd, data)
    finally:
        os.close(request_fd)

    handler_dir = REQUEST_HANDLER_DIR.format(name=name)
    pickup_deadline = time.monotonic() + REQUEST_PICKUP_TIMEOUT
    while time.monotonic() < pickup_deadline:
        if os.path.isdir(handler_dir):
            return
        time.sleep(0.05)


def isRequestOngoing(name):
    """
    Whether the handler of a request is running

    :param name:        name of the request
    :type name:         str
    :return:            whether a request is being handled, or waiting for another request to be handled
    :rtype:             bool
    :raises ValueError: if there is no handler for the request
    """

    requestPath(name)
    return os.path.isdir(REQUEST_HANDLER_DIR.format(name=name))


def getUpgradeExitCode():
    """
    Get the result of the last upgrade that was requested

    :return:    exit code of the upgrade, None if no upgrade finished or it is still running
    :rtype:     int|None
    """

    try:
        with open(UPGRADE_EXITCODE, 'r') as exitcode_file:
            return int(exitcode_file.read(16))
    except (OSError, ValueError):
        return None
