%% -----------------------------------------------------------------------------
%% Copyright (C) Ngineo Limited 2015 - 2016. All rights reserved.
%% -----------------------------------------------------------------------------

-module(juno_rpc).
-include_lib("wamp/include/wamp.hrl").

-define(DEFAULT_LIMIT, 1000).
-define(INVOCATION_QUEUE, invocations).

-export([match_registrations/1]).
-export([match_registrations/2]).
-export([match_registrations/3]).
-export([register/3]).
-export([registrations/1]).
-export([registrations/2]).
-export([registrations/3]).
-export([unregister_all/1]).
-export([unregister/2]).
-export([call/6]).
%% -export([callees/2]).
%% -export([count_callees/2]).
%% -export([count_registrations/2]).
%% -export([lookup_registration/2]).
%% -export([fetch_registration/2]). % wamp.registration.get





%% =============================================================================
%% API
%% =============================================================================

%% -----------------------------------------------------------------------------
%% @doc
%% If the registration already exists, it fails with a
%% 'procedure_already_exists' error.
%% @end
%% -----------------------------------------------------------------------------
-spec register(uri(), map(), juno_context:context()) -> {ok, id()}.
register(ProcUri, Options, Ctxt) ->
    juno_registry:add(registration, ProcUri, Options, Ctxt).


%% -----------------------------------------------------------------------------
%% @doc
%% If the registration does not exist, it fails with a 'no_such_registration'
%% error.
%% @end
%% -----------------------------------------------------------------------------
-spec unregister(id(), juno_context:context()) -> ok.
unregister(RegId, Ctxt) ->
    juno_registry:remove(registration, RegId, Ctxt).


%% -----------------------------------------------------------------------------
%% @doc
%% @end
%% -----------------------------------------------------------------------------
unregister_all(Ctxt) ->
    juno_registry:remove_all(registration, Ctxt).


%% -----------------------------------------------------------------------------
%% @doc
%% Throws not_authorized
%% @end
%% -----------------------------------------------------------------------------
-spec call(id(), uri(), map(), list(), map(), juno_context:context()) ->
    ok.
