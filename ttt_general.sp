#include <ttt_helpers>
#include <basecomm>
#include <player_methodmap>

#include <general>

Handle timer_end_beacons;

char urls[7][3][512] = {
	{ "sm_rules", "https://clwo.eu/thread-1614-post-15525.html#pid15525", "Opens the rules page" },
	{ "sm_clwo", "https://clwo.eu", "Opens the CLWO page" },
	{ "sm_group", "https://steamcommunity.com/groups/ClassyWolves", "Opens the Steam group page" },
	{ "sm_new", "https://clwo.eu/thread-2123-post-21215.html#pid21215", "Opens the new player page" },
	{ "sm_google", "https://google.com", "Opens the Google search page" },
	{ "sm_gametracker", "https://www.gametracker.com/server_info/ttt.clwo.eu:27015", "Opens the TTT Gametracker page" },
	{ "sm_welcome" , "https://ttt.clwo.eu/fastdl/welcome.html", "Opens the welcome page for TTT" }
}

public void OnPluginStart() {
	RegConsoleCmd("sm_profile", command_profile);
	RegConsoleCmd("sm_list", command_list);
	RegConsoleCmd("sm_give", command_give);
	RegAdminCmd("sm_cbeacon", command_toggle_beacon, ADMFLAG_GENERIC);
	RegAdminCmd("sm_teleport", command_teleport, ADMFLAG_GENERIC);
	RegAdminCmd("sm_tp", command_teleport, ADMFLAG_GENERIC);
	//RegAdminCmd("sm_volume", command_volume, ADMFLAG_GENERIC);
	//RegAdminCmd("sm_tp", command_toggle_third_person, ADMFLAG_CHEATS);
	RegAdminCmd("sm_reload", command_reload_plugin, ADMFLAG_CHEATS);

	LoadTranslations("common.phrases");

	for (int url = 0; url < sizeof(urls); url++) {
		RegConsoleCmd(urls[url][0], command_open_url, urls[url][2])
	}

	database_ttt = ConnectDatabase("ttt", "ttt");
	database_player_analytics = ConnectDatabase("player_analytics", "P_A");

	cookie_player_experience = RegClientCookie("player_experience", "Current experience player has.", CookieAccess_Private);
	cookie_player_level = RegClientCookie("player_level", "Current player level.", CookieAccess_Private);
	cookie_player_volume = RegClientCookie("player_volume", "Current player volume as percentage", CookieAccess_Private);

	HookEvent("round_start", OnRoundStart);
	HookEvent("round_end", OnRoundEnd, EventHookMode_PostNoCopy);
	//HookEvent("player_death", OnPlayerDeathPre, EventHookMode_Pre);
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("player_say", OnPlayerSay);

	CreateTimer(1.5, timer_beacon, 0, TIMER_REPEAT);

	LoopClients(client) if (AreClientCookiesCached(client)) OnClientCookiesCached(client);
}

public void OnMapStart() {
    sprite_beam = PrecacheModel("materials/sprites/laserbeam.vmt");
    sprite_halo = PrecacheModel("materials/sprites/glow.vmt");
}

OnClientDisconnect(int client) {
	player_beacon[client] = false;
}

public Action OnPlayerSay(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	char text[200];
	GetEventString(event, "text", text, 200);

	int total_chars = strlen(text)
	if (total_chars > 10) {
		int upper_case = 0;
		for (int character = 0; character < total_chars; character++) {
			if (IsCharUpper(text[character])) {
				upper_case++;
			}
		}
		if (float(upper_case) / float(total_chars) > 0.7) {
			Player(client).display_url("http://theoatmeal.com/pl/minor_differences/capslock");
			CPrintToChat(client, "{purple}[TTT] {orchid}Please calm the caps! :o")
		}
	}
}

//public Action OnPlayerDeathPre(Event event, const char[] name, bool dontBroadcast) {
//	int client = GetClientOfUserId(GetEventInt(event, "userid"));
//	player_beacon[client] = false;
//	third_person[client] = false;

