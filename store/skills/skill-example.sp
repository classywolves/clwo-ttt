#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#include <colorvariables>
#include <generics>
#include <clwo-store>

#define EXAMPLE_ID "xmpl"
#define EXAMPLE_NAME "Example Skill"
#define EXAMPLE_DESCRIPTION "Example text would go here."
#define EXAMPLE_PRICE 100000
#define EXAMPLE_STEP 0.0
#define EXAMPLE_LEVEL 1
#define EXAMPLE_SORT 100

public Plugin myinfo =
{
    name = "CLWO Skill Example Plugin",
    author = "c0rp3n",
    description = "Example plugin for the clwo store plugin.",
    version = "0.1.0",
    url = ""
};

enum struct PlayerData
{
    int level;
}

PlayerData g_playerData[MAXPLAYERS + 1];

public OnPluginStart()
{
    PrintToServer("[SKL] Loaded succcessfully");
}

public void Store_OnRegister()
{
    Store_RegisterSkill(EXAMPLE_ID, EXAMPLE_NAME, EXAMPLE_DESCRIPTION, EXAMPLE_PRICE, EXAMPLE_STEP, EXAMPLE_LEVEL, EXAMPLE_SORT);
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
        g_playerData[client].level = Store_GetSkill(client, EXAMPLE_ID);
        if (g_playerData[client].level > 0)
        {
            CPrintToChat(client, "You have the %s skill.", EXAMPLE_NAME);
        }
    }
}

public void OnClientDisconnect(int client)
{
    g_playerData[client].level = -1;
}

public void Store_OnSkillPurchased(int client, char[] id, int level)
{
    if (StrEqual(id, EXAMPLE_ID, true))
    {
        g_playerData[client].level = level;
        if (g_playerData[client].level > 0)
        {
            CPrintToChat(client, "You purchased the %s skill.", EXAMPLE_NAME);
        }
    }
}