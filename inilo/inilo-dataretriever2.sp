
#undef REQUIRE_PLUGIN
#include <smlib>
#include <inilo>
#include <dataretriever2>
#include <steamworks>
#define PLUGIN_VERSION 			"0.0.300"
/* Plugin Info */
#define PLUGIN_NAME 			"iNilo Dataretiever v2"
#define PLUGIN_VERSION_M 			"1.0.0"
#define PLUGIN_AUTHOR 			"iNilo.net"
#define PLUGIN_DESCRIPTION		"Collect data"
#define PLUGIN_URL				"http://inilo.net"

//#pragma newdecls required

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION_M,
	url = PLUGIN_URL
};

Database g_dDB;


bool g_bLoadNewDataPoints = false;
bool g_bSlackKnows = false;
int g_iFiredQueries = false;

#define DATA_TO_PULL 750
#define DEFAULT_DISTANCE 750.0
#define MAX_DISTANCE 750.0
#define MIN_DISTANCE 250.0
#define DISTANCE_SPLITTER_DEVISOR 30.0


ArrayList g_alData = null;
ArrayList g_alData_pos = null;

ArrayList g_alTimeblock_0 = null;
ArrayList g_alTimeblock_1 = null;
ArrayList g_alTimeblock_2 = null;
ArrayList g_alTimeblock_3 = null;
ArrayList g_alTimeblock_4 = null;
ArrayList g_alTimeblock_5 = null;
ArrayList g_alTimeblock_6 = null;
ArrayList g_alTimeblock_7 = null;
ArrayList g_alTimeblock_8 = null;
ArrayList g_alTimeblock_9 = null;

ArrayList g_aSpreadOutData = null;


float g_fMinBounds[3];
float g_fMaxBounds[3];
float g_fDistance;
float g_fDistanceSplitter;
float g_fDistanceSplitter_strict;

public void OnPluginStart()
{
	hello();
	StartupDB();

	RegisterCvars();
	RegisterCmds();
	HookEvents();

 	PrintToChatAll(" \x03[\x01%s\x03] \x01>\x04Online\x01<", PLUGIN_NAME);
}


public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("inilo-dataretriever2");

	CreateNative("DR2_GetRandomLocation", Native_GetRandomLocation);
	CreateNative("DR2_GetRandomLocationUnique", Native_GetRandomLocationUnique);
	CreateNative("DR2_GetRandomLocationFromTimeBlock", Native_GetRandomLocationFromTimeBlock);
	CreateNative("DR2_GetRandomLocationSpreadOut", Native_GetRandomLocationSpreadOut);
	CreateNative("DR2_LocationSpreadOutCount", Native_LocationSpreadOutCount);

	MarkNativeAsOptional("DR2_GetRandomLocation");
	MarkNativeAsOptional("DR2_GetRandomLocationUnique");
	MarkNativeAsOptional("DR2_GetRandomLocationFromTimeBlock");
	MarkNativeAsOptional("DR2_GetRandomLocationSpreadOut");
	MarkNativeAsOptional("DR2_LocationSpreadOutCount");
	return APLRes_Success;
}


public void RegisterCvars()
{

}
public void RegisterCmds()
{
	RegConsoleCmd("dr2", Command_Dr2, "dr2 command");
	RegAdminCmd("dr2_probe", Command_Probe, ADMFLAG_GENERIC, "dr2_probe");
}
public void HookEvents()
{
	HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_freeze_end", OnRoundFreezeEnd, EventHookMode_PostNoCopy);
	HookEvent("round_end", OnRoundEnd, EventHookMode_PostNoCopy);
}

//setupDB
public void StartupDB()
{
	if(g_dDB == null)
	{
		Database.Connect(DBConnectCallback, "datacollector2");
	}
}
public void DBConnectCallback(Database db, const char[] error, any data)
{
	if(db == null)
	{
		//som ting wong
		LogError(error);
		PrintToServer(error);
		return;
	}
	g_dDB = db;
	PostLoadDB();

}

public void PostLoadDB()
{
	LoadNewDataPoints();
}

