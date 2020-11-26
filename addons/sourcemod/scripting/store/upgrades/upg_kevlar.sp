#pragma semicolon 1

#include <sourcemod>

#undef REQUIRE_PLUGIN
#include <ttt>
#include <clwo_store>
#define REQUIRE_PLUGIN

#define KEV_ID "kvlr"
#define KEV_NAME "Kevlar (+10)"
#define KEV_DESCRIPTION "You start the round with 10 kevlar."
#define KEV_PRICE 7500
#define KEV_SORT 52

public Plugin myinfo =
{
    name = "CLWO Store - Upgrades: Kevlar",
    author = "c0rp3n",
    description = "Grants players kevlar at the start of the round.",
    version = "0.1.0",
    url = ""
};

bool g_bStoreLoaded = false;

bool g_iPlayerHas[MAXPLAYERS + 1];

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

    PrintToServer("[KEV] Loaded succcessfully");
}

public void OnPluginEnd()
{
    Store_UnRegisterUpgrade(KEV_ID);
}

public void Store_OnRegister()
{
    Store_RegisterUpgrade(KEV_ID, KEV_NAME, KEV_DESCRIPTION, KEV_PRICE, Store_OnUpgradeUpdate, KEV_SORT);
}

public void OnClientPutInServer(int client)
{
    g_iPlayerHas[client] = false;
}

public void OnClientDisconnect(int client)
{
    g_iPlayerHas[client] = false;
}

public void Store_OnUpgradeUpdate(int client, bool has)
{
    g_iPlayerHas[client] = has;
}

public void Event_PlayerSpawned(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client)
    {
        SetClientKevlar(client);
    }
}

public void TTT_OnRoundStart()
{
    for (int i = 1; i < MaxClients; ++i)
    {
        if (IsClientConnected(i) && IsPlayerAlive(i))
        {
            SetClientKevlar(i);
        }
    }
}

void SetClientKevlar(int client)
{
    if (g_iPlayerHas[client])
    {
        SetEntProp(client, Prop_Data, "m_ArmorValue", 10, 1);  
    }
}
