#define _is_main_upgrade 1

#include <ttt_helpers>
#include <player_methodmap>

#include <ttt>
#include <general>

typedef NativeCall = function int (Handle plugin, int numParams);

public void OnPluginStart() {
	RegAdminCmd("sm_experience", command_display_experience, ADMFLAG_GENERIC);
	RegAdminCmd("sm_setexperience", command_experience, ADMFLAG_ROOT);
	RegAdminCmd("sm_setlevel", command_level, ADMFLAG_ROOT);
	RegAdminCmd("sm_update_info", command_update_info, ADMFLAG_ROOT);
	RegAdminCmd("sm_display_upgrades", command_display_upgrades, ADMFLAG_GENERIC);
	RegConsoleCmd("sm_session", command_get_session);
	RegConsoleCmd("sm_skills", command_skills, "Opens the skill menu");
	RegConsoleCmd("sm_skill", command_skills, "Opens the skill menu");
	RegConsoleCmd("sm_populate", command_populate, "Populates upgrades");
	RegConsoleCmd("sm_reset_skills", command_reset_skills, "Reset all skills");

	cookie_player_experience = RegClientCookie("player_experience", "Current experience player has.", CookieAccess_Private);
	cookie_player_level = RegClientCookie("player_level", "Current player level.", CookieAccess_Private);

	database_ttt = ConnectDatabase("ttt", "ttt");
	//database_player_analytics = ConnectDatabase("player_analytics", "P_A");

	AddFileToDownloadsTable("sound/ttt_clwo/ttt_levelup.mp3");

	HookEvent("player_death", OnPlayerDeath);
	LoopClients(client) if (AreClientCookiesCached(client)) OnClientCookiesCached(client);
	LoopValidClients(client) OnClientPutInServer(client);
}

public void OnClientPutInServer(int client) {
	Player player = Player(client);
	char string[63], hash[127];
	player.session_and_hash(string, hash);
	player.populate();
	CreateTimer(1800.0, GiveExperience, GetClientSerial(client), TIMER_REPEAT);
}

public APLRes AskPluginLoad2(Handle plugin, bool late, char[] error, int err_max)
{
   RegPluginLibrary("ttt_upgrades");
   CreateNative("get_upgrade_points", Native_upgrades_get_upgrade_points);
   CreateNative("set_upgrade_points", Native_upgrades_set_upgrade_points);
}

public void OnClientCookiesCached(int client) {

}

public void OnClientDisconnect(int client) {
	// Reset upgrade points for the client who just disconnected.
	for (int upgrade = 0; upgrade < 64; upgrade++) {
		upg_points[client][upgrade] = 0;
	}
}

public int Native_upgrades_get_upgrade_points(Handle plugin, int numParams)
{
	if (numParams != 2) return -1;

	int client_id = GetNativeCell(1);
	int upgrade_id = GetNativeCell(2);
	return upg_points[client_id][upgrade_id];
}

public Native_upgrades_set_upgrade_points(Handle plugin, int numParams) {
	if (numParams != 3) {
		PrintToServer("Warning, set_upgrade_points was not called correctly.");
		return;
	}

	int client_id = GetNativeCell(1);
	int upgrade_id = GetNativeCell(2);
	int points = GetNativeCell(3);
	upg_points[client_id][upgrade_id] = points;
}

public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	// Not enough players...
	if (count_players() < 4) return Plugin_Continue;
	// Suicide...
	if (victim == attacker) return Plugin_Continue;
	// Killed by world...
	if (attacker == 0 || victim == 0) return Plugin_Continue;

	Player player = Player(attacker);

	char attacker_auth[256];
	player.get_auth(AuthId_Steam2, attacker_auth);

	if (player.bad_kill(victim)) {
		player.experience -= 10
	} else {
		if (player.role == TRAITOR) {
			player.experience += 5
		} else {
			player.experience += 20
		}
	}

	return Plugin_Continue;
}

public void TTT_OnBodyFound(int client, int victim, const char[] deadPlayer) {
	Player(client).experience += 2;
}

public Action command_display_experience(int client, int args) {
	char target[128] = "@me";
	if (args > 0) {
		GetCmdArg(1, target, sizeof(target));
	}

	int target_client = Player(client).target_one(target)
	if (target_client == -1) return Plugin_Handled;

	Player target_player = Player(target_client);

	CPrintToChat(client, "{purple}[TTT] {yellow}%N currently has %d experience and is level %d.", target_client, target_player.experience, 1)

	return Plugin_Handled;
}

