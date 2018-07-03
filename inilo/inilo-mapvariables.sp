#undef REQUIRE_PLUGIN
#include <sourcemod>
#include <sdktools>
#include <mapvariables>
#include <inilo>
#include <smlib>


/*
21:36 - Meitis: CREATE TABLE `maps` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `map` varchar(32) COLLATE utf8_unicode_ci NOT NULL,
  `server_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`id`),
  KEY `maps_map_index` (`map`),
  KEY `maps_server_id_index` (`server_id`)
) ENGINE=InnoDB AUTO_INCREMENT=49 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
21:36 - Meitis: CREATE TABLE `mapvariables` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `map_id` int(10) unsigned NOT NULL,
  `key` varchar(50) COLLATE utf8_unicode_ci NOT NULL,
  `value` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  KEY `mapvariables_map_id_index` (`map_id`)
) ENGINE=InnoDB AUTO_INCREMENT=60 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;


*/
/* Plugin Info */
#define PLUGIN_NAME 			"iNilo Map Variables"
#define PLUGIN_VERSION 			"0.0.199"
#define PLUGIN_AUTHOR 			"iNilo.net"
#define PLUGIN_DESCRIPTION		"Map Variables Storage"
#define PLUGIN_URL				"http://inilo.net"

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};




#define MAXMAPVARIABLES 32
#define MAXMAPVARIABLESTRING 32

enum MapVariableString
{
	s_key,
	s_value
};

StringMap g_smMapVariables = null;

Handle g_hMapVariablesFetched = null;

Database g_hDatabase = null;


int g_iTime = 0;


bool g_bDatabaseOnline = false;

bool g_bFetched;
bool g_bAvailable;

public void OnPluginStart()
{


	g_smMapVariables = new StringMap();

	g_hMapVariablesFetched = CreateGlobalForward("OnMapVariablesFetched", ET_Ignore);

	sql2_InitDB();
	RegAdminCmd("mapvariables", Command_MapVariables, ADMFLAG_KICK, "mapvariables");
	PrintToChatAll(" \x03[\x01%s\x03] \x01>\x04Online\x01<",PLUGIN_NAME);

}
public Action Command_MapVariables(int client, int args)
{
	ReplyToCommand(client," Database online == %b", g_bDatabaseOnline);
	ReplyToCommand(client," Variables fetched from database == %b", g_bFetched);
	ReplyToCommand(client," Variables found == %b", g_bAvailable);
	StringMapSnapshot snMap = g_smMapVariables.Snapshot();
	char cValue[128];
	int iValue;
	for(int location = 0; location < snMap.Length; location++)
	{
		int length = snMap.KeyBufferSize(location);
		char[] cKey = new char[length];
		snMap.GetKey(location, cKey, length);

		//try string grab
		if(g_smMapVariables.GetString(cKey, cValue, sizeof(cValue)))
		{
			ReplyToCommand(client," [mapvariable] '%s' == '%s' (string)", cKey, cValue);
		}
		//try int grab
		if(g_smMapVariables.GetValue(cKey, iValue))
		{
			ReplyToCommand(client," [mapvariable] %s == '%i' (int)", cKey, iValue);
		}
		
	}
	delete snMap;
	return Plugin_Handled;
}
public OnPluginEnd()
{
	PrintToChatAll(" \x03[\x01%s\x03] \x01>\x02Offline\x01<",PLUGIN_NAME);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("MapVariablesAvailable", Native_MapVariablesAvailable);
	CreateNative("MapVariablesFetched", Native_MapVariablesFetched);


	CreateNative("RefetchMapVariables", Native_RefetchMapVariables);

	CreateNative("DeleteMapVariable", Native_DeleteMapVariable);


	CreateNative("GetMapVariableString", Native_GetMapVariableString);
	CreateNative("SetMapVariableString", Native_SetMapVariableString);


	CreateNative("GetMapVariableFloat", Native_GetMapVariableFloat);
	CreateNative("SetMapVariableFloat", Native_SetMapVariableFloat);

	CreateNative("GetMapVariableInt", Native_GetMapVariableInt);
	CreateNative("SetMapVariableInt", Native_SetMapVariableInt);

	RegPluginLibrary("mapvariables");
	return APLRes_Success;
}

public void OnMapStart()
{
	//SaveMapVariables();	
	if(g_bDatabaseOnline)
	{
		GetMapVariables();
	}
}
public OnMapEnd()
{	
	// @TODO: Might require us to fire a forward other people can save their mapvariables during?
	g_smMapVariables.Clear();
	g_bFetched = false;
	g_bAvailable = false;
}


public void sql2_InitDB()
{
	g_bDatabaseOnline = sql2_connectMysqlDatabase();
	if(g_bDatabaseOnline)
	{
		GetMapVariables();
	}
}

