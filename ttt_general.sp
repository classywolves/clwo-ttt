#include <sourcemod>
#include <sdktools>
#include <ttt>
#include <colorvariables>
#include <general>
#include <imod>
#include <clientprefs>

#define ValidClientsAlive(%1) for(int %1 = 1; %1 <= MaxClients; %1++) if(Player(%1).valid_client && Player(%1).alive)
#define ValidClients(%1) for(int %1 = 1; %1 <= MaxClients; %1++) if(Player(%1).valid_client)
#define StaffClients(%1) for(int %1 = 1; %1 <= MaxClients; %1++) if(Player(%1).staff)
#define Clients(%1) for(int %1 = 1; %1 <= MaxClients; %1++)

Handle cookie_player_volume;

int sprite_beam = -1;
int sprite_halo = -1;

int color_grey[4]	= {128, 128, 128, 255};
int color_red[4]	= {255, 0, 0, 255};
int color_green[4]	= {0, 255, 0, 255};
int color_blue[4]	= {0, 0, 255, 255};
int color_cyan[4]   = {0, 255, 255, 255};

bool player_beacon[MAXPLAYERS + 1];
bool third_person[MAXPLAYERS + 1];

Handle timer_end_beacons;

Database database_ttt;
Database database_player_analytics;

methodmap Player {
	public Player(int client) {
		return view_as<Player>(client);
	}

	property bool beacon_enabled {
		public get() { return player_beacon[this]; }
		public set(bool enable) { player_beacon[this] = enable; }
	}

	property bool valid_client {
		public get() {
			return !(this <= 0 || this > MaxClients || !IsClientConnected(this) || !IsClientInGame(this) || IsFakeClient(this))
		}
	}

	property bool alive {
		public get() { return IsPlayerAlive(this); }
	}

	property int armour {
		public get() { return GetEntProp(this, Prop_Data, "m_ArmorValue"); }
		public set(int armour) { SetEntProp(this, Prop_Data, "m_ArmorValue", armour, 1); }
	}

	property int team {
		public get() { return GetClientTeam(this); }
		public set(int team) { ChangeClientTeam(this, team); }
	}

	property bool staff {
		public get() { return iMod_IsStaff(this); }
	}

	property bool has_clan_tag {
		public get() {
			char player_clan_id[64];
			GetClientInfo(this, "cl_clanid", player_clan_id, sizeof(player_clan_id));
			return StrEqual(player_clan_id, "5157979");
		}
	}

	public void staff_name(char name[255]) {
		iMod_GetUserTypeString(iMod_GetUserType(this), USER_TYPE_FULLNAME, name, sizeof(name));
	}

	property bool third_person {
		public get() { return third_person[this]; }
		public set(bool enable) {
			third_person[this] = enable;
			if (enable) {
				ClientCommand(this, "thirdperson");
			} else {
				ClientCommand(this, "firstperson");
			}
		}
	}

	public void auth_2(char auth_id[255]) {
		GetClientAuthId(this, AuthId_Steam2, auth_id, sizeof(auth_id));
	}

	public void auth_64(char auth_id[255]) {
		GetClientAuthId(this, AuthId_SteamID64, auth_id, sizeof(auth_id));
	}

	property float volume {
		public get() {
			char player_volume[64];
			GetClientCookie(this, cookie_player_volume, player_volume, sizeof(player_volume));
			if (player_volume[0] == '\0') return 100.0;
			return StringToFloat(player_volume);
		}
		public set(float volume) {
			char player_volume[64];
			FloatToString(volume, player_volume, sizeof(player_volume));
			SetClientCookie(this, cookie_player_volume, player_volume);
			FadeClientVolume(this, volume, 0.5, 99999.0, 0.5);
		}
	}

	property int playtime {
		public get() {
			char auth[255];
			this.auth_2(auth);

			DBStatement player_playtime = PrepareStatement(database_player_analytics, "SELECT SUM(`duration`) FROM `player_analytics` WHERE auth=? LIMIT 1");
			SQL_BindParamString(player_playtime, 0, auth, false);
			if (!SQL_Execute(player_playtime)) { PrintToServer("Player Analaytics Sum Failed."); return Plugin_Continue; }

			if (SQL_FetchRow(player_playtime)) {
				return SQL_FetchInt(player_playtime, 0);
			} else {
				return 0;
			}
		}
	}

	property int karma {
		public get() {
			char auth[255];
			this.auth_64(auth);

			DBStatement player_karma = PrepareStatement(database_ttt, "SELECT `karma` FROM `ttt` WHERE communityid=? LIMIT 1");
			SQL_BindParamString(player_karma, 0, auth, false);
			if (!SQL_Execute(player_karma)) { PrintToServer("User Karma Grab Failed."); return Plugin_Continue; }

			if (SQL_FetchRow(player_karma)) {
				return SQL_FetchInt(player_karma, 0);
			} else {
				return 100;
			}
		}
	}

	public void toggle_beacon() {
		player_beacon[this] = !player_beacon[this];
	}

	public void toggle_third_person() {
		this.third_person = !this.third_person;
	}

	public void beacon_ping(int color[4]) {
		float vec[3];
		GetClientAbsOrigin(this, vec);
		vec[2] += 10;

		TE_SetupBeamRingPoint(vec, 10.0, 600.0, sprite_beam, sprite_halo, 0, 15, 0.5, 5.0, 0.0, color, 10, 0);
		TE_SendToAll();
	}

	public int target(char target[128], int targets[MAXPLAYERS], char target_name[128], bool alive, bool immunity) {
		bool translation;
		int filter = 0;
		if (alive) { filter = COMMAND_FILTER_ALIVE; }
		if (!immunity) { filter = filter | COMMAND_FILTER_NO_IMMUNITY; }
		int response = ProcessTargetString(target, this, targets, sizeof(targets), filter, target_name, sizeof(target_name), translation);

		if (response == 0 || response == -5) {
			CPrintToChat(this, "{purple}[TTT] {orchid}No targets were found.");
			return 0;
		} else if (response == -7) {
			CPrintToChat(this, "{purple}[TTT] {orchid}Partial name had too many targets.");
			return 0;
		}

		return response;
	}

	public int target_one(char target[128]) {
		int target_index = FindTarget(this, target, true, false);

		if (target_index == -1) {
			CPrintToChat(this, "{purple}[TTT] {orchid}No targets were found.");
		}

		return target_index;
	}

	public void get_actions(int actions[2]) {
		char auth[255];
		this.auth_2(auth);

		DBStatement player_actions = PrepareStatement(database_ttt, "SELECT bad_action,COUNT(*) AS count FROM `deaths` WHERE `killer_id`=? GROUP BY bad_action ORDER BY bad_action;");
		SQL_BindParamString(player_actions, 0, auth, false);
		if (!SQL_Execute(player_actions)) { PrintToServer("User Action Grab Failed."); return Plugin_Continue; }

		while (SQL_FetchRow(player_actions)) {
			actions[SQL_FetchInt(player_actions, 0)] = SQL_FetchInt(player_actions, 1);
		}

		return 0;
	}

	public void profile(int client) {
		Player player = Player(client);

		// We still need to get colours sorted out.
		int actions[2];
		player.get_actions(actions);

		int good_action_percentage = RoundFloat(float(actions[0]) * 100 / float(actions[0] + actions[1]));
		char good_action_colour[32] = "{GREEN}";

		// We have nine lines to work with...
		CPrintToChat(this, "┏━━━━━━━━━━━━━ {GREEN}%.24N {DEFAULT}━━━━━━━━━━━━━━", client);
		CPrintToChat(this, "┃ Playtime: %d", this.playtime);
		CPrintToChat(this, "┃ Karma: %d ({GREEN}+%d{DEFAULT}, {RED}-%d{DEFAULT}, %s%d%s)", this.karma, actions[0], actions[1], good_action_colour, good_action_percentage, "%%");
		CPrintToChat(this, "┃ Playtime: ");
		CPrintToChat(this, "┃ Playtime: ");
		CPrintToChat(this, "┃ Playtime: ");
		CPrintToChat(this, "┃ Playtime: ");
		CPrintToChat(this, "┃ Playtime: ");
		CPrintToChat(this, "┗━━━━━━━━━━━━━ {GREEN}%.24N {DEFAULT}━━━━━━━━━━━━━━", client);
	}
}

