#pragma semicolon 1

#include <sourcemod>

#include <generics>
#undef REQUIRE_PLUGIN
#include <clwo_store>
#define REQUIRE_PLUGIN

#include "skill_common.sp"

#define EXAMPLE_ID "xmpl"
#define EXAMPLE_NAME "Example"
#define EXAMPLE_DESCRIPTION "Description would go here :)."
#define EXAMPLE_PRICE 100000
#define EXAMPLE_STEP 10.0
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

public void OnPluginStart()
{
    LoopValidClients(i)
    {
        OnClientPutInServer(i);
    }

    PrintToServer("[SKL] Loaded succcessfully");
}

public void OnPluginEnd()
{
    Store_UnRegisterSkill(EXAMPLE_ID);
}

public void Store_OnRegister()
{
    Store_RegisterSkill(EXAMPLE_ID, EXAMPLE_NAME, EXAMPLE_DESCRIPTION, EXAMPLE_PRICE, EXAMPLE_STEP, EXAMPLE_LEVEL, Store_OnSkillUpdate, EXAMPLE_SORT);
}

public void OnClientPutInServer(int client)
{
    g_playerData[client].level = -1;
}

public void OnClientDisconnect(int client)
{
    g_playerData[client].level = -1;
}

public void Store_OnSkillUpdate(int client, int level)
{
    g_playerData[client].level = level;
    if (g_playerData[client].level > 0)
    {
        PrintToChat(client, "You have the %s skill.", EXAMPLE_NAME);
    }
}
