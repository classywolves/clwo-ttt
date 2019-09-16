#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#include <colorvariables>
#include <ttt>
#include <generics>
#include <ttt_messages>
#include <clwo-store>
#include <progress-bars>

#define INVS_ID "invs"
#define INVS_NAME "Reactive Camoflage"
#define INVS_DESCRIPTION "Grants the user invisibility for short periods of time when hit with a electric charge."
#define INVS_PRICE 400
#define INVS_STEP 1.5
#define INVS_LEVEL 3
#define INVS_SORT 0
#define INVS_LENGTH 2.5

public Plugin myinfo =
{
    name = "CLWO Skill Reactive Camoflage",
    author = "c0rp3n",
    description = "Skill that grants invisibility upon being tasered.",
    version = "0.1.0",
    url = ""
};

enum struct PlayerData
{
    int level;
    bool invisible;
    float length;
}

PlayerData g_playerData[MAXPLAYERS + 1];

public OnPluginStart()
{
    PrintToServer("[RCM] Loaded succcessfully");
}

public void Store_OnRegister()
{
    Store_RegisterSkill(INVS_ID, INVS_NAME, INVS_DESCRIPTION, INVS_PRICE, INVS_STEP, INVS_LEVEL, INVS_SORT);
}

public void Store_OnReady()
{
    LoopValidClients(i)
    {
        OnClientPutInServer(i);
    }
}

public void OnClientPutInServer(int client)
{
    if (Store_IsReady())
    {
        g_playerData[client].level = Store_GetSkill(client, INVS_ID);
        if (g_playerData[client].level > 0)
        {
            g_playerData[client].length = INVS_LENGTH * g_playerData[client].level;
        }
    }
}

public void OnClientDisconnect(int client)
{
    g_playerData[client].level = -1;
    g_playerData[client].invisible = false;
    g_playerData[client].length = 0.0;
}

public void Store_OnSkillPurchased(int client, char[] id, int level)
{
    if (StrEqual(id, INVS_ID, true))
    {
        g_playerData[client].level = level;
        if (g_playerData[client].level > 0)
        {
            g_playerData[client].length = INVS_LENGTH * g_playerData[client].level;
        }
    }
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
    if (g_playerData[client].invisible)
    {
        buttons = buttons & (IN_ATTACK | IN_ATTACK2);
    }
}

public Action TTT_OnTased(int attacker, int victim)
{
    if (g_playerData[victim].level > 0)
    {
        if (TTT_GetClientRole(victim) == TTT_TEAM_TRAITOR)
        {
            SetEntityRenderMode(victim, RENDER_NONE);
            CPrintToChat(victim, TTT_MESSAGE ... "Reactive camoflage {green}activated!");
            ProgressBar_Create(victim, "Charge", g_playerData[victim].length, ProgressBar_Decrement);

            CreateTimer(g_playerData[victim].length, Timer_RemoveInvisibility, GetClientUserId(victim));
        }
    }
}

public Action Timer_RemoveInvisibility(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    if (IsValidClient(client))
    {
        SetEntityRenderMode(client, RENDER_NORMAL);
        CPrintToChat(client, TTT_MESSAGE ... "Reactive camoflage {red}deactivated!");
    }

    return Plugin_Stop;
}
