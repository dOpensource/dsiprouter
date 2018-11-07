Carrier Groups
^^^^^^^^^^^^^^

The Carrier Group section of dSIPRouter allows you to define which carriers will be used to provide Internet service (aka ISP) for your VOIP (Voice Over IP) services. Carrier groups support IP Authentication and Username/Password authentication. Below is an example of a carrier groups list.

.. image:: images/carrier_groups.png
        :align: center
        
Adding a Carrier
^^^^^^^^^^^^^^^^

- Log into dSIPRouter using proper username and password.

- Click "Add" to create a Carrier Group.  A carrier group can contain 1 or more SIP endpoints provided by the carrier. A SIP Endpoint represents a device that makes or receives calls via your Gateway. This could be a physical IP phone, a softphone app such as Skype, on a PC or smartphone, an Analog Telephone Adapter (ATA) such as for fax machines, or even a PBX system. 
Select Username/Password Auth, fill in the username, password of your registration server and the registration server name. Then click ADD.




.. image:: images/add_carrier_group.png
        :align: center

For example:   .. image:: images/username_password.PNG
        :align: right


After you have added the new group, the screen will return back to the List of Carriers Group page. Select the pencil in the blue box to the right to allow editing the Config and Endpoints. 



.. image:: images/carrier_editing.PNG
        :align: center



Selcet the Config tab. The Config tab allows you to edit/ change the Carrier group name. Then click Update.

.. image:: images/config_pic.PNG
        :align: center
        



To add an endpoint, click the Endpoint tab. Click ADD, enter the carrier details then click ADD again.  


.. image:: images/add_endpoint.PNG
        :align: center
       




























.. image:: images/add_carrier_details.PNG
        :align: center
        
        
   
 
 You should now see your added carrier in the Carrier Group List.
