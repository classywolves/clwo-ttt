#include <general>
#include <sourcemod>
#include <geoip>

Database ttt_db;

public OnPluginStart() {
	ttt_db = ConnectDatabase("ttt", "ANN");
	HookEvent("player_team", OnPlayerTeam, EventHookMode_Pre);
	HookEvent("player_disconnect", OnPlayerDisconnect, EventHookMode_Pre);
	//HookEvent("player_connect", OnPlayerConnect, EventHookMode_Pre);
}

public Action OnPlayerTeam(Event event, const char[] name, bool dontBroadcast) {
	return Plugin_Handled;
}

public OnClientAuthorized(client, const String:auth[]) {
	char player_name[64], country[3], ip[32];
	int karma;

	GetClientName(client, player_name, sizeof(player_name));
	GetClientIP(client, ip, sizeof(ip));
	GeoipCode2(ip, country);

	GetClientAuthId(client, AuthId_SteamID64, auth, strlen(auth));

	DBStatement get_karma = PrepareStatement(ttt_db, "SELECT `karma` FROM `ttt` WHERE communityid=?");
	SQL_BindParamString(get_karma, 0, auth, false);	
	if (!SQL_Execute(get_karma)) { PrintToServer("SQL Execute Failed..."); }

	while (SQL_FetchRow(get_karma)) {
		karma = SQL_FetchInt(get_karma, 0);
	}

	CPrintToChatAll("{GREEN}[+] {BLUE}%s {DEFAULT}[{LIGHTGREEN}%s{DEFAULT} | {LIGHTGREEN}%d{DEFAULT}] {LIGHTGREEN}connected.", player_name, country, karma);
	return Plugin_Handled;
}

public Action OnPlayerDisconnect(Event event, const char[] name, bool dontBroadcast) {
	char player_name[64], steam_id[64];

	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	GetClientName(client, player_name, sizeof(player_name));
	GetClientAuthId(client, AuthId_Steam2, steam_id, strlen(steam_id));

	char disconnect_message[256];
	Format(disconnect_message, sizeof(disconnect_message), "{DARKRED}[-] {BLUE}%s {DEFAULT}<{LIGHTGREEN}%s{DEFAULT}> {LIGHTRED}disconnected.", player_name, steam_id)
	CPrintToStaff(disconnect_message);
	return Plugin_Handled;
}