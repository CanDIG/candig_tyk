
************
Installation
************

Modified from the ga4gh documentation files. These steps outline a production deployment of the CanDIG ga4gh-server running on Apache and mod_wsgi. The configuration files included here are also modified to support the CanDIG architecture which includes Tyk and Keycloak.

--------------------
Deployment on Apache
--------------------

Instructions modified from original Ubuntu/Debian to fit CentOS7

First, we install some basic pre-requisite packages:

.. code-block:: bash

  sudo yum install python-devel python-virtualenv zlib-devel libxslt-devel libffi-devel openssl-devel libcurl-devel

Install Apache and mod_wsgi, and enable mod_wsgi:

.. code-block:: bash

  sudo yum install httpd
  sudo yum install mod_wsgi

Create the Python egg cache directory, and make it writable by
the ``apache`` user:

.. code-block:: bash

  sudo mkdir /var/cache/httpd/python-egg-cache
  sudo chown apache:apache /var/cache/httpd/python-egg-cache/

Create a directory to hold the GA4GH server code, configuration
and data. For convenience, we make this owned by the current user
(but make sure all the files are world-readable).:

.. code-block:: bash

  sudo mkdir /srv/ga4gh
  sudo chown $USER /srv/ga4gh
  cd /srv/ga4gh

Make a virtualenv, and install the ga4gh package with an empty repo:

.. code-block:: bash

  virtualenv ga4gh-server-env
  cd ga4gh-server-env
  source bin/activate
  pip install --upgrade pip setuptools
  pip install git+https://github.com/CanDIG/ga4gh-schemas.git@authz#egg=ga4gh_schemas
  pip install git+https://github.com/CanDIG/ga4gh-client.git@authz#egg=ga4gh_client
  pip install git+https://github.com/CanDIG/ga4gh-server.git@authz#egg=ga4gh_server
  pip install git+https://github.com/CanDIG/PROFYLE_ingest.git@authz#egg=PROFYLE_ingest
  mkdir -p /srv/ga4gh/ga4gh-server-env/ga4gh/server/templates
  touch /srv/ga4gh/ga4gh-server-env/ga4gh/server/templates/initial_peers.txt
  mkdir /srv/ga4gh/ga4gh-server-env/ga4gh-example-data
  ga4gh_repo init ga4gh-example-data/registry.db

Create the WSGI file at ``/srv/ga4gh/application.wsgi`` and write the following
contents:

.. code-block:: python

  from ga4gh.server.frontend import app as application
  import ga4gh.server.frontend as frontend
  frontend.configure(configFile = "/srv/ga4gh/config.py", baseConfig = "BaseConfig")

Create the configuration file at ``/srv/ga4gh/config.py``, and write the
following contents (edit for http and server addresses/paths):

.. code-block:: python

    # Production config
    DATA_SOURCE = '/srv/ga4gh/ga4gh-server-env/ga4gh-example-data/registry.db'
    REQUEST_VALIDATION = True
    INITIAL_PEERS = '/srv/ga4gh/ga4gh-server-env/ga4gh/server/templates/initial_peers.txt'

    # Tyk settings 
    TYK_ENABLED = True
    TYK_SERVER = 'http(s)://<tyk server address>'
    TYK_LISTEN_PATH = '<tyk listen path>'

    # Keycloak settings with redirection through tyk
    KC_REALM = '<key cloak realm>'
    KC_SERVER = 'http(s)://<keycloak server address>'
    KC_SCOPE = 'openid+email'
    KC_RTYPE = 'code'
    KC_CLIENT_ID = '<keycloak client>'
    KC_RMODE = 'form_post'
    KC_REDIRECT = TYK_SERVER+TYK_LISTEN_PATH+'/login_oidc'
    KC_LOGIN_REDIRECT = '/auth/realms/{0}/protocol/openid-connect/auth?scope={1}&response_type={2}&client_id={3}&response_mode{4}&redirect_uri={5}'.format(KC_REALM, KC_SCOPE, KC_RTYPE, KC_CLIENT_ID, KC_RMODE, KC_REDIRECT)

Note that it is expected that the user running the server, `apache`, 
have write and read access to the directories containing data files.

(Many more configuration options are available --- see the :ref:`configuration`
section for a detailed discussion on the server configuration and input data.)

Configure Apache. Note that these instructions are for Apache 2.4 or greater.
Edit the file ``/etc/httpd/conf/httpd.conf``
and insert the following contents towards the end of the file
(*within* the ``<VirtualHost:80>...</VirtualHost>`` block):

.. code-block:: apacheconf

    WSGIDaemonProcess ga4gh \
        processes=10 threads=1 \
        python-path=/srv/ga4gh/ga4gh-server-env/lib/python2.7/site-packages \
        python-eggs=/var/cache/apache2/python-egg-cache
    WSGIScriptAlias /ga4gh /srv/ga4gh/application.wsgi

    <Directory /srv/ga4gh>
        WSGIProcessGroup ga4gh
        WSGIApplicationGroup %{GLOBAL}
        WSGIPassAuthorization On
        Require all granted
    </Directory>

.. warning::

    Be sure to keep the number of threads limited to 1 in the WSGIDaemonProcess
    setting. Performance tuning should be done using the processes setting.

The instructions for configuring Apache 2.2 (on Ubuntu 14.04) are the same as
above with thee following exceptions:

You need to edit
``/etc/apache2/sites-enabled/000-default``

instead of
``/etc/apache2/sites-enabled/000-default.conf``

And while in that file, you need to set permissions for the directory to

.. code-block:: apacheconf

    Allow from all

instead of

.. code-block:: apacheconf

    Require all granted



Now restart Apache:

.. code-block:: bash

  sudo service httpd restart

Note: Ideally the Apache server should be configured for ssl and port 443. Documentation in progress.