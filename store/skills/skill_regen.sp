#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <colorlib>

#include <generics>
#undef REQUIRE_PLUGIN
#include <clwo_store>
#define REQUIRE_PLUGIN

#define RGN_ID "hrgn"
#define RGN_NAME "Larraman's Organ"
#define RGN_DESCRIPTION "Pumps healing cells towards any sustained injuries. These clot blood and form scar tissu allowing you too fight on."
#define RGN_PRICE 600
#define RGN_STEP 1.4
#define RGN_LEVEL 2
#define RGN_SORT 0

public Plugin myinfo =
{
    name = "Skill: Larraman's Organ (Health Regen)",
    author = "Popey & c0rp3n",
    description = "A skill that allows for the player to regenrate some health.",
    version = "1.0.0",
    url = ""
};

enum struct PlayerData
{
    int level;
    int pendingAmount;
    int regenAmount;
    float regenFactor;
    Handle pendingTimer;
    Handle regenTimer;
}

PlayerData g_playerData[MAXPLAYERS + 1];

public OnPluginStart()
{
    HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);

    PrintToServer("[RGN] Loaded successfully");
}

public void OnClientPutInServer(int client)
{
    ClearClientData(client);
}

public void OnClientDisconnect(int client)
{
    ClearClientData(client);
}

public void Store_OnRegister()
{
    Store_RegisterSkill(RGN_ID, RGN_NAME, RGN_DESCRIPTION, RGN_PRICE, RGN_STEP, RGN_LEVEL, Store_OnSkillUpdate, RGN_SORT);
}

/*
public void Store_OnClientSkillsLoaded(int client)
{
    Store_OnSkillUpdate(client, Store_GetSkill(client, RGN_ID));
}
*/

public void Store_OnSkillUpdate(int client, int level)
{
    g_playerData[client].level = level;
    g_playerData[client].regenAmount = 0;
    if (g_playerData[client].level > 0)
    {
        g_playerData[client].regenFactor = 0.4 * g_playerData[client].level;
        SDKHook(client, SDKHook_OnTakeDamageAlivePost, Hook_OnTakeDamageAlive);
    }
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    LoopClients(i)
    {
        g_playerData[i].pendingAmount = 0;
        g_playerData[i].regenAmount = 0;
        ClearTimer(g_playerData[i].pendingTimer);
        ClearTimer(g_playerData[i].regenTimer);
    }
}

public void Hook_OnTakeDamageAlive(int victim, int attacker, int inflictor, float damage, int damagetype)
{
    int amount = RoundToFloor(damage * g_playerData[victim].regenFactor);
    g_playerData[victim].pendingAmount += amount;
    if (g_playerData[victim].pendingTimer == INVALID_HANDLE)
    {
        g_playerData[victim].pendingTimer = CreateTimer(5.0, Timer_HealthPending, GetClientUserId(victim), TIMER_FLAG_NO_MAPCHANGE);
    }
}

public Action Timer_HealthPending(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    if (client && IsPlayerAlive(client))
    {
        int amount = g_playerData[client].pendingAmount;
        g_playerData[client].regenAmount += amount;
        g_playerData[client].pendingAmount = 0;

        CPrintToChat(client, "[RGN] Larraman's Organ activated, dispensing cells.");

        if (g_playerData[client].regenTimer == INVALID_HANDLE)
        {
            g_playerData[client].regenTimer = CreateTimer(1.0, Timer_HealthRegen, GetClientUserId(client), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
        }

        return Plugin_Continue;
    }

    return Plugin_Stop;
}

public Action Timer_HealthRegen(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    if (client && IsPlayerAlive(client) && (g_playerData[client].regenAmount > 0))
    {
        SetEntityHealth(client, GetClientHealth(client) + 1);
        --g_playerData[client].regenAmount;

        return Plugin_Continue;
    }

    return Plugin_Stop;
}

void ClearClientData(int client)
{
    g_playerData[client].level = -1;
    g_playerData[client].regenAmount = 0;
    g_playerData[client].regenFactor = 0.0;
    ClearTimer(g_playerData[client].pendingTimer);
    ClearTimer(g_playerData[client].regenTimer);
}
