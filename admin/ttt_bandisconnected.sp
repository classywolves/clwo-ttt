#include <sourcemod>
#include <sdktools>
#include <cstrike>

#include <sourcebanspp>
#include <colorlib>

#define PLUGIN_NAME "TTT Bandisconnected"

public Plugin myinfo =
{
    name = "CLWO Chat",
    author = "Sourcecode",
    description = "Keeps track of disconnected players and adds the ability to ban them",
    version = "1.1",
    url = "https://clwo.eu"
};

/////////
//Globals
/////////

//Array lists to store the names,steamids,times
ArrayList g_hSteamIDs;
ArrayList g_hNicknames;
ArrayList g_hTimes;

int g_iPlayerBanTarget[MAXPLAYERS+1]; //Ban target for client used in the menus

public OnPluginStart() 
{
	//COMMANDS
	RegAdminCmd("sm_dcd", Command_DisconnectedList, ADMFLAG_GENERIC, "Prints list of latest disconnected players");
	RegAdminCmd("sm_disconnected", Command_DisconnectedList, ADMFLAG_GENERIC, "Prints list of latest disconnected players");
	RegAdminCmd("sm_dclist", Command_DisconnectedList, ADMFLAG_GENERIC, "Prints list of latest disconnected players");
	RegAdminCmd("sm_listdisconnected", Command_DisconnectedList, ADMFLAG_GENERIC, "Prints list of latest disconnected players");

	RegAdminCmd("sm_bandc", Command_BanDisconnected, ADMFLAG_BAN, "Bans a disconnected player");
	RegAdminCmd("sm_dcban", Command_BanDisconnected, ADMFLAG_BAN, "Bans a disconnected player");
	RegAdminCmd("sm_bandisconnected", Command_BanDisconnected, ADMFLAG_BAN, "Bans a disconnected player");
	
	//EVENTS
	HookEvent("player_disconnect", ClientDisconnect_Event, EventHookMode_Pre); 

	//Arrays
	g_hSteamIDs = CreateArray(64);
	g_hNicknames = CreateArray(128);
	g_hTimes = CreateArray(32);

	CPrintToChatAll("{purple}[{default}%s{purple}] {default}>{green}Online{default}<", PLUGIN_NAME);
}

public void OnPluginEnd() {
	CPrintToChatAll("{purple}[{default}%s{purple}] {default}>{darkred}Offline{default}<", PLUGIN_NAME);
}

public void OnMapEnd() {
	//Remove the entries that are older than 60 minutes
	for (int i = 0; i < GetArraySize(g_hTimes); i++) {
		int stamp = GetArrayCell(g_hTimes, i);

		int currentstamp = GetTime();

		//Delete all older then 60 minutes
		if (currentstamp - stamp >= 60 * 60) {
			RemoveFromArray(g_hNicknames, i);
			RemoveFromArray(g_hSteamIDs, i);
			RemoveFromArray(g_hTimes, i);
		}
	}
}

////////
//Events
////////
public Action ClientDisconnect_Event(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(!IsValidClient(client)) {
		return;
	}

	char nickname[128];
	GetClientName(client, nickname, sizeof(nickname));

	char steamid[64];
	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid), true);

	int time = GetTime();

	int existingEntry = FindStringInArray(g_hNicknames, nickname);
	if(existingEntry != -1) {
		RemoveFromArray(g_hNicknames, existingEntry);
		RemoveFromArray(g_hSteamIDs, existingEntry);
		RemoveFromArray(g_hTimes, existingEntry);
	}

	PushArrayString(g_hNicknames, nickname);
	PushArrayString(g_hSteamIDs, steamid);
	PushArrayCell(g_hTimes, time);
}

//////////
//Commands
//////////

public Action Command_DisconnectedList(int client, int args)
{
	if(!IsValidClient(client))
		return Plugin_Handled;

	int dcplayers = GetArraySize(g_hNicknames);

	if(dcplayers == 0) {
		ReplyToCommand(client, "[SM] No one has disconnected in the last 60 minutes.");

		return Plugin_Handled;
	}

	for (int i = 0; i < dcplayers; i++) {
		char nickname[128];
		GetArrayString(g_hNicknames, i, nickname, sizeof(nickname));

		char steamid[64];
		GetArrayString(g_hSteamIDs, i, steamid, sizeof(steamid));

		int stamp = GetArrayCell(g_hTimes, i);

		char time[32];
		FormatTime(time, sizeof(time), "%R", stamp);

		PrintToConsole(client, "%s - %s - %s", steamid, nickname, time);	
	}
	
	PrintToChat(client, "[SM] Check console for output");

	return Plugin_Handled;
}