public bool DBOnline()
{
	if(!g_bDatabaseOnline)
		return false;
	if(g_hDatabase == null)
		return false;
	return true;
}

public bool sql2_connectMysqlDatabase()
{
	if (g_hDatabase != null)
		return true;
	
	char error[512];
	g_hDatabase = SQL_Connect("jailbreak", true, error, sizeof(error));


	if (g_hDatabase == null)
	{
		PrintToServer("[mapvariables] SQL faillure %s",error);

	}
	return g_hDatabase != null;
}



public int Native_RefetchMapVariables(Handle plugin, int numParams)
{
	if(g_bDatabaseOnline)
	{
		GetMapVariables();
	}
	return;
}
public int Native_MapVariablesAvailable(Handle plugin, int numParams)
{
	return g_bAvailable;
}
public int Native_MapVariablesFetched(Handle plugin, int numParams)
{
	return g_bFetched;
}
public int Native_GetMapVariableString(Handle plugin, int numParams)
{
	if(!DBOnline())
		return MAPVARIABLE_NOT_AVAILABLE;
	char sKey[MAPVARIABLES_KEY_MAXSIZE];
	char sValue[MAPVARIABLES_VALUE_MAXSIZE];

	GetNativeString(1, sKey, sizeof(sKey));
	int iWritten;
	if (!g_smMapVariables.GetString(sKey, sValue,sizeof(sValue),iWritten))
	{
		return MAPVARIABLE_NOT_AVAILABLE;
	}
	
	int iLength = GetNativeCell(3);
	return SetNativeString(2, sValue, iLength);	
}

public int Native_SetMapVariableString(Handle plugin, int numParams)
{
	if(!DBOnline())
		return MAPVARIABLE_NOT_AVAILABLE;
	char sKey[MAPVARIABLES_KEY_MAXSIZE];
	char sValue[MAPVARIABLES_VALUE_MAXSIZE];

	GetNativeString(1, sKey, sizeof(sKey));
	GetNativeString(2, sValue,sizeof(sValue));

	char sValueLookup[MAPVARIABLES_VALUE_MAXSIZE];
	if (g_smMapVariables.GetString(sKey,sValueLookup,sizeof(sValueLookup)))
	{
		if(!StrEqual(sValueLookup,sValue,true))
		{
			//not the same.
			UpdateMapVariableString(sKey,sValue);
		}
	}
	else
	{
		//key & value dont exist.
		UpdateMapVariableString(sKey,sValue);
	}
}


public int Native_GetMapVariableFloat(Handle plugin, int numParams)
{
	if(!DBOnline())
		return MAPVARIABLE_NOT_AVAILABLE;
	char sKey[MAPVARIABLES_KEY_MAXSIZE];
	char sValue[MAPVARIABLES_VALUE_MAXSIZE];
	GetNativeString(1, sKey, sizeof(sKey));
	int iWritten;
	if (!g_smMapVariables.GetString(sKey, sValue,sizeof(sValue),iWritten))
	{
		return MAPVARIABLE_NOT_AVAILABLE;
	}
	SetNativeCellRef(2, StringToFloat(sValue));
	return true;
}

public int Native_GetMapVariableInt(Handle plugin, int numParams)
{
	if(!DBOnline())
		return MAPVARIABLE_NOT_AVAILABLE;
	char sKey[MAPVARIABLES_KEY_MAXSIZE];
	char sValue[MAPVARIABLES_VALUE_MAXSIZE];
	GetNativeString(1, sKey, sizeof(sKey));
	int iWritten;
	if (!g_smMapVariables.GetString(sKey, sValue,sizeof(sValue),iWritten))
	{
		return MAPVARIABLE_NOT_AVAILABLE;
	}
	SetNativeCellRef(2, StringToInt(sValue))
	return true;
}


public int Native_SetMapVariableFloat(Handle plugin, int numParams)
{
	if(!DBOnline())
		return MAPVARIABLE_NOT_AVAILABLE;
	char sKey[MAPVARIABLES_KEY_MAXSIZE];
	char sValue[MAPVARIABLES_VALUE_MAXSIZE];

	GetNativeString(1, sKey, sizeof(sKey));

	float fValue = view_as<float>(GetNativeCell(2));
	FloatToString(fValue, sValue, sizeof(sValue));

	char sValueLookup[MAPVARIABLES_VALUE_MAXSIZE];
	if (g_smMapVariables.GetString(sKey,sValueLookup,sizeof(sValueLookup)))
	{
		if(!StrEqual(sValueLookup,sValue,true))
		{
			//not the same.
			UpdateMapVariableString(sKey,sValue);
		}
	}
	else
	{
		//key & value dont exist.
		UpdateMapVariableString(sKey,sValue);
	}
}

