#include <smlib>
#include <main>
#include <inilo>
#define PLUGIN_VERSION 			"0.0.253"
#define BOUNDINGBOX_INFLATION_OFFSET 3

/* Plugin Info */
#define PLUGIN_NAME 			"iNilo Datacollector v2"
#define PLUGIN_VERSION_M 			"1.0.0"
#define PLUGIN_AUTHOR 			"iNilo.net"
#define PLUGIN_DESCRIPTION		"Collect data"
#define PLUGIN_URL				"http://inilo.net"

#pragma newdecls required

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION_M,
	url = PLUGIN_URL
};

Database g_dDB;

float g_fLastLocation[MAXPLAYERS+1][3]; //store anti camping beacons.
int g_iFoundCamping[MAXPLAYERS+1]; //store anti camping beacons.
bool g_bStartcollecting = false;
float g_fRoundStartTime;

ConVar mp_ignore_round_win_conditions;
ConVar mp_friendlyfire;
ConVar mp_teammates_are_enemies;
ConVar sv_autobunnyhopping;
ConVar mp_tagging_scale;
ConVar sv_maxspeed;

ConVar sv_friction;
ConVar sv_accelerate;


#define DC2_STATE_REBEL									(1 << 1)	
#define DC2_STATE_WARDEN								(1 << 2)
#define DC2_STATE_FD									(1 << 3)


#define DEV_ACCOUNT 48251305


public void OnPluginStart()
{
	hello();
	StartupDB();

	RegisterCvars();
	RegisterCmds();
	HookEvents();

 	PrintToChatAll(" \x03[\x01%s\x03] \x01>\x04Online\x01<", PLUGIN_NAME);
}

public void RegisterCvars()
{
	mp_ignore_round_win_conditions = FindConVar("mp_ignore_round_win_conditions");
	mp_friendlyfire = FindConVar("mp_friendlyfire");
	mp_teammates_are_enemies = FindConVar("mp_teammates_are_enemies");
	sv_autobunnyhopping = FindConVar("sv_autobunnyhopping");
	mp_tagging_scale = FindConVar("mp_tagging_scale");
	sv_maxspeed = FindConVar("sv_maxspeed");
	sv_friction = FindConVar("sv_friction");
	sv_accelerate = FindConVar("sv_accelerate");
}
public void RegisterCmds()
{
	RegConsoleCmd("dc2", Command_Dc2, "dc2 command");
	RegAdminCmd("dc2_fire", Command_Dc2Fire, ADMFLAG_GENERIC, "dc2 command");
	RegAdminCmd("dc2_time", Command_Time, ADMFLAG_GENERIC, "dc2 command");
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
	CreateDatabaseTable();
}


public void OnPluginEnd()
{

	PrintToChatAll(" \x03[\x01%s\x03] \x01>\x02Offline\x01<",PLUGIN_NAME);
}
public void OnMapStart()
{
	CreateDatabaseTable();
	CreateTimer(1.0, Timer_CheckForPlayersStandingStill, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	//PrintToChatiNilo("OnRoundStart");
	//g_bStartcollecting = true;
	return Plugin_Continue;
}

public Action OnRoundFreezeEnd(Event event, const char[] name, bool dontBroadcast)
{
	//PrintToChatiNilo("OnRoundFreezeEnd");
	g_fRoundStartTime = GetEngineTime();
	g_bStartcollecting = true;
	return Plugin_Continue;
}

public Action OnRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	g_bStartcollecting = false;
	return Plugin_Continue;
}



public Action Command_Dc2(int client, int args)
{
	if(g_dDB == null)
	{
		ReplyToCommand(client, "[%s] Database interface offline ", PLUGIN_NAME);
	}
	else
	{
		ReplyToCommand(client, "[%s] Database interface online ", PLUGIN_NAME);
	}

	ReplyToCommand(client, "[%s] GetTimePassed() == %f ", PLUGIN_NAME, GetTimePassed());
	ReplyToCommand(client, "[%s] AllowDataCollecting() == %b ", PLUGIN_NAME, AllowDataCollecting());
	ReplyToCommand(client, "[%s] g_bStartcollecting == %b ", PLUGIN_NAME, g_bStartcollecting);
	
	char cMapName[512];
	GetDBMapName(cMapName, sizeof(cMapName));
	ReplyToCommand(client, "[%s] GetDBMapName() == %s ", PLUGIN_NAME, cMapName);
	
	return Plugin_Handled
}
public Action Command_Dc2Fire(int client, int args)
{
	if(g_dDB == null)
	{
		ReplyToCommand(client, " db is null");
	}
	else
	{
		CreateDatabaseTable();
	}
	return Plugin_Handled
}
public Action Command_Time(int client, int args)
{
	ReplyToCommand(client, " GetTimePassed == %f", GetTimePassed());
	return Plugin_Handled
}

