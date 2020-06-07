from crontab import CronTab, CronSlices
from cron_descriptor import ExpressionDescriptor

# TODO: we should propagate exceptions from here so we can
#       better handle them at the API level

def getTaggedCronjob(tag):
    """
    Get a cronjob from current user's crontab by its tag

    :param tag:     tag specified when creating
    :type tag:      str|int
    :return:        cronjob entry or None
    :rtype:         CronTab|None
    """
    try:
        if isinstance(tag, int):
            tag = str(tag)
        cron  = CronTab(user=True)
        return tuple(cron.find_comment(tag))[0]
    except:
        return None

def addTaggedCronjob(tag, interval, cmd):
    """
    Adds a tagged cronjob to current user's crontab

    :param tag:         tag for new entry
    :type tag:          str|int
    :param interval:    crontab interval
    :type interval:     str
    :param cmd:         crontab cmd to run
    :type cmd:          str
    :return:            whether it succeeded
    :rtype:             bool
    """
    try:
        if isinstance(tag, int):
            tag = str(tag)
        if not CronSlices.is_valid(interval):
            return False

        cron  = CronTab(user=True)

        matching_jobs = tuple(cron.find_comment(tag))
        if len(matching_jobs) == 0:
            job = cron.new(command=cmd, comment=tag)
        else:
            job = matching_jobs[0]
            job.set_command(cmd)
        job.setall(interval)

        if not job.is_valid():
            return False

        cron.write()
        return True
    except:
        return False

def updateTaggedCronjob(tag, interval='', cmd='', new_tag=''):
    """
    Update a tagged cronjob in the current user's crontab

    :param tag:         tag of existing entry
    :type tag:          str|int
    :param interval:    new crontab interval
    :type interval:     str
    :param cmd:         new crontab cmd to run
    :type cmd:          str
    :param new_tag:     new tag for entry
    :type new_tag:      str|int
    :return:            whether it succeeded
    :rtype:             bool
    """
    try:
        if isinstance(tag, int):
            tag = str(tag)
        if isinstance(new_tag, int):
            new_tag = str(new_tag)

        cron = CronTab(user=True)

        matching_jobs = tuple(cron.find_comment(tag))
        if len(matching_jobs) == 0:
            job = cron.new(comment=tag)
        else:
            job = tuple(cron.find_comment(tag))[0]

        if len(interval) > 0:
            if not CronSlices.is_valid(interval):
                return False
            job.setall(interval)

        if len(cmd) > 0:
            job.set_command(cmd)

        if len(new_tag) > 0:
            job.set_comment(new_tag)

        if not job.is_valid():
            return False

        cron.write()
        return True
    except:
        return False

def deleteTaggedCronjob(tag):
    """
    Delete a tagged cronjob from the existing user's crontab

    :param tag:     tag of existing entry
    :type tag:      str|int
    :return:        whether it succeeded
    :rtype:         bool
    """
    try:
        if isinstance(tag, int):
            tag = str(tag)

        cron  = CronTab(user=True)

        matching_jobs = tuple(cron.find_comment(tag))
        if len(matching_jobs) == 0:
            return True

        job = tuple(cron.find_comment(tag))[0]
        cron.remove(job)

        cron.write()
        return True
    except:
        return False

def cronIntervalToDescription(interval):
    """
    Convert a crontab interval to a human readable format

    :param interval:        crontab interval
    :type interval:         str
    :return:                readable format or None
    :rtype:                 str|None
    """
    try:
        descriptor = ExpressionDescriptor(interval, use_24hour_time_format=True)
        return descriptor.get_description()
    except:
        return None
