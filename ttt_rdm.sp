#undef REQUIRE_PLUGIN
#include <sourcemod>
#include <sdktools>
#include <colorvariables>
#include <imod>
#include <ttt>
#include <general>
#include <cstrike>

/* Plugin Info */
#define PLUGIN_NAME 			"TTT RDM"
#define PLUGIN_VERSION_M 		"0.0.4"
#define PLUGIN_AUTHOR 			"Popey"
#define PLUGIN_DESCRIPTION		"Handles TTT RDMs."
#define PLUGIN_URL				"https://sinisterheavens.com"

#define should_slay				1
#define should_warn				2

Database db;

/*
TODO:
 - Add a command to list deaths.
 - Add a command to search recents deaths per player.
 - Allow people to target by death number, instead of just shortid.
 - Profile: Karma, good actions, bad actions, percentage, playtime, innocent times, traitor times, longest traitorless streak
    
 - Create sm_verdict <case> - Menu with guilty or innocent.
 - Add menu after /rdm, whether the rdmer slain or not. (If found guilty).
 - Only store non-traitor kills.
 - Add "handled" column to the kills db, only show unhandled cases.
 - Add how many times a person has rdmed in a time period.
 - Merge a couple if int arrays together to make the code neater.
*/

public Plugin myinfo = {
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION_M,
	url = PLUGIN_URL
};

int max_index = 0;
int max_round = 0;
int round_time = 0;
int current_short_id = 0;

// Lists short_ids for RDMs
int short_ids[500];
int handled_by[500];
int case_accused[500];

// Lists clients to slay (1 = slay, 0 = don't slay)
int to_slay[MAXPLAYERS + 1];
int last_handled[MAXPLAYERS + 1];	// Store a staff's last handled case id.
int case_slay[500];		// Store a 1 if case wants the other person slain, 2 if to warn.
char slay_admins[MAXPLAYERS + 1][255];

// Number of times a person has been slain this map.
int slay_count[MAXPLAYERS + 1];

// Prevent spamming of rdm command
int rdm_cooldown[MAXPLAYERS + 1];

// Array of last player death indexes
// int player_death_index[MAXPLAYERS + 1];

// Array of last time players fired guns
int last_gun_fire[MAXPLAYERS + 1];

public StartTimers() {
	CreateTimer(1.0, Timer_1, _, TIMER_REPEAT);
	CreateTimer(60.0, Timer_60, _, TIMER_REPEAT);
}

public InitialiseVariables() {
	db = ConnectDatabase("ttt", "TTT");
	SQL_FastQuery(db, "SET NAMES utf8");
	SQL_SetCharset(db, "utf8");
	
	// Highest previous death
	DBResultSet max_index_query = SQL_Query(db, "SELECT Max(death_index) FROM deaths;");
	if (SQL_FetchRow(max_index_query)) {
		max_index = SQL_FetchInt(max_index_query, 0);
		max_index++;
	}
	
	// Highest previous round
	DBResultSet max_round_query = SQL_Query(db, "SELECT Max(round_no) FROM deaths;");
	if (SQL_FetchRow(max_round_query)) {
		max_round = SQL_FetchInt(max_round_query, 0);
		max_round++;
	}
}

public SetCVARS() {
	CreateConVar("rdm_version", PLUGIN_VERSION_M, "RDM Plugin Version");
}

public ResetShorts() {
	current_short_id = 0;
	for (int i = 0; i < 500; i++) {
		short_ids[i] = 0;
		handled_by[i] = 0;
		case_slay[i] = 0;
		case_accused[i] = 0;
	}
	for (int i = 0; i < MAXPLAYERS + 1; i++) {
		last_handled[i] = -1;
	}
}

public SetCommands() {
	RegConsoleCmd("sm_rdm", Command_RDM, "Requests help with an RDM");
	RegAdminCmd("sm_handle", Command_Handle, ADMFLAG_GENERIC, "Handle an RDM");
	RegAdminCmd("sm_handlenext", Command_HandleNext, ADMFLAG_GENERIC, "Handle next unhandled RDM");
	RegAdminCmd("sm_verdict", Command_Verdict, ADMFLAG_GENERIC, "Give a verdict");
	RegAdminCmd("sm_damage", Command_Damage, ADMFLAG_GENERIC, "Check damage on an RDM");
	RegAdminCmd("sm_slaynr", Command_SlayNR, ADMFLAG_GENERIC, "Slay a player next round");
	RegAdminCmd("sm_unslaynr", Command_UnSlayNR, ADMFLAG_GENERIC, "Unslay a player next round");
	RegAdminCmd("sm_info", Command_Info, ADMFLAG_GENERIC, "See info on an RDM");
}

public HookEvents() {
	HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", OnRoundEnd, EventHookMode_PostNoCopy);
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("player_disconnect", OnPlayerDisconnect);
	HookEvent("weapon_fire", OnWeaponFire);
	HookEvent("player_hurt", OnPlayerHurt);
	HookEvent("player_spawned", OnPlayerSpawned);
}

