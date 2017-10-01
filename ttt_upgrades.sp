#include <ttt_helpers>
#include <player_methodmap>

#include <ttt>
#include <general>

public void OnPluginStart() {
	RegAdminCmd("sm_experience", command_display_experience, ADMFLAG_GENERIC);
	RegAdminCmd("sm_setexperience", command_experience, ADMFLAG_ROOT);
	RegAdminCmd("sm_update_info", command_update_info, ADMFLAG_ROOT);
	RegAdminCmd("sm_session", command_get_session, ADMFLAG_ROOT);
	RegAdminCmd("sm_skills", command_skills, ADMFLAG_ROOT, "Opens the skill menu");
	RegAdminCmd("sm_skill", command_skills, ADMFLAG_ROOT, "Opens the skill menu");

	cookie_player_experience = RegClientCookie("player_experience", "Current experience player has.", CookieAccess_Private);
	cookie_player_level = RegClientCookie("player_level", "Current player level.", CookieAccess_Private);

	database_ttt = ConnectDatabase("ttt", "ttt");
	database_player_analytics = ConnectDatabase("player_analytics", "P_A");

	HookEvent("player_death", OnPlayerDeath);

	LoopClients(client) if (AreClientCookiesCached(client)) OnClientCookiesCached(client);
	LoopValidClients(client) OnClientPutInServer(client);
}

public void OnClientPutInServer(int client) {

}

public void OnClientCookiesCached(int client) {

}

public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	char attacker_auth[256];

	Player player = Player(attacker);
	player.auth_2(attacker_auth);

	if (!StrEqual(attacker_auth, "STEAM_1:0:39463079")) return Plugin_Continue;

	if (player.bad_kill(victim)) {
		player.experience -= 50 // TODO: Custom karma based on players & etc.
	} else {
		if (player.role == TRAITOR) {
			player.experience += 5
		} else {
			player.experience += 20
		}
	}

	CPrintToChat(attacker, "Your Experience is: %d", player.experience);

	return Plugin_Continue;
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

public Action command_experience(int client, int args) {
	if (args != 2) {
		CPrintToChat(client, "{purple}[TTT] {orchid}Invalid command usage, expects: /experience <target> <experience>");
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

public Action command_update_info(int client, int args) {
	if (args != 2) {
		if (client != 0) {
			CPrintToChat(client, "{purple}[TTT] {orchid}Invalid command usage, expects: /update_info <steam64> <hashmap>");
			return Plugin_Handled;
		}
	}

	char target[128], hashmap[256];
	GetCmdArg(1, target, sizeof(target));
	GetCmdArg(2, hashmap, sizeof(hashmap));

	int target_id = Get_Client(target, AuthId_SteamID64);

	if (target_id == -1) {
		PrintToServer("Warning, Steam_64 not found for %s", target)
		return Plugin_Handled;
	}

	// Do some fantastic stuff with these two values here...
	PrintToServer("Update Info Called, %s %s %d", target, hashmap, target_id);

	return Plugin_Handled;
}

public Action command_get_session(int client, int args) {
	Player player = Player(client);
	char session[63], hash[127];
	player.session_and_hash(session, hash);
	CPrintToChat(client, "{purple}[TTT] {yellow}Debug: Session: %s, Hash: %s", session, hash);
}

public Action command_skills(int client, int args) {
	Player player = Player(client);
	player.display_skills_page();
}