public void OnPluginEnd()
{

	PrintToChatAll(" \x03[\x01%s\x03] \x01>\x02Offline\x01<", PLUGIN_NAME);
}
public void OnMapStart()
{
	g_bSlackKnows = false;

	GetEntPropVector(0, Prop_Data, "m_WorldMins", g_fMinBounds);
	GetEntPropVector(0, Prop_Data, "m_WorldMaxs", g_fMaxBounds);
	g_fDistance = GetVectorDistance(g_fMinBounds, g_fMaxBounds);
	g_fDistanceSplitter = (g_fDistance / DISTANCE_SPLITTER_DEVISOR);
	g_fDistanceSplitter_strict = g_fDistanceSplitter;
	if(g_fDistanceSplitter <= MIN_DISTANCE)
		g_fDistanceSplitter_strict = MIN_DISTANCE;
	if(g_fDistanceSplitter >= MAX_DISTANCE)
		g_fDistanceSplitter_strict = MAX_DISTANCE;

	//ReportWorldSpawnsToSlack();
}
public void OnMapEnd()
{
	//ReportWorldSpawnsToSlack();
}

public Action OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	//PrintToChatiNilo("OnRoundStart");
	//g_bStartcollecting = true;
	return Plugin_Continue;
}

public Action OnRoundFreezeEnd(Event event, const char[] name, bool dontBroadcast)
{
	return Plugin_Continue;
}

public Action OnRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	//grab points from DB.
	LoadNewDataPoints();
	return Plugin_Continue;
}


public int Native_GetRandomLocation(Handle plugin, int numParams)
{
	if(!DBHasData())
		return false;
	float fLocation[3];
	GetRandomLocation(fLocation);
	SetNativeArray(1, fLocation, 3);
	return true;
}
public int Native_GetRandomLocationFromTimeBlock(Handle plugin, int numParams)
{
	if(!DBHasData())
		return false;
	int TimeBlock = GetNativeCell(2);
	float fLocation[3];
	GetRandomLocationFromTimeBlock(fLocation, TimeBlock);
	SetNativeArray(1, fLocation, 3);
	return true;
}
public int Native_GetRandomLocationSpreadOut(Handle plugin, int numParams)
{
	if(!DBHasData())
		return false;
	float fLocation[3];
	GetRandomLocationFromSpreadOut(fLocation);
	SetNativeArray(1, fLocation, 3);
	return true;
}
public int Native_LocationSpreadOutCount(Handle plugin, int numParams)
{
	if(!DBHasData())
		return 0;
	return g_aSpreadOutData.Length;
}

public int Native_GetRandomLocationUnique(Handle plugin, int numParams)
{
	if(!DBHasData())
		return false;
	float fLocation[3];
	GetRandomLocationUnique(fLocation);
	SetNativeArray(1, fLocation, 3);
	return true;
}

public void GetRandomLocationUnique(float fLocation[3])
{
	GetRandomLocation(fLocation);
}

public int GetRandomLocation(float fLocation[3])
{
	int location =  GetRandomInt(0, g_alData_pos.Length);
	g_alData_pos.GetArray(location, fLocation, sizeof(fLocation));
	return location;
}
public int GetRandomLocationFromTimeBlock(float fLocation[3], int TimeBlock)
{
	ArrayList alTimeBlock = GetTimeBlockArrayList(TimeBlock);
	int location_reference = GetRandomInt(0, alTimeBlock.Length);
	int real_location = alTimeBlock.Get(location_reference);
	g_alData_pos.GetArray(real_location, fLocation, sizeof(fLocation));
	return real_location;
}
public int GetRandomLocationFromSpreadOut(float fLocation[3])
{
	int location_reference = GetRandomInt(0, g_aSpreadOutData.Length - 1);
	int real_location = g_aSpreadOutData.Get(location_reference);
	g_alData_pos.GetArray(real_location, fLocation, sizeof(fLocation));
	return real_location;
}


public bool DBHasData()
{
	if(g_dDB == null)
		return false;
	if(g_alData == null || g_alData_pos == null)
		return false;
	if(g_alData.Length == 0 || g_alData_pos.Length == 0)
		return false;
	return true;
}