public OnPluginStart() {
	StartTimers();
	InitialiseVariables();
	SetCVARS();
	SetCommands();
	HookEvents();
	ResetShorts();
	PrintToServer("[RDM] Has Loaded Succcessfully!");
}

public OnPluginEnd() {
	// Alert Unload Success
	PrintToServer("[RDM] Has Unloaded Successfully!");
}

public OnMapStart() {
	ResetShorts();
}

public Action OnRoundStart(Event event, const char[] name, bool dontBroadcast) {
	max_round++;
	round_time = 0;
	return Plugin_Continue;
}

public Action OnRoundEnd(Event event, const char[] name, bool dontBroadcast) {
	return Plugin_Continue;
}

public Action OnPlayerDisconnect(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (to_slay[client] == 1) {
		char message[256];
		Format(message, sizeof(message), "{purple}[RDM] {yellow}Player %N left before his slay took place.", client);
		CPrintToStaff(message);
		to_slay[client] = 0;
		slay_admins[client] = "";
	}
	
	if (last_handled[client] > 0)
	{
		last_handled[client] = -1;
	}
	
	
	return Plugin_Continue;
}

public Action OnWeaponFire(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	last_gun_fire[client] = GetTime();
}

public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	if (!TTT_IsRoundActive()) { return Plugin_Continue; }
	// A player died in round, we need to update the MySQL table.
	
	// Identify victim & attacker ids
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker", victim));
	
	// Prepare a SQL statement for the insertion
	char error[255];
	DBStatement insert_death = SQL_PrepareQuery(db, "INSERT INTO deaths (death_index, death_time, victim_name, victim_id, victim_role, victim_karma, killer_name, killer_id, killer_role, killer_karma, weapon, bad_action, last_gun_fire, round_no) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);", error, sizeof(error));
	if (insert_death == null) { PrintToServer("Error templating death in the database"); PrintToServer(error); return Plugin_Continue; }
	
	// Determine whether RDM
	int victim_role = TTT_GetClientRole(victim);
	int attacker_role = TTT_GetClientRole(attacker);
	
	// Determine karma
	int victim_karma = TTT_GetClientKarma(victim);
	int attacker_karma = TTT_GetClientKarma(attacker);

	// Determine is the kill was a bad action or not
	int bad_action = BadAction(victim_role, attacker_role);
	
	// Identify permanent names for victim & attacker, plus grab weapon used to kill
	char weapon[100];
	char victim_id[100];
	char attacker_id[100];
	char victim_name[100];
	char attacker_name[100];
	
	GetClientAuthId(victim, AuthId_Steam2, victim_id, sizeof(victim_id), true);
	GetClientAuthId(attacker, AuthId_Steam2, attacker_id, sizeof(attacker_id), true);
	GetClientName(victim, victim_name, sizeof(victim_name));
	GetClientName(attacker, attacker_name, sizeof(attacker_name));
	GetEventString(event, "weapon", weapon, sizeof(weapon), "Unknown");
	
	// Bind parameters to query
	SQL_BindParamInt(insert_death, 0, max_index, false);
	SQL_BindParamInt(insert_death, 1, GetTime(), false);
	SQL_BindParamString(insert_death, 2, victim_name, false);
	SQL_BindParamString(insert_death, 3, victim_id, false);
	SQL_BindParamInt(insert_death, 4, victim_role, false);
	SQL_BindParamInt(insert_death, 5, victim_karma, false);
	SQL_BindParamString(insert_death, 6, attacker_name, false);
	SQL_BindParamString(insert_death, 7, attacker_id, false);
	SQL_BindParamInt(insert_death, 8, attacker_role, false);
	SQL_BindParamInt(insert_death, 9, attacker_karma, false);
	SQL_BindParamString(insert_death, 10, weapon, false);
	SQL_BindParamInt(insert_death, 11, bad_action, false);
	SQL_BindParamInt(insert_death, 12, last_gun_fire[victim], true);
	SQL_BindParamInt(insert_death, 13, max_round, true);
	
	// Execute statement
	if (!SQL_Execute(insert_death)) { PrintToServer("SQL Execute Failed..."); return Plugin_Continue; }
	max_index++;
	return Plugin_Continue;
}

