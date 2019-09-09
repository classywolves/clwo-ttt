#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cstrike>

#include <colorvariables>
#include <generics>
#include <clwo-store>

#define RGN_ID "hrgn"
#define RGN_NAME "Larraman's Organ"
#define RGN_DESCRIPTION "Pumps healing cells towards any sustained injuries. These clot blood and form scar tissu allowing you too fight on."
#define RGN_PRICE 600
#define RGN_STEP 1.4
#define RGN_LEVEL 2
#define RGN_SORT 0

public Plugin myinfo =
{
    name = "Skill Larraman's Organ (Health Regen)",
    author = "Popey & c0rp3n",
    description = "A skill that allows for the player to regenrate some health.",
    version = "1.0.0",
    url = ""
};

enum struct PlayerData
{
    int level;
    int regenAmount;
    float regenFactor;
    Handle regenTimer;
}

PlayerData g_playerData[MAXPLAYERS + 1];

public OnPluginStart()
{
    PrintToServer("[RGN] Loaded successfully");
}

public void Store_OnRegister()
{
    Store_RegisterSkill(RGN_ID, RGN_NAME, RGN_DESCRIPTION, RGN_PRICE, RGN_STEP, RGN_LEVEL, RGN_SORT);
}

public void Store_OnReady()
{
    LoopValidClients(i)
    {
        g_playerData[i].level = Store_GetSkill(i, RGN_ID);
        g_playerData[i].regenAmount = 0;
        if (g_playerData[i].level > 0)
        {
            g_playerData[i].regenFactor = 0.4 * g_playerData[i].level;
            SDKHook(i, SDKHook_OnTakeDamageAlivePost, Hook_OnTakeDamage);
        }
    }
}

public void OnClientPutInServer(int client)
{
    if (Store_IsReady())
    {
        g_playerData[client].level = Store_GetSkill(client, RGN_ID);
        g_playerData[client].regenAmount = 0;
        if (g_playerData[client].level > 0)
        {
            g_playerData[client].regenFactor = 0.4 * g_playerData[client].level;
            SDKHook(client, SDKHook_OnTakeDamageAlivePost, Hook_OnTakeDamage);
        }
    }
}

public void OnClientDisconnect(int client)
{
    g_playerData[client].level = -1;
    g_playerData[client].regenAmount = 0;
    g_playerData[client].regenFactor = 0.0;
    ClearTimer(g_playerData[client].regenTimer);
}

public void Store_OnSkillPurchased(int client, char[] id, int level)
{
    if (StrEqual(id, RGN_ID, true))
    {
        g_playerData[client].level = level;
        g_playerData[client].regenAmount = 0;
        if (g_playerData[client].level > 0)
        {
            g_playerData[client].regenFactor = 0.4 * g_playerData[client].level;
            SDKHook(client, SDKHook_OnTakeDamageAlivePost, Hook_OnTakeDamage);
        }
    }
}

public void Hook_OnTakeDamage(int victim, int attacker, int inflictor, float damage, int damagetype)
{
    g_playerData[victim].regenAmount += RoundToFloor(damage * g_playerData[victim].regenFactor);
    if (g_playerData[victim].regenTimer == INVALID_HANDLE)
    {
        g_playerData[victim].regenTimer = CreateTimer(1.0, Timer_HealthRegen, GetClientUserId(victim), TIMER_REPEAT);
    }
}

public Action Timer_HealthRegen(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    if (IsAliveClient(client) && g_playerData[client].regenAmount > 0)
    {
        SetEntityHealth(client, GetClientHealth(client) + 1);
        g_playerData[client].regenAmount -= 1;

        return Plugin_Continue;
    }
    else
    {
        g_playerData[client].regenTimer = INVALID_HANDLE;
        return Plugin_Stop;
    }
}