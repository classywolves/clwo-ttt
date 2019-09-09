#if defined _generics_included
#endinput
#endif
#define _generics_included

/**
* This function will check if we have a valid player (alive)
**/
stock bool IsAliveClient(int client) // ingame and not bot and alive
{
    if(!IsValidClient(client))
    {
        return false;
    }

    if(!IsPlayerAlive(client))
    {
        return false;
    }

    if(GetClientTeam(client) == CS_TEAM_SPECTATOR)
    {
        return false;
    }

    if(GetClientTeam(client) == CS_TEAM_NONE)
    {
        return false;
    }

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
    #define LoopValidClients(%1) 	for(int %1 = 1; %1 <= MaxClients; %1++) if(IsValidClient(%1))
#endif

#define LoopAliveClients(%1) 		for(int %1 = 1; %1 <= MaxClients; %1++) if(IsAliveClient(%1))
#define LoopDeadClients(%1) 		for(int %1 = 1; %1 <= MaxClients; %1++) if(IsValidClient(%1) && !IsPlayerAlive(%1))
#define LoopClients(%1) 			for(int %1 = 1; %1 <= MaxClients; %1++)

/*
* Stock functions.
*/
/*
stock int GetUnfoundPlayers(char playerNames[MAXPLAYERS][64])
{
    int visible = 0;
    LoopClients(i)
    {
        Player player = Player(i);
        if (player.Found)
        {
            player.Name(playerNames[visible]);
            // Some stuff to array/
            visible++;
        }
    }

    return visible;
}
*/

stock void CallTimer(Handle& timer)
{
    if (timer != INVALID_HANDLE)
    {
        TriggerTimer(timer);
        ClearTimer(timer);
    }
}

stock void ClearTimer(Handle& timer)
{
    if (timer != INVALID_HANDLE)
    {
        KillTimer(timer);
        timer = INVALID_HANDLE;
    }
}

stock Database ConnectDatabase(char[] database, char[] name)
{
    char error[255];
    Database dbDatabase = SQL_Connect(database, true, error, sizeof(error));
    if (dbDatabase == null) { PrintToServer("[%s] Could not connect to db: %s", name, error); }
    else { PrintToServer("[%s] Connected to DB", name); }
    return dbDatabase;
}

stock DBStatement PrepareStatement(Database database, char[] statement)
{
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
        return 1;
    }

    return 0;
}

stock int GetClientCookieInt(int client, Handle cookie, int defaultValue)
{
    char cookieValue[64];
    GetClientCookie(that, cookie, cookieValue, sizeof(cookieValue));
    if (cookieValue[0] == '\0') return defaultValue;
    return StringToInt(cookieValue);
}

stock void SetClientCookieInt(int client, Handle cookie, int value)
{
    char cookieValue[64];
    IntToString(value, cookieValue, sizeof(cookieValue));
    SetClientCookie(that, cookie, cookieValue);
}

stock void IntToChar4(int value, char[] array,  int index = 0)
{
    array[index] = (value >> 24) & 0xFF;
    array[index + 1] = (value >> 16) & 0xFF;
    array[index + 2] = (value >> 8) & 0xFF;
    array[index + 3] = value & 0xFF;
}

stock int Char4ToInt(const char[] array, int index = 0)
{
    int value = 0;
    value += array[index] << 24;
    value += array[index + 1] << 16;
    value += array[index + 2] << 8;
    value += array[index + 3];

    return value;
}
