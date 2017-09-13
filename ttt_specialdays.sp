
#undef REQUIRE_PLUGIN
#include <sourcemod>
#include <sdktools>
#include <colorvariables>
#include <advanced_motd>
#include <ttt>
#include <cstrike>
#include <general>
#include <smlib>

/* Plugin Info */
#define PLUGIN_NAME 			"TTT Special Days"
#define PLUGIN_VERSION_M 		"0.0.4"
#define PLUGIN_AUTHOR 			"Popey"
#define PLUGIN_DESCRIPTION		"Special days."
#define PLUGIN_URL				"https://sinisterheavens.com"

bool url_seen[MAXPLAYERS + 1];

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
	RegAdminCmd("sm_force_day", Command_Force_Day, FCVAR_CHEAT, "Force a special day");
	
	// Register Events
	
	// Alert Load Success
	PrintToServer("[URL] Has Loaded Succcessfully!");
}

public Action Command_Force_Day(int client, int args) {

}

public void Display_Page(int client, char[] url) {
	char web_url[512];
	strcopy(web_url, sizeof(web_url), url);
	CraftMOTDUrl(client, web_url);
	AdvMOTD_ShowMOTDPanel(client, "Displaying...", web_url, MOTDPANEL_TYPE_URL);
	CPrintToChat(client, "{purple}[URL] {yellow}Loading {green}%s", url);
}

stock void CraftMOTDUrl(int client, char WebUrl[512]) {
	char encodedWebUrl[512];
	Crypt_Base64Encode(WebUrl, encodedWebUrl, sizeof(encodedWebUrl));

	char buffer[512];
	if (url_seen[client]) {
		PrintToConsole(client, "1");
		url_seen[client] = false;
		Format(buffer, sizeof(buffer), "http://clwo.inilo.net/webredirect/payload/direct.php?website=%s", encodedWebUrl);
	} else {
		PrintToConsole(client, "2");
		url_seen[client] = true;
		Format(buffer, sizeof(buffer), "http://clwo.eu/webredirect/payload/direct.php?website=%s", encodedWebUrl);
	}
	strcopy(WebUrl, 512, buffer);
}

public Action Command_Rules(int client, int args) {
	SetCommandFlags("sm_tp", FCVAR_CHEAT);
	SetCommandFlags("/tp", FCVAR_CHEAT);
	SetCommandFlags("!tp", FCVAR_CHEAT);
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