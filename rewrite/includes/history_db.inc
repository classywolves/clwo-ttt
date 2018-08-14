Database historyDb;
bool historyConnected;

public void HistoryInit() {
	Database.Connect(HistoryCallback, "ttt");
}

// SteamID, Timestamp, Message, MsgType AdminID, AdminName

/*
 * ttt
 *   .history (time int, auth varchar(64), msg varchar(256), msg_type varchar(32), admin_name varchar(128), admin_auth varchar(64))
 */

public void HistoryCallback(Database db, const char[] error, any data) {
	if (db == null) {
		LogError("HistoryCallback: %s", error);
		return;
	}

	historyDb = db;
	historyConnected = true;
}

public void HistoryInsert(char[] auth, char[] msg, char[] msgType, char[] adminName, char[] adminAuth) {
	if (!historyConnected) {
		return;
	}

	char query[1024], cAuth[64], cMsg[256], cMsgType[32], cAdminName[128], cAdminAuth[64];

	historyDb.Escape(auth, cAuth, sizeof(cAuth));
	historyDb.Escape(msg, cMsg, sizeof(cMsg));
	historyDb.Escape(msgType, cMsgType, sizeof(cMsgType));
	historyDb.Escape(adminName, cAdminName, sizeof(cAdminName));
	historyDb.Escape(adminAuth, cAdminAuth, sizeof(cAdminAuth));

	Format(query, sizeof(query), "INSERT INTO history VALUES (%i, '%s', '%s', '%s', '%s', %s');", GetTime(), cAuth, cMsg, cMsgType, cAdminName, cAdminAuth);

	historyDb.Query(HistoryInsertCallback, query)
}

public void HistoryInsertCallback(Database db, DBResultSet results, const char[] error, any data) {
	if (results == null) {
		LogError("HistoryInsertCallback: %s", error)
	}
}
