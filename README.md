# MERLOT specific plugins for the [Omejdn server](https://github.com/Fraunhofer-AISEC/omejdn-server)
This repository contains plugins that are used within the MERLOT project to achieve the usage of Omejdn as a DAPS authentication server for use with EDC connectors.

**Warning: The plugins in this repository may contain endpoints that are not secured by any means of authentication. These endpoints may be dangerous in production and must never be exposed to the Internet!**

## Structure

    ├── plugins
    │   ├── connector_api    # basic API plugin that adds (unauthorized!) endpoints for easy creation of a new DAPS certificate
    ├── scripts              # scripts internally used by the plugins