Extra Resources
===============

Uploading CSVs
--------------

`CSV Example <https://raw.githubusercontent.com/dOpensource/dsiprouter/v0.51/docs/images/DID_test.csv>`_ 

Proxy FusionPBX UI
------------------

Add the following stanza before "location /images/" stanza to proxy the FusionPBX UI thru dSIPRouter.  Once the following text 
is added to /opt/dsiprouter/gui/modules/fusionpbx/dsiprouter.nginx.tpl you will be able to access the FusionPBX GUI via:
https://dSIPRouter_IP/ or https://dSIPRouter_IP::

    location / {
        proxy_pass https://fusionpbx;
        proxy_redirect off;
        proxy_next_upstream error timeout http_404 http_403 http_500 http_502 http_503 http_504 non_idempotent;
    }
