#if defined _ttt_db_included
#endinput
#endif
#define _ttt_db_included

Database tttDb;
bool tttConnected = false;

public void TTTInit() {
    Database.Connect(TTTCallback, "ttt");
}

public void TTTCallback(Database db, const char[] error, any data) {
    if (db == null) {
        LogError("RdmCallback: %s", error);
        return;
    }

    //SQL_FastQuery(db, "SET NAMES utf8");
    SQL_SetCharset(db, "utf8");

    tttDb = db;
    tttConnected = true;
}
