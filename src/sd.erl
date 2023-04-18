%%%-------------------------------------------------------------------
%%% @author c50 <joq62@c50>
%%% @copyright (C) 2023, c50
%%% @doc
%%%
%%% @end
%%% Created : 18 Apr 2023 by c50 <joq62@c50>
%%%-------------------------------------------------------------------
-module(sd).

-behaviour(gen_server).
%%--------------------------------------------------------------------
%% Include 
%%
%%--------------------------------------------------------------------

-include("log.api").


%% API
-export([
	 get_node/1,
	 get_node_on_node/2,
	 get_node_on_host/2,
	 get_node_host/1,
	 get_node_host_on_node/2,
	 get_node_host_on_host/2,
	 call/5,
	 cast/4,
	 all/0,

	 ping/0,
	 stop/0
	]).

-export([start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3, format_status/2]).

-define(SERVER, ?MODULE).

-record(state, {}).

%%%===================================================================
%%% API
%%%===================================================================
%%--------------------------------------------------------------------
%% @doc
%% @spec
%% @end
%%--------------------------------------------------------------------
all()->
    gen_server:call(?SERVER, {all},infinity).
%%--------------------------------------------------------------------
%% @doc
%% @spec
%% @end
%%--------------------------------------------------------------------
call(App,M,F,A,Timeout)->
    gen_server:call(?SERVER, {call,App,M,F,A,Timeout},infinity).

cast(App,M,F,A)->
    gen_server:call(?SERVER, {cast,App,M,F,A},infinity).

%%--------------------------------------------------------------------
%% @doc
%% @spec
%% @end
%%--------------------------------------------------------------------
get_node(WantedApp)->
    gen_server:call(?SERVER, {get_node,WantedApp},infinity).

get_node_on_node(WantedApp,WantedHost)->
    gen_server:call(?SERVER, {get_node_on_node,WantedApp,WantedHost},infinity).

get_node_host(WantedApp)->
    gen_server:call(?SERVER, {get_node_host,WantedApp},infinity).

get_node_on_host(WantedApp,WantedHost)->
    gen_server:call(?SERVER, {get_node_on_host,WantedApp,WantedHost},infinity).

get_node_host_on_host(WantedApp,WantedHost)->
    gen_server:call(?SERVER, {get_node_host_on_host,WantedApp,WantedHost},infinity).

get_node_host_on_node(WantedApp,WantedHost)->
    gen_server:call(?SERVER, {get_node_host_on_node,WantedApp,WantedHost},infinity).
%%--------------------------------------------------------------------
%% @doc
%% @spec
%% @end
%%--------------------------------------------------------------------
ping()-> 
    gen_server:call(?SERVER, {ping},infinity).
%%--------------------------------------------------------------------
%% @doc
%% Starts the server
%% @end
%%--------------------------------------------------------------------
-spec start_link() -> {ok, Pid :: pid()} |
	  {error, Error :: {already_started, pid()}} |
	  {error, Error :: term()} |
	  ignore.
start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).


stop()-> gen_server:call(?SERVER, {stop},infinity).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Initializes the server
%% @end
%%--------------------------------------------------------------------
-spec init(Args :: term()) -> {ok, State :: term()} |
	  {ok, State :: term(), Timeout :: timeout()} |
	  {ok, State :: term(), hibernate} |
	  {stop, Reason :: term()} |
	  ignore.

