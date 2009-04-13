% Nitrogen Web Framework for Erlang
% Copyright (c) 2009 Andreas Stenius
% See MIT-LICENSE for licensing information.

-module (element_tabs).
-include ("wf.inc").
-compile(export_all).

reflect() -> record_info(fields, tabs).

render(ControlID, Record) -> 
    Options = action_jquery_effect:options_to_js(
		Record#tabs.options),
    Script = wf:f("Nitrogen.$tabs(obj('~s'), ~s);",
		  [ControlID, Options]),

    wf:wire(Script),

    case Record#tabs.tag of
	undefined -> skip;
	Tag ->
	    wf:wire(ControlID, 
		    [ #event{ type=Type, 
			      postback={Type, Tag} }
		      || Type <- [
				  tabsselect,
				  tabsload,
				  tabsshow,
				  tabsadd,
				  tabsremove,
				  tabsenable,
				  tabsdisable
				 ]]
		   )
    end,
    
    Terms = #panel{
      class = "tabs " ++ wf:to_list(Record#tabs.class),
      style = Record#tabs.style,
      body = ["<ul>"]
      ++ [[wf:f("<li><a href='#~s'>", [html_id(Tab#tab.id)]),
	   Tab#tab.title,
	   "</a></li>"]
	  || Tab <- Record#tabs.tabs]
      ++ ["</ul>"]
      ++ [#panel{ id = Tab#tab.id,
		  class = "tab",
		  body = Tab#tab.body } 
	  || Tab <- Record#tabs.tabs]
     },

    element_panel:render(ControlID, Terms).

html_id(Id) ->
    case wf_path:is_temp_element(Id) of
	true ->
	    wf_path:to_html_id(Id);
	false ->
	    wf_path:push_path(Id),
	    HtmlId = wf_path:to_html_id(wf_path:get_path()),
	    wf_path:pop_path(),
	    HtmlId
    end.
