Database playtimeDb;
bool playtimeConnected;

public void PlaytimeInit() {
	Database.Connect(PlaytimeCallback, "playtime");
}

/*
 * playtime
 *   .playtime (time int, name varchar(64), auth varchar(64), playtime varchar(255))
 *   .pm () // not implemented
 */

public void PlaytimeCallback(Database db, const char[] error, any data) {
	if (db == null) {
		LogError("PlaytimeCallback: %s", error);
		return;
	}

	playtimeDb = db;
	playtimeConnected = true;
}

public void PlaytimeInsert(char[] name, char[] auth, char[] playtime) {
	if (!playtimeConnected) {
		return;
	}

	char query[768], cName[64], cPlaytime[256];

	playtimeDb.Escape(name, cName, sizeof(cName));
	playtimeDb.Escape(playtime, cPlaytime, sizeof(cPlaytime));

	Format(query, sizeof(query), "INSERT INTO playtime VALUES (%i, '%s', '%s', '%s');", GetTime(), cName, auth, cPlaytime);

	playtimeDb.Query(PlaytimeInsertCallback, query)
}

public void PlaytimeInsertCallback(Database db, DBResultSet results, const char[] error, any data) {
	if (results == null) {
		LogError("PlaytimeInsertCallback: %s", error)
	}
}