//	// For all players, see if they're within x units.
//	float dead_position[3];
//	GetClientEyePosition(client, dead_position)

//	LoopAliveClients(i) {
//		if (i != client) {
//			float alive_position[3];
//			GetClientEyePosition(i, alive_position);
//			float distance = GetVectorDistance(dead_position, alive_position, true);
//			if (distance < 3.0) {
//				// Person died too close to another person.  Remove body.
//				CPrintToChatAdmins(ADMFLAG_GENERIC, "Someone died close to a player (%f).", distance);
//				// BlockBody(client);
//			}
//		}
//	}

//	float ent_position[3];
//	int entity = -1;
//	while ((entity = FindEntityByClassname(entity, "prop_ragdoll")) != INVALID_ENT_REFERENCE) {
//		// Entity is a reference.
//		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", ent_position);
//		float distance = GetVectorDistance(dead_position, ent_position, true);
//		if (distance < 3.0) {
//			// Person died too close to a body.  Remove body.
//			CPrintToChatAdmins(ADMFLAG_GENERIC, "Someone died close to an ent (%f).", distance);
//			// BlockBody(client);
//		}
//	}

//	return Plugin_Continue;
//}

public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	player_beacon[client] = false;
	third_person[client] = false;
}

public Action OnRoundStart(Event event, const char[] name, bool dontBroadcast) {
	//CPrintToChatAll("{purple}[TTT] {yellow}Debug: Round Start Event Fired")
	timer_end_beacons = CreateTimer(210.0, timer_beacon_all);

	LoopAliveClients(client) {
		Player player = Player(client);
		if (player.has_clan_tag && player.armour == 0) {
			player.armour += 10;
		}

		player.third_person = false;
	}

	return Plugin_Continue;
}

public Action OnRoundEnd(Event event, const char[] name, bool dontBroadcast) {
	LoopClients(client) {
		player_beacon[client] = false;
		third_person[client] = false;
	}

	//CPrintToChatAll("{purple}[TTT] {yellow}Debug: Round End Event Fired")
	KillTimer(timer_end_beacons);
	return Plugin_Continue;
}

OnClientCookiesCached(int client) {
	Player player = Player(client);
	// player.volume = player.volume;
}

public Action command_toggle_beacon(int client, int args) {
	if (args == 0) {
		Player(client).toggle_beacon();
	} else if (args == 1) {
		char target[128], target_name[128];
		int targets[MAXPLAYERS];

		GetCmdArg(1, target, sizeof(target));
		int response = Player(client).target(target, targets, target_name, true, false);

		for (int i = 0; i < sizeof(targets); i++) {
			if (targets[i]) {
				Player(targets[i]).toggle_beacon();
			} else {
				break;
			}
		}

		if (response > 0) {
			CPrintToChat(client, "{purple}[TTT] {yellow}Toggled beacons on %s.", target_name);
		}
	}
	
	return Plugin_Handled;
}

public Action command_teleport(int client, int args)
{
	Player player = Player(client);

	if (player.has_informer_block()) {
		CPrintToChat(client, "{purple}[TTT] {orchid}Not enough permissions.")
		return Plugin_Handled;
	}

	if (args < 1 || args > 2) {
		CPrintToChat(client, "{purple}[TTT] {orchid}Invalid command usage, expects: /teleport <player> or /teleport <player> <target_player>");
		return Plugin_Handled;
	}

	char from[128];
	GetCmdArg(1, from, sizeof(from));

	int player_from_int = player.target_one(from);
	if (player_from_int == -1) return Plugin_Handled;

	Player player_from = Player(player_from_int);

	if (!player_from.alive) // only matters that the player being moved is alive, allows admins to tp whilst dead.
	{
		CPrintToChat(client, "{purple}[TTT] {orchid}The player being teleported must be alive.");
		return Plugin_Handled;
	}
	
	float pos[3];
	
	if (args == 1)
	{
		if (rayTrace(client, pos) == 1)
		{ 
			CPrintToChat(client, "{purple}[TTT] {orchid}Please look at a valid location to teleport a player too.");
			return Plugin_Handled;
		}

		char staff_message[512];
		Format(staff_message, sizeof(staff_message), "{purple}[TP] {yellow}%N teleported %N to where he was looking", client, player_from_int);
		CPrintToStaff(staff_message);
	}
	else
	{
		char target[128];
		GetCmdArg(2, target, sizeof(target));
		int player_target_int = player.target_one(target);
		
		if (player_target_int == -1) return Plugin_Handled;
		
		Player player_target = Player(player_target_int);
		player_target.pos(pos);
		char staff_message[512];
		Format(staff_message, sizeof(staff_message), "{purple}[TP] {yellow}%N teleported %N to %N", client, player_from_int, player_target_int);
		CPrintToStaff(staff_message);
	}
	
	pos[2] += 4;

	TeleportEntity(player_from.id, pos, NULL_VECTOR, NULL_VECTOR);
	return Plugin_Handled;
}

