#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cstrike>

#include <colorvariables>
#include <generics>
#include <clwo-store>
#include <error-timeout>

#define SPD_ID "sped"
#define SPD_NAME "Adrenal Injector"
#define SPD_DESCRIPTION "Gives the player a surge of adrenaline to get them out of a tricky situation."
#define SPD_PRICE 600
#define SPD_STEP 1.1
#define SPD_LEVEL 4
#define SPD_SORT 0

#define SPD_TIME 3.0
#define SPD_COOLDOWN_TIME 80.0

public Plugin myinfo =
{
    name = "Skill Adrenal Injector (Speed Increase)",
    author = "Popey & c0rp3n",
    description = "A skill that that grants the user a gust of speed.",
    version = "1.0.0",
    url = ""
};

enum struct PlayerData
{
    int level;
    float cooldown;
    int cooldownEnd;
    bool isInCooldown;
    bool isUsingSpeed;
    bool useKeyPressed;
    float useKeyLastPressed;
    Handle revokeTimer;
    Handle cooldownTimer;
}

PlayerData g_playerData[MAXPLAYERS + 1];

public OnPluginStart()
{
    PrintToServer("[SPD] Loaded successfully");
}

public void Store_OnRegister()
{
    Store_RegisterSkill(SPD_ID, SPD_NAME, SPD_DESCRIPTION, SPD_PRICE, SPD_STEP, SPD_LEVEL, SPD_SORT);
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
    if (Store_IsReady())
    {
        g_playerData[client].level = Store_GetSkill(client, SPD_ID);
        g_playerData[client].cooldown = SPD_COOLDOWN_TIME / g_playerData[client].level;
    }
}

public void OnClientDisconnect(int client)
{
    g_playerData[client].level = -1;
    g_playerData[client].cooldown = 0.0;
    g_playerData[client].cooldownEnd = 0.0;
    g_playerData[client].isInCooldown = false;
    g_playerData[client].isUsingSpeed = false;
    g_playerData[client].useKeyPressed = false;
    g_playerData[client].useKeyLastPressed = 0.0;
    CallTimer(g_playerData[client].revokeTimer);
    CallTimer(g_playerData[client].cooldownTimer);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float velocity[3], float angles[3], int &weapon)
{
    if (g_playerData.level <= 0) return Plugin_Continue;

    if (!(buttons & IN_USE))
    {
        g_playerData.useKeyPressed[client] = false;

        return Plugin_Continue;
    }

    if (g_playerData.useKeyPressed[client]) return Plugin_Continue;

    g_playerData.useKeyPressed[client] = true;

    float currentGameTime = GetGameTime();
    if (currentGameTime > g_playerData[client].useKeyLastPressed + 0.2)
    {
        g_playerData[client].useKeyLastPressed = currentGameTime;

        return Plugin_Continue;
    }

    if (g_playerData.isInCooldown)
    {
        if (ErrorTimeout(client))
        {
            CPrintToChat(client, "{default}[TTT] > You are currently in cooldown for {orange}%d {default}more seconds.", g_playerData[client].cooldownEnd - GetTime());
        }
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

    g_playerData[client].isUsingSpeed = true;
    CreateTimer(g_playerData[client].cooldown, Timer_SpeedRevoke, userid);

    return Plugin_Continue;
}

public void Store_OnSkillPurchased(int client, char[] id, int level)
{
    if (StrEqual(id, SPD_ID, true))
    {
        g_playerData[client].level = level;
        g_playerData[client].cooldown = SPD_COOLDOWN_TIME / level;
    }
}

public Action Timer_SpeedCooldown(Handle timer, int userid)
{
    int client = GetClientFromUserId(userid);
    g_playerData[client].cooldownTimer = INVALID_HANDLE;
    g_playerData[client].isInCooldown = false;

    return Plugin_Stop;
}

public Action Timer_SpeedIncrease(Handle timer, DataPack pack)
{
    int client = GetClientFromUserId(pack.ReadCell());
    if (IsAliveClient(client))
    {
        float speed = pack.ReadFloat();
        SetClientSpeed(client, speed);
        SetEntityGravity(client, 1.0 / speed);
    }

    delete pack;

    return Plugin_Stop;
}

public Action Timer_SpeedRevoke(Handle timer, int userid)
{
    int client = GetClientFromUserId(userid);
    g_playerData[client].revokeTimer = INVALID_HANDLE;
    g_playerData[client].isUsingSpeed = false;

    return Plugin_Stop;
}