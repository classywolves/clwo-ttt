#pragma semicolon 1

/*
 * Base CS:GO plugin requirements.
 */
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cstrike>

/*
 * Custom include files.
 */
#include <ttt>
#include <ttt_taser>
#include <colorvariables>
#include <generics>

/*
 * Custom methodmap includes.
 */
#include <player_methodmap>

#define FLASH_MAX_LEVEL 1

public Plugin myinfo =
{
    name = "TTT Flash",
    author = "c0rp3n",
    description = "TTT Flash on Tase",
    version = "0.0.1",
    url = ""
};

public OnPluginStart()
{
    PrintToServer("[FLH] Loaded successfully");
}

public Action TTT_OnTased(int attacker, int victim)
{
    if (TTT_GetClientRole(victim) != TTT_TEAM_TRAITOR) { return Plugin_Continue; }

    if (Player(victim).Skill(Skill_Flash, 0, FLASH_MAX_LEVEL))
    {
        int color[4] = {255, 255, 255, 255};
        int duration = 480;
        int holdTime = 480;
        int flags = 0x0001;

        Player(attacker).SetScreenColor(color, duration, holdTime, flags);
    }
}
