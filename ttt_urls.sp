
#undef REQUIRE_PLUGIN
#include <sourcemod>
#include <sdktools>
#include <colorvariables>
#include <advanced_motd>
//#include <imod>
//#include <ttt>
#include <cstrike>
#include <general>

/* Plugin Info */
#define PLUGIN_NAME 			"TTT URLs"
#define PLUGIN_VERSION_M 		"0.0.4"
#define PLUGIN_AUTHOR 			"Popey"
#define PLUGIN_DESCRIPTION		"Opens URLs."
#define PLUGIN_URL				"https://sinisterheavens.com"

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
	// Register CVARS
	// rdm_version = CreateConVar("ldb_version", PLUGIN_VERSION_M, "Leaderboard Plugin Version");
	CreateConVar("url_version", PLUGIN_VERSION_M, "URL Plugin Version");
	
	// Register Commands
	RegConsoleCmd("sm_rules", Command_Rules, "Open the rules page");
	RegConsoleCmd("sm_clwo", Command_CLWO, "Open the clwo page");
	RegConsoleCmd("sm_group", Command_Group, "Open the group page");
	RegConsoleCmd("sm_new", Command_New, "Open the new page");
	RegConsoleCmd("sm_google", Command_Google, "Open Google");
	RegConsoleCmd("sm_gametracker", Command_Gametracker, "Open Gametracker");
	
	// Alert Load Success
	PrintToServer("[URL] Has Loaded Succcessfully!");
}

public Display_Page(int client, char[] url) {
	AdvMOTD_ShowMOTDPanel(client, "Displaying...", url, MOTDPANEL_TYPE_URL);
	CPrintToChat(client, "{purple}[URL] {yellow}Loading {green}%s", url);
}

public Action Command_Rules(int client, int args) {
	Display_Page(client, "https://clwo.eu/thread-1614-post-15525.html#pid15525");
	return Plugin_Handled;
}

public Action Command_CLWO(int client, int args) {
	Display_Page(client, "https://clwo.eu");
	return Plugin_Handled;
}

public Action Command_Group(int client, int args) {
	Display_Page(client, "https://steamcommunity.com/groups/ClassyWolves");
	return Plugin_Handled;
}


public Action Command_New(int client, int args) {
	Display_Page(client, "https://clwo.eu/thread-2123-post-21215.html#pid21215");
	return Plugin_Handled;
}

public Action Command_Google(int client, int args) {
	Display_Page(client, "https://google.com");
	return Plugin_Handled;
}

public Action Command_Gametracker(int client, int args) {
	Display_Page(client, "https://www.gametracker.com/server_info/ttt.clwo.eu:27015");
	return Plugin_Handled;
}

public OnPluginEnd() {
	// Alert Unload Success
	PrintToServer("[URL] Has Unloaded Successfully!");
}