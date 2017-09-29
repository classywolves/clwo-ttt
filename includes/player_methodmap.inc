#if defined _player_methodmap_included
	#endinput
#endif
#define _player_methodmap_included

#include <sourcemod> 		// Default Sourcemod Includes
#include <sdktools>			// ┫
#include <clientprefs>		// ┛
#include <imod>				// iNilo Staff Functionality
#include <general>			// General Definitions
#include <colorvariables>	// Pretty Printing
#include <ttt>				// Interact with TTT
#include <smlib>			// Larger Standard Library

Handle cookie_player_volume;

int sprite_beam = -1;
int sprite_halo = -1;

bool player_beacon[MAXPLAYERS + 1];
bool third_person[MAXPLAYERS + 1];

bool website_payload[MAXPLAYERS + 1];

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

	public bool bad_kill(int victim) {
		int attacker_role = TTT_GetClientRole(this);
		int victim_role = TTT_GetClientRole(victim);

		return (victim_role - attacker_role == 1 || attacker_role - victim_role == 1)
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

	public void display_url(char url[512]) {
		char web_url[512];
		Crypt_Base64Encode(url, web_url, sizeof(web_url));

		char buffer[512];
		if (website_payload[this]) {
			Format(buffer, sizeof(buffer), "http://clwo.inilo.net/webredirect/payload/direct.php?website=%s", web_url);
		} else {
			Format(buffer, sizeof(buffer), "http://clwo.eu/webredirect/payload/direct.php?website=%s", web_url);
		}

		website_payload[this] = !website_payload[this];

		ShowMOTDPanel(this, "Displaying Page...", url, MOTDPANEL_TYPE_URL);
		CPrintToChat(this, "{purple}[URL] {yellow}Loading {green}%s", url);
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