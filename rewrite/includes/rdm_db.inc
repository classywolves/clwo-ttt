Database rdmDb;
bool rdmConnected;

public void RdmInit() {
	Database.Connect(RdmCallback, "rdm");
}

/*
 * rdm
 *   .rdm (time int, name varchar(64), auth varchar(64), rdm varchar(255))
 *   .pm () // not implemented
 */

public void RdmCallback(Database db, const char[] error, any data) {
	if (db == null) {
		LogError("RdmCallback: %s", error);
		return;
	}

	rdmDb = db;
	rdmConnected = true;
}

public void RdmInsert(char[] name, char[] auth, char[] rdm) {
	if (!rdmConnected) {
		return;
	}

	char query[768], cName[64], cRdm[256];

	rdmDb.Escape(name, cName, sizeof(cName));
	rdmDb.Escape(rdm, cRdm, sizeof(cRdm));

	Format(query, sizeof(query), "INSERT INTO rdm VALUES (%i, '%s', '%s', '%s');", GetTime(), cName, auth, cRdm);

	rdmDb.Query(RdmInsertCallback, query)
}

public void RdmInsertCallback(Database db, DBResultSet results, const char[] error, any data) {
	if (results == null) {
		LogError("RdmInsertCallback: %s", error)
	}
}
