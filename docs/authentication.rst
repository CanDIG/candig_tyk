
****************************************
Configuring CanDIG-Tyk Authentication API:
****************************************

This document assumes that Tyk-gateway, Tyk-dashboard, Keycloak, and a CanDIG ga4gh-flask server (latest master branch) have been properly installed. Most of the Tyk configuration here can be done using the dashboard. If the default Tyk installation instructions were followed, it can be logged into on port 3000.

Create + Configure API (Using Dashboard)
----------------------------

**Core Settings:**

- System Management > API's > Add New API
- API Name: Authentication
- Listen path: /auth/
- Target URL: <tyk-server>/auth/login (forwards on to login endpoint)
- Uncheck strip listen path
- Scroll down to Authentication mode: Select Open(Keyless)
- Save

**Endpoint Designer:**

Add the following endpoints (virtual.js code found in this repo in middleware/):

- Method: GET, Relative Path: login, Plugins: Virtual Endpoint

  JS function to call: loginHandler

  Choose inline and paste in virtualLogin.js code
  OR Choose file and enter middleware/virtualLogin.js after exporting to installed directory

- Method: GET, Relative Path: logout, Plugins: Virtual Endpoint

  JS function to call: logoutHandler

  Choose inline and paste in virtualLogout.js code
  OR Choose file and enter middleware/virtualLogout.js after exporting to installed directory

- Method: POST, Relative Path: token, Plugins: Virtual Endpoint

  JS function to call: tokenHandler

  Choose inline and paste in virtualToken.js code
  OR Choose file and enter middleware/virtualToken.js after exporting to installed directory

**Advanced Options:**

- Enter config data as JSON

.. code-block:: bash

    {
      "KC_RTYPE": "code",
      "KC_REALM": "<realm-name>",
      "KC_CLIENT_ID": "<client-id>",
      "KC_SERVER": "http(s)://<kc-server>",
      "KC_SCOPE": "openid+email",
      "KC_RMODE": "query",
      "USE_SSL": false,
      "KC_SECRET": "<kc-secret>",
      "TYK_SERVER": "http(s)://<tyk-server>",
      "MAX_TOKEN_AGE": 43200
    }