public int Native_SetMapVariableInt(Handle plugin, int numParams)
{
	if(!DBOnline())
		return MAPVARIABLE_NOT_AVAILABLE;
	char sKey[MAPVARIABLES_KEY_MAXSIZE];
	char sValue[MAPVARIABLES_VALUE_MAXSIZE];

	GetNativeString(1, sKey, sizeof(sKey));

	int iValue = view_as<int>(GetNativeCell(2));
	IntToString(iValue, sValue, sizeof(sValue));

	char sValueLookup[MAPVARIABLES_VALUE_MAXSIZE];
	if (g_smMapVariables.GetString(sKey, sValueLookup, sizeof(sValueLookup)))
	{
		if(!StrEqual(sValueLookup,sValue,true))
		{
			//not the same.
			UpdateMapVariableString(sKey,sValue);
		}
	}
	else
	{
		//key & value dont exist.
		UpdateMapVariableString(sKey,sValue);
	}
}

public int Native_DeleteMapVariable(Handle plugin, int numParams)
{
	if(!DBOnline())
		return MAPVARIABLE_NOT_AVAILABLE;
	char sKey[MAPVARIABLES_KEY_MAXSIZE];
	GetNativeString(1, sKey, sizeof(sKey));

	char sValueLookup[MAPVARIABLES_VALUE_MAXSIZE];
	if (g_smMapVariables.GetString(sKey,sValueLookup,sizeof(sValueLookup)))
	{
		//exists 
		Internal_DeleteMapVariable(sKey);
	}
}

public void Internal_DeleteMapVariable(char[] cKey)
{
	char cKey_SAFE[MAPVARIABLES_KEY_MAXSIZE];

	g_hDatabase.Escape(cKey, cKey_SAFE, sizeof(cKey_SAFE));

	char sQuery[2048];

	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));
	Format(sQuery, sizeof(sQuery), "DELETE FROM `inilo_mapvariables` WHERE `inilo_mapvariables`.`Mapname` LIKE '%s' AND  `inilo_mapvariables`.`VariableKey` LIKE '%s';",sMap,cKey_SAFE);

	PrintToServer(sQuery);

	DataPack pack = new DataPack();
	pack.WriteString(sMap);
	pack.WriteString(cKey_SAFE);

	g_hDatabase.Query(SQL_Callback_DeleteVariable, sQuery, pack, DBPrio_Normal);

}



public void UpdateMapVariableString(char[] cKey, char[] cValue)
{
	//INSERT INTO `jailbreak_jailbreak`.`inilo_mapvariables` (`VariableID`, `Mapname`, `VariableKey`, `VariableValue`) VALUES (NULL, 'map_name', 'key', 'value');

	char cKey_SAFE[MAPVARIABLES_KEY_MAXSIZE];
	char cValue_SAFE[MAPVARIABLES_VALUE_MAXSIZE];

	g_hDatabase.Escape(cKey, cKey_SAFE, sizeof(cKey_SAFE));
	g_hDatabase.Escape(cValue, cValue_SAFE, sizeof(cValue_SAFE));


	char sQuery[2048];

	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));
	//Format(sQuery, sizeof(sQuery), "INSERT IGNORE INTO `inilo_mapvariables` (`VariableID`, `Mapname`, `VariableKey`, `VariableValue`) VALUES (NULL, '%s', '%s', '%s');",sMap,cKey_SAFE,cValue_SAFE);
	Format(sQuery, sizeof(sQuery), "INSERT INTO `inilo_mapvariables` (`VariableID`, `Mapname`, `VariableKey`, `VariableValue`) VALUES (NULL, '%s', '%s', '%s') ON DUPLICATE KEY UPDATE `VariableValue` = VALUES(VariableValue);",sMap,cKey_SAFE,cValue_SAFE);

/*
INSERT INTO subs
  (subs_name, subs_email, subs_birthday)
VALUES
  (?, ?, ?)
ON DUPLICATE KEY UPDATE
  subs_name     = VALUES(subs_name),
  subs_birthday = VALUES(subs_birthday)

  */
	DataPack pack = new DataPack();
	pack.WriteString(sMap);
	pack.WriteString(cKey_SAFE);
	pack.WriteString(cValue_SAFE);

	g_hDatabase.Query(SQL_Callback_SaveVariable, sQuery, pack, DBPrio_Normal);

	//Escape(const char[] string, char[] buffer, int maxlength, int &written)
}

