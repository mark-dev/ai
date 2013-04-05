%%%-------------------------------------------------------------------
%%% @author Mark <>
%%% @copyright (C) 2013, Mark
%%% @doc
%%%
%%% @end
%%% Created :  3 Apr 2013 by Mark <>
%%%-------------------------------------------------------------------
-module(ai).
-export([main/1,test_all/0]).

-include_lib("eunit/include/eunit.hrl").

-define(LOG(S,R),io:format(S,R)).
-define(LOG(S),io:format(S)).


main([TreeFile,PropFile])->
    {ok,[Tree]}=file:consult(TreeFile),
    {ok,[Props]} = file:consult(PropFile),
    calc_result(Tree,Props).

calc_result([],_)->
    ?LOG("reached end without result ~n"),
    failed;
%Выйти с результатом в случае если условие верно
calc_result([{Condition,{result,Result}}|Tail],Props) -> 
    case calc_condition(Condition,Props) of
	true -> Result; %Условие выполненно = получаем результат
	false ->
	    calc_result(Tail,Props)
    end;
%Если условие верно то спуститься на 1 уровень вниз
calc_result([{Condition,TreeIfCondTrue}|Tail],Props) when is_list(TreeIfCondTrue)->
    NewTree = case calc_condition(Condition,Props) of
		  true ->
		      TreeIfCondTrue;
		  false ->
		      Tail
	      end,
    calc_result(NewTree,Props).
%Возвращает результат условия true | false
calc_condition({A1,Cond,A2},Props)->
    {ok,F} = cond_to_function(Cond),
    Arg1 = get_real_arg(A1,Props),
    Arg2 = get_real_arg(A2,Props),
    F(Arg1,Arg2).
%Возвращает значение аргумента
%которое будет использоваться для расчета условия
get_real_arg(Arg,Props) ->
    case Arg of
	%Аргумент - свойство из props.txt
	_ when is_atom(Arg)->
	    get_key(Arg,Props);
	%Аргумент = константа(не числовая),например да или нет
	_ when is_list(Arg)->
	    list_to_atom(Arg);
	%Аргумент = число
	_ when is_integer(Arg) ->
	    Arg;
	{Min,Max}-> %between
	    {Min,Max};
	_ ->
	    ?LOG("unknown condition argument ~n")
    end.
get_key(Key,PropList) when is_atom(Key)->	    
    case proplists:get_value(Key,PropList) of
	undefined ->
	    ?LOG("key ~p not found at proplist ~p ~n -> exit",[Key,PropList]),
	    exit(-1);
	Other ->
	    Other
    end.
%Конвертирует текстовое условие в реальную функцию erlang-а
%{ok,FunctionAtom} | {error,Reason}
cond_to_function(Cond) when is_atom(Cond)->
    case Cond of
	less -> {ok,fun erlang:'<'/2};
	greater -> {ok,fun erlang:'>'/2};
	equals -> {ok,fun erlang:'=='/2};
	eq -> {ok,fun erlang:'=='/2};
	between -> {ok, fun(A1,{Min,Max})->
				(A1>Min) and (A1<Max)
			end};
	_ ->
	    ?LOG("unknown condition"),
	    {error,unknown_cond}
    end.

test_all()->
    {ok,[Tree]}=file:consult("tree.txt"),
    Prop1 = [{difficulty,easy},{type,exam},{labs,true},{marks,true}],
    Prop2 = [{difficulty,easy},{type,exam},{labs,false},{marks,false}],
    Prop3 = [{difficulty,easy},{type,exam},{labs,false},{marks,true}],
    
    Prop4 = [{difficulty,easy},{type,offset},{depends_marks,true},{marks,true}],
    Prop5 = [{difficulty,easy},{type,offset},{depends_marks,false},{marks,true}],
    Prop6 = [{difficulty,mid},{type,exam}],
    Prop7 = [{difficulty,mid},{type,offset},{labs,true}],
    Prop8 = [{difficulty,mid},{type,offset},{labs,false},{marks,true}],
    Prop9 = [{difficulty,mid},{type,offset},{labs,false},{marks,false},{depends_marks,true}],
    Prop10 = [{difficulty,mid},{type,offset},{labs,false},{marks,false},{depends_marks,false}],
    Prop11 = [{difficulty,hard}],
    ?assertEqual(mid,test_prop(Tree,Prop1)),
    ?assertEqual(low,test_prop(Tree,Prop2)),
    ?assertEqual(mid,test_prop(Tree,Prop3)),
    ?assertEqual(mid,test_prop(Tree,Prop4)),
    ?assertEqual(low,test_prop(Tree,Prop5)),
    ?assertEqual(mid,test_prop(Tree,Prop6)),
    ?assertEqual(high,test_prop(Tree,Prop7)),
    ?assertEqual(mid,test_prop(Tree,Prop8)),
    ?assertEqual(mid,test_prop(Tree,Prop9)),
    ?assertEqual(low,test_prop(Tree,Prop10)),
    ?assertEqual(high,test_prop(Tree,Prop11)).

test_prop(Tree,Props)->
    calc_result(Tree,Props).
    







