
****************************************
Configuring Apps for CanDIG-Tyk Architecture:
****************************************

This document assumes that Tyk-gateway, Tyk-dashboard, Keycloak, and a CanDIG ga4gh-flask server (latest master branch) have been properly installed. Most of the Tyk configuration here can be done using the dashboard. If the default Tyk installation instructions were followed, it can be logged into on port 3000.

Create API (Using Dashboard)
----------------------------
- System Management > API's > Add New API
- API Name: <new api>
- Listen path: create a name and strip trailing '/' (to use an empty path, set the listen path to exactly '/') 
- Target URL: deployed application server to proxy to
- Make sure strip listen path is checked
- Scroll down to Authentication mode: Select OpenID Connect (leave unconfigured for now)
- Save

Create Policy (Using Dashboard)
-------------------------------
- System Management > Policies > Add Policy
- Make sure 'Activate Policy' is selected
- Access Rights: Select the newly created API
- Trial period: Select 'do not expire key'
- Default rate limits/quotas
- Save


Configure API (Using Dashboard)
-------------------------------
Use your configured keycloak server as the identity provider for OIDC:

- System Management > API's > select your new API and EDIT

If you are setting up a federation network, you have to register your Peer Production Keycloak in the API.

**Add Host Production Keycloak**

- Scroll down to 'Authenticate Mode' which should be OpenID Connect and register your own Keycloak server as an issuer
- Issuer: http(s)://<keycloak_server_address>/auth/realms/<host CanDIG realm>
- Enter the desired client id and the policy created above
- Update

**Add Peer Production Keycloak**

- Scroll down to 'Authenticate Mode' which should be OpenID Connect and register your peer Keycloak server as an issuer
- Issuer: http(s)://<keycloak_server_address>/auth/realms/<peer CanDIG realm>
- Enter the desired client id and the policy created above
- Update

**Advanced Options:**

- Enter config data as JSON

.. code-block:: bash

  {
  "SESSION_ENDPOINTS": [
    "/",
    "/gene_search",
    "/patients_overview",
    "/sample_analysis",
    "/custom_visualization",
    "/api_info",
    "/serverinfo"
  ],
  "TYK_SERVER": "http(s)://<tyk server address>"
  }

Note: SESSION_ENDPOINTS is optional. If you would like to redirect all unauthenticated incoming requests to the login page, leave this variable undefined.

Middleware
----------
Download authMiddleware.js from this github repo (middleware/ directory)

The middleware can be activated for an API by using the Dashboard to edit the 'RAW API definition'. Under "custom middleware", change the "pre" definition to the following:

.. code-block:: bash

  "pre": [
    {
      "name": "authMiddleware",
      "path": "middleware/authMiddleware.js",
      "require_session": false
    }
  ],

SSL
---
Documentation in progress.

Configure Flask
---------------
If running a development version of the ga4gh flask server using the default Werkzeug, edit the serverconfig.py file as follows (note be sure to run server with '-c TykConfig':

.. code-block:: python

  class TykConfig(KeycloakOidConfig):

    TYK_ENABLED = True
    TYK_SERVER = 'http(s)://<tyk server address>'
    TYK_LISTEN_PATH = '</tyk listen path>' #note if using an empty path, set this to an empty string ('')
    ACCESS_LIST = '/path/to/acl.tsv'

If using uWSGI/nginx or Apache be sure to copy this to a separate config file

Authorization (Flask + ACL solution):

    After installing the flask application, use the "acl.tsv" in the root env directory to set access levels. Or create a new "acl.tsv" and make sure that the ACCESS_LIST server config variable points to it's full file path

example:

::

    issuer	username	PROFYLE	TF4CN	mock1	mock2

    https://candigauth.bcgsc.ca/auth/realms/candig	userA	4	4	4	4
    https://candigauth.bcgsc.ca/auth/realms/candig	userB	4		0	1

    https://candigauth.uhnresearch.ca/auth/realms/CanDIG	userC	4	3	2	1
    https://candigauth.uhnresearch.ca/auth/realms/CanDIG	userD			4	4

    https://candigauth.calculquebec.ca/auth/realms/candig	userE	4	4		4
    https://candigauth.calculquebec.ca/auth/realms/candig	userF	0	0	4	4

Configure Keycloak
------------------
Keycloak Config Details:


Basic keycloak setup using admin console:

- Default interface port is 8080
- Log in as admin there and if you haven't yet, create new Realm (e.g. candig)
- If you haven't yet, create a new client (e.g. <your_location>_candig) with client protocol 'openid-connect'

Navigate to Clients and select your new client and edit:

- client protocol: openid-connect
- access: confidential
- all access flows enabled
- ONLY valid redirect_url should be the virtual login endpoint:
   - http(s)://<tyk server>/auth/login
   - e.g. http://candig.bcgsc.ca/auth/login


- User Federation: Add new provider (e.g. ldap) and input directories / settings
- use edit mode: READONLY
- authentication type: none
- <enter ldap settings>
