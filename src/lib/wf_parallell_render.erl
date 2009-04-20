% Nitrogen Web Framework for Erlang
% Copyright (c) 2009 Andreas Stenius
% See MIT-LICENSE for licensing information.

-module (wf_parallell_render).
-include ("wf.inc").
-export ([
	  queue/2,
	  merge/1
	 ]).

queue(Fun, Args) ->
    {Pid, _} = Q = spawn_monitor(fun render/0),
    wf_parallell_state:split(Pid),
    Pid!{self(), Fun, Args},
    Q.

merge([]) -> [];
merge(Qs) ->
    merge(Qs, []).


merge([], Acc) ->
    lists:reverse(Acc);
merge([{Pid, Ref}|Qs], Acc) ->
    receive
	{queue_res, Pid, Res} ->
	    erlang:demonitor(Ref, [flush]),
	    merge(Qs, [Res|Acc]);
	{'DOWN', Ref, _, _, Why} ->
	    ?PRINT(Why),
	    merge(Qs, Acc)
    end.


render() ->
    receive
	{Parent, Fun, Args} ->
	    Res = apply(Fun, Args),
	    wf_parallell_state:merge(Parent),
	    Parent!{queue_res, self(), Res}
    end.
