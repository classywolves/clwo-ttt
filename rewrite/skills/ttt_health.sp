#pragma semicolon 1

/*
 * Base CS:GO plugin requirements.
 */
#include <sourcemod>
#include <sdktools>
#include <cstrike>

/*
 * Custom include files.
 */
#include <ttt>
#include <colorvariables>
#include <generics>

/*
 * Custom methodmap includes.
 */
#include <player_methodmap>

#define HEALTH_MAX_LEVEL 4

Handle healthTimers[MAXPLAYERS + 1] = { INVALID_HANDLE, ... };

public Plugin myinfo =
{
    name = "TTT Health",
    author = "Popey & c0rp3n",
    description = "TTT Health Skill",
    version = "0.0.1",
    url = ""
};

public OnPluginStart()
{
    LoadTranslations("common.phrases");

    PrintToServer("[HPR] Loaded successfully");
}

public OnClientDisconnect(int client)
{
    ClearTimer(healthTimers[client]);
}

public void TTT_OnRoundStart(int innocents, int traitors, int detectives) {
    LoopAliveClients(i)
    {
        Player player = Player(i);
        int upgradeLevel = player.Skill(Skill_Health, 0, HEALTH_MAX_LEVEL);
        if (upgradeLevel == 0)
        continue;

        healthTimers[i] = CreateTimer(10.0 - (upgradeLevel * 2.0), HealthRegen, GetClientUserId(i), TIMER_REPEAT);
    }
}

public void TTT_OnRoundEnd(int winner)
{
    LoopClients(i)
    {
        ClearTimer(healthTimers[i]);
    }
}

public Action HealthRegen(Handle timer, int serial) {
    int client = GetClientOfUserId(serial);
    Player player = Player(client);

    if (!player.Alive)
    {
        ClearTimer(healthTimers[client]);
        return Plugin_Stop;
    }

    int health = player.Health;
    if (health < player.MaxHealth)
    player.Health = ++health;

    return Plugin_Continue;
}
