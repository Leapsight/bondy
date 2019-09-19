# CHANGELOG

## Develop

### Added

- Added a controlled phased startup process
  - Bondy now starts in phases allowing to block on several steps using configuration parameters. The main benefit is to avoid starting up the WAMP client socket listeners before serveral subsystems have finish initialisation and/or some processes have been completed.
    - `startup.wait_for_store_partitions` - controls whether to block further stages until all db partitions have been initialised, this includes loading all data into those entities stored in ram and disk. Default is `on`.
    - `startup.wait_for_store_hashtrees` - defines whether Bondy will wait for the db hashtrees to be built before continuing with initialisation. Default is `on`.
    - `startup.wait_for_store_aae_exchange` - Defines whether Bondy will wait for the first active anti-entropy exchange to be finished before continuing with initialisation. These only works if Bondy is part of a cluster i.e. when Peer Discovery and Automatic Cluster join is enabled.
  - The Bondy Admin HTTP API listeners are started as soon as the store partitions and other subsystems are initilised. This allows for liveness probes to be able to check on Bondy and/or admin users to inspect and/or operate while the other phases are running.

### Fixed

- Several fixes to Security Configuration file format
  - `sources.usernames` now takes a string "any" of a list of usernames, including "anonymous"
  - `grants.roles` now takes a string "any" of a list of rolenames, including "anonymous"

## 0.8.6

- First implementation of Peer Discovery and Automatic Cluster join.
  - Implementation of DNS srv based discovery tested to work with Kubernetes DNS
- Finished Bondy Broker schema specification
- Added authorization controls for all WAMP verbs (register, unregister, call, cancel, publish, subscribe and unsubscribe). Authorization is managed by the existing Security subsystem which now can be configured using JSON files defined in the bondy.conf file (in addition to the WAMP and HTTP/REST APIs).
- Fixed WAMPRA (with salted password) authentication method.
  - This requires a rehash of the existing passwords. If you are migrating from an existing Bondy installation, the migration occurs lazily on the new user login (as we need the user to provide the password for Bondy to be able to rehash, as Bondy never stores clear text passwords).
- Refactoring of configuration via bondy.conf
  - Removed legacy config options,
  - Renamed a few a config options and introduced new ones to support static configuration via JSON files and new features like Peer Discovery and Automatic Cluster join.

## 0.8.2

- Migration to OTP 21.3 or higher.
- Upgraded all dependencies to support OTP 21

## 0.8.1

This version includes a complete redesign of event management and instrumentation.
The new `bondy_event_manager` is now the way for the different subsystems to asynchronously publish events (notifications) and offload all instrumentation to event handlers:

- `bondy_promethues` is an event handler that implements all promethues instrumentation
- `bondy_wamp_meta_events` is an event handler that selectively re-published bondy events to WAMP Meta events.

### New Modules

- `bondy_event_manager` implements a form of supervised handlers similar to lager (logging library), by spawning a "watcher" processes per handler (module) under a supervision tree and restarting it when it crashes.

- `bondy_alarm_handler` replaces sasl’s default alarm_handler.

### Deprecated Modules

`bondy_stats` containing legacy exometer instrumentation was removed.

## 0.8.0

This version introduces an incompatibility with previous versions data storage. If you want to upgrade an existing installation you will need to use the bondy_backup module's functions or the Admin Backup API.

- Upgrade to plum_db 0.2.0 which introduces prefix types to determine which storage type to use with the following types supported: ram (ets-based storage), disk (leveledb) and ram_disk(ets and leveldb).
    - Registry uses `ram` storage type
    - All security resources use `ram_disk` storage type
    - Api Gateway (specs) and OAuth2 tokens use `disk` storage type
- Handling of migration in bondy_backup. To migrate from v0.7.1 perform a backup on Bondy v0.7.1 and then restore it on Bondy v0.7.2.

## 0.7.1
- New Trie data structure for bondy_registry
    - Bondy now uses Leapsight's `art` library to implement the registry index structure use to match RPC calls and PubSub subscriptions. `art`  provides a single-writter, multi-reader Radix Trie following the Adaptive Radix Tree algorithm. The implementation uses one gen_server and one ets table per trie and currently supports WAMP `exact` and `prefix` matching strategies. `wildcard` matching support is on its way.