public Action Command_Dr2(int client, int args)
{
	if(g_dDB == null)
	{
		ReplyToCommand(client, "[%s] Database interface offline ", PLUGIN_NAME);
	}
	else
	{
		ReplyToCommand(client, "[%s] Database interface online ", PLUGIN_NAME);
	}

	char cMapName[512];
	GetDBMapName(cMapName, sizeof(cMapName));
	ReplyToCommand(client, "[%s] GetDBMapName() == %s ", PLUGIN_NAME, cMapName);
	if(g_alData == null)
	{
		ReplyToCommand(client, "[%s] g_alData is null ", PLUGIN_NAME);
	}	
	else
	{
		ReplyToCommand(client, "[%s] g_alData.Length == %i ", PLUGIN_NAME, g_alData.Length);
	}
	if(g_alData_pos == null)
	{
		ReplyToCommand(client, "[%s] g_alData_pos is null ", PLUGIN_NAME);
	}	
	else
	{
		ReplyToCommand(client, "[%s] g_alData_pos.Length == %i ", PLUGIN_NAME, g_alData_pos.Length);
	}	
	PrintTimeBlockStats(client);
	ReplyToCommand(client, "[%s] m_WorldMins [%f,%f,%f]", PLUGIN_NAME, g_fMinBounds[0], g_fMinBounds[1], g_fMinBounds[2]);
	ReplyToCommand(client, "[%s] m_WorldMaxs [%f,%f,%f]", PLUGIN_NAME, g_fMaxBounds[0], g_fMaxBounds[1], g_fMaxBounds[2]);
	ReplyToCommand(client, "[%s] Distance [%f]", PLUGIN_NAME, g_fDistance);
	ReplyToCommand(client, "[%s] DistanceSplitter [%f] g_fDistanceSplitter_strict [%f]", PLUGIN_NAME, g_fDistanceSplitter, g_fDistanceSplitter_strict);
	ReplyToCommand(client, "[%s] g_aSpreadOutData.Length == %i points with minimum distance of %f", PLUGIN_NAME, g_aSpreadOutData.Length, DEFAULT_DISTANCE);
	ReplyToCommand(client, "[%s] Current timeblock sync is %.2f%% ", PLUGIN_NAME, GetTimeBlockSync());
	return Plugin_Handled
}
public Action Command_Probe(int client, int args)
{
	if(!DBHasData())
	{
		ReplyToCommand(client, " [SM] DB's not ready");
		return Plugin_Handled
	}
	int probe = GetRandomInt(0, g_alData_pos.Length);
	ReplyToCommand(client, " probing %i ", probe);
	DumpLocationInfo(client, probe);
	return Plugin_Handled
}

public void DumpLocationInfo(int client, int location)
{
	float fLoc[3];
	int iData[3];
	g_alData_pos.GetArray(location, fLoc, sizeof(fLoc));
	g_alData.GetArray(location, iData, sizeof(iData));
	char cTeam[32];
	GetTeamName(iData[0] , cTeam, sizeof(cTeam));
	/*	
		iData[0] = results.FetchInt(iF_team);
		iData[1] = results.FetchInt(iF_state);
		iData[2] = results.FetchInt(iF_time);
	*/
	char cState[64];
	GetDataRetrieverState(iData[1], cState, sizeof(cState));
	PrintToConsole(client, " Location [%f,%f,%f] %s %s", fLoc[0], fLoc[1], fLoc[2], cTeam, cState);
	TeleportEntity(client, fLoc , NULL_VECTOR, NULL_VECTOR);
}

public int GetDBMapName(char[] cOutput, int maxlen)
{
	char cMapName[512];
	int len = GetCurrentMap(cMapName, sizeof(cMapName));
	return Crypt_Base64Encode(cMapName, cOutput, maxlen, len);
}


