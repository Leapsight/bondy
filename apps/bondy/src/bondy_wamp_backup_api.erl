%% =============================================================================
%%  bondy_wamp_backup_api.erl -
%%
%%  Copyright (c) 2016-2021 Leapsight. All rights reserved.
%%
%%  Licensed under the Apache License, Version 2.0 (the "License");
%%  you may not use this file except in compliance with the License.
%%  You may obtain a copy of the License at
%%
%%     http://www.apache.org/licenses/LICENSE-2.0
%%
%%  Unless required by applicable law or agreed to in writing, software
%%  distributed under the License is distributed on an "AS IS" BASIS,
%%  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%%  See the License for the specific language governing permissions and
%%  limitations under the License.
%% =============================================================================


%% -----------------------------------------------------------------------------
%% @doc
%% @end
%% -----------------------------------------------------------------------------
-module(bondy_wamp_backup_api).
-include_lib("wamp/include/wamp.hrl").
-include("bondy.hrl").
-include("bondy_uris.hrl").

-export([handle_call/2]).



%% =============================================================================
%% API
%% =============================================================================



%% -----------------------------------------------------------------------------
%% @doc
%% @end
%% -----------------------------------------------------------------------------
-spec handle_call(M :: wamp_message:call(), Ctxt :: bony_context:t()) -> ok.

handle_call(M, Ctxt) ->
    PeerId = bondy_context:peer_id(Ctxt),

    try
        Reply = do_handle(M, Ctxt),
        bondy:send(PeerId, Reply)
    catch
        _:Reason ->
            %% We catch any exception from do_handle and turn it
            %% into a WAMP Error
            Error = bondy_wamp_utils:maybe_error({error, Reason}, M),
            bondy:send(PeerId, Error)
    end.



%% =============================================================================
%% PRIVATE
%% =============================================================================



-spec do_handle(M :: wamp_message:call(), Ctxt :: bony_context:t()) ->
    wamp_messsage:result() | wamp_message:error().

do_handle(
    #call{procedure_uri = ?BONDY_BACKUP_CREATE} = M, Ctxt) ->
    [Info] = bondy_wamp_utils:validate_call_args(M, Ctxt, 1),
    bondy_wamp_utils:maybe_error(bondy_backup:backup(Info), M);

do_handle(#call{procedure_uri = ?BONDY_BACKUP_STATUS} = M, Ctxt) ->
    [Info] = bondy_wamp_utils:validate_call_args(M, Ctxt, 1),
    bondy_wamp_utils:maybe_error(bondy_backup:status(Info), M);

do_handle(#call{procedure_uri = ?BONDY_BACKUP_RESTORE} = M, Ctxt) ->
    [Info] = bondy_wamp_utils:validate_call_args(M, Ctxt, 1),
    bondy_wamp_utils:maybe_error(bondy_backup:restore(Info), M);

do_handle(#call{} = M, _) ->
    bondy_wamp_utils:no_such_procedure_error(M).