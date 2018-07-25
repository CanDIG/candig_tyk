
****************************************
Configuring Tyk for CanDIG Architecture:
****************************************

This document assumes that Tyk-gateway, Tyk-dashboard, Keycloak, and a CanDIG ga4gh-flask server (latest authz branch) have been properly installed. Most of the Tyk configuration here can be done using the dashboard. If the default Tyk installation instructions were followed, it can be logged into on port 3000.

Create API (Using Dashboard)
----------------------------
- System Management > API's > Add New API
- API Name: <new api>
- Listen path (create a name and strip trailing '/')
- Target URL: ga4gh-flask server to proxy to (can be a development or production version)
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
- Scroll down to 'Authenticate Mode' which should be OpenID Connect and register your Keycloak server as an issuer
- Issuer: http(s)://<keycloak_server_address>/auth/realms/<your CanDIG realm>
- Enter the desired client id and your new policy
- Update

Navigate to the Endpoint Designer tab. Add the following endpoint:
 
- [ GET ] [ login_oidc ] [ Ignore ] (for keycloak login redirects)
- Update

While on the API admin page, navigate to Advanced Configuration tab and scroll down to 'Config data' and add:

.. code-block:: bash

  {
    "keycloak_client": "<keycloak client id>",
    "keycloak_secret": "<keycloak client secret>",
    "keycloak_realm": "<keycloak realm on which client exists>",
    "keycloak_host": “http(s)://<keycloak server address>”,
    "tyk_host": "http(s)://<tyk server address>",
    "tyk_listen": "<tyk listen path>"
  }

Middleware
----------
Download and follow instructions @ https://github.com/CanDIG/candig_tyk

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
    TYK_LISTEN_PATH = '<tyk listen path>'

    # Keycloak settings with redirection through tyk
    KC_REALM = '<keycloak realm on which client exists>'
    KC_SERVER = 'http(s)://<keycloak server address>'
    KC_SCOPE = 'openid+email'
    KC_RTYPE = 'code'
    KC_CLIENT_ID = '<keycloak client id>'
    KC_RMODE = 'form_post'
    KC_REDIRECT = TYK_SERVER+TYK_LISTEN_PATH+'/login_oidc'
    KC_LOGIN_REDIRECT = '/auth/realms/{0}/protocol/openid-connect/auth?scope={1}&response_type={2}&client_id={3}&response_mode={4}&redirect_uri={5}'.format(
        KC_REALM, KC_SCOPE, KC_RTYPE, KC_CLIENT_ID, KC_RMODE, KC_REDIRECT
    )

If running a production version of the ga4gh flask server, ignore this and follow the setup instructions @ https://github.com/CanDIG/candig_tyk/blob/master/docs/flask_deployment.rst   

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
- ONLY valid redirect_url should be:
   - http(s)://<tyk server addresss>/<listen path>/login_oidc 
   - e.g. http://candig.bcgsc.ca/dev/login_oidc


- User Federation: Add new provider (e.g. ldap) and input directories / settings
- use edit mode: READONLY
- authentication type: none
- <enter ldap settings>


Authorization (current solution):

- Clients > Select Client > Roles > Create roles
- Enter role name as: '<project_name> : <access_level>' e.g. profyle:0 would be min access to the data (4 for max)

- Clients > Select Client > Mappers > Create
	- Protocol: openid-connect
	- User Client Role
	- <use selected client>
	- Multivalued: ON, type: STRING
	- Token Claim name: access_levels
	- Add to ID TOKEN: True and Add to Access TOKEN: True
