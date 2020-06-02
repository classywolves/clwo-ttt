#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <colorlib>

#undef REQUIRE_PLUGIN
#include <ttt>
#include <ttt_taser>
#define REQUIRE_PLUGIN
#include <generics>
#include <progress_bars>
#include <ttt_messages>
#undef REQUIRE_PLUGIN
#include <clwo_store>
#define REQUIRE_PLUGIN

#define INVS_ID "invs"
#define INVS_NAME "Reactive Camoflage"
#define INVS_DESCRIPTION "Grants the user invisibility for short periods of time when hit with a electric charge."
#define INVS_PRICE 600
#define INVS_STEP 1.5
#define INVS_LEVEL 3
#define INVS_SORT 0
#define INVS_LENGTH 2.5

public Plugin myinfo =
{
    name = "CLWO Store - Skill: Reactive Camoflage",
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

public void OnPluginStart()
{
    if (Store_IsReady())
    {
        Store_OnRegister();
    }

    PrintToServer("[RCM] Loaded succcessfully");
}

public void Store_OnRegister()
{
    Store_RegisterSkill(INVS_ID, INVS_NAME, INVS_DESCRIPTION, INVS_PRICE, INVS_STEP, INVS_LEVEL, Store_OnSkillUpdate, INVS_SORT);
}

public void OnClientPutInServer(int client)
{
    ClearClientData(client);
}

public void OnClientDisconnect(int client)
{
    ClearClientData(client);
}

/*
public void Store_OnClientSkillsLoaded(int client)
{
    Store_OnSkillUpdate(client, Store_GetSkill(client, INVS_ID));
}
*/

public void Store_OnSkillUpdate(int client, int level)
{
    g_playerData[client].level = level;
    if (g_playerData[client].level > 0)
    {
        g_playerData[client].length = INVS_LENGTH * g_playerData[client].level;
    }
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
    if (g_playerData[client].invisible)
    {
        buttons = buttons & ~(IN_ATTACK | IN_ATTACK2);
    }
}

public void TTT_OnTased_Post(int attacker, int victim)
{
    if (g_playerData[victim].level > 0)
    {
        if (TTT_GetClientRole(victim) == TTT_TEAM_TRAITOR)
        {
            g_playerData[victim].invisible = true;
            SetEntityRenderMode(victim, RENDER_NONE);
            CPrintToChat(victim, TTT_MESSAGE ... "Reactive camoflage {green}activated!");
            ProgressBar_Create(victim, "Charge", g_playerData[victim].length, ProgressBar_Decrement);

            CreateTimer(g_playerData[victim].length, Timer_RemoveInvisibility, GetClientUserId(victim), TIMER_FLAG_NO_MAPCHANGE);
        }
    }
}

public Action Timer_RemoveInvisibility(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    if (client > 0)
    {
        g_playerData[client].invisible = false;
        SetEntityRenderMode(client, RENDER_NORMAL);
        if (IsPlayerAlive(client))
        {
            CPrintToChat(client, TTT_MESSAGE ... "Reactive camoflage {red}deactivated!");
        }
    }

    return Plugin_Stop;
}

void ClearClientData(int client)
{
    g_playerData[client].level = -1;
    g_playerData[client].invisible = false;
    g_playerData[client].length = 0.0;
}
