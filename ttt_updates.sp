#include <general>
#include <ttt_helpers>
#include <player_methodmap>
#include <logger>

Database hDatabase = null;

int current_update = 1;

public OnPluginStart() {
	setLogSource("updates");
	Database.Connect(DBCallback, "ttt");
}

public void OnClientPostAdminCheck(int client) {
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

	Player player = Player(client);
	char auth[255];
	player.get_auth(AuthId_Steam2, auth);

	if (results == null) {
		LogError("Query failed! %s", error);
	} else if (results.RowCount == 0) {
		// NEW USER
		createUser(client)
	} else {
		// EXISTING USER
		if (SQL_FetchRow(results)) {
			int current_player_update = SQL_FetchInt(results, 1)
			PrintToConsole(client, "Heyo, got %d", current_player_update)

			if (current_update != current_player_update) {
				// SHOW CURRENT_UPDATE
				char query[255];
				Format(query, sizeof(query), "UPDATE updates SET update = %d WHERE steamid = \"%s\"", current_update, auth)
				if (!SQL_FastQuery(hDatabase, query)) {
					char error_update[255];
					SQL_GetError(hDatabase, error_update, sizeof(error_update));
					log(Error, "Failed to update current_update_version (error_update: %s)", error_update);
				}
			}
		} else {
			createUser(client)
		}
	}
}

public void createUser(int client) {
	Player player = Player(client);
	char auth[255];
	player.get_auth(AuthId_Steam2, auth);
	PrintToConsole(client, "Heyo new user %N!", client);
	char query[255];
	Format(query, sizeof(query), "INSERT INTO updates VALUES (\"%s\", %d)", auth, current_update);
	if (!SQL_FastQuery(hDatabase, query)) {
		char error_update[255];
		SQL_GetError(hDatabase, error_update, sizeof(error_update));
		log(Error, "Failed to insert current_update for %N (error_update: %s)", client, error_update);
	}
	// SHOW NEW USER SCREEN
	CreateTimer(30.0, displayNew, GetClientSerial(client));
}
 
public void DBCallback(Database db, const char[] error, any data)
{
	if (db == null) LogError("Database failure: %s", error);
	else {
		hDatabase = db;
	}
}

public Action displayNew(Handle timer, any serial) {
	int client = GetClientFromSerial(serial);
	if (!client) return Plugin_Stop;

	Player player = Player(client);
	if (player.valid_client) {
		player.display_url("https://ttt.clwo.eu/fastdl/welcome.html", false);
	} else {
		CreateTimer(30.0, displayNew, serial);
	}

	return Plugin_Stop;
}