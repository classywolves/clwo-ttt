#include <ttt_helpers>
#include <player_methodmap>
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <logger>

typedef NativeCall = function int (Handle plugin, int numParams);

int action_cache[MAXPLAYERS + 1][2];
int refresh_time[MAXPLAYERS + 1];
Database hDatabase = null;

public OnPluginStart() {
	setLogSource("actions");
	Database.Connect(DBCallback, "ttt");
	CreateTimer(20.0, LoadAllActionData, _, TIMER_REPEAT);
}

public void DBCallback(Database db, const char[] error, any data)
{
	if (db == null) LogError("Database failure: %s", error);
	else hDatabase = db;
}

OnClientDisconnect(int client) {
	int action_cache[client] = { 0, 0 };
}

OnClientConnect(int client) {
	LoadActionData(GetClientSerial(client));
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	CreateNative("GetActions", Native_GetActions);
	return APLRes_Success;
}

// Called with (int client, int[2] actions)
public int Native_GetActions(Handle plugin, int numParams) {
	int client = GetNativeCell(1);

	if (refresh_time[client] < GetTime() - 60) {
		log(Warn, "%N has out of date data it appears, time: %d", client, refresh_time[client]);
	}

	log(Info, "Grabbing action array for %N %d %d", client, action_cache[client][0], action_cache[client][1])

	int temp_array[2];
	temp_array[0] = action_cache[client][0];
	temp_array[1] = action_cache[client][1];

	SetNativeArray(2, temp_array, 2);
	return 0;
}

public void LoadActionData(int serial) {
	int client = GetClientFromSerial(serial);
	if (client == 0) return;

	char query[256], steam_id[64];
	GetClientAuthId(client, AuthId_Steam2, steam_id, sizeof(steam_id));
	Format(query, sizeof(query), "SELECT bad_action,COUNT(*) AS count FROM `deaths` WHERE `killer_id`='%s' GROUP BY bad_action ORDER BY bad_action;", steam_id)
	//log(Info, query);
	hDatabase.Query(GetActionCallback, query, serial); 
	//log(Info, "Hey, we got below hDatabase.Query within ttt_actions")
	return;
}

public Action LoadAllActionData(Handle timer) {
	LoopValidClients(client) {
		LoadActionData(GetClientSerial(client));
	}
}

public void GetActionCallback(Database db, DBResultSet results, const char[] error, any serial) {
	//log(Info, "Oh, hey, we got to the GetActionCallback")
	int client = GetClientFromSerial(serial);
	if (client == 0) return;

	//log("Player is totally still online: %d, %N", serial, client);

	if (results == null) {
		log(Error, "Get Action Query failed! %s", error);
	} else {
		while (SQL_FetchRow(results)) {
			//log(Info, "Oh hey, we got a row of results!  How exciting <3");
			int index = SQL_FetchInt(results, 0);
			action_cache[client][index] = SQL_FetchInt(results, 1);
			//log(Info, "action set %d %d", SQL_FetchInt(results, 0),  SQL_FetchInt(results, 1));
			//log(Info, "Action log %d %d", action_cache[client][0], action_cache[client][1]);
		}
		refresh_time[client] = GetTime();
	}
}