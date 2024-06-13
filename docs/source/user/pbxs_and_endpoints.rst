PBX(s) and Endpoints
======================



Allows you to define a PBX or Endpoint that will send or receive calls from dSIPRouter.  The PBX or Endpoint can use IP
authentication or a username/password can be defined.



To add an Endpoint Group:
^^^^^^^^^^^^^^^^^^^^^^^^^

1) Click on Endpoints Groups.



2) Click on the green Add button.

.. image:: images//dSIP_PBX_Add.png
        :align: center

3) Configure the Endpoint Group

     The Endpoint Tab is where you specify the endpoints that will be signaling
     with dSIPRouter.  The weight field allows you to define how much SIP traffic
     is distributed to a particular endpoint. If you don't specify a weight for an endpoint
     the system will automatically generate a weight.  If you are using FusionPBX Domain
     Auth then Register and INVITE requests will be distributed to the endpoints based
     upon the weights.  You will also have the option to route Inbound calls to the
     endpoints based on the weights by selecting the name of the Endpoint Group with
     an LB concatenated to the name.  For example, if the name of the Endpoint Group is
     **PBXCluster** then you would select **PBXCluster LB** from the Inbound Mapping
     Endpoint Group drop down.

  b) Click the green Add button.

.. image:: images//dSIP_PBX_ADD_New_PBX.png
        :align: center



4) Click on the Reload Kamailio button in order for the changes to be updated.
