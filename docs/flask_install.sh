  python3 -m venv candig-server-env
  cd candig-server-env
  source bin/activate
  pip install --upgrade pip setuptools
  pip install candig-server
  pip install candig-ingest
  touch access_list.txt
  mkdir /srv/candig/candig-server-env/candig-example-data
  candig_repo init candig-example-data/registry.db
  deactivate
