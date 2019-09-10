#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#include <colorvariables>
#include <generics>
#include <ttt_messages>

public Plugin myinfo = {
    name = "TTT AFK",
    author = "c0rp3n",
    description = "TTT Away from Keyboard manager.",
    version = "1.0.0",
    url = ""
};

Handle afkTimers[MAXPLAYERS + 1] =  { INVALID_HANDLE, ... };
int playerWarningCount[MAXPLAYERS + 1] = { 0, ... };
float playerLocations[MAXPLAYERS + 1][3];

public OnPluginStart()
{
    HookEvents();

    PrintToServer("[AFK] Loaded successfully");
}

public void HookEvents()
{
    HookEvent("player_spawn", Event_OnPlayerSpawnPost, EventHookMode_Post);
}

public void Event_OnPlayerSpawnPost(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    GetClientAbsOrigin(client, playerLocations[client]);
    afkTimers[client] = CreateTimer(5.0, Timer_AntiAfk, GetClientUserId(client), TIMER_REPEAT);
}

public Action Timer_AntiAfk(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    if (IsValidClient(client))
    {
        float newLocation[3];
        GetClientAbsOrigin(client, newLocation);

        if
        (
            playerLocations[client][0] - newLocation[0] < 5.0 &&
            playerLocations[client][1] - newLocation[1] < 5.0 &&
            playerLocations[client][2] - newLocation[2] < 5.0
        )
        {
            playerWarningCount[client]++;
            if (playerWarningCount[client] == 5)
            {
                CPrintToChat(client, TTT_MESSAGE ... "You have been afk for {orange}30 {default}seconds if you do not start moving in {orange}30 {default}seconds you shall be slain.");
            }
            else if (playerWarningCount[client] == 11)
            {
                CPrintToChat(client, TTT_MESSAGE ... "You have been slain for being afk for over {orange}1 {default}minute.");
                ForcePlayerSuicide(client);

                ClearTimer(timer);
                return Plugin_Stop;
            }
        }
        else
        {
            if (playerWarningCount[client])
            {
                playerWarningCount[client]--;
            }
        }

        playerLocations[client][0] = newLocation[0];
        playerLocations[client][1] = newLocation[1];
        playerLocations[client][2] = newLocation[2];

        return Plugin_Continue;
    }
    else
    {
        ClearTimer(timer);
        return Plugin_Stop;
    }
}
