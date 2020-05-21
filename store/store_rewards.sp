#pragma semicolon 1

#include <sourcemod>
#include <cstrike>
#include <colorlib>

#include <generics>
#include <clwo_store_credits>
#include <clwo_store_messages>

public Plugin myinfo =
{
    name = "CLWO Store - Rewards",
    author = "c0rp3n",
    description = "Example plugin for the clwo store plugin.",
    version = "1.0.0",
    url = ""
};

ConVar g_cCrReward = null;
ConVar g_cRewardActiveTime = null;
ConVar g_cRewardAfkTime = null;

Handle g_hRewardActiveTimer = INVALID_HANDLE;
Handle g_hRewardAfkTimer = INVALID_HANDLE;

public void OnPluginStart()
{
    g_cCrReward = CreateConVar("clwo_store_reward", "1", "The maximum reward a player can get.");
    g_cRewardActiveTime = CreateConVar("clwo_store_active_reward_time", "1", "The delta in time between rewards in minutes 0 = Disabled.");
    g_cRewardAfkTime = CreateConVar("clwo_store_afk_reward_time", "5", "The delta in time between rewards in minutes 0 = Disabled.");

    AutoExecConfig(true, "store_rewards", "clwo");

    PrintToServer("[RWD] Loaded succcessfully");
}

public void OnConfigsExecuted()
{
    g_hRewardActiveTimer = CreateTimer(g_cRewardActiveTime.FloatValue * 60.0, Timer_RewardActive, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
    g_hRewardAfkTimer = CreateTimer(g_cRewardAfkTime.FloatValue * 60.0, Timer_RewardAfk, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_RewardActive(Handle timer)
{
    int credits = g_cCrReward.IntValue;
    LoopValidClients(i)
    {
        int team = GetClientTeam(i);
        if (team == CS_TEAM_CT || team == CS_TEAM_T)
        {
            Store_AddClientCredits(i, credits);
        }
    }

    return Plugin_Continue;
}

public Action Timer_RewardAfk(Handle timer)
{
    int credits = g_cCrReward.IntValue;
    LoopValidClients(i)
    {
        int team = GetClientTeam(i);
        if (team == CS_TEAM_SPECTATOR || team == CS_TEAM_NONE)
        {
            Store_AddClientCredits(i, credits);
        }
    }

    return Plugin_Continue;
}