public void LoadNewDataPoints()
{
	if(g_bLoadNewDataPoints) //prevent double
		return;
	g_bLoadNewDataPoints = true;
	//before we continue, clear all the current data
	ClearArrayData();
	//PrintToChatiNilo("g_aSpreadOutData.Length == %i", g_aSpreadOutData.Length);
	int amount_to_grab_per_team = (DATA_TO_PULL / 2);
	int amount_per_block = (amount_to_grab_per_team / 10);
	//PrintToConsoleiNilo("amount_to_grab_per_team == %i ", amount_to_grab_per_team);
	//PrintToConsoleiNilo("amount_per_block == %i ", amount_per_block);µ
	g_iFiredQueries = 0;
	for(int timeblock = 0; timeblock < 10; timeblock++)
	{
		float timeminimum = float((timeblock) * 60);
		float timemaximum = float((timeblock + 1) * 60);
		GrabPointsFromDB(CS_TEAM_T, timeminimum, timemaximum, amount_per_block);
		GrabPointsFromDB(CS_TEAM_CT, timeminimum, timemaximum, amount_per_block);
		//PrintToConsoleiNilo("Timeblock %i [%f -> %f]", timeblock, timeminimum, timemaximum);
	}
}

public void PrintTimeBlockStats(int client)
{
	int iTimeBlockInfo[10];
	GetTimeBlockStats(iTimeBlockInfo)
	
	for(int timeblock = 0; timeblock < 10; timeblock++)
	{
		ReplyToCommand(client, "[%s] Timeblock[%i] has %i data points (Sorted arraylist is at Length == %i)", PLUGIN_NAME, timeblock, iTimeBlockInfo[timeblock], GetTimeBlockArrayList(timeblock).Length);
	}

}

public float GetTimeBlockSync()
{
	int current_sync = 0;
	int needed_sync = DATA_TO_PULL;
	for(int timeblock = 0; timeblock < 10; timeblock++)
	{
		current_sync += GetTimeBlockArrayList(timeblock).Length;
	}
	float sync = (float(current_sync) / float(needed_sync)) * 100.00;
	return sync;
}

public void GetTimeBlockStats(int iTimeBlockInfo[10])
{
	/*
	float fLoc[3];
	fLoc[0] = results.FetchFloat(iF_x);
	fLoc[1] = results.FetchFloat(iF_y);
	fLoc[2] = results.FetchFloat(iF_z);
	int iData[3];
	iData[0] = results.FetchInt(iF_team);
	iData[1] = results.FetchInt(iF_state);
	iData[2] = results.FetchInt(iF_time);
	*/
	if(!DBHasData())
		return;
	for (int pointer = 0; pointer < g_alData.Length; pointer++)
	{
		float fLoc[3];
		int iData[3];
		g_alData_pos.GetArray(pointer, fLoc, sizeof(fLoc));
		g_alData.GetArray(pointer, iData, sizeof(iData));
		//grab time timeblock.
		iTimeBlockInfo[GetSlotBasedOnTimeInt(iData[2])]++;
	}
}

public int GetSlotBasedOnTimeInt(const int iTime)
{
	for(int timeblock = 0; timeblock <= 10; timeblock++)
	{
		int timeminimum = RoundToNearest(float((timeblock) * 60));
		int timemaximum = RoundToNearest(float((timeblock + 1) * 60));
		if(iTime >= timeminimum && iTime <= timemaximum)
		{
			return timeblock;
		}
	}
	return -1;
}


/*

[iNilo Dataretiever v2] -> SELECT * FROM `amJfb2JhbWFfdjVfYmV0YQ==` WHERE team = 2 ORDER BY RAND() LIMIT 250
[iNilo Dataretiever v2] -> SELECT * FROM `amJfb2JhbWFfdjVfYmV0YQ==` WHERE team = 3 ORDER BY RAND() LIMIT 250
[iNilo Dataretiever v2] -> results.RowCount == 250
[iNilo Dataretiever v2] -> results.RowCount == 250
*/
public void GrabPointsFromDB(int team, float fMinTime, float fMaxTime, int amount)
{
	if(g_dDB == null)
		return;
	char cMapName[512];
	GetDBMapName(cMapName, sizeof(cMapName));
	char cSelect[512];
	//pull from CT and T.
	//spread out the 1 minutes.
	Format(cSelect, sizeof(cSelect), "SELECT * FROM `%s` WHERE team = %i AND time >= %f AND TIME <= %f ORDER BY RAND() LIMIT %i", cMapName, team, fMinTime, fMaxTime, amount);
	//PrintToConsoleiNilo("[%s] -> %s", PLUGIN_NAME, cSelect);

	int iData[4];
	iData[0] = team;
	iData[1] = RoundToNearest(fMinTime);
	iData[2] = RoundToNearest(fMaxTime);
	iData[3] = amount;


	if(g_dDB != null)
	{
		g_iFiredQueries++;
		g_dDB.Query(GrabPointsFromDB_Callback, cSelect);
	}
}

