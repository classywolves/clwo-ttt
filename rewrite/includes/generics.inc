#if defined _generics_included
	#endinput
#endif
#define _generics_included

/*
 * Includes for generics.
 */
#include <player_methodmap>

/*
 * Definitions.
 */

/**
 * This function will check if we have a valid player (alive)
 **/
stock bool IsAliveClient(int client) // ingame and not bot and alive
{
  if(!IsValidClient(client))
    return false;

  if(!IsPlayerAlive(client))
    return false;

  if(GetClientTeam(client) == CS_TEAM_SPECTATOR)
    return false;

  if(GetClientTeam(client) == CS_TEAM_NONE)
    return false;

  return true;
}

/**
 * This function will check if we have a valid player
 **/

stock bool IsValidClient(int client, bool allowconsole=false)
{
    if(client == 0 && allowconsole)
    {
      return true;
    }
    if(client <= 0)
    {
      return false;
    }
    if(client > MaxClients)
    {
      return false;
    }
    if (!IsClientConnected(client))
    {
      return false;
    }
    if(!IsClientInGame(client))
    {
      return false;
    }
    if(IsFakeClient(client))
    {
      return false;
    }
    return true;
}

#if !defined LoopValidClients
	#define LoopValidClients(%1) 	for(int %1 = 1; %1 <= MaxClients; %1++) if(Player(%1).ValidClient)
#endif

#define LoopAliveClients(%1) 		for(int %1 = 1; %1 <= MaxClients; %1++) if(Player(%1).ValidClient && Player(%1).Alive)
#define LoopDeadClients(%1) 		for(int %1 = 1; %1 <= MaxClients; %1++) if(Player(%1).ValidClient && !Player(%1).Alive)
#define LoopStaff(%1) 				for(int %1 = 1; %1 <= MaxClients; %1++) if(Player(%1).ValidClient && Player(%1).Staff)
#define LoopClients(%1) 			for(int %1 = 1; %1 <= MaxClients; %1++)

/*
 * Stock functions.
 */
stock int GetStaffArray(int staff[32] = {}) {
	int staffCount = 0;

	LoopValidClients(i) {
		if (Player(i).Staff) {
			staff[staffCount] = i;
			staffCount++;
		}
	}

	return staffCount;
}

stock int GetStaffCount() {
	int staffCount = 0;

	LoopStaff(i) {
		staffCount++;
	}

	return staffCount;
}

stock int GetActiveStaffCount() {
	int staffCount = 0;

	LoopStaff(client) {
		Player player = Player(client);
		if (player.CounterTerrorist || player.Terrorist) {
			staffCount++;
		}
	}

	return staffCount;
}

stock int GetUnfoundPlayers(char playerNames[MAXPLAYERS][64]) {
	int visible = 0;

	LoopClients(i) {
		Player player = Player(i)
		if (player.Found) {
			player.Name(playerNames[visible])
			// Some stuff to array/
			visible++;
		}
	}

	return visible;
}

stock void CallTimer(&Handle:timer)
{
	if (timer != INVALID_HANDLE)
	{
		TriggerTimer(timer);
		ClearTimer(timer);
	}
}

stock void ClearTimer(&Handle:timer)
{
	if (timer != INVALID_HANDLE)
	{
		KillTimer(timer);
		timer = INVALID_HANDLE;
	}
}

stock Database ConnectDatabase(char[] database, char[] name) {
	char error[255];
	Database dbDatabase = SQL_Connect(database, true, error, sizeof(error));
	if (dbDatabase == null) { PrintToServer("[%s] Could not connect to db: %s", name, error); }
	else { PrintToServer("[%s] Connected to DB", name); }
	return dbDatabase;
}

stock DBStatement PrepareStatement(Database database, char[] statement) {
	char error[255];
	DBStatement newStatement = SQL_PrepareQuery(database, statement, error, sizeof(error));
	if (newStatement == null) { PrintToServer(error); return newStatement; }
	return newStatement;
}

stock int GenericOnSQLConnectCallback(Handle owner, Handle hndl, char [] error, any data)
{
	if(hndl == INVALID_HANDLE)
	{
		LogError("Query failure: %s", error);
		return;
	}
}
