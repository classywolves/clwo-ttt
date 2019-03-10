#if defined _ttt_actions_included
	#endinput
#endif
#define _ttt_actions_included

public SharedPlugin __pl_ttt_actions =
{
	name = "ttt_actions",
	file = "ttt_actions.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_ttt_upgrades_SetNTVOptional()
{
	MarkNativeAsOptional("Actions_GetGoodActions");
	MarkNativeAsOptional("Actions_GetBadActions");
}
#endif

native int Actions_GetGoodActions(int client);
native int Actions_GetBadActions(int client);