public int rayTrace(int client, float pos[3])
{
	float vOrigin[3], vAngles[3];
	
	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);
	
	Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SOLID, RayType_Infinite, TraceEntityFilterPlayer);
	
	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(pos, trace);
		CloseHandle(trace);
		
		return 0;
	}
	
	CloseHandle(trace);
	return 1;
}

public bool TraceEntityFilterPlayer(entity, contentsMask)
{
	return entity > MaxClients;
}

public Action command_volume(int client, int args) {
	if (args != 2) {
		CPrintToChat(client, "{purple}[TTT] {orchid}Invalid command usage, expects: /volume <target> <percentage>");
		return Plugin_Handled;
	}

	char target[128], volume_string[128];
	GetCmdArg(1, target, sizeof(target));
	GetCmdArg(2, volume_string, sizeof(volume_string));

	int target_player = Player(client).target_one(target)
	if (target_player == -1) return Plugin_Handled;

	float volume = StringToFloat(volume_string);
	if (volume == 0.0) volume = 100.0;

	Player(target_player).volume = volume;

	CPrintToChat(client, "{purple}[TTT] {yellow}Set volume on %N to %.0f%s.", target_player, volume, "%%");

	return Plugin_Handled;
}

public Action command_toggle_third_person(int client, int args) {
	if (Player(client).has_informer_block()) {
		CPrintToChat(client, "{purple}[TTT] {orchid}Not enough permissions.")
		return Plugin_Handled;
	}

	if (args == 0) {
		Player(client).toggle_third_person();
	} else if (args == 1) {
		char target[128], target_name[128];
		int targets[MAXPLAYERS];

		GetCmdArg(1, target, sizeof(target));
		int response = Player(client).target(target, targets, target_name, true, false);

		for (int i = 0; i < sizeof(targets); i++) {
			if (targets[i]) {
				Player(targets[i]).toggle_third_person();
			} else {
				break;
			}
		}

		if (response > 0) {
			CPrintToChat(client, "{purple}[TTT] {yellow}Toggled third person on %s.", target_name);
		}
	}
	
	return Plugin_Handled;
}

public Action command_reload_plugin(int client, int args) {
	if (args == 0) {
		CPrintToChat(client, "{purple}[TTT] {orchid}Invalid usage, /reload <plugin_name>");
		return Plugin_Handled;
	}

	char plugin_name[128]
	GetCmdArg(1, plugin_name, sizeof(plugin_name));

	char load[1024], reload[1024];
	ServerCommandEx(reload, sizeof(reload), "sm plugins reload %s", plugin_name);
	PrintToConsole(client, reload);
	ServerCommandEx(load, sizeof(load), "sm plugins load %s", plugin_name);
	PrintToConsole(client, load);
	CPrintToChat(client, "{purple}[TTT] {yellow}Reloaded %s successfully!", plugin_name);

	return Plugin_Handled;
}

public Action command_profile(int client, int args) {
	if (args == 0) {
		Player(client).profile(client);
	} else if (args == 1) {
		char target[128];

		GetCmdArg(1, target, sizeof(target));
		int target_client = Player(client).target_one(target);

		if (target_client != -1) {
			Player(client).profile(target_client);
		}
	}
	
	return Plugin_Handled;
}

