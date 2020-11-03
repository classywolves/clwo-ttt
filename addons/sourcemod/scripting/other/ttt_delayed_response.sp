/*
 * This file converts asynchronous, non-blocking calls to synchronous, memory lookups.
 * 
 * This should be used for long-running SQL queries, such as "bad actions" or "playtime"
 * which would be challenging to retrieve asynchronously.
 * 
 * In the long term this file should be replaced with either replacing all the synchronous
 * queries with async queries or by fixing the database design.
 */

/*
 * Custom include files.
 */
#include <player_methodmap>
#include <generics>

/*
 * Custom methodmap includes.
 */
#include <playtime_db>

int actions[MAXPLAYERS + 1][2];

public OnPluginStart()
{
	RegisterCmds();
	HookEvents();
	InitDBs();
	
	PrintToServer("[GEN] Loaded succcessfully");
}

public void RegisterCmds() {
}

public void HookEvents() {
}

public void InitDBs() {
	PlaytimeInit();
}

public int Native_GetGoodActions(Handle plugin, int numParams) {
	int client = GetNativeCell(1);

	return actions[client][0];
}

public int Native_GetBadActions(Handle plugin, int numParams) {
	int client = GetNativeCell(1);

	return actions[client][1];
}