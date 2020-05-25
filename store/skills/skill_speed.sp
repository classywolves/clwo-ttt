#pragma semicolon 1

#include <sourcemod>
#include <colorlib>

#include <generics>
#include <clwo_store>
#include <error_timeout>

#define SPD_ID "sped"
#define SPD_NAME "Adrenal Injector"
#define SPD_DESCRIPTION "Gives the player a surge of adrenaline to get them out of a tricky situation."
#define SPD_PRICE 1000
#define SPD_STEP 1.1
#define SPD_LEVEL 4
#define SPD_SORT 0

#define SPD_TIME 3.0
#define SPD_COOLDOWN_TIME 80

public Plugin myinfo =
{
    name = "CLWO Store - Skill: Adrenal Injector (Speed Increase)",
    author = "Popey & c0rp3n",
    description = "A skill that that grants the user a gust of speed.",
    version = "1.0.0",
    url = ""
};

enum struct PlayerData
{
    int level;
    int cooldown;
    int cooldownEnd;
    bool isUsingSpeed;
    bool useKeyPressed;
    float useKeyLastPressed;
    Handle revokeTimer;
}

PlayerData g_playerData[MAXPLAYERS + 1];

public void OnPluginStart()
{
    PrintToServer("[SPD] Loaded successfully");
}

public void Store_OnRegister()
{
    Store_RegisterSkill(SPD_ID, SPD_NAME, SPD_DESCRIPTION, SPD_PRICE, SPD_STEP, SPD_LEVEL, Store_OnSkillUpdate, SPD_SORT);
}

public void Store_OnReady()
{
    LoopValidClients(i)
    {
        g_playerData[i].level = Store_GetSkill(i, SPD_ID);
        g_playerData[i].cooldown = SPD_COOLDOWN_TIME / g_playerData[i].level;
    }
}

public void OnClientPutInServer(int client)
{
    ClearClientData(client);
    g_playerData[client].revokeTimer = INVALID_HANDLE;
}

public void OnClientDisconnect(int client)
{
    ClearClientData(client);
    CallTimer(g_playerData[client].revokeTimer);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float velocity[3], float angles[3], int &weapon)
{
    if (g_playerData[client].level <= 0 || g_playerData[client].isUsingSpeed) return Plugin_Continue;

    if (!(buttons & IN_USE))
    {
        g_playerData[client].useKeyPressed = false;

        return Plugin_Continue;
    }

    if (g_playerData[client].useKeyPressed) return Plugin_Continue;

    g_playerData[client].useKeyPressed = true;

    float currentGameTime = GetGameTime();
    if (currentGameTime > g_playerData[client].useKeyLastPressed + 0.2)
    {
        g_playerData[client].useKeyLastPressed = currentGameTime;

        return Plugin_Continue;
    }

    int currentTime = GetTime();
    if (currentTime < g_playerData[client].cooldownEnd)
    {
        if (ErrorTimeout(client))
        {
            CPrintToChat(client, "{default}[TTT] > You are currently in cooldown for {orange}%d {default}more seconds.", g_playerData[client].cooldownEnd - GetTime());
        }

        return Plugin_Continue;
    }

    g_playerData[client].cooldownEnd = GetTime() + g_playerData[client].cooldown;

    CPrintToChat(client, "{default}[TTT] > Adrenal Injector activated.");

    int userid = GetClientUserId(client);
    for (float i = 0.0; i < 0.5; i += 0.01)
    {
        DataPack pack;
        pack.WriteCell(userid);
        pack.WriteFloat(i);
        pack.Reset();

        CreateDataTimer(i, Timer_SpeedIncrease, pack);
    }

    g_playerData[client].isUsingSpeed = true;
    CreateTimer(SPD_TIME, Timer_SpeedRevoke, userid);
    CreateTimer(float(g_playerData[client].cooldown), Timer_SpeedRevoke, userid);

    return Plugin_Continue;
}

public void Store_OnSkillUpdate(int client, int level)
{
    g_playerData[client].level = level;
}

public Action Timer_SpeedIncrease(Handle timer, DataPack pack)
{
    int client = GetClientOfUserId(pack.ReadCell());
    if (client && IsPlayerAlive(client))
    {
        float speed = 1.0 + pack.ReadFloat();
        SetClientSpeed(client, speed);
        SetEntityGravity(client, 1.0 / speed);
    }

    delete pack;

    return Plugin_Stop;
}

public Action Timer_SpeedRevoke(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    if (client)
    {
        g_playerData[client].revokeTimer = INVALID_HANDLE;
        g_playerData[client].isUsingSpeed = false;
        SetClientSpeed(client, 1.0);
        SetEntityGravity(client, 1.0);
    }

    return Plugin_Stop;
}

void ClearClientData(int client)
{
    g_playerData[client].level = -1;
    g_playerData[client].cooldown = 0;
    g_playerData[client].cooldownEnd = 0;
    g_playerData[client].isUsingSpeed = false;
    g_playerData[client].useKeyPressed = false;
    g_playerData[client].useKeyLastPressed = 0.0;
}

void SetClientSpeed(int client, float speed)
{
    SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", speed);
}