public Action OnPlayerHurt(Event event, const char[] name, bool dontBroadcast) {
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	int damage = GetEventInt(event, "dmg_health");
	int health_left = GetEventInt(event, "health");
	char weapon[32];
	GetEventString(event, "weapon", weapon, sizeof(weapon), "Unknown");
	
	char victim_name[64], attacker_name[64];
	char victim_auth[32], attacker_auth[32];
	GetClientName(victim, victim_name, sizeof(victim_name));
	GetClientName(attacker, attacker_name, sizeof(attacker_name));
	GetClientAuthId(victim, AuthId_Steam2, victim_auth, sizeof(victim_auth));
	GetClientAuthId(attacker, AuthId_Steam2, attacker_auth, sizeof(attacker_auth));
	
	// Determine whether RDM
	int victim_role = TTT_GetClientRole(victim);
	int attacker_role = TTT_GetClientRole(attacker);

	// Prepare a SQL statement for the insertion
	char error[255];
	DBStatement insert_damage = SQL_PrepareQuery(db, "INSERT INTO damage (round_no, victim_name, victim_auth, victim_role, attacker_name, attacker_auth, attacker_role, damage_done, health_left, round_time, weapon) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);", error, sizeof(error));
	if (insert_damage == null) { PrintToServer("Error templating damage in the database"); PrintToServer(error); return Plugin_Continue; }
	
	SQL_BindParamInt(insert_damage, 0, max_round, false);
	SQL_BindParamString(insert_damage, 1, victim_name, false);
	SQL_BindParamString(insert_damage, 2, victim_auth, false);
	SQL_BindParamInt(insert_damage, 3, victim_role, false);
	SQL_BindParamString(insert_damage, 4, attacker_name, false);
	SQL_BindParamString(insert_damage, 5, attacker_auth, false);
	SQL_BindParamInt(insert_damage, 6, attacker_role, false);
	SQL_BindParamInt(insert_damage, 7, damage, false);
	SQL_BindParamInt(insert_damage, 8, health_left, false);
	SQL_BindParamInt(insert_damage, 9, round_time, false);
	SQL_BindParamString(insert_damage, 10, weapon, false);
	
	// Execute statement
	if (!SQL_Execute(insert_damage)) { PrintToServer("SQL Execute Failed..."); return Plugin_Continue; }
	max_index++;
	return Plugin_Continue;
}

public Action OnPlayerSpawned(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (TTT_IsRoundActive()) {
		if (IsValidClient(client) && IsPlayerAlive(client)) {
			CPrintToChat(client, "{purple}[Slay] {orchid}You joined the game too late and were automatically slain.");
			ForcePlayerSuicide(client);
			TTT_SetFoundStatus(client, true);
		}
	}
}

public Action Timer_1(Handle timer) {
	if (TTT_IsRoundActive()) {
		round_time++;
	}
}

public Action Timer_60(Handle timer) {
	for (int i = 0; i < 500; i++) {
		if (short_ids[i] == 0) {
			break;
		}
		if (handled_by[i] == 0) {
			char message[255];
			Format(message, sizeof(message), "{purple}[RDM] {red}No-one has handled case %d yet.", i);
			CPrintToStaff(message);
		}
	}
}

public Action Command_RDM(int client, int args) {
	if (GetTime() - rdm_cooldown[client] < 15) {
		CPrintToChat(client, "{purple}[RDM] {darkred}Please do not spam this command...")
		return Plugin_Handled; // 15 seconds hasn't passed yet, don't allow
	}
		
	char client_auth[100];
	GetClientAuthId(client, AuthId_Steam2, client_auth, sizeof(client_auth), true);

	DBStatement rdm_statement = PrepareStatement(db, "SELECT * FROM `deaths` WHERE victim_id=? AND death_time>=? ORDER BY `death_time` DESC LIMIT 20;");

	char time[100];
	IntToString(GetTime() - 24 * 60 * 60, time, sizeof(time));

	SQL_BindParamString(rdm_statement, 0, client_auth, false);
	SQL_BindParamString(rdm_statement, 1, time, false);
	
	if (!SQL_Execute(rdm_statement)) { PrintToServer("SQL Execute Failed..."); return Plugin_Continue; }
	
	Menu menu = new Menu(RDM_Menu_Callback);
	bool ran = false;
	
	while (SQL_FetchRow(rdm_statement)) {
		ran = true;
		
		char killer_name[100], death_index_string[100], print_string[200];
		
		int death_index = SQL_FetchInt(rdm_statement, 0);
		int death_time = SQL_FetchInt(rdm_statement, 1);
		SQL_FetchString(rdm_statement, 6, killer_name, sizeof(killer_name))		

		IntToString(death_index, death_index_string, sizeof(death_index_string));
		Format(print_string, sizeof(print_string), "%d secs ago by %s", GetTime() - death_time, killer_name);
		menu.AddItem(death_index_string, print_string);
	}
	
	if (ran) {
		menu.SetTitle("Select RDM");
		menu.Display(client, MENU_TIME_FOREVER);
	} else {
		CPrintToChat(client, "{purple}[RDM] {darkred}You don't appear to have been RDM'd recently.")
	}
	
	return Plugin_Handled;
}

