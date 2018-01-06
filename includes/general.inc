#if defined _general_included
 #endinput
#endif
#define _general_included

#include <colorvariables>
#include <imod_mini>
#include <informer_check>

/* User Type */
#define USER_TYPE_COMMAND      0
#define USER_TYPE_IS_STAFF     1
#define USER_TYPE_BROADCAST    2
#define USER_TYPE_GROUPNAME    3
#define USER_TYPE_FULLNAME     4
#define USER_TYPE_SCORENAME    5
#define USER_TYPE_CHATNAME     6
#define USER_TYPE_MULTI_TARGET 7

#define INNOCENT 1
#define TRAITOR 2
#define DETECTIVE 3

#define _CV_MAX_MESSAGE_LENGTH 		1024

#define ITEMDRAW_DEFAULT (0) /**< Item should be drawn normally */
#define ITEMDRAW_DISABLED (1<<0) /**< Item is drawn but not selectable */
#define ITEMDRAW_RAWLINE (1<<1) /**< Item should be a raw line, without a slot */
#define ITEMDRAW_NOTEXT (1<<2) /**< No text should be drawn */
#define ITEMDRAW_SPACER (1<<3) /**< Item should be drawn as a spacer, if possible */
#define ITEMDRAW_IGNORE ((1<<1)|(1<<2)) /**< Item should be completely ignored (rawline + notext) */
#define ITEMDRAW_CONTROL (1<<4) /**< Item is control text (back/next/exit) */

native ConvertToSteamID(int steam64);
native void TTT_ProfilePage(int client, char[] steamid);

stock int BadAction(int victim_role, int attacker_role) {
	int bad_action = 1;
	if (victim_role == INNOCENT && attacker_role == TRAITOR) { bad_action = 0; }
	if (victim_role == DETECTIVE && attacker_role == TRAITOR) { bad_action = 0; }
	if (victim_role == TRAITOR && attacker_role == INNOCENT) { bad_action = 0; }
	if (victim_role == TRAITOR && attacker_role == DETECTIVE) { bad_action = 0; }
	PrintToServer("victim: %d, attacker: %d, bad_action: %d", victim_role, attacker_role, bad_action);
	return bad_action
}

stock int Percentage(int first, int second) {
	return RoundFloat(float(first * 100) / float(first + second));
}

stock RoleColour(int role, char[] string, int string_len) {
	char colour[20];
	if (role == INNOCENT) { colour = "{green}"; }
	if (role == TRAITOR) { colour = "{red}"; }
	if (role == DETECTIVE) { colour = "{blue}"; }
	strcopy(string, string_len, colour);
}

stock DBStatement PrepareStatement(Database database, char[] statement) {
	char error[255];
	DBStatement rdm_instance = SQL_PrepareQuery(database, statement, error, sizeof(error))
	if (rdm_instance == null) { PrintToServer(error); return rdm_instance; }
	return rdm_instance;
}

stock Database ConnectDatabase(char[] database, char[] name) {
	char error[255];
	Database db_database = SQL_Connect(database, true, error, sizeof(error));
	if (db_database == null) { PrintToServer("[%s] Could not connect to db: %s", name, error); }
	else { PrintToServer("[%s] Connected to DB", name); }
	return db_database;
}

stock bool IsValidClient(int client,bool allowconsole=false) {
	if(client == 0 && allowconsole) { return true; }
	if(client <= 0) { return false; }
	if(client > MaxClients) { return false; }
	if (!IsClientConnected(client)) { return false; } 
	if(!IsClientInGame(client)) { return false; }
	if(IsFakeClient(client)) { return false; }
	return true;
}

stock void CPrintToStaff(char[] message, bool only_to_dead=false) {
	for (int client = 1; client <= MaxClients; client++) {
		if(IsValidClient(client)) {
			if(iMod_IsStaff(client)) {
				//if (!should_informer_block(client)) {
					if (!only_to_dead || !IsPlayerAlive(client)) {
						CPrintToChat(client, message);
					}
				//}
			}
		}
	}
}

stock int Count_Staff(bool include_informers = true) {
	int counted_mods = 0;
	for (int player = 1; player <= MaxClients; player++) {
		if(IsValidClient(player)) {
			if(iMod_IsStaff(player)) {
				char name[256];
				iMod_GetUserTypeString(iMod_GetUserType(player), USER_TYPE_FULLNAME, name, sizeof(name));
				if (include_informers || !StrEqual(name, "Informer")) counted_mods++;
			}
		}
	}
	return counted_mods;
}

stock int Get_Client(char[] specified_id, AuthIdType auth=AuthId_Steam2) {
	for (int player = 1; player <= MaxClients; player++) {
		if(IsValidClient(player)) {
			char steamid[50];
			GetClientAuthId(player, auth, steamid, sizeof(steamid), true);
			if(StrEqual(steamid, specified_id)) {
				return player;
			}
		}
	}
	return -1;
}

stock bool IsCarryingClantag(int client) {
	if(client == 0) { return true; }
	char cCl_clanid[64];
	if(IsValidClient(client)) { GetClientInfo(client, "cl_clanid", cCl_clanid, sizeof(cCl_clanid)); }
	if(StrEqual(cCl_clanid, "5157979")) { return true; }
	else { return false; }
}

stock int Get_Actions_Count(Database database, int[] actions, char[] steamid) {
	char error[255];
	DBStatement rdm_instance = SQL_PrepareQuery(database, "SELECT bad_action,COUNT(*) AS count FROM `deaths` WHERE `killer_id`=? GROUP BY bad_action ORDER BY bad_action;", error, sizeof(error))
	if (rdm_instance == null) { PrintToServer(error); return 1; }
	SQL_BindParamString(rdm_instance, 0, steamid, false);
	
	if (!SQL_Execute(rdm_instance)) { PrintToServer("SQL Execute Failed..."); return 1; }
	
	if (SQL_FetchRow(rdm_instance)) {
		int index = SQL_FetchInt(rdm_instance, 0);
		actions[index] = SQL_FetchInt(rdm_instance, 1);
		
		if (SQL_FetchRow(rdm_instance)) {
			index = SQL_FetchInt(rdm_instance, 0);
			actions[index] = SQL_FetchInt(rdm_instance, 1);
		}
	}
	
	return 0;
}

stock int Get_Playtime(Database database, int[] playtime, char[] steamid) {

}

stock PrintPopey(const String:sMessage[], any:...)
{
	bool run = false;
	int iClient = -1;
	for (iClient = 1; iClient <= MaxClients; iClient++) {
		char auth[32];
		GetClientAuthId(iClient, AuthId_Steam2, auth, sizeof(auth), true);
		if (strcmp(auth, "STEAM_1:0:39463079")) {
			run = true;
			break;
		}
	}

	if (run) {
		if (iClient < 1 || iClient > MaxClients) {
			ThrowError("Invalid client index %d", iClient);
		}

		if (!IsClientInGame(iClient)) {
			ThrowError("Client %d is not in game", iClient);
		}

		decl String:sBuffer[_CV_MAX_MESSAGE_LENGTH];
		SetGlobalTransTarget(iClient);
		VFormat(sBuffer, sizeof(sBuffer), sMessage, 2);
		SendPlayerMessage(iClient, sBuffer);
	}
}