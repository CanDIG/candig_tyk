# candig_tyk
Middleware, documentation, and config settings for running Tyk as part of the CanDIG infrastructure

Documentation here will be for the configuration of Tyk within the specific context of CanDIG infrastructure
See https://tyk.io/docs/ for general information about Tyk gateway installation

## Installing pre-auth middleware
authMiddleware.js is intended to run as a pre-auth middleware on the tyk-gateway. It can be installed by downloading the .js file and saving it in the installed tyk directory e.g. ../tyk-gateway/middleware

The middleware can be activated for an API by using the Dashboard to edit the 'RAW API definition'. Under "custom middleware", change the "pre" definition to the following:
```
      "pre": [
        {
          "name": "authMiddleware",
          "path": "middleware/authMiddleware.js",
          "require_session": false
        }
      ],
```
