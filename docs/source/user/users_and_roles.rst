.. _users_and_roles:

Users and Roles
^^^^^^^^^^^^^^^

dSIPRouter has one built-in administrator account, its username and password are set when dSIPRouter is installed.
More users can be added, each with a role that decides which pages of the UI the user can use.

Roles
-----

===================================     ==========================================================================
Role                                    Access
===================================     ==========================================================================
dsip_admin                              Every page of the UI
dsip_engineer                           Every page except Users, Backup and Restore and Upgrade
dsip_guest                              Every page except Users, Backup and Restore, Upgrade, Global Settings and
                                        Certificates
===================================     ==========================================================================

The built-in administrator account always has the ``dsip_admin`` role.
The links to Users, Backup and Restore, Certificates and Upgrade are only shown in the menu to the users that can use those pages.

The roles apply to users that are logged in to the UI, including the requests the UI makes to the API on their behalf.
Requests made with the API token are not limited by a role, see :doc:`api`.

Managing Users
--------------

Users are managed by a user with the ``dsip_admin`` role.

1) Click on System Settings, then on Users.

2) To add a user click the green Add button and fill in the first name, last name, username, password and role of the user.

3) To change a user click the edit button of the user. The password is only changed when a new one is entered.

4) To remove a user click the delete button of the user.

A user logs in with its username and password on the same login page as the administrator.
