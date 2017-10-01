#if defined _player_methodmap_included
	#endinput
#endif
#define _player_methodmap_included

#define that view_as<int>(this)

#include <sourcemod> 			// Default Sourcemod Includes
#include <sdktools>				// ┫
#include <clientprefs>			// ┛
#include <imod>					// iNilo Staff Functionality
#include <general>				// General Definitions
#include <colorvariables>		// Pretty Printing
#include <ttt>					// Interact with TTT
#include <smlib>				// Larger Standard Library
#include <database_methodmap>	// Helpers for working with a DB

Handle cookie_player_volume;
Handle cookie_player_experience;
Handle cookie_player_level;

int sprite_beam = -1;
int sprite_halo = -1;

bool player_beacon[MAXPLAYERS + 1];
bool third_person[MAXPLAYERS + 1];

bool website_payload[MAXPLAYERS + 1];

Database database_ttt;
Database database_player_analytics;

/*======== Upgrades ========*/
#define AllUpgrades for(int i = 1; i <= MaxClients; i++) for(int j = 1; j <= 64; j++)
int upg_points[MAXPLAYERS+1][64];
Handle skill_timers[MAXPLAYERS+1];

enum UpgradeTypes {
	health_regen
}

methodmap Upgrades {
    public Upgrades(int client) {
        return view_as<Upgrades>(client);
    }

    public int get_points(int skill_id) {
        return upg_points[view_as<int>(this)][skill_id];
    }
    public void set_points(int skill_id, int value) {
        upg_points[view_as<int>(this)][skill_id] = value;
    }
}


