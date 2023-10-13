In this section we will show you how to upgrade from 0.621 to 0.63.  This is the first release
to contain our new upgrade approach.  

The following steps will upgrade your Kamailio configuration from 0.621 to 0.63.  

.. code-block:: bash
  
  cd /opt/dsiprouter
  git stash
  git checkout v0.63
  dsiprouter upgrade -rel 0.63

You should now be able to login to dSIPRouter and see that the new release has been applied.  
