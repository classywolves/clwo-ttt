#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#include <colorvariables>
#include <generics>
#include <clwo-store>

#define EXAMPLE_ID 0x6c706d78 // fourcc xmpl little-endian
#define EXAMPLE_NAME "Example Skill"
#define EXAMPLE_DESCRIPTION "Example text would go here."
#define EXAMPLE_PRICE 100000
#define EXAMPLE_STEP 0.0
#define EXAMPLE_COUNT 1
#define EXAMPLE_SORT 100

public Plugin myinfo =
{
    name = "CLWO Skill Example Plugin",
    author = "c0rp3n",
    description = "Example plugin for the clwo store plugin.",
    version = "0.1.0",
    url = ""
};

public OnPluginStart()
{
    PrintToServer("[SKL] Loaded succcessfully");
}

public void Store_OnRegister()
{
    Store_RegisterSkill(EXAMPLE_ID, EXAMPLE_NAME, EXAMPLE_DESCRIPTION, EXAMPLE_PRICE, EXAMPLE_STEP, EXAMPLE_COUNT, EXAMPLE_SORT);
}

public void Store_OnReady()
{
    LoopValidClient(i)
    {
        if (Store_GetSkill(client, EXAMPLE_ID))
        {
            CPrintToChat("Example text again.");
        }
    }
}