public void OnPluginStart() {
	RegAdminCmd("sm_cbeacon", command_toggle_beacon, ADMFLAG_GENERIC);
	//RegAdminCmd("sm_volume", command_volume, ADMFLAG_GENERIC);
	RegAdminCmd("sm_profile", command_profile, ADMFLAG_GENERIC);
	RegAdminCmd("sm_tp", command_toggle_third_person, ADMFLAG_CHEATS);

	database_ttt = ConnectDatabase("ttt", "ttt");
	database_player_analytics = ConnectDatabase("player_analytics", "P_A");

	cookie_player_volume = RegClientCookie("player_volume", "Current player volume as percentage", CookieAccess_Private);

	HookEvent("round_start", OnRoundStart);
	HookEvent("round_end", OnRoundEnd, EventHookMode_PostNoCopy);
	HookEvent("player_death", OnPlayerDeath);

	CreateTimer(1.5, timer_beacon, 0, TIMER_REPEAT);

	Clients(client) {
		if (AreClientCookiesCached(client)) OnClientCookiesCached(client);
	}
}

public void OnMapStart() {
    sprite_beam = PrecacheModel("materials/sprites/laserbeam.vmt");
    sprite_halo = PrecacheModel("materials/sprites/glow.vmt");
}

OnClientDisconnect(int client) {
	player_beacon[client] = false;
}

public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	player_beacon[client] = false;
	third_person[client] = false;

	return Plugin_Continue;
}

public Action OnRoundStart(Event event, const char[] name, bool dontBroadcast) {
	//CPrintToChatAll("{purple}[TTT] {yellow}Debug: Round Start Event Fired")
	timer_end_beacons = CreateTimer(210.0, timer_beacon_all);

	ValidClientsAlive(client) {
		Player player = Player(client);
		if (player.has_clan_tag) {
			player.armour += 10;
		}
	}

	return Plugin_Continue;
}

public Action OnRoundEnd(Event event, const char[] name, bool dontBroadcast) {
	Clients(client) {
		player_beacon[client] = false;
		third_person[client] = false;
	}

	//CPrintToChatAll("{purple}[TTT] {yellow}Debug: Round End Event Fired")
	KillTimer(timer_end_beacons);
	return Plugin_Continue;
}

OnClientCookiesCached(int client) {
	Player player = Player(client);
	player.volume = player.volume;
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

public Action timer_beacon(Handle Timer) {
	ValidClientsAlive(client) {
		Player player = Player(client);
		//CPrintToChatAll("{purple}[TTT] {yellow}Debug: Testing Ping For: %N", client);
		if (player.beacon_enabled) {
			//CPrintToChatAll("{purple}[TTT] {yellow}Debug: Beacon Ping For: %N", client);
			player.beacon_ping(color_cyan)
		}
	}
}

public Action timer_beacon_all(Handle Timer) {
	CPrintToChatAll("{purple}[TTT] {yellow}There's only one minute thirty left!");
	ValidClientsAlive(client) {
		//CPrintToChatAll("{purple}[TTT] {yellow}Debug: Enabled Beacon For: %N", client);
		Player(client).beacon_enabled = true;
	}
}