public RDM_Menu_Callback(Menu menu, MenuAction action, int client, int item)
{
	if (action == MenuAction_Select) {
		char info[32];
		char message_slain[32];
		char message_warned[32];
		
		menu.GetItem(item, info, sizeof(info));
		
		Menu menu_slay = new Menu(RDM_SlayMenu_Callback);
		menu_slay.SetTitle("Slain or Warned?");
		
		FormatEx(message_slain, sizeof(message_slain), "slain,%s", info);
		menu_slay.AddItem(message_slain, "Slain");
		
		FormatEx(message_warned, sizeof(message_warned), "warned,%s", info);
		menu_slay.AddItem(message_warned, "Warned");
		
		menu_slay.Display(client, MENU_TIME_FOREVER);
	}
}

public RDM_SlayMenu_Callback(Menu menu, MenuAction action, int client, int item)
{
	if (action == MenuAction_Select) {
		char to_explode[32];
		menu.GetItem(item, to_explode, sizeof(to_explode));
		
		char buffers[2][32];
		ExplodeString(to_explode, ",", buffers, 2, 32);
		
		
		rdm_cooldown[client] = GetTime();
		
		int death_index = StringToInt(buffers[1]);
		
		char error[255];
		DBStatement rdm_instance = SQL_PrepareQuery(db, "SELECT * FROM `deaths` WHERE death_index=? LIMIT 1;", error, sizeof(error))
		if (rdm_instance == null) {
			PrintToServer(error);
			return;
		}
		SQL_BindParamInt(rdm_instance, 0, death_index, false);
		
		if (!SQL_Execute(rdm_instance)) { PrintToServer("SQL Execute Failed..."); return; }
		
		// Only Expecting 1 row, changed while to if.
		if (SQL_FetchRow(rdm_instance)) {
			char victim_name[100];
			char killer_name[100];

			SQL_FetchString(rdm_instance, 2, victim_name, sizeof(victim_name));
			SQL_FetchString(rdm_instance, 6, killer_name, sizeof(killer_name));

			if (Count_Staff() != 0) {
				char message[256];
				Format(message, sizeof(message), "{purple}[RDM] {orchid}%s may have been RDM'd by %s. Handle with `/handle %i`", victim_name, killer_name, current_short_id);
				CPrintToStaff(message);
				CPrintToChat(client, "{purple}[RDM] {orchid}Thanks for the report.  Awaiting staff response..."); 
				
				if (strcmp(buffers[0], "slain", false))
				{
					case_slay[current_short_id] = 1;
				}
				else if (strcmp(buffers[0], "warned", false))
				{
					case_slay[current_short_id] = 2;
				}
				
				short_ids[current_short_id] = death_index;
				case_accused[current_short_id] = GetClientUserId(FindTarget(client, killer_name, false));
				current_short_id++;
				
			} else {
				CPrintToChat(client, "{purple}[RDM] {darkred}There are no staff online, you can do /calladmin to request one join.");
			}
			
		}
		// This will act as the final step before submitting the report, replacing the RDM menu callback.
	}
}

public Action Command_Info(int client, int args) {
	if (args == 0) {
		CPrintToChat(client, "{purple}[RDM] {orchid}At this moment in time, this function expects a case number.  Future versions may change this.");
		return Plugin_Handled;
	}
	
	// Get target
	char target_string[32];
	GetCmdArg(1, target_string, sizeof(target_string));
	int target_id = StringToInt(target_string);
	
	if (short_ids[target_id] == 0) {
		CPrintToChat(client, "{purple}[RDM] {orchid}The given target_id is either invalid or not distributed yet.");
		return Plugin_Handled;
	}
	
	int death_index = short_ids[target_id];
	
	Display_Information(client, death_index);
	
	return Plugin_Handled;
}

public Handle_Menu_Callback(Menu menu, MenuAction action, int client, int item)
{
	if (action == MenuAction_Select) {
		
	}
}

public Action Command_Handle(int client, int args) {
	if (args == 0) {
		Menu menu = new Menu(Handle_Menu_Callback);
		menu.SetTitle("Unhandled Cases");
		bool run = false;
		for (int i = 0; i < 500; i++) {
			if (short_ids[i]) {
				if (handled_by[i] == 0) {
					run = true;
					char message[255];
					Format(message, sizeof(message), "%d", i);
					char index[64];
					Format(index, sizeof(index), "%d", i);
					menu.AddItem(index, message);
				}
			}
		}
		
		if (run) {
			menu.Display(client, MENU_TIME_FOREVER);
		} else {
			CPrintToChat(client, "{purple}[RDM] {orchid}No cases have been found at this time.");
		}
		
		CPrintToChat(client, "{purple}[RDM] {orchid}At this moment in time, this function expects a case number.  Future versions may change this.");
		return Plugin_Handled;
	}
	
	// Get target
	char case_id_string[32];
	GetCmdArg(1, case_id_string, sizeof(case_id_string));
	int case_id = StringToInt(case_id_string);
	
	HandleCase(client, case_id);
	
	return Plugin_Handled;
}

