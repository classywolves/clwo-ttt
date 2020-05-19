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

Handle g_hRewardTimer = INVALID_HANDLE;

public void OnPluginStart()
{
    g_cCrReward = CreateConVar("clwo_store_reward", "1", "The maximum reward a player can get.");
    g_cRewardTime = CreateConVar("clwo_store_reward_time", "1", "The delta in time between rewards in minutes 0 = Disabled.");

    AutoExecConfig(true, "store_rewards", "clwo");

    PrintToServer("[RWD] Loaded succcessfully");
}

public void OnConfigsExecuted()
{
    g_hRewardTimer = CreateTimer(g_cRewardTime.FloatValue * 60.0, Timer_Reward, _, TIMER_REPEAT);
}

public Action Timer_Reward(Handle timer)
{
    int credits = g_cCrReward.IntValue;
    LoopValidClients(i)
    {
        Store_AddClientCredits(i, credits);
    }

    return Plugin_Continue;
}