methodmap Player {
	public Player(int client) {
		return view_as<Player>(client);
	}

	property int id {
		public get() { return that; }
	}

	property bool beacon_enabled {
		public get() { return player_beacon[this]; }
		public set(bool enable) { player_beacon[this] = enable; }
	}

	property bool valid_client {
		public get() {
			return !(that <= 0 || that > MaxClients || !IsClientConnected(that) || !IsClientInGame(that) || IsFakeClient(that))
		}
	}

	property Upgrades upgrades {
		public get() {
			return view_as<Upgrades>(this);
		}
	}

	property bool alive {
		public get() { return IsPlayerAlive(that); }
	}

	property int armour {
		public get() { return GetEntProp(that, Prop_Data, "m_ArmorValue"); }
		public set(int armour) { SetEntProp(that, Prop_Data, "m_ArmorValue", armour, 1); }
	}

	property int team {
		public get() { return GetClientTeam(that); }
		public set(int team) { ChangeClientTeam(that, team); }
	}

	property bool staff {
		public get() { return iMod_IsStaff(that); }
	}

	property bool has_clan_tag {
		public get() {
			char player_clan_id[64];
			GetClientInfo(that, "cl_clanid", player_clan_id, sizeof(player_clan_id));
			return StrEqual(player_clan_id, "5157979");
		}
	}

	public bool bad_kill(int victim) {
		int attacker_role = TTT_GetClientRole(that);
		int victim_role = TTT_GetClientRole(victim);

		return !(victim_role - attacker_role == 1 || attacker_role - victim_role == 1);
	}

	property int role {
		public get() { return TTT_GetClientRole(that); }
	}

	public void staff_name(char name[255]) {
		iMod_GetUserTypeString(iMod_GetUserType(that), USER_TYPE_FULLNAME, name, sizeof(name));
	}

	property bool third_person {
		public get() { return third_person[this]; }
		public set(bool enable) {
			third_person[this] = enable;
			if (enable) {
				ClientCommand(that, "thirdperson");
			} else {
				ClientCommand(that, "firstperson");
			}
		}
	}

	public void auth_2(char auth_id[255]) {
		GetClientAuthId(that, AuthId_Steam2, auth_id, sizeof(auth_id));
	}

	public void auth_64(char auth_id[255]) {
		GetClientAuthId(that, AuthId_SteamID64, auth_id, sizeof(auth_id));
	}

	public int get_cookie_int(Handle cookie, int default_value) {
		char cookie_value[128];
		GetClientCookie(that, cookie, cookie_value, sizeof(cookie_value));
		if (cookie_value[0] == '\0') return default_value;
		return StringToInt(cookie_value);
	}

	public int set_cookie_int(Handle cookie, int value) {
		char cookie_value[64];
		IntToString(value, cookie_value, sizeof(cookie_value));
		SetClientCookie(that, cookie, cookie_value);
	}

	property int experience {
		public get() { return this.get_cookie_int(cookie_player_experience, 0); }
		public set(int experience) { this.set_cookie_int(cookie_player_experience, experience); check_level(this); }
	}

	property int level {
		public get() { return this.get_cookie_int(cookie_player_level, 1); }
		public set(int level) { this.set_cookie_int(cookie_player_level, level); }
	}

	property int skill_points {
		public get() { return this.level; }
		public set(int skill_points) { this.level = skill_points; }
	}

	property float volume {
		public get() {
			char player_volume[64];
			GetClientCookie(that, cookie_player_volume, player_volume, sizeof(player_volume));
			if (player_volume[0] == '\0') return 100.0;
			return StringToFloat(player_volume);
		}
		public set(float volume) {
			char player_volume[64];
			FloatToString(volume, player_volume, sizeof(player_volume));
			SetClientCookie(that, cookie_player_volume, player_volume);
			FadeClientVolume(that, volume, 0.5, 99999.0, 0.5);
		}
	}

	property int playtime {
		public get() {
			char auth[255];
			this.auth_2(auth);

			DBStatement player_playtime = PrepareStatement(database_player_analytics, "SELECT SUM(`duration`) FROM `player_analytics` WHERE auth=? LIMIT 1");
			SQL_BindParamString(player_playtime, 0, auth, false);
			if (!SQL_Execute(player_playtime)) { PrintToServer("Player Analaytics Sum Failed."); return -1; }

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
			if (!SQL_Execute(player_karma)) { PrintToServer("User Karma Grab Failed."); return -1; }

			if (SQL_FetchRow(player_karma)) {
				return SQL_FetchInt(player_karma, 0);
			} else {
				return 100;
			}
		}
	}

	property int health {
		public get() {
			return GetEntProp(this.id, Prop_Data, "m_iHealth", 4);
		}
		public set(int new_health) {
			SetEntProp(this.id, Prop_Data, "m_iHealth", new_health);
		}
	}
	// WIP
	public void populate(char steam_id[255]) {
			DBStatement player_karma = PrepareStatement(database_ttt, "SELECT * FROM `ttt.karma` WHERE steam_id=?");
			SQL_BindParamString(player_karma, 0, steam_id, false);
			if (!SQL_Execute(player_karma)) { PrintToServer("User Skills grab failed."); return -1; }

			int current_row = 0;
			while (SQL_FetchRow(player_karma)) {
				this.upgrades.set_points()
				current_row++;
				return SQL_FetchInt(player_karma, 0);

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

		ShowMOTDPanel(that, "Displaying Page...", buffer, MOTDPANEL_TYPE_URL);
		CPrintToChat(that, "{purple}[URL] {yellow}Loading {green}%s", url);
	}

	public void beacon_ping(int color[4]) {
		float vec[3];
		GetClientAbsOrigin(that, vec);
		vec[2] += 10;

		TE_SetupBeamRingPoint(vec, 10.0, 600.0, sprite_beam, sprite_halo, 0, 15, 0.5, 5.0, 0.0, color, 10, 0);
		TE_SendToAll();
	}

	public int target(char target[128], int targets[MAXPLAYERS], char target_name[128], bool alive, bool immunity) {
		bool translation;
		int filter = 0;
		if (alive) { filter = COMMAND_FILTER_ALIVE; }
		if (!immunity) { filter = filter | COMMAND_FILTER_NO_IMMUNITY; }
		int response = ProcessTargetString(target, that, targets, sizeof(targets), filter, target_name, sizeof(target_name), translation);

		if (response == 0 || response == -5) {
			CPrintToChat(that, "{purple}[TTT] {orchid}No targets were found.");
			return 0;
		} else if (response == -7) {
			CPrintToChat(that, "{purple}[TTT] {orchid}Partial name had too many targets.");
			return 0;
		}

		return response;
	}

	public int target_one(char target[128]) {
		int target_index = FindTarget(that, target, true, false);

		if (target_index == -1) {
			CPrintToChat(that, "{purple}[TTT] {orchid}No targets were found.");
		}

		return target_index;
	}

	public void get_actions(int actions[2]) {
		char auth[255];
		this.auth_2(auth);

		DBStatement player_actions = PrepareStatement(database_ttt, "SELECT bad_action,COUNT(*) AS count FROM `deaths` WHERE `killer_id`=? GROUP BY bad_action ORDER BY bad_action;");
		SQL_BindParamString(player_actions, 0, auth, false);
		if (!SQL_Execute(player_actions)) { PrintToServer("User Action Grab Failed."); return; }

		while (SQL_FetchRow(player_actions)) {
			actions[SQL_FetchInt(player_actions, 0)] = SQL_FetchInt(player_actions, 1);
		}
	}

	public void profile(int client) {
		Player player = Player(client);

		// We still need to get colours sorted out.
		int actions[2];
		player.get_actions(actions);

		int good_action_percentage = RoundFloat(float(actions[0]) * 100 / float(actions[0] + actions[1]));
		char good_action_colour[32] = "{GREEN}";

		// We have nine lines to work with...
		CPrintToChat(that, "┏━━━━━━━━━━━━━ {GREEN}%.24N {DEFAULT}━━━━━━━━━━━━━━", client);
		CPrintToChat(that, "┃ Playtime: %d", this.playtime);
		CPrintToChat(that, "┃ Karma: %d ({GREEN}+%d{DEFAULT}, {RED}-%d{DEFAULT}, %s%d%s)", this.karma, actions[0], actions[1], good_action_colour, good_action_percentage, "%%");
		CPrintToChat(that, "┃ Playtime: ");
		CPrintToChat(that, "┃ Playtime: ");
		CPrintToChat(that, "┃ Playtime: ");
		CPrintToChat(that, "┃ Playtime: ");
		CPrintToChat(that, "┃ Playtime: ");
		CPrintToChat(that, "┗━━━━━━━━━━━━━ {GREEN}%.24N {DEFAULT}━━━━━━━━━━━━━━", client);
	}

	public void session_and_hash(char string[63], char hash[127]) {
		char auth[255];
		this.auth_64(auth);
		DBStatement statement = PrepareStatement(database_ttt, "SELECT * FROM sessions WHERE steam_id=?");
		SQL_BindParamString(statement, 0, auth, false);
		if (!SQL_Execute(statement)) { PrintToServer("SQL Execute Failed..."); return; }

		if (SQL_FetchRow(statement)) {
			// A row was found!  Return the session.
			SQL_FetchString(statement, 1, string, sizeof(string));
			SQL_FetchString(statement, 2, hash, sizeof(hash));
		} else {
			// A row was not found.  Generate the session and insert it into the DB.
			int session_number = GetRandomInt(10000, 1000000000)
			IntToString(session_number, string, sizeof(string))
			DBStatement insert_statement = PrepareStatement(database_ttt, "INSERT INTO sessions (steam_id, session_id, skill_hash, skill_points) VALUES (?, ?, \"\", ?);");
			SQL_BindParamString(insert_statement, 0, auth, false);
			SQL_BindParamString(insert_statement, 1, string, false);
			SQL_BindParamInt(insert_statement, 2, this.skill_points, false);
			if (!SQL_Execute(insert_statement)) { PrintToServer("SQL Execute Failed..."); return; }
		}

		return;
	}

	public void display_skills_page() {
		char url[512], session[63], hash[127];
		this.session_and_hash(session, hash);
		Format(url, sizeof(url), "https://skills.ttt.clwo.eu/#^%s^%s", hash, session);
		this.display_url(url);
	}
}

public void check_level(Player player) {
	int level_up_experience = RoundToFloor(player.level + 300 * Pow(2.0, (float(player.level) / 7.0)))
	CPrintToChat(player.id, "%d %d", player.experience, level_up_experience);
	if (player.experience > level_up_experience) {
		CPrintToChat(player.id, "You've levelled up to %d", player.level + 1);
	}
}