#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cstrike>

#include <colorvariables>
#include <generics>
#include <clwo-store>

#define FF_ID "rfll"
#define FF_NAME "Feather Falling"
#define FF_DESCRIPTION "Reduces the amount of damage taken from falling."
#define FF_PRICE 600
#define FF_STEP 1.2
#define FF_LEVEL 4
#define FF_SORT 0

public Plugin myinfo =
{
    name = "Skill Reduced Fall Damage",
    author = "Popey & c0rp3n",
    description = "A skill that reduces the fall damage a player receives.",
    version = "1.0.0",
    url = ""
};

enum struct PlayerData
{
    int level;
}

PlayerData g_playerData[MAXPLAYERS + 1];

public OnPluginStart()
{
    PrintToServer("[FLL] Loaded successfully");
}

public void Store_OnRegister()
{
    Store_RegisterSkill(FF_ID, FF_NAME, FF_DESCRIPTION, FF_PRICE, FF_STEP, FF_LEVEL, FF_SORT);
}

public void Store_OnReady()
{
    LoopValidClients(i)
    {
        g_playerData[i].level = Store_GetSkill(i, FF_ID);
        if (g_playerData[i].level)
        {
            SDKHook(i, SDKHook_OnTakeDamageAlive, Hook_OnTakeDamage);
        }
    }
}

public void OnClientPutInServer(int client)
{
    if (Store_IsReady())
    {
        g_playerData[client].level = Store_GetSkill(client, FF_ID);
        if (g_playerData[client].level)
        {
            SDKHook(client, SDKHook_OnTakeDamageAlive, Hook_OnTakeDamage);
        }
    }
}

public void OnClientDisconnect(int client)
{
    g_playerData[client].level = -1;
}

public void Store_OnSkillPurchased(int client, char[] id, int level)
{
    if (StrEqual(id, FF_ID, true))
    {
        g_playerData[client].level = level;
        if (g_playerData[client].level > 0)
        {
            SDKHook(client, SDKHook_OnTakeDamageAlive, Hook_OnTakeDamage);
        }
    }
}

public Action Hook_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, const float damageForce[3], const float damagePosition[3], int damagecustom)
{
    // We only care for fall damage here.
    if (!(damagetype & DMG_FALL))
    {
        return Plugin_Continue;
    }

    float oldDamage = damage;
    damage = damage * (1.0 - (0.2 * float(g_playerData[victim].level)));

    CPrintToChat(victim, "{default}[TTT] > Feather falling reduced your damage from {orange}%.0f {default}to {orange}%.0f.", oldDamage, damage);

    return Plugin_Changed;
}
