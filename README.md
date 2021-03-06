# Bondy
## A Distributed WAMP Router and API Gateway

Bondy is an open source, distributed, scaleable and robust networking platform for microservices and IoT applications written in Erlang.

It implements the open Web Application Messaging Protocol (WAMP) offering both Publish and Subscribe (PubSub) and routed Remote Procedure Calls (RPC) comunication patterns. It also provides a built-in HTTP/REST API Gateway.

Bondy is Apache2 licensed.

## Notice for Contributors

Active development is done at Bondy's Gitlab repository (https://gitlab.com/leapsight/bondy).

If you are reading this file at Bondy's Github repository, notice that this is a mirror that is unidirectionally synced to Gitlab's i.e. no commits or PRs done in Github will be synced to the main repository.

So if you would like to fork and/or contribute please do it at Gitlab.

## Documentation

For our work-in-progress documentation go to [http://docs.getbondy.io](http://docs.getbondy.io).

## Quick Start

Bondy requires Erlang/OTP 21.2 or higher and `rebar3`.

The fastest way to get going is to have the [rebar3_run](https://www.rebar3.org/docs/using-available-plugins#section-run-release) plugin.

### Run a first node

We will start a node named `bondy1@127.0.0.1` which uses the following variables from the config file (`config/test1/vars.config`).

|Transport|Description|Port|
|---|---|---|
|HTTP|REST API GATEWAY|18080|
|HTTP|REST API GATEWAY|18083|
|HTTP|REST Admin API|18081|
|HTTPS|REST Admin API|18084|
|Websockets|WAMP|18080|
|TCP|WAMP Raw Socket|18082|
|TLS|WAMP Raw Socket|18085|


```bash
rebar3 as test1 run
```

#### Create a Realm

WAMP is a session-based protocol. Each session belongs to a Realm.

```curl
curl -X "POST" "http://localhost:18081/realms/" \
     -H 'Content-Type: application/json; charset=utf-8' \
     -H 'Accept: application/json; charset=utf-8' \
     -d $'{
  "uri": "com.myrealm",
  "description": "My First Realm"
}'
```

#### Disable Security

We will disable security to avoid setting up credentials at this moment.

```curl
curl -X "DELETE" "http://localhost:18081/realms/com.myrealm/security_enabled" \
     -H 'Content-Type: application/json; charset=utf-8' \
     -H 'Accept: application/json; charset=utf-8'
```

#### Run a second node

We start a second node named `bondy2@127.0.0.1` which uses the following variables from the config file (`config/test2/vars.config`).

|Transport|Description|Port|
|---|---|---|
|HTTP|REST API GATEWAY|18180|
|HTTP|REST API GATEWAY|18183|
|HTTP|REST Admin API|18181|
|HTTPS|REST Admin API|18184|
|Websockets|WAMP|18180|
|TCP|WAMP Raw Socket|18182|
|TLS|WAMP Raw Socket|18185|

```bash
rebar3 as test2 run
```

#### Connect the nodes

In `bondy1@127.0.0.1` erlang's shell type:

```erlang
(bondy2@127.0.0.1)1> bondy_peer_service:join('bondy2@127.0.0.1').
```

All new state changes will be propagated in real-time through gossip.
One minute after joining the cluster, the Active Anti-entropy service will trigger an exchange after which the Realm we have created in `bondy1@127.0.0.1` will have been replicated to `bondy2@127.0.0.1`.

## Important links

* [http://docs.getbondy.io](http://docs.getbondy.io).
* Read more about [WAMP](wamp-proto.org)
* #bondy on slack (coming soon!)
* [Follow us on twitter @leapsight](https://twitter.com/leapsight)
