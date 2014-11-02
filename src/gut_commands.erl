-module(gut_commands).
-export([
         help/0,
         version/1,
         new/1,
         find/1,
         erlangmk/1,
         escriptize/1,
         update/1,
         'update.gens'/1
        ]).

%% Commands
help() ->
    #{
      "version" =>
          #{desc => "Prints gutenberg version",
            long => ""
           },
      "new" => #{desc => "Creates a new project or file",
                 long => ""
                },
      "find" => #{desc => "Find available generators and templates",
                  long => ""
                 },
      "erlangmk" => #{desc => "Downloads erlang.mk",
                      long => ""
                     },
      "escriptize" => #{desc => "Turn your erlang application into an escript",
                        long => ""
                       },
      "update" => #{desc => "Get the latest version of the gut executable and update.gens",
                    long => ""
                   },
      "update.gens" => #{desc => "Update all generators in the local ~/.gut folder",
                         long => ""
                        },
      "help" => #{desc => "Print help information",
                  long => ""
                 }
     }.

version(_) ->
    io:format("~s~n", [version()]),
    ok.

version() ->
    {ok, Keys} = application:get_all_key(gut),
    proplists:get_value(vsn, Keys).

new([ProvidedName, Path | _]) ->
    FullGeneratorName = gut_suffix:full_name(ProvidedName),

    Name = filename:basename(Path),
    Values = [{<<"{{NAME}}">>, Name}],

    Generator = gut_generators:find_by_name(FullGeneratorName),
    case Generator of
        not_found ->
            io:format("Generator ~s not found ~n", [ProvidedName]);
        #{name := GenName,
          url := GenUrl} ->
            gut_generators:clone(GenName, GenUrl),
            gut_generators:copy(GenName, Path),

            os:cmd("rm -rf " ++ Path ++ "/.git"),
            os:cmd("rm -rf " ++ Path ++ "/README.md"),

            gut_readme:generate(Path, Name),

            gut_compile:compile(Path, Values),
            io:format("~nYour gut project was created successfully.~n")
    end,
    ok;
new(_) ->
    throw({error, "Missing generator/template name"}).

find([]) ->
    io:format("Fetching list of generators and templates from github...~n"),
    Generators = gut_generators:find_all(),
    print_generators(Generators),
    ok;
find([Name | _]) ->
    Generators = gut_generators:find_all_by_name(Name),
    print_generators(Generators),
    ok.

print_generators(Generators) ->
    Padding = padding_size(Generators),
    lists:foreach(fun (X) ->
                          print_generator(X, Padding)
                  end,
                  Generators).

print_generator(#{name := GenName, description := Desc}, Padding) ->
    ShortName = gut_suffix:short_name(GenName),
    ShortName2 = erlang:binary_to_list(ShortName),
    ShortNamePadded = string:left(ShortName2, Padding),
    io:format("~s # ~s~n", [color:green(ShortNamePadded), Desc]).

erlangmk(_) ->
    Url = "https://raw.githubusercontent.com/"
        "ninenines/erlang.mk/master/erlang.mk",
    {ok, "200", _, Content} = ibrowse:send_req(Url, [], get),
    file:write_file("erlang.mk", Content).

escriptize([]) ->
    gut_escriptize:run(),
    ok;
escriptize([Name | _]) ->
    gut_escriptize:run(Name),
    ok.

update(_) ->
  io:format("Updating generators..."),
  gut_generators:update(),
  io:format(" ~s~n", [color:green("done")]),

  ScriptPath = escript:script_name(),
  io:format("Updating gut binary in ~s...", [ScriptPath]),
  Url = "https://raw.githubusercontent.com/"
    "unbalancedparentheses/gut/master/bin/gut",
  {ok, "200", _, Content} = ibrowse:send_req(Url, [], get),
  file:write_file(ScriptPath, Content),
  io:format(" ~s~n", [color:green("done")]),
  ok.

'update.gens'(_) ->
  io:format("Updating generators..."),
  gut_generators:update(),
  io:format(" ~s~n", [color:green("done")]),
  ok.

padding_size(List) ->
    lists:max(lists:map(fun (#{name := Name}) ->
                                ShortName = gut_suffix:short_name(Name),
                                erlang:size(ShortName)
                        end, List)).