public Action command_list(int client, int args) {
	int player_array[MAXPLAYERS + 1][5];
	LoopValidClients(i) {
		Player player = Player(i)
		int actions[2];
		player.get_actions(actions);
		player_array[i][0] = player.karma
		player_array[i][1] = player.level
		//player_array[i][2] = actions[0]
		//player_array[i][3] = actions[1]
		player_array[i][4] = i
	}

	SortCustom2D(player_array, MAXPLAYERS + 1, SortPlayerItems);

	for (int i = 0; i < MAXPLAYERS + 1; i++) {
		if (player_array[i][0] != 0) {
			PrintToConsole(client, "%d %d %d %d %N", player_array[i][0], player_array[i][1], player_array[i][2], player_array[i][3], player_array[i][4])
		}
	}
	
	return Plugin_Handled;
}

public SortPlayerItems(int[] a, int[] b, const int[][] array, Handle hndl) {
	if (b[0] == a[0]) return 0;
	if (b[0] > a[0]) return 1;
	return -1;
}

public Action command_open_url(int client, int args) {
	char page[128];
	GetCmdArg(0, page, sizeof(page));

	for (int url = 0; url < sizeof(urls); url++) {
		if (strcmp(page, urls[url][0]) == 0) {
			Player(client).display_url(urls[url][1])
			return Plugin_Handled;
		}
	}

	CPrintToChat(client, "{purple}[TTT] {orchid}Invalid URL.  This code should be unreachable.");
	return Plugin_Handled;
}

public Action timer_beacon(Handle Timer) {
	LoopAliveClients(client) {
		Player player = Player(client);
		//CPrintToChatAll("{purple}[TTT] {yellow}Debug: Testing Ping For: %N", client);
		if (player.beacon_enabled) {
			//CPrintToChatAll("{purple}[TTT] {yellow}Debug: Beacon Ping For: %N", client);
			player.beacon_ping(colour_cyan)
		}
	}
}

public Action timer_beacon_all(Handle Timer) {
	CPrintToChatAll("{purple}[TTT] {yellow}There's only one minute thirty left!");
	LoopAliveClients(client) {
		//CPrintToChatAll("{purple}[TTT] {yellow}Debug: Enabled Beacon For: %N", client);
		Player(client).beacon_enabled = true;
	}
}


public Action command_give(int client, int args) {
	if (args < 2) {
		CPrintToChat(client, "{purple}[TTT] {red}Invalid arguments, usage: /give <player> <amount>");
		return Plugin_Handled;
	}

	char target_argument[128], amount_argument[64];
	GetCmdArg(1, target_argument, sizeof(target_argument));
	GetCmdArg(2, amount_argument, sizeof(amount_argument));

	int amount = StringToInt(amount_argument);

	if (amount == 0) {
		CPrintToChat(client, "{purple}[TTT] {red}Invalid amount, must be a number.");
		return Plugin_Handled;
	}

	Player player = Player(client);

	if (!player.alive) {
		CPrintToChat(client, "{purple}[TTT] {red}You must be alive to give credits.");
		return Plugin_Handled;
	}
	
	int target_client = Player(client).target_one(target_argument);
	if (target_client == -1) return Plugin_Handled;

	Player target = Player(target_client);

	if (player.credits < amount) {
		CPrintToChat(client, "{purple}[TTT] {red}You don't have enough credits!");
		return Plugin_Handled;
	}

	if (amount < 0) {
		CPrintToChat(client, "{purple}[TTT] {red}Don't try to steal other players credits!");
		return Plugin_Handled;
	}

	player.credits -= amount;
	target.credits += amount;

	CPrintToChat(client, "{purple}[TTT] {yellow}You have given {blue}%d{yellow} credits to {blue}%N{yellow}.", amount, target_client);
	CPrintToChat(target_client, "{purple}[TTT] {yellow}You have received {blue}%d{yellow} credits from {blue}%N{yellow}.", amount, client);

	return Plugin_Handled;	
}