public Action Command_BanDisconnected(int client, int args)
{
	if(!IsValidClient(client))
		return Plugin_Handled;

	if(args == 1) {
		char steamid[32];
		GetCmdArg(1, steamid, sizeof(steamid));

		int existingEntry = FindStringInArray(g_hSteamIDs, steamid);
		if(existingEntry != -1) {
			g_iPlayerBanTarget[client] = existingEntry;

			Menu_BanTime(client);
		}


		return Plugin_Handled;
	}

	if(args >= 2) {
		char steamid[64], time[32], reason[128];
		GetCmdArg(1, steamid, sizeof(steamid));
		GetCmdArg(2, time, sizeof(time));
		if(args == 3) {
			GetCmdArg(3, reason, sizeof(reason));	
		}
		
		if(StrEqual(steamid, "") || StrEqual(time, "")) {
			ReplyToCommand(client, "[SM] Usage: sm_bandc <steamid> <time> [reason]");

			return Plugin_Handled;
		}

		//Make the ban
		BanDisconnected(client, steamid, time, reason);

		return Plugin_Handled;
	}

	Menu menu = new Menu(MenuHandler_BanDisconnected, MENU_ACTIONS_ALL);
	
	menu.SetTitle("Select the player you want to ban");

	int dcplayers = GetArraySize(g_hNicknames);

	if(dcplayers == 0) {
		ReplyToCommand(client, "[SM] No one has disconnected in the last 60 minutes.");

		return Plugin_Handled;
	}

	for (int i = 0; i < dcplayers; i++) {
		char nickname[128];
		GetArrayString(g_hNicknames, i, nickname, sizeof(nickname));

		char steamid[64];
		GetArrayString(g_hSteamIDs, i, steamid, sizeof(steamid));

		menu.AddItem(steamid, nickname);
	}

	menu.ExitButton = true;
	menu.Display(client, 60);

	return Plugin_Handled;
}

///////
//Menus
///////

public int MenuHandler_BanDisconnected(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		//Select player to ban
		case MenuAction_Select:
		{
			char steamid[64];
			menu.GetItem(param2, steamid, sizeof(steamid));

			int existingEntry = FindStringInArray(g_hSteamIDs, steamid);
			if(existingEntry != -1) {
				g_iPlayerBanTarget[param1] = existingEntry;

				Menu_BanTime(param1);
			}
		}

		case MenuAction_End:
		{
			delete menu;
		}
	}
	return 0;
}

public void Menu_BanTime(int client) {
	Menu menu = new Menu(MenuHandler_BanTime, MENU_ACTIONS_ALL);
	
	menu.SetTitle("How long do you want to ban the player");

	//Only add permanent if they have access to sm_unban
	if(CheckCommandAccess(client, "sm_unban", ADMFLAG_VOTE))
	{
		menu.AddItem("0", "Permanent");
	}

	menu.AddItem("30", "30 Minutes");
	menu.AddItem("60", "1 Hour");
	menu.AddItem("120", "2 Hours");
	menu.AddItem("240", "4 Hours");
	menu.AddItem("720", "12 hours");
	menu.AddItem("1440", "1 Day");
	menu.AddItem("10080", "1 Week");
	menu.AddItem("43200", "1 Month");

	menu.ExitButton = true;
	menu.Display(client, 60);
}

public int MenuHandler_BanTime(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		//Select player to ban
		case MenuAction_Select:
		{
			char steamid[64];
			GetArrayString(g_hSteamIDs, g_iPlayerBanTarget[param1], steamid, sizeof(steamid))

			char minutes[64];
			menu.GetItem(param2, minutes, sizeof(minutes));

			//Make the ban
			BanDisconnected(param1, steamid, minutes, "");
		}

		case MenuAction_End:
		{
			//Reset ban target of admin
			g_iPlayerBanTarget[param1] = 0;

			delete menu;
		}
	}
	return 0;
}

///////////
//Functions
///////////
public void BanDisconnected(int admin, const char[] steamid, const char[] time, const char[] reason) {
	ServerCommand("sm_addban %s %s %s", time, steamid, reason);
	
	PrintToConsole(admin, "sm_addban %s %s %s", time, steamid, reason);

	int banEntry = FindStringInArray(g_hSteamIDs, steamid);
	
	char nickname[64];
	GetArrayString(g_hNicknames, banEntry, nickname, sizeof(nickname));

	if(StrEqual(reason, "")) {
		ShowActivity(admin, "banned %s for %s minutes", nickname, time);
	} else {
		ShowActivity(admin, "banned %s for %s minutes [reason: %s]", nickname, time, reason);
	}
	
	for (int i = 1; i <= MaxClients; i++) {
		if(!IsValidClient(i)) {
			continue;
		}
		
		char pSteamId[64];
		GetClientAuthId(i, AuthId_Steam2, pSteamId, sizeof(pSteamId), true);

		if(StrEqual(pSteamId, steamid)) {
			PrintToConsole(i, "sm_addban %s %s %s", time, steamid, reason);
			KickClient(i, "You have been banned by %N for %s minutes", admin, time);
		}PrintToConsole(i, "sm_addban %s %s %s", time, steamid, reason);
	}

	//Reset ban target of admin
	g_iPlayerBanTarget[admin] = 0;
}

////////
//STOCKS
////////
stock bool IsValidClient(client, bool:nobots = true)
{ 
	if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (nobots && IsFakeClient(client)))
	{
		return false; 
	}
	return IsClientInGame(client); 
}