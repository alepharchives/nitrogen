% Nitrogen Web Framework for Erlang
% Copyright (c) 2009 Andreas Stenius
% See MIT-LICENSE for licensing information.

-module (wf_parallell_state).
-include ("wf.inc").
-export ([
	  init/0, state/1,

	  get/0,
	  get/1,
	  get_keys/0,

	  put/2,

	  erase/0,
	  erase/1
	 ]).


init() ->
    case whereis(?MODULE) of
	undefined ->
	    register(
	      ?MODULE,
	      spawn(?MODULE, state, [[]])
	     );
	Pid ->
	    Pid
    end.

state(State) ->
    receive
	{get, From} ->
	    do_get(From, State),
	    state(State);
	{get, From, Key} ->
	    do_get(From, State, Key),
	    state(State);
	{get_keys, From} ->
	    do_get_keys(From, State),
	    state(State);
	{put, From, Key, Value} ->
	    State1 = do_put(From, State, Key, Value),
	    state(State1);
	{erase, From} ->
	    State1 = do_erase(From, State),
	    state(State1);
	{erase, From, Key} ->
	    State1 = do_erase(From, State, Key),
	    state(State1);
	_ ->
	    state(State)
    end.

send_response(From, Res) ->
    From!{?MODULE, Res}.

get_response() ->
    receive
	{?MODULE, Res} ->
	    Res
    end.

search(Key, List, Default) ->
    case lists:keysearch(Key, 1, List) of
	{value, Res} ->
	    element(2, Res);
	false ->
	    Default
    end.
    
lookup(From, State) ->
    search(From, State, []).

lookup(From, State, Key) ->
    lookup_value(lookup(From, State), Key).

lookup_value(Dict, Key) ->
    search(Key, Dict, undefined).

do_get(From, State) ->
    send_response(From, lookup(From, State)).

do_get(From, State, Key) ->
    send_response(From, lookup(From, State, Key)).

do_get_keys(From, State) ->
    send_response(From, [element(1, E) || E <- lookup(From, State)]).

do_put(From, State, Key, Value) ->
    Dict = lookup(From, State),
    Res = lookup_value(Dict, Key),
    State1 = lists:keystore( 
	       From, 1, State,
	       {From, lists:keystore(
			Key, 1, Dict,
			{Key, Value})
	       }),
    send_response(From, Res),
    State1.

do_erase(From, State) ->
    case lists:keytake(From, 1, State) of
	{value, Dict, State1} ->
	    send_response(From, Dict),
	    State1;
	false ->
	    send_response(From, []),
	    State
    end.

do_erase(From, State, Key) ->
    Dict = lookup(From, State),
    case lists:keytake(Key, 1, Dict) of
	{value, E, Dict1} ->
	    send_response(From, element(2, E)),
	    lists:keyreplace(From, 1, State, Dict1);
        false ->
	    send_response(From, undefined),		  
	    State
    end.


%%% API %%%

get() ->
    ?MODULE!{get, self()},
    get_response().

get(Key) ->
    ?MODULE!{get, self(), Key},
    get_response().
    
get_keys() ->
    ?MODULE!{get_keys, self()},
    get_response().

put(Key, Value) ->
    ?MODULE!{put, self(), Key, Value},
    get_response().

erase() ->
    ?MODULE!{erase, self()},
    get_response().

erase(Key) ->
    ?MODULE!{erase, self(), Key},
    get_response().
