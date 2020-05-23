#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <colorlib>

#undef REQUIRE_PLUGIN
#include <ttt>
#define REQUIRE_PLUGIN
#include <generics>
#undef REQUIRE_PLUGIN
#include <clwo_store>
#define REQUIRE_PLUGIN

#define RGN_ID "hrgn"
#define RGN_NAME "Larraman's Organ"
#define RGN_DESCRIPTION "Pumps healing cells towards any sustained injuries. These clot blood and form scar tissu allowing you too fight on."
#define RGN_PRICE 2000
#define RGN_STEP 2.5
#define RGN_LEVEL 2
#define RGN_SORT 0

public Plugin myinfo =
{
    name = "CLWO Store - Skill: Larraman's Organ (Health Regen)",
    author = "Popey & c0rp3n",
    description = "A skill that allows for the player to regenrate some health.",
    version = "1.0.0",
    url = ""
};

bool g_bTTTLoaded = false;

int g_iBands[] = { 35, 48, 61, 74, 87, 100 };

// look-up table for the health bands, eleminates the need for a loop in the
// damage hook.
char g_iBandLut[] = "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x02\x02\x02\x02\x02\x02\x02\x02\x02\x02\x02\x02\x02\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x04\x04\x04\x04\x04\x04\x04\x04\x04\x04\x04\x04\x04\x05\x05\x05\x05\x05\x05\x05\x05\x05\x05\x05\x05";

enum struct PlayerData
{
    int level;
    int band;
    Handle pendingTimer;
    Handle regenTimer;
}

PlayerData g_playerData[MAXPLAYERS + 1];

public void OnPluginStart()
{
    LoopClients(i)
    {
        g_playerData[i].pendingTimer = INVALID_HANDLE;
        g_playerData[i].regenTimer = INVALID_HANDLE;
    }

    HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);

    PrintToServer("[RGN] Loaded successfully");
}

public void OnAllPluginLoaded()
{
    g_bTTTLoaded = LibraryExists("ttt");
}

public void OnLibraryAdded(const char[] name)
{
    if (strcmp(name, "ttt", true) == 0)
    {
        g_bTTTLoaded = true;
    }
}

public void OnLibraryRemoved(const char[] name)
{
    if (strcmp(name, "ttt", true) == 0)
    {
        g_bTTTLoaded = false;
    }
}

public void OnClientPutInServer(int client)
{
    ClearClientData(client);

    g_playerData[client].pendingTimer = INVALID_HANDLE;
    g_playerData[client].regenTimer = INVALID_HANDLE;
}

public void OnClientDisconnect(int client)
{
    ClearClientData(client);

    ClearTimer(g_playerData[client].pendingTimer);
    ClearTimer(g_playerData[client].regenTimer);
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
    g_playerData[client].band = 0;
    if (g_playerData[client].level > 0)
    {
        SDKHook(client, SDKHook_OnTakeDamageAlivePost, Hook_OnTakeDamageAlive);
    }
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    LoopClients(i)
    {
        g_playerData[i].band = 0;
        ClearTimer(g_playerData[i].pendingTimer);
        ClearTimer(g_playerData[i].regenTimer);
    }
}

public void Hook_OnTakeDamageAlive(int victim, int attacker, int inflictor, float damage, int damagetype)
{
    if (!g_bTTTLoaded && TTT_GetRoundStatus() != Round_Active)
    {
        return;
    }

    int health = GetClientHealth(victim);
    if (health <= 0 || health >= 100)
    {
        return;
    }

    // select band to heal up to if the client has level 2
    int band = 0;
    if (g_playerData[victim].level > 1)
    {
        // replaced the loop with the lut, use py/bands_gen.py to regnerate the
        // the lut if needed.
        /*
        for (int i = 0; i < sizeof(g_iBands); ++i)
        {
            if (health < g_iBands[i])
            {
                g_playerData[victim].band = i;
                break;
            }
            else if (health == g_iBands[i])
            {
                // already hit this band so they can not heal past this
                return;
            }
        }
        */
        band = g_iBandLut[health];
    }

    // check to see if the players health is less than the band
    if (health < g_iBands[band])
    {
        g_playerData[victim].band = band;
    }
    else // dont bother healing 
    {
        return;
    }

    if (g_playerData[victim].pendingTimer == INVALID_HANDLE)
    {
        g_playerData[victim].pendingTimer = CreateTimer(5.0, Timer_HealthPending, GetClientUserId(victim), TIMER_FLAG_NO_MAPCHANGE);
    }
}

public Action Timer_HealthPending(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    if (client > 0 && IsPlayerAlive(client))
    {
        CPrintToChat(client, "[RGN] Larraman's Organ activated, dispensing cells.");

        if (g_playerData[client].regenTimer == INVALID_HANDLE)
        {
            g_playerData[client].regenTimer = CreateTimer(1.0, Timer_HealthRegen, GetClientUserId(client), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
        }
    }

    return Plugin_Stop;
}

public Action Timer_HealthRegen(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    int health = GetClientHealth(client);
    int maxHealth = g_iBands[g_playerData[client].band];
    if (client > 0 && IsPlayerAlive(client) && health < maxHealth)
    {
        ++health;
        SetEntityHealth(client, health);

        return Plugin_Continue;
    }

    return Plugin_Stop;
}

void ClearClientData(int client)
{
    g_playerData[client].level = -1;
    g_playerData[client].band = 0;
}
