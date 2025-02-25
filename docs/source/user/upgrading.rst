.. _upgrading:

Upgrading dSIPRouter
====================

Auto Upgrade Feature
--------------------

The dSIPRouter auto upgrade feature allows you to upgrade dSIPRouter from the User Interface (UI) and the command line (CLI).
If you are upgrading from 0.70, 0.72, or 0.721 you can boostrap to the latest release to get the auto-upgrade feature.

Upgrading to 0.73 doesn't require a dSIPRouter Core Subscription license because the auto-upgrade framework was not yet feature complete.
However, all subsequent releases of dSIPRouter require a Core Subscription License to use the auto-upgrade feature.
A core license can be purchased from the `dSIPRouter Marketplace <https://dopensource.com/product/dsiprouter-core/>`_.

.. image:: images/upgrade_up_to_date.png
        :align: center

Note that during upgrades, the hashed passwords have to be reset (such as dsiprouter admin password).
You can find the new passwords displayed; either on the CLI after completion, or by viewing the upgrade log in the UI:

.. image:: images/upgrading-log-01.png
        :align: center

.. image:: images/upgrading-log-02.png
        :align: center

Upgrade to 0.77
--------------------

Upgrading from version 0.76 to 0.77 can be done using the auto upgrade feature via the UI or CLI.

To upgrade using the UI click the "Upgrade Now" button:

.. image:: images/upgrade_available.png
        :align: center

Or by using the CLI:

.. code-block:: bash

   dsiprouter upgrade -rel 0.77

Upgrade to 0.76
--------------------

Upgrading from version 0.75 to 0.76 can be done using the auto upgrade feature via the UI or CLI.

To upgrade using the UI click the "Upgrade Now" button:

.. image:: images/upgrade_available.png
        :align: center

Or by using the CLI:

.. code-block:: bash

   dsiprouter upgrade -rel 0.76

Upgrade to 0.75
---------------

Upgrading to 0.75 can be done from a version greater than or equal to 0.72.
Upgrading from version 0.73 or 0.74 can be done using the UI:

.. image:: images/upgrade_available.png
        :align: center

Or by using the CLI:

.. code-block:: bash

   dsiprouter upgrade

To upgrade from 0.72 or 0.721 use the command below to bootstrap the upgrade:

.. code-block:: bash

   curl -s https://raw.githubusercontent.com/dOpensource/dsiprouter/v0.75/resources/upgrade/v0.75/scripts/bootstrap.sh | bash

Upgrade 0.73 to 0.74
--------------------

Upgrading from version 0.73 to 0.74 can be done using the auto upgrade feature via the UI or CLI.

Upgrade 0.72x to 0.73
---------------------

Upgrading to 0.73 can be done from 0.72 or 0.721 by doing the following

1. SSH to your dSIPRouter Instance
2. Run the following command

.. code-block:: bash

   curl -s https://raw.githubusercontent.com/dOpensource/dsiprouter/v0.73/resources/upgrade/v0.73/scripts/bootstrap.sh | bash

3. Login to the dSIPRouter UI to validate that the upgrade was successful.

**Note**, if you are upgrading from a debian 9 system you must first upgrade OS versions to a supported version.
See the `debian upgrade <https://wiki.debian.org/DebianUpgrade>`_ documentation for more information.

Note, if the upgrade fails you can purchase a dSIPRouter Core Subscription from the `dSIPRouter Marketplace <https://dopensource.com/product/dsiprouter-core/>`_.
This will provide you with support hours so that we can help with the upgrade.

Upgrade 0.70 to 0.721
---------------------

You can upgrade from 0.70 by doing the following

1. SSH to your dSIPRouter Instance
2. Run the following command

.. code-block:: bash

   curl -s https://raw.githubusercontent.com/dOpensource/dsiprouter/v0.721/resources/upgrade/v0.721/scripts/bootstrap.sh | bash

3. Login to the dSIPRouter UI to validate that the upgrade was successful.  

Note, if the upgrade fails you can purchase a dSIPRouter Core Subscription which can be purchased from the `dSIPRouter Marketplace <https://dopensource.com/product/dsiprouter-core/>`_.
This will provide you with support hours so that we can help with the upgrade.

Upgrade 0.70 to 0.72
--------------------

This upgrade path is deprecated. Upgrade to the **0.721** release instead.

Upgrade 0.644 to 0.70
---------------------

There is no automated upgrade available from 0.644 to 0.70.
Support is available via a dSIPRouter Core Subscription which can be purchased from the `dSIPRouter Marketplace <https://dopensource.com/product/dsiprouter-core/>`_.This will provide you with support hours so that we can help with the upgrade.

Upgrade 0.621 to 0.63
---------------------

.. include:: upgrade_0.621_to_0.63.rst

Upgrade 0.522 to 0.523
----------------------

.. include:: upgrade_0.522_to_0.523.rst

Upgrade 0.50 to 0.51
--------------------

.. include:: upgrade_0.50_to_0.51.rst