public Action Command_HandleNext(int client, int args) {
	if (args == 0) {
		bool run = true;
		int first_unhandled = 0;
		for (int i = 0; i < 500; i++) {
			if (short_ids[i] && run) {
				if (handled_by[i] == 0 && run) {
					run = false;
					first_unhandled = i;
				}
			}
		}
		
		if (!run) {
			HandleCase(client, first_unhandled);
		} else {
			CPrintToChat(client, "{purple}[RDM] {orchid}No cases have been found at this time.");
		}
		
		// CPrintToChat(client, "{purple}[RDM] {orchid}At this moment in time, this function expects a case number.  Future versions may change this.");
		return Plugin_Handled;
	}

	
	return Plugin_Handled;
}

public HandleCase(int client, int case_id)
{
	
	if (short_ids[case_id] == 0) {
		CPrintToChat(client, "{purple}[RDM] {orchid}The given case_id is either invalid or not distributed yet.");
		return;
	}
	
	if (handled_by[case_id] != 0) {
		char message[512];
		Format(message, sizeof(message), "{purple}[RDM] {orchid}This case has already been handled by %N.  You can stil find information about this event by doing /info %d", handled_by[case_id], case_id);
		CPrintToChat(client, message);
		return;
	}
	
	int death_index = short_ids[case_id];
	handled_by[case_id] = client;
	last_handled[client] = case_id;

	// Prepare a SQL statement for the insertion
	char error[255];
	DBStatement insert_handles = SQL_PrepareQuery(db, "INSERT INTO handles (death_index, staff_name, staff_auth) VALUES (?, ?, ?);", error, sizeof(error));
	if (insert_handles == null) { PrintToServer("Error templating handles in the database"); PrintToServer(error); return; }
	
	char staff_name[64], staff_auth[64];
	GetClientAuthId(client, AuthId_Steam2, staff_auth, sizeof(staff_auth), true);
	GetClientName(client, staff_name, sizeof(staff_name));
	
	SQL_BindParamInt(insert_handles, 0, death_index, false);
	SQL_BindParamString(insert_handles, 1, staff_name, false);
	SQL_BindParamString(insert_handles, 2, staff_auth, false);
	
	// Execute statement
	if (!SQL_Execute(insert_handles)) { PrintToServer("SQL Execute Failed..."); return; }

	DBStatement rdm_instance = SQL_PrepareQuery(db, "SELECT * FROM `deaths` WHERE death_index=? LIMIT 1;", error, sizeof(error))
	if (rdm_instance == null) {
		PrintToServer(error);
		return;
	}
	SQL_BindParamInt(rdm_instance, 0, death_index, false);
	
	if (!SQL_Execute(rdm_instance)) { PrintToServer("SQL Execute Failed..."); return; }
	
	char victim_name[100];
	char victim_id[100];
	while (SQL_FetchRow(rdm_instance)) {
		SQL_FetchString(rdm_instance, 2, victim_name, sizeof(victim_name));
		SQL_FetchString(rdm_instance, 3, victim_id, sizeof(victim_id));
	}

	char staff_message[255];
	Format(staff_message, sizeof(staff_message), "{purple}[RDM] {yellow}%N has taken on %s's case (%d)", client, victim_name, case_id);
	CPrintToStaff(staff_message);
	
	int victim_client = Get_Client(victim_id)
	if (victim_client != -1) {
		char message[255];
		Format(message, sizeof(message), "{purple}[RDM] {orchid}%N has taken on your case (%d)", client, case_id, victim_name);
		CPrintToChat(victim_client, message);
	}
	
	Display_Information(client, death_index);
	return;
}

/*
L 09/05/2017 - 04:59:24: --------------------------------------
L 09/05/2017 - 04:59:24: -----------START ROUND LOGS-----------
L 09/05/2017 - 04:59:24: [00:00] -> [ElHectorXD (Innocent) damaged King of ping (Traitor) for 60 damage with ak47]
L 09/05/2017 - 04:59:24: [00:02] -> [King of ping (Traitor) damaged ElHectorXD (Innocent) for 41 damage with m4a1]
L 09/05/2017 - 04:59:24: [00:02] -> [King of ping (Traitor) damaged Harry / csgoboss /  (Innocent) for 20 damage with m4a1]
L 09/05/2017 - 04:59:24: [00:02] -> [King of ping (Traitor) damaged ElHectorXD (Innocent) for 41 damage with m4a1]
L 09/05/2017 - 04:59:24: [00:02] -> [King of ping (Traitor) damaged ElHectorXD (Innocent) for 32 damage with m4a1]
L 09/05/2017 - 04:59:24: [00:02] -> [King of ping (Traitor) killed ElHectorXD (Innocent) with m4a1]
L 09/05/2017 - 04:59:24: [00:03] -> [King of ping (Traitor) damaged Harry / csgoboss /  (Innocent) for 31 damage with m4a1]
L 09/05/2017 - 04:59:24: [00:03] -> [Harry / csgoboss /  (Innocent) damaged King of ping (Traitor) for 115 damage with p250] L 09/05/2017 - 04:59:24: [00:03] -> [Harry / csgoboss /  (Innocent) killed King of ping (Traitor) with p250]
L 09/05/2017 - 04:59:24: --------------------------------------
*/

