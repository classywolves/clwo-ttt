#if defined _player_methodmap_included
	#endinput
#endif
#define _player_methodmap_included

#define that view_as<int>(this)

/* User Type */
#define USER_TYPE_COMMAND      0
#define USER_TYPE_IS_STAFF     1
#define USER_TYPE_BROADCAST    2
#define USER_TYPE_GROUPNAME    3
#define USER_TYPE_FULLNAME     4
#define USER_TYPE_SCORENAME    5
#define USER_TYPE_CHATNAME     6
#define USER_TYPE_MULTI_TARGET 7

#include <sourcemod> 			// Default Sourcemod Includes
#include <sdktools>				// ┫
#include <clientprefs>			// ┛
#include <general>				// General Definitions
#include <ttt>					// Interact with TTT
#include <ttt_shop>				// Interact with TTT Shop
#include <smlib>				// Larger Standard Library
#include <imod>

Handle cookie_player_volume;
Handle cookie_player_experience;
Handle cookie_player_level;
Handle cookie_player_slaynr;
Handle cookie_player_slayed_by;

int sprite_beam = -1;
int sprite_halo = -1;

bool player_beacon[MAXPLAYERS + 1];
bool third_person[MAXPLAYERS + 1];

bool website_payload[MAXPLAYERS + 1];

Database database_ttt;
Database database_player_analytics;

