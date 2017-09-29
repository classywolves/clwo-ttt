char database_names[3][64];
Database databases[3];

methodmap DB {
	public DB(char[] name) {
		for (int index = 0; index < sizeof(database_names); index++) {
			if (StrEqual(database_names[index], name)) {
				// Return existing DB
				return view_as<DB>(index);
			}
			if (StrEqual(database_names[index], "")) {
				// Create new DB
				char error[255];
				databases[index] = SQL_Connect(name, true, error, sizeof(error));
				if (databases[index] == null) { PrintToServer("[%s] Could not connect to db: %s", name, error); }
				else { PrintToServer("[%s] Connected to DB", name); }
				return view_as<DB>(index);
			}
		}

		PrintToConsole("Error, %s is not a known database entry and there is no space left to add it.", name)
		return view_as<DB>(-1);
	}

	public DBStatement query(char[] statement) {
		char error[255];
		DBStatement db_query = SQL_PrepareQuery(databases[this], statement, error, sizeof(error))
		if (db_query == null) { PrintToServer(error); return db_query; }
		return db_query;
	}
}
