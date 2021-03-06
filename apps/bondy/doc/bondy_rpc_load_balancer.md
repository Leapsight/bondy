

# Module bondy_rpc_load_balancer #
* [Description](#description)
* [Data Types](#types)
* [Function Index](#index)
* [Function Details](#functions)

This module implements a distributed load balancer, providing the
different load balancing strategies used by bondy_dealer to choose
the Callee and Procedure to invoke when handling a WAMP Call.

<a name="description"></a>

## Description ##

At the moment the load balancing state is local and not replicated
across the nodes in the cluster. However, each node has access to a local
replica of the global registry and thus can load balance between local and
remote Callees.

In the future we will explore implementing distributed load balancing
algorithms such as Ant Colony, Particle Swarm Optimization and Biased Random
Sampling [See references](https://pdfs.semanticscholar.org/b9a9/52ed1b8bfae2e976b5c0106e894bd4c41d89.pdf)
<a name="types"></a>

## Data Types ##




### <a name="type-continuation">continuation()</a> ###


__abstract datatype__: `continuation()`




### <a name="type-entries">entries()</a> ###


<pre><code>
entries() = [<a href="bondy_registry_entry.md#type-t">bondy_registry_entry:t()</a>]
</code></pre>




### <a name="type-opts">opts()</a> ###


<pre><code>
opts() = #{strategy =&gt; <a href="#type-strategy">strategy()</a>, force_locality =&gt; boolean()}
</code></pre>




### <a name="type-strategy">strategy()</a> ###


<pre><code>
strategy() = single | first | last | random | round_robin
</code></pre>

<a name="index"></a>

## Function Index ##


<table width="100%" border="1" cellspacing="0" cellpadding="2" summary="function index"><tr><td valign="top"><a href="#get-2">get/2</a></td><td></td></tr><tr><td valign="top"><a href="#iterate-1">iterate/1</a></td><td></td></tr><tr><td valign="top"><a href="#iterate-2">iterate/2</a></td><td></td></tr></table>


<a name="functions"></a>

## Function Details ##

<a name="get-2"></a>

### get/2 ###

<pre><code>
get(Entries::<a href="#type-entries">entries()</a>, Opts::<a href="#type-opts">opts()</a>) -&gt; <a href="bondy_registry_entry.md#type-t">bondy_registry_entry:t()</a> | {error, noproc}
</code></pre>
<br />

<a name="iterate-1"></a>

### iterate/1 ###

<pre><code>
iterate(X1::<a href="#type-continuation">continuation()</a>) -&gt; {<a href="bondy_registry_entry.md#type-t">bondy_registry_entry:t()</a>, <a href="#type-continuation">continuation()</a>} | {error, noproc}
</code></pre>
<br />

<a name="iterate-2"></a>

### iterate/2 ###

<pre><code>
iterate(Entries0::<a href="#type-entries">entries()</a>, Opts0::<a href="#type-opts">opts()</a>) -&gt; {<a href="bondy_registry_entry.md#type-t">bondy_registry_entry:t()</a>, <a href="#type-continuation">continuation()</a>} | $end_of_table
</code></pre>
<br />

