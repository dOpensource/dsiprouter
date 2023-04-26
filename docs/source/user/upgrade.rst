Upgrading dSIPRouter 
============================================

Auto Upgrade Feature (Released 0.72)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
The dSIPRouter auto upgrade feature was released in 0.72.  It allows you to upgrade dSIPRouter from the User Interface(UI) and the command line.  If you are upgrading from 0.70 you will need to use the command line option since the 0.70 version doesn't have the upgrade feature builtin. Upgrading from 0.70 doesn't require a dSIPRouter Core Subscription license because this is the first release of the upgrade framework unless you need support during the upgrade process.  However, future releases of dSIPRouter will require a Core Subscription License, which can be purchased from the `dSIPRouter Marketplace <https://dopensource.com/product/dsiprouter-core/>`_.  

.. image:: images/upgrade_up_to_date.png
        :align: center

Upgrade 0.70 to 0.721
^^^^^^^^^^^^^^^^^^^^^
You can upgrade from 0.70 by doing the following

1. SSH to your dSIPRouter Instance
2. Run the following command

.. code-block:: bash

   curl -s https://raw.githubusercontent.com/dOpensource/dsiprouter/v0.721/resources/upgrade/v0.721/scripts/bootstrap.sh | bash

3. Login to the dSIPRouter UI to validate that the upgrade was successful.  

Note, if the upgrade fails you can purchase a dSIPRouter Core Subscription which can be purchased from the `dSIPRouter Marketplace <https://dopensource.com/product/dsiprouter-core/>`_.This will provide you with support hours so that we can help with the upgrade.

Upgrade 0.70 to 0.72
^^^^^^^^^^^^^^^^^^^^
You can upgrade from 0.70 by doing the following

1. SSH to your dSIPRouter Instance
2. Run the following command

.. code-block:: bash

   curl -s https://raw.githubusercontent.com/dOpensource/dsiprouter/v0.72/resources/upgrade/v0.72/scripts/bootstrap.sh | bash

3. Login to the dSIPRouter UI to validate that the upgrade was successful.  

Note, if the upgrade fails you can purchase a dSIPRouter Core Subscription which can be purchased from the `dSIPRouter Marketplace <https://dopensource.com/product/dsiprouter-core/>`_.This will provide you with support hours so that we can help with the upgrade.

Upgrade 0.644 to 0.72
^^^^^^^^^^^^^^^^^^^^^
There is no automated upgrade available from 0.644 to 0.72.  Support is available via a dSIPRouter Core Subscription which can be purchased from the `dSIPRouter Marketplace <https://dopensource.com/product/dsiprouter-core/>`_.This will provide you with support hours so that we can help with the upgrade.


Upgrade 0.621 to 0.63
^^^^^^^^^^^^^^^^^^^^^
   .. toctree::
    :maxdepth: 2
   
    upgrade_0.621_to_0.63.rst

Upgrade 0.522 to 0.523
^^^^^^^^^^^^^^^^^^^^^^
   .. toctree::
    :maxdepth: 2
  
    upgrade_0.522_to_0.523.rst

Upgrade 0.50 to 0.51
^^^^^^^^^^^^^^^^^^^^
   .. toctree::
    :maxdepth: 2
   
    upgrade_0.50_to_0.51.rst