char chars[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890";

native int GetActions(int client, int actions[2]);
native int get_upgrade_points(int client_id, int upgrade_id);
native set_upgrade_points(int client_id, int upgrade_id, int points);

/*======== Upgrades ========*/
#define AllUpgrades for(int i = 1; i <= MaxClients; i++) for(int j = 1; j <= 64; j++)
#define PlayerUpgrades(%1) for(int %1 = 1; %1 <= 64; %1++)

#if defined _is_main_upgrade
	int upg_points[MAXPLAYERS+1][64];
#endif

methodmap Player {
	public Player(int client) {
		return view_as<Player>(client);
	}

	property int id {
		public get() { return that; }
	}
	public void get_auth(AuthIdType auth_id_type , char output[255]) {
		GetClientAuthId(view_as<int>(this), auth_id_type, output, sizeof(output));
	}

	public void slayed_by(int client, char admin_name[256]) {
		GetClientCookie(client, cookie_player_slayed_by, admin_name, sizeof(admin_name));
	}

	public void set_slayed_by(int client, char admin_name[256]) {
		SetClientCookie(client, cookie_player_slayed_by, admin_name);
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

	property bool alive {
		public get() { return IsPlayerAlive(that); }
	}

	public void pos(float loc[3]) {
		GetClientAbsOrigin(that, loc);
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

	public bool has_weapon(const char[] weapon) {
		return Client_HasWeapon(that, weapon);
	}

	public int has_upgrade(int upgrade_id) {
		return get_upgrade_points(that, upgrade_id);
	}

	public int set_upgrade(int upgrade_id, int points) {
		set_upgrade_points(that, upgrade_id, points);
	}

	public bool bad_kill(int victim) {
		int attacker_role = TTT_GetClientRole(that);
		int victim_role = TTT_GetClientRole(victim);

		if (victim == that || victim == 0 || that == 0) return false;

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

	property int credits {
		public get() { return TTT_GetClientCredits(that); }
		public set(int amount) { TTT_SetClientCredits(that, amount); }
	}

	property int level {
		public get() { return this.get_cookie_int(cookie_player_level, 1); }
		public set(int level) { this.set_cookie_int(cookie_player_level, level); }
	}

	property int slaynr {
		public get() { return this.get_cookie_int(cookie_player_slaynr, 0); }
		public set(int slaynr) { this.set_cookie_int(cookie_player_slaynr, slaynr); }
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
			this.get_auth(AuthId_Steam2, auth);

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

	property int level_up_experience {
		public get() {
			//return this.level * 1000;
			return RoundToFloor(this.level + 600 * Pow(2.0, (float(this.level) / 4.0)));
		}
	}

	property int karma {
		public get() {
			char auth[255];
			this.get_auth(AuthId_SteamID64, auth);

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
		public get() { return GetEntProp(this.id, Prop_Data, "m_iHealth", 4); }
		public set(int new_health) { SetEntProp(this.id, Prop_Send, "m_iHealth", new_health); }
	}
	
	property int max_health {
		public get() { return GetEntProp(this.id, Prop_Data, "m_iMaxHealth", 4); }
		public set(int new_max_health) { SetEntProp(this.id, Prop_Send, "m_iMaxHealth", new_max_health); }
	}

	// WIP
	public void populate() {
		char steam_id[255];
		this.get_auth(AuthId_SteamID64, steam_id);
		DBStatement player_skill_points = PrepareStatement(database_ttt, "SELECT * FROM `upgrades` WHERE steam_id=? LIMIT 1");
		SQL_BindParamString(player_skill_points, 0, steam_id, false);
		if (!SQL_Execute(player_skill_points)) { PrintToServer("User Skills grab failed."); return; }
		if (SQL_FetchRow(player_skill_points)) {
			int latest_value;
			for (int upgrade_id = 1; upgrade_id < 32; upgrade_id++) {
				latest_value = SQL_FetchInt(player_skill_points, upgrade_id);
				this.set_upgrade(upgrade_id, latest_value);
			}
		}
		return;
	}

	public void toggle_beacon() {
		player_beacon[this] = !player_beacon[this];
	}

	public void toggle_third_person() {
		this.third_person = !this.third_person;
	}

	public void display_url(char url[512], bool display=true) {
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
		if (display) {
			CPrintToChat(that, "{purple}[URL] {yellow}Loading {green}%s", url);
		}
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

	public bool has_informer_block() {
		char name[200];
		iMod_GetUserTypeString(iMod_GetUserType(that), USER_TYPE_FULLNAME, name, sizeof(name));
		if (!StrEqual(name, "Informer")) return false;
		if (!Count_Staff(false)) return false;
		return true;
	}

	public int target_one(char target[128]) {
		int target_index = FindTarget(that, target, true, false);

		if (target_index == -1) {
			CPrintToChat(that, "{purple}[TTT] {orchid}No targets were found.");
		}

		return target_index;
	}

	public void get_actions(int actions[2]) {
		GetActions(that, actions);
		//char auth[255];
		//this.get_auth(AuthId_Steam2, auth);

		//DBStatement player_actions = PrepareStatement(database_ttt, "SELECT bad_action,COUNT(*) AS count FROM `deaths` WHERE `killer_id`=? GROUP BY bad_action ORDER BY bad_action;");
		//SQL_BindParamString(player_actions, 0, auth, false);
		//if (!SQL_Execute(player_actions)) { PrintToServer("User Action Grab Failed."); return; }

		//while (SQL_FetchRow(player_actions)) {
		//	actions[SQL_FetchInt(player_actions, 0)] = SQL_FetchInt(player_actions, 1);
		//}
	}

	public void session_and_hash(char string[63], char hash[127]) {
		char auth[255];
		this.get_auth(AuthId_SteamID64, auth);
		DBStatement statement = PrepareStatement(database_ttt, "SELECT * FROM sessions WHERE steam_id=?");
		SQL_BindParamString(statement, 0, auth, false);
		if (!SQL_Execute(statement)) { PrintToServer("Session Search SQL Execute Failed..."); return; }

		if (SQL_FetchRow(statement)) {
			// A row was found!  Return the session.
			SQL_FetchString(statement, 1, string, sizeof(string));
			SQL_FetchString(statement, 2, hash, sizeof(hash));
		} else {
			// A row was not found.  Generate the session and insert it into the DB.
			char session_string[62];
			generate_session(session_string);
			DBStatement insert_statement = PrepareStatement(database_ttt, "INSERT INTO sessions (steam_id, session_id, skill_hash, skill_points) VALUES (?, ?, \"\", ?);");
			SQL_BindParamString(insert_statement, 0, auth, false);
			SQL_BindParamString(insert_statement, 1, session_string, false);
			SQL_BindParamInt(insert_statement, 2, this.skill_points, false);
			if (!SQL_Execute(insert_statement)) { PrintToServer("Session Set SQL Execute Failed..."); return; }
		}

		return;
	}

	public void display_skills_page() {
		char url[512], session[63], hash[127];
		this.session_and_hash(session, hash);
		Format(url, sizeof(url), "http://ttt.clwo.eu:3000/#^%s^%s", hash, session);
		this.display_url(url, false);
	}

	property int experience {
		public get() { 
			return this.get_cookie_int(cookie_player_experience, 0);
		}
		public set(int experience) {
			this.set_cookie_int(cookie_player_experience, experience);
			check_level(this);
			show_experience_bar(this);
		}
	}

	public void profile(int client) {
		Player player = Player(client);

		// We still need to get colours sorted out.
		int actions[2];
		char exp_bar[80];
		player.get_actions(actions);
		get_experience_bar(player, exp_bar);

		int good_action_percentage = RoundFloat(float(actions[0]) * 100 / float(actions[0] + actions[1]));
		// Fix for azure's report where having a 0 in the total actions will cause a very large negative percentage.
		if (actions[0] + actions[1] < 1) { good_action_percentage = 50; }
		char good_action_colour[32] = "{GREEN}";

		// We have nine lines to work with...
		CPrintToChat(that, "┏━━━━━━━━━━━━━ {GREEN}%.24N {DEFAULT}━━━━━━━━━━━━━━", client);
		CPrintToChat(that, "┃ Playtime: %d hours", RoundFloat(float(player.playtime) / 3600));
		CPrintToChat(that, "┃ Karma: %d ({GREEN}+%d{DEFAULT}, {RED}-%d{DEFAULT}, %s%d%s)", player.karma, actions[0], actions[1], good_action_colour, good_action_percentage, "%%");
		CPrintToChat(that, "┃ Level: %d (%d / %d | %d%s)", player.level, player.experience, player.level_up_experience, Percentage(player.experience, player.level_up_experience - player.experience), "%%");
		CPrintToChat(that, "┃ EXP: %s", exp_bar);
		CPrintToChat(that, "┃ ");
		CPrintToChat(that, "┃ ");
		CPrintToChat(that, "┃ ");
		CPrintToChat(that, "┗━━━━━━━━━━━━━ {GREEN}%.24N {DEFAULT}━━━━━━━━━━━━━━", client);
	}

	public void reset_skills() {
		char auth[255], query[255];
		this.get_auth(AuthId_SteamID64, auth);
		FormatEx(query, sizeof(query), "DELETE FROM `sessions` WHERE `steam_id`=\"%s\"", auth);
		PrintToServer("Running query: %s", query);
		SQL_FastQuery(database_ttt, query);
	}
}

public void check_level(Player player) {
	//PrintToServer("Check level called on %N: %d > %d", player.id, player.experience, player.level_up_experience)
	if (player.experience > player.level_up_experience) {
		player.experience -= player.level_up_experience;
		int new_level = player.level + 1;
		player.level = new_level;
		CPrintToChat(player.id, "{purple}[TTT] {green}Congratulations!  You've levelled up to level %d", new_level);
		ClientCommand(player.id, "play */ttt_clwo/ttt_levelup.mp3");

		char auth[255], query[255];
		player.get_auth(AuthId_SteamID64, auth);
		FormatEx(query, sizeof(query), "UPDATE `sessions` SET `skill_points` = %d WHERE `steam_id` = \"%s\"", new_level, auth);
		PrintToServer("Running query: %s", query);
		if (!SQL_FastQuery(database_ttt, query))
		{
			char error[255];
			SQL_GetError(database_ttt, error, sizeof(error));
			PrintToServer("Failed to query (error: %s)", error);
		}
	}
}

public void show_experience_bar(Player player)
{
	char unicode_bar[80];
	char introduction[100] = "Exp: ";
	get_experience_bar(player, unicode_bar);
	StrCat(introduction, sizeof(introduction), unicode_bar);
	Handle hHudText = CreateHudSynchronizer();
	SetHudTextParams(0.01, 0.01, 5.0, 255, 128, 0, 255, 0, 0.0, 0.0, 0.0);
	ShowSyncHudText(player.id, hHudText, introduction);
	CloseHandle(hHudText);
}

public void generate_session(char session_string[62]) {
	for (int i = 0; i < 60; i++) {
		int random_int = GetRandomInt(0, 61);
		Format(session_string, sizeof(session_string), "%s%c", session_string, chars[random_int])
	}
}

public void get_experience_bar(Player player, char unicode_bar[80]) {
	const int bar_size = 80;
	const int num_bars = 20;

	float level_up_percentage = float(player.experience) / float(player.level_up_experience);
	int coloured_squares = RoundFloat(num_bars * level_up_percentage);

	//CPrintToChat(player.id, "Bar Size: %d, Levelup Percentage: %f, Total Bars: %d", bar_size, level_up_percentage, coloured_squares, num_bars);

	for (int i = 0; i < num_bars; i++) {
		//CPrintToChat(player.id, "Bar: %s", unicode_bar);
		if (i <= coloured_squares) {
			StrCat(unicode_bar, bar_size, "▰");
			//CPrintToChat(player.id, "Adding filled in bar: %d", i);
		}
		else {
			StrCat(unicode_bar, bar_size, "▱");
			//CPrintToChat(player.id, "Adding empty in bar: %d", i);
		}
		//CPrintToChat(player.id, "Bar: %s", unicode_bar);
	}

	//CPrintToChat(player.id, "Bar: %s", unicode_bar);
}
