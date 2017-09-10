
#undef REQUIRE_PLUGIN
#include <sourcemod>
#include <sdktools>
#include <colorvariables>
//#include <imod>
#include <ttt>
#include <cstrike>

/* User Type */
#define USER_TYPE_COMMAND      0
#define USER_TYPE_IS_STAFF     1
#define USER_TYPE_BROADCAST    2
#define USER_TYPE_GROUPNAME    3
#define USER_TYPE_FULLNAME     4
#define USER_TYPE_SCORENAME    5
#define USER_TYPE_CHATNAME     6
#define USER_TYPE_MULTI_TARGET 7

#define INNOCENT 1
#define TRAITOR 2
#define DETECTIVE 3

/* Plugin Info */
#define PLUGIN_NAME 			"TTT Leaderboard"
#define PLUGIN_VERSION_M 		"0.0.4"
#define PLUGIN_AUTHOR 			"Popey"
#define PLUGIN_DESCRIPTION		"Shows a TTT karma leaderboard."
#define PLUGIN_URL				"https://sinisterheavens.com"

// ConVar rdm_version = null;
Database db_ttt;
Database db_player_analytics;

DBStatement sql_karma;

native void Steam64ToSteamID(char[] steam64, char[] output);
Menu menu;

Menu menu_temp;



// Create Menu


public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION_M,
	url = PLUGIN_URL
};

public OnPluginStart()
{
	// Connect to Database
	char error[255];
	db_ttt = SQL_Connect("ttt", true, error, sizeof(error));
	if (db_ttt == null) { PrintToServer("[LDB] Could not connect to TTT db: %s", error); }
	else { PrintToServer("[LDB] Connected to TTT DB"); } 
	
	db_player_analytics = SQL_Connect("player_analytics", true, error, sizeof(error));
	if (db_player_analytics == null) { PrintToServer("[LDB] Could not connect to Player Analytics db: %s", error); }
	else { PrintToServer("[LDB] Connected to Player Analytics DB"); } 
	
	// Register CVARS
	// rdm_version = CreateConVar("ldb_version", PLUGIN_VERSION_M, "Leaderboard Plugin Version");
	CreateConVar("ldb_version", PLUGIN_VERSION_M, "Leaderboard Plugin Version");
	
	// Register Commands
	RegConsoleCmd("sm_leaderboard", Command_leaderboard, "Open the Leaderboard"); ///////////////////////////////
	
	
	// Hook Events
	// HookEvent("player_disconnect", OnPlayerDisconnect);
	HookEvent("round_end", OnRoundEnd, EventHookMode_PostNoCopy);
	
	update_menu();
	
	// Alert Load Success
	PrintToServer("[LDB] Has Loaded Succcessfully!");
}

public Action OnRoundEnd(Event event, const char[] name, bool dontBroadcast) {
	update_menu();
	return Plugin_Continue;
}

public OnPluginEnd()
{
	// Alert Unload Success
	PrintToServer("[LDB] Has Unloaded Successfully!");
}


public update_menu()
{
	menu_temp = new Menu(RDM_Menu_Callback);
	menu_temp.SetTitle("Karma Leaderboard");
	
	// Add Entries
	
	// Initiate the query statement
	char error[255];
	sql_karma = SQL_PrepareQuery(db_ttt, "SELECT * FROM ttt ORDER BY karma DESC LIMIT 60", error, sizeof(error))
	if (sql_karma == null) { PrintToServer(error); return; }
	
	// Execute the command
	if (!SQL_Execute(sql_karma)) { PrintToServer("[LDB] Karma - Failed Execute"); return; }

	// Loop over rows

	if (SQL_FetchRow(sql_karma))
	{
		char community_id[64];
		
		SQL_FetchString(sql_karma, 1, community_id, sizeof(community_id));
		int karma = SQL_FetchInt(sql_karma, 2);
		
		char steamid[32];
		Steam64ToSteamID(community_id, steamid);
		
		char query[128];
		FormatEx(query, sizeof(query), "SELECT `name` FROM `player_analytics` WHERE `auth` = '%s' ORDER BY `connect_date` DESC LIMIT 1", steamid);
		SQL_TQuery(db_player_analytics, playeranalyticsquerycallback, query, karma, DBPrio_Normal);
	}


}
public RDM_Menu_Callback(Menu menu, MenuAction action, int client, int item) 
{
	return 0;
}


public Action Command_leaderboard(int client, int args)
{	
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public void playeranalyticsquerycallback(Handle db, Handle query_input, const char[] error, int karma_input)
{
	if (SQL_FetchRow(query_input))
	{
		char steamname[32];
		char buffer[64];
		
		SQL_FetchString(query_input, 0, steamname, sizeof(steamname));
		FormatEx(buffer, sizeof(buffer), "%.18s [%d]", steamname, karma_input);

		menu_temp.AddItem(steamname, buffer);

	}
	
	if (SQL_FetchRow(sql_karma))
	{
		char community_id[64];
		
		SQL_FetchString(sql_karma, 1, community_id, sizeof(community_id));
		int karma = SQL_FetchInt(sql_karma, 2);
		
		char steamid[32];
		Steam64ToSteamID(community_id, steamid);
		
		char query[128];
		FormatEx(query, sizeof(query), "SELECT `name` FROM `player_analytics` WHERE `auth` = '%s' ORDER BY `connect_date` DESC LIMIT 1", steamid);
		
		
		SQL_TQuery(db_player_analytics, playeranalyticsquerycallback, query, karma, DBPrio_Normal);
	}
	else
	{
		menu = menu_temp;
	}
	
}