void GetMapVariables()
{
	if (g_hDatabase == null)
	{
		// We don't know what map and/or server this is yet OR we already got the map's variables
		return;
	}
	
	int iCurrentTime = GetTime();
	if ((iCurrentTime - g_iTime) < 5)
	{
		// OnMapStart was probably fired multiple times in quick succession
		return;
	}
	g_iTime = iCurrentTime;
	
	char sQuery[2048];

	char sMap[255];
	GetCurrentMap(sMap, sizeof(sMap));
	g_hDatabase.Escape(sMap, sMap, sizeof(sMap));
	Format(sQuery, sizeof(sQuery), "SELECT * FROM `inilo_mapvariables` WHERE `Mapname` LIKE '%s'", sMap);

	DataPack pack = new DataPack();
	pack.WriteString(sMap);

	PrintToServer("[mapvariables] %s", sQuery);
	g_hDatabase.Query(SQL_Callback_GetMapVariables, sQuery, pack, DBPrio_Normal);
}


public void SQL_Callback_DeleteVariable(Database db, DBResultSet results, const char[] sError, any data)
{
	if (db == null || strlen(sError) != 0)
	{
		PrintToServer("[SQL_Callback_SaveVariable] %s", sError);
		LogError("An error occured while fetching the mapvariables: %s", sError);
		return;
	}

	char sOldMap[64]; 
	char sCurrentMap[64];

	char cKey[MAPVARIABLES_KEY_MAXSIZE];

	DataPack pack = view_as<DataPack>(data);
	pack.Reset();
	pack.ReadString(sOldMap, sizeof(sOldMap));
	pack.ReadString(cKey, sizeof(cKey));
	delete pack;

	GetCurrentMap(sCurrentMap, sizeof(sCurrentMap));
	if (!StrEqual(sOldMap, sCurrentMap))
	{
		// We're already on the next map
		LogMessage("Only got the current map while on the next one");
		return;
	}

	g_smMapVariables.Remove(cKey);
}


public void SQL_Callback_SaveVariable(Database db, DBResultSet results, const char[] sError, any data)
{
	if (db == null || strlen(sError) != 0)
	{
		PrintToServer("[SQL_Callback_SaveVariable] %s", sError);
		LogError("An error occured while fetching the mapvariables: %s", sError);
		return;
	}

	char sOldMap[64]; 
	char sCurrentMap[64];

	char cKey[MAPVARIABLES_KEY_MAXSIZE];
	char cValue[MAPVARIABLES_VALUE_MAXSIZE];

	


	DataPack pack = view_as<DataPack>(data);
	pack.Reset();
	pack.ReadString(sOldMap, sizeof(sOldMap));
	pack.ReadString(cKey, sizeof(cKey));
	pack.ReadString(cValue, sizeof(cValue));
	delete pack;

	GetCurrentMap(sCurrentMap, sizeof(sCurrentMap));
	if (!StrEqual(sOldMap, sCurrentMap))
	{
		// We're already on the next map
		LogMessage("Only got the current map while on the next one");
		return;
	}

	g_smMapVariables.SetString(cKey, cValue, true);
}
public void SQL_Callback_GetMapVariables(Database db, DBResultSet results, const char[] sError, any data)
{
	if (db == null || strlen(sError) != 0)
	{
		LogError("An error occured while fetching the mapvariables: %s", sError);
		return;
	}
	g_bFetched = true; //fetched them

	char sOldMap[64]; 
	char sCurrentMap[64];
	
	DataPack pack = view_as<DataPack>(data);
	pack.Reset();
	pack.ReadString(sOldMap, sizeof(sOldMap));
	delete pack;
	
	GetCurrentMap(sCurrentMap, sizeof(sCurrentMap));

	if (!StrEqual(sOldMap, sCurrentMap))
	{
		// We're already on the next map
		LogMessage("Only got the current map while on the next one");
		return;
	}
	if(results.RowCount > 0)
	{
		g_bAvailable = true;
	}
	else
	{
		g_bAvailable = false;
		LogToMyOwnLittleFile("map[%s] has no mapvariables", sCurrentMap);
	}
	while (results.FetchRow())
	{

		int iField_VariableKey;
		int iField_VariableValue;



		char cKey[MAPVARIABLES_KEY_MAXSIZE];
		char cValue[MAPVARIABLES_VALUE_MAXSIZE];

		if(results.FieldNameToNum("VariableKey",iField_VariableKey) && results.FieldNameToNum("VariableValue",iField_VariableValue))
		{
			//grab em.
			results.FetchString(iField_VariableKey,cKey, MAPVARIABLES_KEY_MAXSIZE);
			results.FetchString(iField_VariableValue,cValue, MAPVARIABLES_VALUE_MAXSIZE);
			g_smMapVariables.SetString(cKey,cValue,true);
		}
		
	}
	Call_StartForward(g_hMapVariablesFetched);
	Call_Finish();
}