init([]) ->
    ?LOG_NOTICE("Server started ",[]),
    
     
    
    {ok, #state{}}.


%%--------------------------------------------------------------------
%% @doc
%% @spec
%% @end
%%--------------------------------------------------------------------
handle_call({call,App,M,F,A,Timeout}, _From, State) ->
    Reply=case local_get_node(App) of
	      []->
		  {error,["No node available for app : ",App,?MODULE,?LINE]};
	      [Node|_]->
		  rpc:call(Node,M,F,A,Timeout)
	  end,
    {reply, Reply, State};

handle_call({cast,App,M,F,A}, _From, State) ->
    Reply=case local_get_node(App) of
	      []->
		  {error,["No node available for app : ",App,?MODULE,?LINE]};
	      [Node|_]->
		  rpc:cast(Node,M,F,A)
	  end,
    {reply, Reply, State};
%%--------------------------------------------------------------------
%% @doc
%% @spec
%% @end
%%--------------------------------------------------------------------
handle_call({all}, _From, State) ->
    io:format("all ~p~n",[{?MODULE,?LINE}]),
    Apps=[{Node,rpc:call(Node,net,gethostname,[],5*1000),
	   rpc:call(Node,application,which_applications,[],5*1000)}||Node<-[node()|nodes()]],
    Reply=[{Node,HostName,AppList}||{Node,{ok,HostName},AppList}<-Apps,
				    AppList/={badrpc,nodedown}],
    {reply, Reply, State};

handle_call({get_node,WantedApp}, _From, State) ->
    Apps=[{Node,rpc:call(Node,application,which_applications,[],5*1000)}||Node<-[node()|nodes()]],
    Reply=[Node||{Node,AppList}<-Apps,
		 AppList/={badrpc,nodedown},
		 AppList/={badrpc,timeout},
		 true==lists:keymember(WantedApp,1,AppList)],
    {reply, Reply, State};

handle_call({get_node_on_node,WantedApp,WantedNode}, _From, State) ->
    Apps=[{Node,rpc:call(Node,application,which_applications,[],5*1000)}||Node<-[node()|nodes()]],
    
    Reply=[Node||{Node,AppList}<-Apps,
		 AppList/={badrpc,nodedown},
		 AppList/={badrpc,timeout},
		 true==lists:keymember(WantedApp,1,AppList),
		 Node==WantedNode],
    {reply, Reply, State};

handle_call({get_node_host,WantedApp}, _From, State) ->
    Apps=[{Node,rpc:call(Node,net,gethostname,[],5*1000),
	   rpc:call(Node,application,which_applications,[],5*1000)}||Node<-[node()|nodes()]],
    Reply=[{Node,HostName}||{Node,{ok,HostName},AppList}<-Apps,
			    AppList/={badrpc,nodedown},
			    AppList/={badrpc,timeout},
			    true==lists:keymember(WantedApp,1,AppList)],
    {reply, Reply, State};

handle_call({get_node_host,WantedApp,WantedHost}, _From, State) ->
    Apps=[{Node,rpc:call(Node,net,gethostname,[],5*1000),
	   rpc:call(Node,application,which_applications,[],5*1000)}||Node<-[node()|nodes()]],
    Reply=[Node||{Node,{ok,HostName},AppList}<-Apps,
		 AppList/={badrpc,nodedown},
		 AppList/={badrpc,timeout},
		 true=:=lists:keymember(WantedApp,1,AppList),
		 HostName=:=WantedHost],
    
    {reply, Reply, State};


handle_call({get_node_on_host,WantedApp,WantedHost}, _From, State) ->
    Apps=[{Node,rpc:call(Node,net,gethostname,[],5*1000),
	   rpc:call(Node,application,which_applications,[],5*1000)}||Node<-[node()|nodes()]],
    Reply=[{Node,HostName}||{Node,{ok,HostName},AppList}<-Apps,
			    AppList/={badrpc,nodedown},
			    AppList/={badrpc,timeout},
			    true==lists:keymember(WantedApp,1,AppList),
			    HostName=:=WantedHost],
    
    {reply, Reply, State};

handle_call({get_node_host_on_host,WantedApp,WantedHost}, _From, State) ->
    Apps=[{Node,rpc:call(Node,net,gethostname,[],5*1000),
	   rpc:call(Node,application,which_applications,[],5*1000)}||Node<-[node()|nodes()]],
    Reply=[{Node,HostName}||{Node,{ok,HostName},AppList}<-Apps,
			    AppList/={badrpc,nodedown},
			    AppList/={badrpc,timeout},
			    true=:=lists:keymember(WantedApp,1,AppList),
			    HostName=:=WantedHost],
    
    {reply, Reply, State};

%%--------------------------------------------------------------------
%% @doc
%% @spec
%% @end
%%--------------------------------------------------------------------
handle_call({ping}, _From, State) ->
    Reply=pong,
    {reply, Reply, State};


handle_call(UnMatchedSignal, From, State) ->
    io:format("unmatched_signal ~p~n",[{UnMatchedSignal, From,?MODULE,?LINE}]),
    Reply = {error,[unmatched_signal,UnMatchedSignal, From]},
    {reply, Reply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling cast messages
%% @end
%%--------------------------------------------------------------------
handle_cast(UnMatchedSignal, State) ->
    io:format("unmatched_signal ~p~n",[{UnMatchedSignal,?MODULE,?LINE}]),
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling all non call/cast messages
%% @end
%%--------------------------------------------------------------------
-spec handle_info(Info :: timeout() | term(), State :: term()) ->
	  {noreply, NewState :: term()} |
	  {noreply, NewState :: term(), Timeout :: timeout()} |
	  {noreply, NewState :: term(), hibernate} |
	  {stop, Reason :: normal | term(), NewState :: term()}.
handle_info(Info, State) ->
    io:format("unmatched_signal ~p~n",[{Info,?MODULE,?LINE}]),
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any
%% necessary cleaning up. When it returns, the gen_server terminates
%% with Reason. The return value is ignored.
%% @end
%%--------------------------------------------------------------------
-spec terminate(Reason :: normal | shutdown | {shutdown, term()} | term(),
		State :: term()) -> any().
terminate(_Reason, _State) ->
    ok.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Convert process state when code is changed
%% @end
%%--------------------------------------------------------------------
-spec code_change(OldVsn :: term() | {down, term()},
		  State :: term(),
		  Extra :: term()) -> {ok, NewState :: term()} |
	  {error, Reason :: term()}.
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called for changing the form and appearance
%% of gen_server status when it is returned from sys:get_status/1,2
%% or when it appears in termination error logs.
%% @end
%%--------------------------------------------------------------------
-spec format_status(Opt :: normal | terminate,
		    Status :: list()) -> Status :: term().
format_status(_Opt, Status) ->
    Status.

%%%===================================================================
%%% Internal functions
%%%===================================================================
local_get_node(WantedApp)->
    Apps=[{Node,rpc:call(Node,application,which_applications,[],5*1000)}||Node<-[node()|nodes()]],
    [Node||{Node,AppList}<-Apps,
	   AppList/={badrpc,nodedown},
	   AppList/={badrpc,timeout},
	   true==lists:keymember(WantedApp,1,AppList)].