call(ReqId, <<"wamp.registration.list">>, _Opts, _Args, _Payload, Ctxt) ->
    Res = #{
        <<"exact">> => [], % @TODO
        <<"prefix">> => [], % @TODO
        <<"wildcard">> => [] % @TODO
    },
    M = wamp_message:result(ReqId, #{}, [], Res, Ctxt),
    juno:send(M, Ctxt);

call(ReqId, <<"wamp.registration.lookup">>, _Opts, _Args, _Payload, Ctxt) ->
    %% @TODO
    Res = #{},
    M = wamp_message:result(ReqId, #{}, [], Res, Ctxt),
    juno:send(M, Ctxt);

call(ReqId, <<"wamp.registration.match">>, _Opts, _Args, _Payload, Ctxt) ->
    %% @TODO
    Res = #{},
    M = wamp_message:result(ReqId, #{}, [], Res, Ctxt),
    juno:send(M, Ctxt);

call(ReqId, <<"wamp.registration.get">>, _Opts, _Args, _Payload, Ctxt) ->
    %% @TODO
    Res = #{},
    M = wamp_message:result(ReqId, #{}, [], Res, Ctxt),
    juno:send(M, Ctxt);

call(ReqId, <<"wamp.registration.list_callees">>, _Opts, _Args, _Payload, Ctxt) ->
    %% @TODO
    Res = #{},
    M = wamp_message:result(ReqId, #{}, [], Res, Ctxt),
    juno:send(M, Ctxt);

call(ReqId, <<"wamp.registration.count_callees">>, _Opts, _Args, _Payload, Ctxt) ->
    %% @TODO
    Res = #{count => 0},
    M = wamp_message:result(ReqId, #{}, [], Res, Ctxt),
    juno:send(M, Ctxt);

call(_ReqId, ProcUri, Opts, Args, Payload, Ctxt) ->
    #{session_id := SessionId} = Ctxt,

    %% We asume that as with pubsub, the _Caller_ should not receive the
    %% invocation even if the _Caller_ is also a _Callee_ registered
    %% for that procedure.
    Regs = match_registrations(ProcUri, Ctxt, #{exclude => [SessionId]}),

    %% We will use the caller's {node, pid} to get back the result to him.
    Caller = #{
        caller_node => atom_to_list(node()),
        caller_pid => pid_to_list(juno_session:pid(SessionId))
    },
    Details = #{},

    Fun = fun
        ({_Sid, Pid, RegId}) ->
            Id = wamp_id:new(global),
            %% We enqueue the call request i.e. a form of promise.
            ok = tuplespace_queue:enqueue(
                ?INVOCATION_QUEUE,
                Caller,
                #{key => Id, timeout => timeout(Opts)}),
            Pid ! wamp_message:invocation(Id, RegId, Details, Args, Payload)
    end,
    send_invocations(Regs, Fun).


%% -----------------------------------------------------------------------------
%% @doc
%% Returns the list of registrations for the active session.
%%
%% When called with a juno:context() it is equivalent to calling
%% registrations/2 with the RealmUri and SessionId extracted from the Context.
%% @end
%% -----------------------------------------------------------------------------
-spec registrations(juno_context:context() | ets:continuation()) ->
    [juno_registry:entry()].
registrations(#{realm_uri := RealmUri, session_id := SessionId}) ->
    registrations(RealmUri, SessionId);
registrations(Cont) ->
    juno_registry:entries(Cont).



%% -----------------------------------------------------------------------------
%% @doc
%% Returns the complete list of registrations matching the RealmUri
%% and SessionId.
%%
%% Use {@link registrations/3} and {@link registrations/1} to limit the
%% number of registrations returned.
%% @end
%% -----------------------------------------------------------------------------
-spec registrations(RealmUri :: uri(), SessionId :: id()) ->
    [juno_registry:entry()].
registrations(RealmUri, SessionId) ->
    juno_registry:entries(registration, RealmUri, SessionId, infinity).


%% -----------------------------------------------------------------------------
%% @doc
%% Returns the complete list of registrations matching the RealmUri
%% and SessionId.
%%
%% Use {@link registrations/3} to limit the number of registrations returned.
%% @end
%% -----------------------------------------------------------------------------
-spec registrations(RealmUri :: uri(), SessionId :: id(), non_neg_integer()) ->
    {[juno_registry:entry()], Cont :: '$end_of_table' | term()}.
registrations(RealmUri, SessionId, Limit) ->
    juno_registry:entries(registration, RealmUri, SessionId, Limit).



%% -----------------------------------------------------------------------------
%% @doc
%% @end
%% -----------------------------------------------------------------------------
-spec match_registrations(uri(), juno_context:context()) ->
    {[juno_registry:entry()], ets:continuation()}
    | '$end_of_table'.
match_registrations(ProcUri, Ctxt) ->
    juno_registry:match(registration, ProcUri, Ctxt, #{limit => infinity}).


%% -----------------------------------------------------------------------------
%% @doc
%% @end
%% -----------------------------------------------------------------------------
-spec match_registrations(
    uri(), juno_context:context(), map()) ->
    {[juno_registry:entry()], ets:continuation()}
    | '$end_of_table'.
match_registrations(ProcUri, Ctxt, Opts) ->
    juno_registry:match(registration, ProcUri, Ctxt, Opts).


%% -----------------------------------------------------------------------------
%% @doc
%% @end
%% -----------------------------------------------------------------------------
-spec match_registrations(ets:continuation()) ->
    {[juno_registry:entry()], ets:continuation()} | '$end_of_table'.
match_registrations(Cont) ->
    ets:select(Cont).



%% =============================================================================
%% PRIVATE
%% =============================================================================



%% @private
timeout(#{timeout := T}) when is_integer(T), T > 0 ->
    T;
timeout(#{timeout := 0}) ->
    infinity;
timeout(_) ->
    juno_config:request_timeout().


%% @private
send_invocations('$end_of_table', _Fun) ->
    ok;

send_invocations({L, '$end_of_table'}, Fun) ->
    lists:foreach(Fun, L);

send_invocations({L, Cont}, Fun ) ->
    ok = lists:foreach(Fun, L),
    send_invocations(match_registrations(Cont), Fun).