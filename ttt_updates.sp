#include <general>
#include <ttt_helpers>
#include <player_methodmap>

Database hDatabase = null;

int current_update = 1;

public OnPluginStart() {
	Database.Connect(DBCallback, "ttt");
}

public void OnClientPutInServer(int client) {
	Player player = Player(client);
	char query[255], auth[255];
	player.get_auth(AuthId_Steam2, auth);
	FormatEx(query, sizeof(query), "SELECT * FROM updates WHERE steamid = '%s'", auth);
	hDatabase.Query(UpdateStandingCallback, query, GetClientUserId(client));
}

public void UpdateStandingCallback(Database db, DBResultSet results, const char[] error, any data) {
	int client = 0;
 
	/* Make sure the client didn't disconnect while the thread was running */
	if ((client = GetClientOfUserId(data)) == 0) return;

	if (results == null) {
		LogError("Query failed! %s", error);
	} else if (results.RowCount == 0) {
		// NEW USER

	} else {
		// EXISTING USER
		if (SQL_FetchRow(results)) {
			int current_player_update = SQL_FetchInt(results, 0)
			PrintToConsole(client, "Heyo, got %d", current_player_update)

			if (current_update != current_player_update) {
				if (!SQL_FastQuery(hDatabase, "UPDATE stats SET players = players + 1")) {
					char error[255];
					SQL_GetError(hDatabase, error, sizeof(error));
					PrintToServer("Failed to query (error: %s)", error);
				}
			}
		}
	}
}
 
public void DBCallback(Database db, const char[] error, any data)
{
	if (db == null) LogError("Database failure: %s", error);
	else {
		hDatabase = db;
	}
}