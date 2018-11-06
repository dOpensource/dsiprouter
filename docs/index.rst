Intro to dSIPRouter
===================

.. raw:: html

        <object width="560" height="315"><param name="movie"
        value="https://www.youtube.com/embed/Iu4BQkL1wGc"></param><param
        name="allowFullScreen" value="true"></param><param
        name="allowscriptaccess" value="always"></param><embed
        src="https://www.youtube.com/embed/Iu4BQkL1wGc"
        type="application/x-shockwave-flash" allowscriptaccess="always"
        allowfullscreen="true" width=""
        height="385"></embed></object>

       
       
       
       
       
dSIPRouter by dOpenSource | a Flyball Company [ Built in Detroit ]
       
           
           
           
       dSIPRouter allows you to quickly turn [Kamailio](https://www.kamailio.org/) into an easy to use SIP Service Provider platform, which enables the following two basic use cases: 
       
       
- **SIP Trunking services:** Provide services to customers that have an on-premise PBX such as FreePBX, FusionPBX, Avaya, etc.  We have support for IP and credential based authentication.

- **Hosted PBX services:** Proxy SIP Endpoint requests to a multi-tenant PBX such as FusionPBX or single-tenant such as FreePBX. We have an integration with FusionPBX that make is really easy and scalable!



Demo System

You can checkout our demo system by clicking the link below and enter the listed username and password:



[http://demo.dsiprouter.org:5000]


username: admin


password: ZmIwMTdmY2I5NjE4


**Follow us at [#dsiprouter](https://twitter.com/dsiprouter) on Twitter to get the latest updates on dSIPRouter**


Sponsors

We would like to say thank you to [Skyetel](http://skye.tel/dsiprouter) for believing in us and becoming our first sponsor. 

[Skyetel Logo](/pictures/skyetel_logo.jpeg


Installing dSIPRouter
=====================

.. toctree::
   :maxdepth: 2
   
   installing.rst
   



  
   
Starting dSIPRouter
=====================
  
  .. toctree::
   :maxdepth: 2
   
   starting.rst
  
  
  
-->Login 

Open a broswer and go to `http://[ip address of your server]:5000`

The username and the dynamically generated password is displayed after the install



-->Starting dSIPRouter:

./dsiprouter.sh start



-->Stopping dSIPRouter:

./dsiprouter.sh stop



-->Restarting dSIPRouter:

./dsiprouter.sh restart



-->Run At Startup:

Put this line in /etc/rc.local


<your directory>/dsiprouter.sh start

* We will provide a systemctl startup/stop script in the near future

-->Uninstall

./dsiprouter.sh uninstall


Configuring dSIPRouter
======================
  
  .. toctree::
   :maxdepth: 2
   
   configuring.rst
  
   
Implementing Use Cases
======================
  
  .. toctree::
   :maxdepth: 2
   
   use-cases.rst
  
       
Troubleshooting
===============
   
  .. toctree::
   :maxdepth: 2
   
   troubleshooting.rst
   
  
   
   







