#pragma semicolon 1

#include <sourcemod>
#include <colorlib>

#include <generics>
#include <clwo_store_credits>
#include <clwo_store_messages>

public Plugin myinfo =
{
    name = "CLWO Store Rewards",
    author = "c0rp3n",
    description = "Example plugin for the clwo store plugin.",
    version = "1.0.0",
    url = ""
};

ConVar g_cCrReward = null;
ConVar g_cRewardTime = null;

Handle g_hRewardTimers[MAXPLAYERS + 1] = { INVALID_HANDLE, ... };

public void OnPluginStart()
{
    g_cCrReward = CreateConVar("clwo_store_reward", "1", "The maximum reward a player can get.");
    g_cRewardTime = CreateConVar("clwo_store_reward_time", "15", "The delta in time between rewards in minutes 0 = Disabled.");

    AutoExecConfig(true, "store-rewards", "clwo");

    PrintToServer("[RWD] Loaded succcessfully");
}

public void OnClientPostAdminCheck(int client)
{
    g_hRewardTimers[client] = CreateTimer(g_cRewardTime.FloatValue * 60.0, Timer_ActiveReward, GetClientUserId(client), TIMER_REPEAT);
}

public void OnClientDisconnect(int client)
{
    ClearTimer(g_hRewardTimers[client]);
}

public Action Timer_ActiveReward(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    if (!client)
    {
        return Plugin_Stop;
    }

    int credits = g_cCrReward.IntValue;
    Store_AddClientCredits(client, credits);
    CPrintToChat(client, STORE_MESSAGE ... "You have gained {orange}%dcR.", credits);

    return Plugin_Continue;
}