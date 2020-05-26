#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <colorlib>

#include <generics>
#undef REQUIRE_PLUGIN
#include <clwo_store>
#define REQUIRE_PLUGIN

#define FF_ID "rfll"
#define FF_NAME "Feather Falling"
#define FF_DESCRIPTION "Reduces the amount of damage taken from falling."
#define FF_PRICE 1000
#define FF_STEP 1.2
#define FF_LEVEL 4
#define FF_SORT 0

public Plugin myinfo =
{
    name = "CLWO Store - Skill: Feather Falling",
    author = "Popey & c0rp3n",
    description = "A skill that reduces the fall damage a player receives.",
    version = "1.0.0",
    url = ""
};

g_bHasReducedDamage[MAXPLAYERS + 1] = { false, ... };

enum struct PlayerData
{
    int level;
    float ratio;
}

PlayerData g_playerData[MAXPLAYERS + 1];

public void OnPluginStart()
{
    if (Store_IsReady())
    {
        Store_OnRegister();
    }

    PrintToServer("[FLL] Loaded successfully");
}

public void OnClientPutInServer(int client)
{
    ClearClientData(client);
}

public void OnClientDisconnect(int client)
{
    ClearClientData(client);
}

public void OnGameFrame()
{
    LoopClients(i)
    {
        g_bHasReducedDamage[i] = false;
    }
}

public void Store_OnRegister()
{
    Store_RegisterSkill(FF_ID, FF_NAME, FF_DESCRIPTION, FF_PRICE, FF_STEP, FF_LEVEL, Store_OnSkillUpdate, FF_SORT);
}

/*
public void Store_OnClientSkillsLoaded(int client)
{
    Store_OnSkillUpdate(client, Store_GetSkill(client, FF_ID));
}
*/

public void Store_OnSkillUpdate(int client, int level)
{
    g_playerData[client].level = level;
    if (g_playerData[client].level > 0)
    {
        SDKHook(client, SDKHook_OnTakeDamageAlive, Hook_OnTakeDamageAlive);
        g_playerData[client].ratio = 1.0 - (0.2 * float(g_playerData[client].level));
    }
}

public Action Hook_OnTakeDamageAlive(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, const float damageForce[3], const float damagePosition[3], int damagecustom)
{
    // We only care for fall damage here.
    if (!(damagetype & DMG_FALL) || g_bHasReducedDamage[victim])
    {
        return Plugin_Continue;
    }

    float oldDamage = damage;
    damage = damage * g_playerData[victim].ratio;

    CPrintToChat(victim, "{default}[TTT] > Feather falling reduced your damage from {orange}%.0f {default}to {orange}%.0f.", oldDamage, damage);

    g_bHasReducedDamage[victim] = true;

    return Plugin_Changed;
}

void ClearClientData(int client)
{
    g_playerData[client].level = -1;
    g_playerData[client].ratio = 0.0;
}
