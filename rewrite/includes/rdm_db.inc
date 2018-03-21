#if defined _rdm_db_included
	#endinput
#endif
#define _rdm_db_included

Database rdmDb;
bool rdmConnected;

int currentRound

public void RdmInit() {
	Database.Connect(RdmCallback, "rdm");
}

/*
 * rdm
 *   .death (index int, time int, victimName varchar(64), victimAuth varchar(32), victimRole tinyint, victimKarma int, killerName varchar(64), killerAuth varchar(32), killerRole tinyint, killerKarma int, weapon varchar(64), bad boolean, lastGunFire int, round int, verdict int)
 */

public void RdmCallback(Database db, const char[] error, any data) {
	if (db == null) {
		LogError("RdmCallback: %s", error);
		return;
	}

	SQL_FastQuery(db, "SET NAMES utf8");
	SQL_SetCharset(db, "utf8");

	rdmDb = db;
	rdmConnected = true;
}

public void RdmDeathInsert(char[] name, char[] auth, char[] rdm) {
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