public Action Command_Verdict(int client, int args) {
	if (args == 0) {
		CPrintToChat(client, "{purple}[RDM] {orchid}Expected an argument, but got none.)");
		return Plugin_Handled;
	}
	
	char verdict[32];
	GetCmdArg(1, verdict, sizeof(verdict));
	if (strcmp(verdict, "guilty", false) == 0)
	{
		if (last_handled[client] == -1)
		{
			CPrintToChat(client, "You do not have any handled RDM's");
			return Plugin_Handled;
		}
		
		int case_id = last_handled[client];
		
		if (case_slay[case_id] == 0)
		{
			CPrintToChat(client, "User did not choose slay or warn.");
			return Plugin_Handled;
		}
		if (case_accused[case_id] == 0) 
		{
			CPrintToChat(client, "I do not have the accused' client id.");
			return Plugin_Handled;
		}
		
		int attacker_id = case_accused[case_id];
		
		if (case_slay[case_id] == should_slay)
		{
			ClientCommand(client, "sm_slaynr #%d", attacker_id);
			CPrintToChat(client, "Slaying RDM\'er next round");
		}
		else
		{
			CPrintToChat(client, "Please warn the RDMer");
		}
		
		CPrintToChat(client, "{Red} (name)'s case is closed.");
	}
	else if (strcmp(verdict, "innocent", false) == 0)
	{
		CPrintToChat(client, "{Green} (name)'s case is closed.");
	}
	else
	{
		CPrintToChat(client, "Unrecognized verdict, please try again.");
	}

	return Plugin_Handled;
}

public Action Command_Damage(int client, int args) {
	if (args == 0) {
		CPrintToChat(client, "{purple}[RDM] {orchid}At this moment in time, this function expects a case number.  Future versions may change this.");
		return Plugin_Handled;
	}
	
	// Get target
	char target_string[32];
	GetCmdArg(1, target_string, sizeof(target_string));
	int target_id = StringToInt(target_string);
	
	if (short_ids[target_id] == 0) {
		CPrintToChat(client, "{purple}[RDM] {orchid}The given target_id is either invalid or not distributed yet.");
		return Plugin_Handled;
	}

	int death_index = short_ids[target_id];

	char error[255];
	DBStatement rdm_instance = SQL_PrepareQuery(db, "SELECT * FROM `deaths` WHERE death_index=? LIMIT 1;", error, sizeof(error))
	if (rdm_instance == null) {
		PrintToServer(error);
		return Plugin_Handled;
	}
	SQL_BindParamInt(rdm_instance, 0, death_index, false);
	
	if (!SQL_Execute(rdm_instance)) { PrintToServer("SQL Execute Failed..."); return Plugin_Handled; }
	
	char attacker_auth[100];
	char victim_auth[100];
	int round_number;
	while (SQL_FetchRow(rdm_instance)) {
		SQL_FetchString(rdm_instance, 3, victim_auth, sizeof(victim_auth));
		SQL_FetchString(rdm_instance, 7, attacker_auth, sizeof(attacker_auth));
		round_number = SQL_FetchInt(rdm_instance, 13);
	}

	DBStatement damage_log = SQL_PrepareQuery(db, "SELECT * FROM `damage` WHERE `round_no`=? AND (`victim_auth`=? OR `victim_auth`=? OR `attacker_auth`=? OR `attacker_auth`=?);", error, sizeof(error))
	if (damage_log == null) {
		PrintToServer(error);
		return Plugin_Handled;
	}
	SQL_BindParamInt(damage_log, 0, round_number, false);
	SQL_BindParamString(damage_log, 1, attacker_auth, false);
	SQL_BindParamString(damage_log, 2, victim_auth, false);
	SQL_BindParamString(damage_log, 3, attacker_auth, false);
	SQL_BindParamString(damage_log, 4, victim_auth, false);
	
	if (!SQL_Execute(damage_log)) { PrintToServer("SQL Execute Failed..."); return Plugin_Handled; }
	
	PrintToConsole(client, "========================== Round %d ==========================", round_number)
	
	while (SQL_FetchRow(damage_log)) {
		char victim_name_temp[64], victim_auth_temp[32];
		char attacker_name_temp[64], attacker_auth_temp[32];
		char weapon[32];
		
		SQL_FetchString(damage_log, 1, victim_name_temp, sizeof(victim_name_temp));
		SQL_FetchString(damage_log, 2, victim_auth_temp, sizeof(victim_auth_temp));
		int victim_role = SQL_FetchInt(damage_log, 3);
		SQL_FetchString(damage_log, 4, attacker_name_temp, sizeof(attacker_name_temp));
		SQL_FetchString(damage_log, 5, attacker_auth_temp, sizeof(attacker_auth_temp));
		int attacker_role = SQL_FetchInt(damage_log, 6);
		int damage_done = SQL_FetchInt(damage_log, 7);
		int health_left = SQL_FetchInt(damage_log, 8);
		int round_time_temp = SQL_FetchInt(damage_log, 9);
		SQL_FetchString(damage_log, 10, weapon, sizeof(weapon));
		
		int time[2];
		Format_Time(round_time_temp, time);
		
		PrintToConsole(client, "[%02d:%02d] [%-12.12s] (%d) damaged [%-16.16s] (%d) for %03.3dhp with %s", time[0], time[1], attacker_name_temp, attacker_role, victim_name_temp, victim_role, damage_done, weapon);
		if (health_left < 0) {
			PrintToConsole(client, "[%02d:%02d] [%-12.12s] (%d) killed  [%-16.16s] (%d)           with %s", time[0], time[1], attacker_name_temp, attacker_role, victim_name_temp, victim_role, damage_done, weapon);
		}
	}
	return Plugin_Handled;
}

