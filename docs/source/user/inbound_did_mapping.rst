Inbound DID Mapping
======================



To Import a DID from a CSV file:
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


1) Click on Inbound DID Mapping.



.. image:: images//dSIP_IN_DID_Map.png
        :align: center



2) Click on the green Import DID button underneath List on Inbound Mappings.



.. image:: images//dSIP_IN_Import_DID.png
        :align: center



3) Click the Browse button and select the file that contains the DID numbers that you wish to use.

4) Click the green Add button.

  Click `CSV Example <https://https://raw.githubusercontent.com/dOpensource/dsiprouter/master/gui/static/template/DID_example.csv>`_ to view a sample of the .CSV file

5) Click on the Reload Kamailio button in order for the changes to be updated.


To Manually import a DID:
^^^^^^^^^^^^^^^^^^^^^^^^^

1) Click on Inbound DID Mapping
2) Click on the green ADD button.

  - Enter the name of the Inbound mapping
  - Enter the DID number in the DID field.
  - Select the Endpoint Group from the drop-down list

      Note: Each endpoint will contain at least two entries.  One that leverages load balancing weights and another that randomly selects an endpoint.
      The one denoted with a LB is the one that uses the load balancing algorithm.  If FusionPBX Domain Support is enabled you will see an additional
      entry for routing to the external interface of the FusionPBX server.

  - Click the green Add button.

  .. image:: images//dSIP_IN_DID_Map.png
          :align: center



3) Click on the Reload Kamailio button in order for the changes to be updated.