public void GenericDB_Callback(Database db, DBResultSet results, const char[] error, any data)
{
	if(results == null)
	{
		LogError(error);
		PrintToServer(error);
		PrintToConsoleiNilo(error);
		return;
	}
}	

public void GrabPointsFromDB_Callback(Database db, DBResultSet results, const char[] error, any data)
{
	g_bLoadNewDataPoints = false;
	char cInitiator[128] = "GrabPointsFromDB_Callback";
	if(results == null)
	{
		LogError(error);
		PrintToServer(error);
		PrintToConsoleiNilo(error);
		return;
	}
	if(!results.HasResults)
	{
		PrintToServer("[%s] No results", cInitiator);
		return;
	}
	PrintToConsoleiNilo("[%s] -> results.RowCount == %i", PLUGIN_NAME, results.RowCount);//RowCount 

	int iF_xr;
	int iF_yr;
	int iF_zr;
	int iF_x;
	int iF_y;
	int iF_z;
	int iF_team;
	int iF_state;
	int iF_time;

	if(!results.FieldNameToNum("xr", iF_xr)
		|| !results.FieldNameToNum("yr", iF_yr)
		|| !results.FieldNameToNum("zr", iF_zr)
		|| !results.FieldNameToNum("x", iF_x)
		|| !results.FieldNameToNum("y", iF_y)
		|| !results.FieldNameToNum("z", iF_z)
		|| !results.FieldNameToNum("team", iF_team)
		|| !results.FieldNameToNum("state", iF_state)
		|| !results.FieldNameToNum("time", iF_time))
	{
		PrintToServer("[%s] FAILED TO SET COLUMN INDEXES", cInitiator);
		return;
	}

	while (results.FetchRow())
	{
		float fLoc[3];
		fLoc[0] = results.FetchFloat(iF_x);
		fLoc[1] = results.FetchFloat(iF_y);
		fLoc[2] = results.FetchFloat(iF_z);
		int iData[3];
		iData[0] = results.FetchInt(iF_team);
		iData[1] = results.FetchInt(iF_state);
		iData[2] = RoundToNearest(results.FetchFloat(iF_time)); //fetch the float, but convert it to an int.
		g_alData_pos.PushArray(fLoc, sizeof(fLoc));
		int location = g_alData.PushArray(iData, sizeof(iData));
		SaveTimeBlockReference(GetSlotBasedOnTimeInt(iData[2]), location);

	}
	g_iFiredQueries--;
	if(g_iFiredQueries == 0)
	{
		PrintToConsoleiNilo(" g_iFiredQueries == %i", g_iFiredQueries);
		BuildDistanceBasedData();
		ReportDataBlocksToSlack();
	}

}	
public void BuildDistanceBasedData()
{
	PrintToConsoleiNilo("[%s] Starting to build distance based array", PLUGIN_NAME);
	if(!DBHasData())
		return;
	g_aSpreadOutData.Clear();
	for (int pointer1 = 0; pointer1 < g_alData_pos.Length; pointer1++)
	{
		float fLoc1[3];
		g_alData_pos.GetArray(pointer1, fLoc1, sizeof(fLoc1));
		//take this point.
		//loop it through all the existing distance based points.
		bool add_to_distance_based_data = true;
		for (int pointer2 = 0; pointer2 < g_aSpreadOutData.Length; pointer2++)
		{
			int reference_pointer = g_aSpreadOutData.Get(pointer2);//grab the reference pointer off the stack
			float fLoc2[3];
			g_alData_pos.GetArray(reference_pointer, fLoc2, sizeof(fLoc2));
			float distance = GetVectorDistance(fLoc1, fLoc2);
			if(distance <= g_fDistanceSplitter_strict)// //DEFAULT_DISTANCE
				add_to_distance_based_data = false;
		}
		if(add_to_distance_based_data)
		{
			//actually add this point.
			g_aSpreadOutData.Push(pointer1);
		}
	}
	PrintToConsoleiNilo("[%s] we have found g_aSpreadOutData.Length == %i points with minimum distance of %f", PLUGIN_NAME, g_aSpreadOutData.Length, DEFAULT_DISTANCE);
}

