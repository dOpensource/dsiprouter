'''
@Summary: Contains methods for input and output interaction
@Author: `devopsec <https://github.com/devopsec>`_
'''

import os, shutil, errno

def touch(path):
    with open(path, 'a+'):
        os.utime(path, None)

def mkdir(dir, mode=0o755):
    """ Exit if dir can't be created """
    if not os.path.exists(dir):
        os.makedirs(dir, mode=mode)

def cp(src, dst):
    if os.path.exists(dst):
        shutil.rmtree(dst)
    try:
        shutil.copytree(src, dst)
    except OSError as e:
        if e.errno == errno.ENOTDIR:
            if not os.path.exists(dst):
                shutil.copy(src, dst)
        else:
            raise
