.. _backup_and_restore:

Backup and Restore
^^^^^^^^^^^^^^^^^^

The Kamailio database holds the configuration made in dSIPRouter (carrier groups, endpoint groups, domains, routes, users, ...).
It can be backed up to and restored from a file in the UI. Both require the ``dsip_admin`` role.

Creating a Backup
-----------------

1) Click on System Settings, then on Backup and Restore.

2) On the Backup tab click Download Backup. The backup is downloaded as a ``.sql`` file.

Restoring a Backup
------------------

1) Click on System Settings, then on Backup and Restore.

2) On the Restore tab click Choose Backup File and select the ``.sql`` file of a backup.

3) Click Start Restore.

4) Reload Kamailio when the restore is done, the UI shows that a reload is required.

The restore replaces the current content of the database with the content of the backup.
Only restore backups that were created by dSIPRouter.
The database client can not run programs or open files while it restores a backup, with clients that have no such mode a backup containing those commands is refused.

The backup and the restore run as the ``dsiprouter`` user with the database user of Kamailio, nothing is run as root.
The file is only kept in ``/var/lib/dsiprouter/gui-backups`` (``BACKUP_FOLDER``) while it is transferred.

The dSIPRouter config files are not part of this backup.

The same database can be backed up and restored from the command line as root:

.. code-block:: bash

    dsiprouter backup -f /root/kamailio-backup.sql
    dsiprouter restore -f /root/kamailio-backup.sql