public int GetDBMapName(char[] cOutput, int maxlen)
{
	char cMapName[512];
	int len = GetCurrentMap(cMapName, sizeof(cMapName));
	return Crypt_Base64Encode(cMapName, cOutput, maxlen, len);
}

public void CreateDatabaseTable()
{
	//xr - yr - zr - x - y - z - team - rebel - time
	char cMapName[512];
	GetDBMapName(cMapName, sizeof(cMapName));
	
	char cTableSSQL[512]
	Format(cTableSSQL, sizeof(cTableSSQL), "CREATE TABLE IF NOT EXISTS `%s` ( `xr` int(11) NOT NULL,  `yr` int(11) NOT NULL,  `zr` int(11) NOT NULL,  `x` float NOT NULL,  `y` float NOT NULL,  `z` float NOT NULL,  `team` tinyint(4) NOT NULL,  `state` int(11) NOT NULL,  `time` float NOT NULL, PRIMARY KEY(xr,yr,zr), INDEX(`team`), INDEX(`x`), INDEX(`y`), INDEX(`z`), INDEX(`state`));", cMapName);
	//PrintToConsoleiNilo("Setting up DB %s as %s with query \n%s", cMapName, cMapName, cTableSSQL);
	if(g_dDB != null)
		g_dDB.Query(GenericDB_Callback, cTableSSQL);
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

public bool AllowDataCollecting()
{
	if(!g_bStartcollecting)
		return false;
	if(iNilo_IsSpecialDay())
		return false;
	if(!iNilo_IsGameTime())
		return false;
	if(!IsItValidGameTime_UnsafeCheck())
		return false;
	if(mp_ignore_round_win_conditions.BoolValue) //me fucking around
		return false;
	if(mp_friendlyfire.BoolValue) //ff events
		return false;
	if(mp_teammates_are_enemies.BoolValue) //ff events
		return false;
	if(sv_autobunnyhopping.BoolValue) //prevent extreme bhop
		return false;
	if(sv_maxspeed.IntValue > 350) //prevent bhop 
		return false;
	if(sv_accelerate.FloatValue != 5.5) //prevent bhop 
		return false;
	if(mp_tagging_scale.FloatValue != 1.0) //prevent bhop 
		return false;
	if(sv_friction.FloatValue != 5.2) //prevent bhop 
		return false;
	return true;
}

public Action Timer_CheckForPlayersStandingStill(Handle timer, any data)
{
	if(!AllowDataCollecting())
		return Plugin_Continue;
	float fTempLoc[3];

	//PrintToConsoleiNilo("[%s] Starting checks.", PLUGIN_NAME);


	for (int client = 1; client <= MaxClients; client++)
	{
		if(!IsValidPlayer(client))
		{
			g_iFoundCamping[client] = 0;
			continue;
		}
		if(IsPlayerMoving(client))
		{
			g_iFoundCamping[client] = 0;
			continue;
		}
		if(!IsPlayerValidDataPoint(client))
		{
			g_iFoundCamping[client] = 0;
			continue;
		}
		GetClientAbsOrigin(client, fTempLoc);
		if(!IsValidPlayerLocation(client, fTempLoc))
		{
			g_iFoundCamping[client] = 0;
			continue;
		}

		float fLastLocation[3];
		fLastLocation = g_fLastLocation[client];
		GetClientAbsOrigin(client, g_fLastLocation[client]);

		float distance = GetVectorDistance(fLastLocation, g_fLastLocation[client]);
		if(distance == 0.0)
		{
			//Player is not moving.
			g_iFoundCamping[client]++;
		}
		else
		{
			g_iFoundCamping[client]--;
		}
		if(g_iFoundCamping[client] > 3)
		{
			float a_fOrigin[3];
			GetClientAbsOrigin(client, a_fOrigin);
			
			//player is standing still.
			//save data here.
			PrintToConsole(client, " vSend ");
			SavePointToDB(client, a_fOrigin, GetTimePassed());

			//PrintToChat(client, " I LOVE YOU");
			g_iFoundCamping[client]--;
		}
		if(g_iFoundCamping[client] <= 0)
		{
			g_iFoundCamping[client] = 0;
		}
	}
	return Plugin_Continue;

}

public float GetTimePassed()
{
	return GetEngineTime() - g_fRoundStartTime;
}

public bool IsPlayerMoving(int client)
{
	float velocity[3];
	Entity_GetLocalVelocity(client, velocity);
	if(velocity[0] != 0.0 || velocity[1] != 0.0 && velocity[2] != 0.0)
		return true;
	return false;
}

public bool IsPlayerValidDataPoint(int client)
{
	if(GetEntityMoveType(client) != MOVETYPE_WALK)
		return false; //check for walk.
	
	if(GetEntityGravity(client) != 1.0)
		return false; //gravity

	if(GetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue") != 1.0)
		return false; //flagged movement

	if(iNilo_GotTaggedByIED(client))
		return false; //ied.

	float fFeet[3];
	float fEyes[3];
	GetClientAbsOrigin(client, fFeet);
	GetClientEyePosition(client, fEyes);
	float height = GetVectorDistance(fFeet, fEyes);
	if(height != 64.0) // feet <-> eyes == 64.000000
		return false; //crouching person

	//others?
	if(GetSteamAccountID(client, true) == DEV_ACCOUNT)
		return false;

	return true;
}


public bool IsValidPlayerLocation(int client, float fLocation[3])
{
	if(TR_PointOutsideWorld(fLocation))
		return false;

	float mins[3];
	float maxs[3];

	GetClientMins(client, mins);
	GetClientMaxs(client, maxs);

	TR_TraceHullFilter(fLocation, fLocation, mins, maxs, MASK_SOLID, TraceEntityFilterPlayer2, client);
	return !TR_DidHit();
}

// filter out players, since we can't get stuck on them
public bool TraceEntityFilterPlayer2(int entity, int contentsMask)
{
	return entity <= 0 || entity > MaxClients; //if entity is not a client -> true.
}  

public void SavePointToDB(int client, const float fLocation[3], float fGameTime)
{
	//INSERT INTO `jailbreak_dc2`.`amJfc2dfZG9qb1` (`xr`, `yr`, `zr`, `x`, `y`, `z`, `team`, `state`, `time`) VALUES ('%i', '%i', '%i', '%f', '%f', '%f', '%i', '%i', '%i');
	int xr = RoundToNearest(fLocation[0]);
	int yr = RoundToNearest(fLocation[1]);
	int zr = RoundToNearest(fLocation[2]);

	float x = fLocation[0];
	float y = fLocation[1];
	float z = fLocation[2];

	int team = GetClientTeam(client);

	int state = 0;
	if(iNilo_IsClientRebel(client))
	{
		state |= DC2_STATE_REBEL
	}
	if(iNilo_IsClientWarden(client))
	{
		state |= DC2_STATE_WARDEN
	}
	if(iNilo_IsClientFD(client))
	{
		state |= DC2_STATE_FD
	}

	char cMapName[512];
	GetDBMapName(cMapName, sizeof(cMapName));


	char cInsertSQL[512];
	Format(cInsertSQL, sizeof(cInsertSQL), "INSERT IGNORE INTO `jailbreak_dc2`.`%s` (`xr`, `yr`, `zr`, `x`, `y`, `z`, `team`, `state`, `time`) VALUES ('%i', '%i', '%i', '%f', '%f', '%f', '%i', '%i', '%f');", cMapName, xr, yr, zr, x, y, z, team, state, fGameTime);

	//PrintToConsole(client, cInsertSQL);
	if(g_dDB != null)
		g_dDB.Query(GenericDB_Callback, cInsertSQL);
}