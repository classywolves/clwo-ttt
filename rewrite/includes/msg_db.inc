Database msgDb;
bool msgConnected;

public void MsgInit() {
	Database.Connect(MsgCallback, "msg");
}

/*
 * msg
 *   .msg (time int, name varchar(64), auth varchar(64), msg varchar(255))
 *   .pm () // not implemented
 */

public void MsgCallback(Database db, const char[] error, any data) {
	if (db == null) {
		LogError("MsgCallback: %s", error);
		return;
	}

	msgDb = db;
	msgConnected = true;
}

public void MsgInsert(char[] name, char[] auth, char[] msg) {
	if (!msgConnected) {
		return;
	}

	char query[768], cName[64], cMsg[256];

	msgDb.Escape(name, cName, sizeof(cName));
	msgDb.Escape(msg, cMsg, sizeof(cMsg));

	Format(query, sizeof(query), "INSERT INTO msg VALUES (%i, '%s', '%s', '%s');", GetTime(), cName, auth, cMsg);

	PrintToServer("Running query: %s", query);

	msgDb.Query(MsgInsertCallback, query)
}

public void MsgInsertCallback(Database db, DBResultSet results, const char[] error, any data) {
	if (results == null) {
		LogError("MsgInsertCallback: %s", error)
	}
}
