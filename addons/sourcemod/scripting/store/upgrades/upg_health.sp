#pragma semicolon 1

#include <sourcemod>

#undef REQUIRE_PLUGIN
#include <ttt>
#include <clwo_store>
#define REQUIRE_PLUGIN

#define HEALTH_ID "hlth"
#define HEALTH_NAME "Health +"
#define HEALTH_DESCRIPTION "You start the round with an extra 10 health. (Only I & T)"
#define HEALTH_PRICE 5000
#define HEALTH_SORT 50

#define HEALTH2_ID "hlt2"
#define HEALTH2_NAME "Health ++"
#define HEALTH2_DESCRIPTION "You start the round with extra 10 health (stacks)."
#define HEALTH2_PRICE 20000
#define HEALTH2_SORT 51

public Plugin myinfo =
{
    name = "CLWO Store - Upgrades: Health",
    author = "c0rp3n",
    description = "Grants players extra health at the start of the round.",
    version = "0.1.0",
    url = ""
};

bool g_bStoreLoaded = false;

int g_iPlayerLevel[MAXPLAYERS + 1] = { 0, ... };

public void OnPluginStart()
{
    for (int i = 0; i < MaxClients; ++i)
    {
        OnClientPutInServer(i);
    }

    if (g_bStoreLoaded && Store_IsReady())
    {
        Store_OnRegister();
    }

    HookEvent("player_spawn", Event_PlayerSpawned, EventHookMode_Post);

    PrintToServer("[HTH] Loaded succcessfully");
}

public void OnPluginEnd()
{
    Store_UnRegisterUpgrade(HEALTH_ID);
    Store_UnRegisterUpgrade(HEALTH2_ID);
}

public void Store_OnRegister()
{
    Store_RegisterUpgrade(HEALTH_ID, HEALTH_NAME, HEALTH_DESCRIPTION, HEALTH_PRICE, Store_OnHealthUpdate, HEALTH_SORT);
    Store_RegisterUpgrade(HEALTH2_ID, HEALTH2_NAME, HEALTH2_DESCRIPTION, HEALTH2_PRICE, Store_OnHealth2Update, HEALTH2_SORT);
}

public void OnClientPutInServer(int client)
{
    g_iPlayerLevel[client] = 0;
}

public void OnClientDisconnect(int client)
{
    g_iPlayerLevel[client] = 0;
}

public void Store_OnHealthUpdate(int client, bool has)
{
    if (has && g_iPlayerLevel[client] != 2)
    {
        g_iPlayerLevel[client] = 1;
    }
}

public void Store_OnHealth2Update(int client, bool has)
{
    if (has)
    {
        g_iPlayerLevel[client] = 2;
    }
}

public void Event_PlayerSpawned(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client)
    {
        SetClientHealth(client);
    }
}

public void TTT_OnRoundStart()
{
    for (int i = 1; i < MaxClients; ++i)
    {
        if (IsClientConnected(i) && IsPlayerAlive(i))
        {
            SetClientHealth(i);
        }
    }
}

void SetClientHealth(int client)
{
    if (g_iPlayerLevel[client] == 1)
    {
        SetEntityHealth(client, 110);
    }
    else if (g_iPlayerLevel[client] == 2)
    {
        SetEntityHealth(client, 120);
    }
}