public Action command_display_upgrades(int client, int args) {
	char target[128] = "@me";
	if (args > 0) {
		GetCmdArg(1, target, sizeof(target));
	}

	//CPrintToChat(client, "{purple}[TTT] {orchid}I hate life, seriously, I do.");

	int target_client;

	if (StringToInt(target) == 0) {
		target_client = Player(client).target_one(target);
		if (target_client == -1) return Plugin_Handled;
	} else {
		target_client = StringToInt(target);
		CPrintToChat(client, "{purple}[TTT] {yellow}Upgrades for {green}%d {yellow}have been printed in console.", target_client);

		for (int upgrade_id = 0; upgrade_id < 31; upgrade_id++) {
			PrintToConsole(client, "Upgrade %d: %d", upgrade_id, upg_points[target_client][upgrade_id]);
		}

		return Plugin_Handled;
	}

	Player target_player = Player(target_client);

	CPrintToChat(client, "{purple}[TTT] {yellow}Upgrades for {green}%N {yellow}printed in console.", target_player.id);

	for (int upgrade_id = 0; upgrade_id < 31; upgrade_id++) {
		PrintToConsole(client, "Upgrade %d: %d", upgrade_id, target_player.has_upgrade(upgrade_id));
	}

	return Plugin_Handled;
}

public Action command_experience(int client, int args) {
	if (args != 2) {
		CPrintToChat(client, "{purple}[TTT] {orchid}Invalid command usage, expects: /setexperience <target> <experience>");
		return Plugin_Handled;
	}

	char target[128], experience_string[128];
	GetCmdArg(1, target, sizeof(target));
	GetCmdArg(2, experience_string, sizeof(experience_string));

	int target_player = Player(client).target_one(target)
	if (target_player == -1) return Plugin_Handled;

	int experience = StringToInt(experience_string);
	if (experience == 0) experience = 0;

	Player(target_player).experience = experience;

	CPrintToChat(client, "{purple}[TTT] {yellow}Set experience on %N to %d.", target_player, experience);

	return Plugin_Handled;
}

public Action command_level(int client, int args) {
	if (args != 2) {
		CPrintToChat(client, "{purple}[TTT] {orchid}Invalid command usage, expects: /setlevel <target> <level>");
		return Plugin_Handled;
	}

	char target[128], level_string[128];
	GetCmdArg(1, target, sizeof(target));
	GetCmdArg(2, level_string, sizeof(level_string));

	int target_player = Player(client).target_one(target);
	if (target_player == -1) return Plugin_Handled;

	int level = StringToInt(level_string);
	if (level == 0) level = 0;

	Player(target_player).level = level;

	CPrintToChat(client, "{purple}[TTT] {yellow}Set experience on %N to %d.", target_player, level);

	return Plugin_Handled;
}

public Action command_update_info(int client, int args) {
	if (args != 2) {
		if (client != 0) {
			CPrintToChat(client, "{purple}[TTT] {orchid}Invalid command usage, expects: /update_info <steam64> <hashmap>");
			return Plugin_Handled;
		}
	}

	char target[255], hashmap[255];
	GetCmdArg(1, target, sizeof(target));
	GetCmdArg(2, hashmap, sizeof(hashmap));

	int target_id = Get_Client(target, AuthId_SteamID64);

	if (target_id == -1) {
		PrintToServer("Warning, Steam_64 not found for %s", target)
		return Plugin_Handled;
	}

	// Do some fantastic stuff with these two values here...
	PrintToServer("Update Info Called, %s %s %d", target, hashmap, target_id);
	Player(target_id).populate();

	return Plugin_Handled;
}

public Action command_get_session(int client, int args) {
	Player player = Player(client);
	char session[63], hash[127];
	player.session_and_hash(session, hash);
	CPrintToChat(client, "{purple}[TTT] {yellow}Debug: Session: %s, Hash: %s", session, hash);
}

public Action command_populate(int client, int args) {
	Player(client).populate();
	CPrintToChat(client, "{purple}[TTT] {yellow}Debug: Populating your Upgrades");
}

public Action command_skills(int client, int args) {
	//char auth[255];
	//Player(client).get_auth(AuthId_Steam2, auth);
	//if (!StrEqual(auth, "STEAM_1:1:206820868") 
	//	&& !StrEqual(auth, "STEAM_1:0:39463079") 
	//	&& !StrEqual(auth, "STEAM_1:0:46721510")
	//	&& !StrEqual(auth, "STEAM_1:0:98095439")
	//	&& !StrEqual(auth, "STEAM_1:1:43937779")
	//) {
	//	CPrintToChat(client, "{purple}[TTT] {orchid}You are not authorised to use this command.");
	//	return Plugin_Handled;
	//}

	Player player = Player(client);
	player.display_skills_page();

	return Plugin_Handled;
}

public Action command_reset_skills(int client, int args) {
	Player(client).reset_skills();
	return Plugin_Handled;
}

public Action GiveExperience(Handle timer, any serial)
{
	int client = GetClientFromSerial(serial); // Validate the client serial
 
	if (client == 0) // The serial is no longer valid, the player must have disconnected
	{
		return Plugin_Stop;
	}

	int experience = 25;
	int team = GetClientTeam(client);

	if (team == CS_TEAM_T || team == CS_TEAM_CT) {
		experience = 50;
	}
 	

	CPrintToChat(client, "{purple}[TTT] {yellow}Thanks for playing, you've gained %d experience!", experience);

	Player player = Player(client);
	player.experience += experience;

	PrintToConsole(client, "Welcome to the server!");

	return Plugin_Continue;
}