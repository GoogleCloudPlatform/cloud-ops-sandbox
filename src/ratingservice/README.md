# Rating Service

Rating Service is a microservice developed in Python3 to run on App Engine Standard Environment. It allows to place a rating for an abstract entity in range from 1 to 5 and to get a rating of an entity. Entities are identified using a non-empty string with up to 16 bytes. In order for the service to run correct rating all the time, placed ratings should be processed by calling a dedicated API.

The service is deployed to GAE Standard Environment and stores rating data in the dedicated Postgres DB that is managed by Cloud SQL.

In order to be deployed to the named service, Google App Engine requires a "default" service to be defined. A simple pong Web application is provided to be deployed as the default service.
The pong application returns "pong" string on `GET /` request.
