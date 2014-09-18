-module(gutenberg).
-export([
         main/1,
         start/0,
         start/2,
         stop/0,
         stop/1
        ]).

%%% Exported functions

start() ->
    {ok, _Started} = application:ensure_all_started(gutenberg).

stop() ->
    application:stop(gutenberg).

start(_StartType, _StartArgs) ->
    gute_sup:start_link().

stop(_State) ->
    ok.

main(Args) ->
    check_needed_executables(),
    OptSpecList = option_spec_list(),
    case getopt:parse(OptSpecList, Args) of
        {ok, {[], []}} ->
            help();
        {ok, {Options, Commands}} ->
            process_options(Options, Commands);
        {error, {Reason, Data}} ->
            io:format("Error: ~s ~p~n~n", [Reason, Data]),
            help()
    end.

%%% Internal

%% Command line options

-spec process_options([atom()], [string()]) -> ok.
process_options([help | Opts], Cmds) ->
    help(),
    process_options(Opts, Cmds);
process_options([commands | Opts], Cmds) ->
    commands(),
    process_options(Opts, Cmds);
process_options([], Cmds) ->
    process_commands(Cmds).

-spec process_commands([string()]) -> ok.
process_commands(["new" | Cmds]) ->
    new(Cmds);
process_commands(["list" | Cmds]) ->
    list(),
    process_commands(Cmds);
process_commands([]) ->
    ok;
process_commands([_Cmd | _Cmds]) ->
    throw(unrecognized_or_unimplemened_command).

%% Commands

new(Args) ->
    io:format("~p~n", [Args]).

list() ->
    io:format("Retrieving all generators...~n"),
    Generators = gute_generators:find_all(),
    Fun = fun(#{name := Name, description := Desc}) ->
                  io:format("~s\t~s~n", [Name, Desc])
          end,
    lists:foreach(Fun, Generators).

%% Options

help() ->
    OptSpecList = option_spec_list(),
    getopt:usage(OptSpecList, atom_to_list(?MODULE), standard_io).

-spec commands() -> ok.
commands() ->
    Commands = <<"Gutenberg can perform this awesome commands for you:

new GEN-TPLT NAME [VARIABLE=VALUE]
               Create a new project using a generator, or a new file
               using a template. GEN-TPLT is the generator's or
               template's name. NAME should be the value for the
               variable of the same name. Subsequent VALUE specifications
               should be paired with its VARIABLE name.

list           List all available generators and templates.
">>,
   io:put_chars(Commands).

option_spec_list() ->
    [
     {help, $h, "help", undefined, "Show this help information."},
     {commands, undefined, "commands", undefined, "Show available commands."}
    ].

%% Executables checks

needed_executables() ->
    [
     "git"
    ].

check_needed_executables() ->
    lists:foreach(
      fun (X) ->
              executable_present(X)
      end,
      needed_executables()).

executable_present(Name) ->
    case os:find_executable(Name) of
        false ->
            throw(Name ++ " is not present on the system");
        _ ->
            ok
    end.
