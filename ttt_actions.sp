typedef NativeCall = function int (Handle plugin, int numParams);

int action_cache[MAXPLAYERS + 1][2];
int refresh_time[MAXPLAYERS + 1];
Database hDatabase = null;

public OnPluginStart() {
	Database.Connect(DBCallback, "ttt");
	LoopValidClients(client) OnClientPutInServer(client);
}

public void DBCallback(Database db, const char[] error, any data)
{
	if (db == null) LogError("Database failure: %s", error);
	else hDatabase = db;
}

OnClientPutInServer(int client) {
	// Load action data
	int serial = GetClientSerial(client);
	LoadActionData(serial);
	CreateTimer(30.0, LoadActionData, serial, TIMER_REPEAT);
}

OnClientDisconnect(int client) {
	int action_cache[client] = { 0, 0 };
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	CreateNative("GetActions", Native_GetActions);
	return APLRes_Success;
}

// Called with (int client, int[2] actions)
public int Native_GetActions(Handle plugin, int numParams) {
	int client = GetNativeCell(1);

	if (refresh_time[client] < GetTime() - 60) {
		PrintToServer("%N has out of date data it appears, time: %d", client, refresh_time[client]);
		LoadActionData(serial);
		CreateTimer(30.0, LoadActionData, serial, TIMER_REPEAT);
	}

	SetNativeArray(2, action_cache[client], 2);
	return 0;
}

public Action LoadActionData(Handle timer, any serial) {
	int client = GetClientFromSerial(serial);
	if (client == 0) return Plugin_Stop;

	char query[256], steam_id[64];
	GetClientAuthId(client, AuthId_Steam2, steam_id, sizeof(steam_id));
	Format(query, sizeof(query), "SELECT bad_action,COUNT(*) AS count FROM `deaths` WHERE `killer_id`="%s" GROUP BY bad_action ORDER BY bad_action;", steam_id)
	hDatabase.Query(GetActionCallback, query, serial);

	return Plugin_Handled;
}

public void GetActionCallback(Database db, DBResultSet results, const char[] error, any serial) {
	int client = GetClientFromSerial(serial);
	if (client == 0) return;

	if (results == null) {
		LogError("Get Action Query failed! %s", error);
	} else {
		while (SQL_FetchRow(results)) {
			int index = SQL_FetchInt(results, 0);
			action_cache[client][index] = SQL_FetchInt(results, 1);
		}
		refresh_time[client] = GetTime();
	}
}