public void SaveTimeBlockReference(int TimeBlock, int location)
{
	GetTimeBlockArrayList(TimeBlock).Push(location);
}

public ArrayList GetTimeBlockArrayList(int TimeBlock)
{
	switch(TimeBlock)
	{
		case 0:
		{
			return g_alTimeblock_0;
		}
		case 1:
		{
			return g_alTimeblock_1;
		}
		case 2:
		{
			return g_alTimeblock_2;
		}
		case 3:
		{
			return g_alTimeblock_3;
		}
		case 4:
		{
			return g_alTimeblock_4;
		}
		case 5:
		{
			return g_alTimeblock_5;
		}
		case 6:
		{
			return g_alTimeblock_6;
		}
		case 7:
		{
			return g_alTimeblock_7;
		}
		case 8:
		{
			return g_alTimeblock_8;
		}
		case 9:
		{
			return g_alTimeblock_9;
		}
	}
}
public void ClearArrayData()
{
	if(g_alData == null)
	{
		g_alData = new ArrayList(3)
	}
	else
	{
		g_alData.Clear();
	}
	if(g_alData_pos == null)
	{
		g_alData_pos = new ArrayList(3)
	}
	else
	{
		g_alData_pos.Clear();
	}



	if(g_alTimeblock_0 == null)
	{
		g_alTimeblock_0 = new ArrayList(1);
	}
	else
	{
		g_alTimeblock_0.Clear();
	}
	if(g_alTimeblock_1 == null)
	{
		g_alTimeblock_1 = new ArrayList(1);
	}
	else
	{
		g_alTimeblock_1.Clear();
	}
	if(g_alTimeblock_2 == null)
	{
		g_alTimeblock_2 = new ArrayList(1);
	}
	else
	{
		g_alTimeblock_2.Clear();
	}
	if(g_alTimeblock_3 == null)
	{
		g_alTimeblock_3 = new ArrayList(1);
	}
	else
	{
		g_alTimeblock_3.Clear();
	}
	if(g_alTimeblock_4 == null)
	{
		g_alTimeblock_4 = new ArrayList(1);
	}
	else
	{
		g_alTimeblock_4.Clear();
	}
	if(g_alTimeblock_5 == null)
	{
		g_alTimeblock_5 = new ArrayList(1);
	}
	else
	{
		g_alTimeblock_5.Clear();
	}
	if(g_alTimeblock_6 == null)
	{
		g_alTimeblock_6 = new ArrayList(1);
	}
	else
	{
		g_alTimeblock_6.Clear();
	}
	if(g_alTimeblock_7 == null)
	{
		g_alTimeblock_7 = new ArrayList(1);
	}
	else
	{
		g_alTimeblock_7.Clear();
	}
	if(g_alTimeblock_8 == null)
	{
		g_alTimeblock_8 = new ArrayList(1);
	}
	else
	{
		g_alTimeblock_8.Clear();
	}
	if(g_alTimeblock_9 == null)
	{
		g_alTimeblock_9 = new ArrayList(1);
	}
	else
	{
		g_alTimeblock_9.Clear();
	}
	if(g_aSpreadOutData == null)
	{
		g_aSpreadOutData = new ArrayList(1);
	}
	else
	{
		g_aSpreadOutData.Clear();
	}
}
