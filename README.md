# POSSIBLE-X specific plugins for the [Omejdn server](https://github.com/Fraunhofer-AISEC/omejdn-server)

This repository contains plugins that are used within the POSSIBLE-X project to achieve the usage of Omejdn as a DAPS
authentication server for use with EDC connectors. It is a fork of the MERLOT
project's [Omejdn plugins](https://github.com/merlot-education/omejdn-plugins)
repository and adds the possibility to retrieve and delete certificates.

**Warning: The plugins in this repository may contain endpoints that are not secured by any means of authentication.
These endpoints may be dangerous in production and must never be exposed to the Internet!**

## Structure

    ├── plugins
    │   ├── connector_api    # basic API plugin that adds (unauthorized!) endpoints for easy creation/deletion/retrieval of a new DAPS certificate
    ├── scripts              # scripts internally used by the plugins

## Endpoints

The following endpoints are made available by the connector API plugin:

| Endpoint                                                           | Description                                                                                                                                                                                         |
|--------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| POST /api/v1/connectors                                            | Given a payload containing a client_name and did, generate a new certificate and onboard it to the DAPS service. Returns the certificate details.                                                   |
| DELETE /api/v1/connectors/:client_id                               | Given a client_id, delete the corresponding entry from the DAPS server.                                                                                                                             |
| GET /api/v1/connectors/:client_id                                  | Returns the stored attributes corresponding to that client_id                                                                                                                                       |
| GET /api/v1/connectors?client_name=<some name>&client_id=<some id> | Given a single client_id or client_name or a list of one of them, return the corresponding stored attributes. The client_id takes prevalence over client_name in the request if both are specified. |

