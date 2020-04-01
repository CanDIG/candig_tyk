
************
Installation
************

Modified from the ga4gh documentation files. These steps outline a production deployment of the CanDIG candig-server running on Apache and mod_wsgi. The configuration files included here are also modified to support the CanDIG architecture which includes Tyk and Keycloak.

Please note that you need to have python 3.6.x available to install the candig-server successfully.

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

Create a directory to hold the candig-server code, configuration
and data. For convenience, we make this owned by the current user
(but make sure all the files are world-readable).:

.. code-block:: bash

  sudo mkdir /srv/candig
  sudo chown $USER /srv/candig
  cd /srv/candig

Download and run the flask package basic install script (Note: if reinstalling the flask package, first delete your candig-server-env directory) :

.. code-block:: bash

  wget https://raw.githubusercontent.com/CanDIG/candig_tyk/master/docs/flask_install.sh
  ./flask_install.sh

Create the WSGI file at ``/srv/candig/application.wsgi`` and write the following
contents:

.. code-block:: python

  from candig.server.frontend import app as application
  import candig.server.frontend as frontend
  frontend.configure(configFile = "/srv/candig/config.py", baseConfig = "BaseConfig")

Create the configuration file at ``/srv/candig/config.py``, and write the
following contents (edit for http and server addresses/paths):

.. code-block:: python

    # Production config
    DATA_SOURCE = '/srv/candig/candig-server-env/candig-example-data/registry.db'
    REQUEST_VALIDATION = True
    ACCESS_LIST = '/srv/candig/candig-server-env/access_list.txt'

    # Tyk settings 
    TYK_ENABLED = True
    TYK_SERVER = 'http(s)://<tyk server address>'
    TYK_LISTEN_PATH = '<tyk listen path>'


Note that it is expected that the user running the server, `apache`, 
have write and read access to the directories containing data files.

(Many more configuration options are available --- see the :ref:`configuration`
section for a detailed discussion on the server configuration and input data.)

Configure Apache. Note that these instructions are for Apache 2.4 or greater.
Edit the file ``/etc/httpd/conf/httpd.conf``
and insert the following contents towards the end of the file
(*within* the ``<VirtualHost:80>...</VirtualHost>`` block):

.. code-block:: apacheconf

    WSGIDaemonProcess candig \
        processes=10 threads=1 \
        python-path=/srv/candig/candig-server-env/lib/python2.7/site-packages \
        python-eggs=/var/cache/apache2/python-egg-cache
    WSGIScriptAlias / /srv/candig/application.wsgi

    <Directory /srv/candig>
        WSGIProcessGroup candig
        WSGIApplicationGroup %{GLOBAL}
        WSGIPassAuthorization On
        Require all granted
    </Directory>

.. warning::

    Be sure to keep the number of threads limited to 1 in the WSGIDaemonProcess
    setting. Performance tuning should be done using the processes setting.
    If using Apache webserver WSGIScriptAlias URL-path must be '/'.

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