- Internal wamp subscriptions
    - We have implemented a first version of an internal WAMP subscription so that Bondy internally can subscribe to WAMP events. This is done through new functions in bondy_broker and the new module bondy_broker_events
- OAuth 2 Security
    - Major changes to security subsytem including harmonisation of APIs, deduplication and bug fixes.
    - Use new internal wamp subscriptions to avoid coupling Bondy Security with Bondy API Gateway & OAuth.
        - Bondy Security modules publishe wamp events on entity actions e.g. user creation, deletion, etc.
        - Bondy API Gateway modules and bondy_api_gateway_client subscribe to the user delete events to cleanup OAuth tokens
    - Fixed a bug where internal security operations will not trigger token revocation.
        - Bondy API Gateway modules, i.e. are now implemented by calling Bondy Security modules e.g. bondy_security_user instead of calling bondy_security (former Basho Riak Core Security) directly. This will help in the refactoring of bondy_security and in addition all event publishing is centralised in bondy_security_user.
        - Implemented additional index for tokens to enable deletion of all users’ tokens
        - Added two db maintenance functions to (i) remove dangling tokens and (ii) rebuild the indices on an existing db
    - Added additional Internal wamp events to subsystems e.g. bondy_realm and bondy_backup

## 0.7.0

- Clustering
    - Completion of clustering implementation using partisan library (at the moment supporting the default peer service only, hyparview to be considered in the future)
    - bondy_router can now route WAMP messages across nodes. The internal load balancer prefers local callees by default, only when a local callee is not found for a procedure the invocation is routed to another node. Load balancer state is local and not replicated. Future global load balancing strategies based on ant-colony optimisation to be considered in the future.
    - `bondy-admin` (bondy_cli) implementation of cluster management commands (join, leave, kick-out and members)
- Storage and Replication
    - new storage based on plum_db which
        - uses lasp-lang/plumtree and lasp-lang/partisan to support data replication
        - provides more concurrency than plumtree and removes the capacity limitation imposed by the use of dets
- API Gateway
    - API Specs are replicated using plum_db. A single bondy_api_gateway gen_server process rebuilds the Cowboy dispatch table when API Spec updates are received from other nodes in the cluster (using plum_db pubsub capabilities)
- Registry
    - The registry entries are replicated using plum_db. This is not ideal as we are using disk for transient data but it is a temporary solution for replication and AAE, as we are planning to change the registry by a new implementation of a trie data structure at which point we might use plumtree and partisan directly avoiding storing to disk.
    - A single bondy_registry gen_server process rebuilds the in-memory indices when entry updates are received from other nodes in the cluster (using plum_db pubsub capabilities)
- bondy_backup
    - A new module that allows to backup the contents of the database to a file, and restore it.
    - Allows to migrate from previous versions that use plumtree (dets) to plum_db

## 0.6.6

- General
    - Removed unused modules
    - Minor error description fixes
    - Code tidy up
- Depencies
    - cowboy, hackney, jsx, sidejob, promethus, lager and other dependencies upgraded
- Oauth2
    - Revoke refresh_token
    - Added client_device_id optional parameter for token request which will generate an inde mapping a Username/ClientDeviceId to a refresh_token to enabled revoking token by Username/ClientDeviceId.
    - JWT.iat property using unix erlang:system_time/1 instead of erlang:monotonic_time/1 (as users might want to use this property)
    - Token expiration is now configured via cuttlefish
- API Gateway
    - JSON errors no longer include the status_code property (this was redundant with HTTP Status Code and were sometimes inconsistent)
    - Added http_method in forward actions to enable transforming the upstream HTTP request method e.g. a GET can be transformed to a POST
    - API Gateway Spec now allows to use a mop expression for WAMP procedure URIs
    - New mops functions: min, max and nth on lists (equivalent to the lists module functions)
- Testing
    - Fixed mops suite bugs
    - Added oauth2 refresh_token CRUD test case, covering creation, refresh and revoke by token and by user/client_device_id

## 0.6.3

* Upgraded Cowboy dependency to 2.1.0
* Upgraded promethues_cowboy to latest and added cowboy metrics to prometheus endpoint
* Minor changes in function naming for enhanced understanding
* Minor fixes in options and defaults