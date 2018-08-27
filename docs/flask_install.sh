  virtualenv ga4gh-server-env
  cd ga4gh-server-env
  source bin/activate
  pip install --upgrade pip setuptools
  pip install git+https://github.com/CanDIG/ga4gh-schemas.git@authz#egg=ga4gh_schemas
  pip install git+https://github.com/CanDIG/ga4gh-client.git@authz#egg=ga4gh_client
  pip install git+https://github.com/CanDIG/ga4gh-server.git@master#egg=ga4gh_server
  pip install git+https://github.com/CanDIG/PROFYLE_ingest.git@authz#egg=PROFYLE_ingest
  mkdir -p /srv/ga4gh/ga4gh-server-env/ga4gh/server/templates
  touch /srv/ga4gh/ga4gh-server-env/ga4gh/server/templates/initial_peers.txt
  mkdir /srv/ga4gh/ga4gh-server-env/ga4gh-example-data
  ga4gh_repo init ga4gh-example-data/registry.db
  deactivate