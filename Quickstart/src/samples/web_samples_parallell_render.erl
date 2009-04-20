-module (web_samples_parallell_render).
-include ("wf.inc").
-compile(export_all).

-record(delay, {?ELEMENT_BASE(?MODULE), ms, body}).
-record(timestamp, {?ELEMENT_BASE(?MODULE)}).

main() -> #template { file="./wwwroot/onecolumn.html", bindings=[
	{'Group', learn},
	{'Item', samples}
]}.

title() -> "Parallell Rendering Example".
headline() -> "Show off the parallell rendering".
right() -> linecount:render().

body() -> [
	   [parallell,
	   % fork 1
	   #panel{ body=
		   [
		    #h3{ text="This is render fork 1" },#br{},
		    #timestamp{},
		    "Now sleeping for 1000 ms...",#br{},
		    #timestamp{},#p{}
		   ]},

	   % fork 2
	   #panel{ body=
		   [
		    #h3{ text="This is render fork 2" },#br{},
		    #timestamp{},
		    "Now sleeping for 500 ms...",#br{},
		    #timestamp{},#p{}
		   ]}
	   ],
	   [
	    #h2{ text="What?" },
	    #panel{ body=
		    [#timestamp{},"
Yep, parallell rendering may be started form any where in the
rendering process, and spawns a process for each elemnent in the marked list.<br>
This chunk is rendered AFTER the other two, as seen by the timestamp.<p>
View source to see what is going on..."]}
 ]].


event(_) -> ok.

render(_ControlID, Record) when is_record(Record, timestamp) ->
    wf:f("Timestamp: ~w<br>~n", [now()]);
render(_ControlID, Record) when is_record(Record, delay) ->
    timer:sleep(Record#delay.ms),
    [].
