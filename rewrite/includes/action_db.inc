Database actionDb;
bool actionConnected;

public void ActionInit() {
	Database.Connect(ActionCallback, "action");
}

/*
 * action
 *   .action (time int, name varchar(64), auth varchar(64), action varchar(255))
 *   .pm () // not implemented
 */

public void ActionCallback(Database db, const char[] error, any data) {
	if (db == null) {
		LogError("ActionCallback: %s", error);
		return;
	}

	actionDb = db;
	actionConnected = true;
}

public void ActionInsert(char[] name, char[] auth, char[] action) {
	if (!actionConnected) {
		return;
	}

	char query[768], cName[64], cAction[256];

	actionDb.Escape(name, cName, sizeof(cName));
	actionDb.Escape(action, cAction, sizeof(cAction));

	Format(query, sizeof(query), "INSERT INTO action VALUES (%i, '%s', '%s', '%s');", GetTime(), cName, auth, cAction);

	actionDb.Query(ActionInsertCallback, query)
}

public void ActionInsertCallback(Database db, DBResultSet results, const char[] error, any data) {
	if (results == null) {
		LogError("ActionInsertCallback: %s", error)
	}
}