public Display_Information(int client, int death_index) {
	char error[255];
	DBStatement rdm_instance = SQL_PrepareQuery(db, "SELECT * FROM `deaths` WHERE death_index=? LIMIT 1;", error, sizeof(error))
	if (rdm_instance == null) { PrintToServer(error); return; }
	SQL_BindParamInt(rdm_instance, 0, death_index, false);
	
	if (!SQL_Execute(rdm_instance)) { PrintToServer("SQL Execute Failed..."); return; }
	
	int death_time;

	char victim_name[50];
	char victim_id[50];
	int victim_role;
	int victim_karma;
	
	char killer_name[50];
	char killer_id[50];
	int killer_role;
	int killer_karma;
	
	char weapon[50];
	
	int bad_action;
	int last_gun_fire_time;
	int round_no;
	
	while (SQL_FetchRow(rdm_instance)) {
		death_index = SQL_FetchInt(rdm_instance, 0);
		death_time = SQL_FetchInt(rdm_instance, 1);
		
		SQL_FetchString(rdm_instance, 2, victim_name, sizeof(victim_name));
		SQL_FetchString(rdm_instance, 3, victim_id, sizeof(victim_id));
		victim_role = SQL_FetchInt(rdm_instance, 4);
		victim_karma = SQL_FetchInt(rdm_instance, 5);

		SQL_FetchString(rdm_instance, 6, killer_name, sizeof(killer_name));
		SQL_FetchString(rdm_instance, 7, killer_id, sizeof(killer_id));
		killer_role = SQL_FetchInt(rdm_instance, 8);
		killer_karma = SQL_FetchInt(rdm_instance, 9);
		
		SQL_FetchString(rdm_instance, 10, weapon, sizeof(weapon));
		
		bad_action = SQL_FetchInt(rdm_instance, 11);
		last_gun_fire_time = SQL_FetchInt(rdm_instance, 12);
		round_no = SQL_FetchInt(rdm_instance, 13);
	}
	
	// ┏━┓ ┗━┛ ┣━ ┃
	
	char victim_colour[20];
	char killer_colour[20];
	
	if (victim_role == INNOCENT) { victim_colour = "{green}"; }
	if (victim_role == TRAITOR) { victim_colour = "{red}"; }
	if (victim_role == DETECTIVE) { victim_colour = "{blue}"; }
	
	if (killer_role == INNOCENT) { killer_colour = "{green}"; }
	if (killer_role == TRAITOR) { killer_colour = "{red}"; }
	if (killer_role == DETECTIVE) { killer_colour = "{blue}"; }
	
	char bad_action_string[50];
	if (bad_action == 1) { bad_action_string = "{orchid}True"; }
	else { bad_action_string = "{blue}False"; }
	
	int victim_actions[2];
	Get_Actions_Count(db, victim_actions, victim_id);
	int killer_actions[2];
	Get_Actions_Count(db, killer_actions, killer_id);
	
	int victim_percentage = RoundFloat(float(victim_actions[0]) * 100 / float(victim_actions[0] + victim_actions[1]))
	int killer_percentage = RoundFloat(float(killer_actions[0]) * 100 / float(killer_actions[0] + killer_actions[1]))
	
	char victim_percentage_colour[20];
	char killer_percentage_colour[20];
	if (victim_percentage > 90) { victim_percentage_colour = "{green}"; }
	else if (victim_percentage > 60) { victim_percentage_colour = "{yellow}"; }
	else { victim_percentage_colour = "{red}"; }
	if (killer_percentage > 90) { killer_percentage_colour = "{green}"; }
	else if (killer_percentage > 60) { killer_percentage_colour = "{yellow}"; }
	else { killer_percentage_colour = "{red}"; }
	
	CPrintToChat(client, "┏━━━━━━━━━━━━━ %s ━━━━━━━━━━━━━━", victim_name);
	CPrintToChat(client, "┣━ Player: %s%s (%s)", victim_colour, victim_name, victim_id);
	CPrintToChat(client, "┃  ┣━ Karma: %d ({lime}+%d{default}, {red}-%d{default}, %s%d%s{default})", victim_karma, victim_actions[0], victim_actions[1], victim_percentage_colour, victim_percentage, "%%");
	if (last_gun_fire_time == -1) {
		CPrintToChat(client, "┃  ┣━ Last Shot: Never");
	} else {
		CPrintToChat(client, "┃  ┣━ Last Shot: %d secs before death", death_time - last_gun_fire_time);
	}
	CPrintToChat(client, "┣━ Killed By: %s%s (%s)", killer_colour, killer_name, killer_id);
	CPrintToChat(client, "┃  ┣━ Karma: %d ({lime}+%d{default}, {red}-%d{default}, %s%d%s{default})", killer_karma, killer_actions[0], killer_actions[1], killer_percentage_colour, killer_percentage, "%%");
	CPrintToChat(client, "┃  ┣━ Killed with: %s (%d round(s) ago)", weapon, max_round - round_no);
	CPrintToChat(client, "┣━ Bad Action: %s", bad_action_string);
	CPrintToChat(client, "┗━━━━━━━━━━━━━ %s ━━━━━━━━━━━━━━", victim_name);
	
}

public Action Command_SlayNR(int client, int args) {
	// Ensure target provided
	if (args == 0) {
		CPrintToChat(client, "{purple}[RDM] {orchid}Invalid usage, expects /slaynr <player>.");
		return Plugin_Handled;
	}
	
	// Get target
	char target_string[32];
	GetCmdArg(1, target_string, sizeof(target_string));
	
	// Ensure target exists 
	int target_client = FindTarget(client, target_string);
	if (target_client == -1) {
		CPrintToChat(client, "{purple}[RDM] {orchid}Target not found.");
		return Plugin_Handled;
	}

	// Format slay message and send to recipients
	char message[256];
	if (to_slay[target_client] == 1) {
		Format(message, sizeof(message), "{purple}[RDM] {yellow}%N was already set to slay by %s.", target_client, slay_admins[client]);
		CPrintToChat(client, message);
	} else {
		char string_slay_admin[255];
		Format(string_slay_admin, sizeof(string_slay_admin), "%N", client)
		slay_admins[client] = string_slay_admin;
		Format(message, sizeof(message), "{purple}[RDM] {yellow}Slaying %N next round by request from %s.", target_client, slay_admins[client]);
		CPrintToStaff(message);
	}
	
	// Set target to slay
	to_slay[target_client] = 1;

	return Plugin_Handled
}

public Action Command_UnSlayNR(int client, int args) {
	// Ensure target provided
	if (args == 0) {
		CPrintToChat(client, "{purple}[RDM] {orchid}Invalid usage, expects /unslaynr <player>.");
		return Plugin_Handled;
	}
	
	// Get target
	char target_string[32];
	GetCmdArg(1, target_string, sizeof(target_string));
	
	// Ensure target exists 
	int target_client = FindTarget(client, target_string);
	if (target_client == -1) {
		CPrintToChat(client, "{purple}[RDM] {orchid}Target not found.");
		return Plugin_Handled;
	}
	
	// Set target to slay
	to_slay[target_client] = 0;
	slay_admins[target_client] = "";
	
	// Display slay message to staff
	char message[256];
	Format(message, sizeof(message), "{purple}[RDM] {yellow}No longer slaying %N next round by request of %N.", target_client, client);
	CPrintToStaff(message);
	return Plugin_Handled
}

public void TTT_OnRoundStart() {
	for (new i = 0; i < MAXPLAYERS; i++) {
		last_gun_fire[i] = -1;
		if (to_slay[i] == 1) {
			if (IsValidClient(i) && IsPlayerAlive(i)) {
				slay_count[i]++;
				char message[255];
				if (slay_count[i] > 2) {
					Format(message, sizeof(message), "{purple}[RDM] {red}%N has been slain %d times this map.  Consider a specban.", i, slay_count[i]);
				} else {
					Format(message, sizeof(message), "{purple}[RDM] {yellow}%N has been slain (no. %d).", i, slay_count[i]);
				}
				CPrintToStaff(message);
				CPrintToChat(i, "{purple}[Slay] {orchid}You were slain by %s.  Please read /rules.", slay_admins[i]);
				ForcePlayerSuicide(i);
				TTT_SetFoundStatus(i, true);
			}
			to_slay[i] = 0;
			slay_admins[i] = "";
		}
	}
}

stock Format_Time(int time, int[] time_array) {
	time_array[0] = RoundToFloor(float(time) / 60);
	time_array[1] = time - time_array[0] * 60;
}