#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cstrike>

#include <ttt>
#include <ttt_taser>
#include <colorvariables>
#include <generics>
#include <ttt_skills>

#define FLASH_MAX_LEVEL 1

public Plugin myinfo =
{
    name = "TTT Flash",
    author = "c0rp3n",
    description = "TTT Flash on Tase",
    version = "0.0.1",
    url = ""
};

UserMsg g_FadeUserMsgId = INVALID_MESSAGE_ID;

public OnPluginStart()
{
    PrintToServer("[FLH] Loaded successfully");
}

public OnAllPluginsLoaded()
{
    Skills_RegisterSkill(Skill_Flash, "Taser Flash", "The player releases a flash of light blinding anyone who might taser them whilst as a traitor.", FLASH_MAX_LEVEL);
}

public Action TTT_OnTased(int attacker, int victim)
{
    if (TTT_GetClientRole(victim) != TTT_TEAM_TRAITOR) { return Plugin_Continue; }

    if (Skills_GetSkill(victim, Skill_Flash, 0, FLASH_MAX_LEVEL))
    {
        int color[4] = {255, 255, 255, 255};
        int duration = 480;
        int holdTime = 480;
        int flags = 0x0001;

        SetScreenColor(attacker, color, duration, holdTime, flags);
    }

    return Plugin_Continue;
}

public void SetScreenColor(int client, int color[4], int duration, int holdTime, int flags)
{
    if (g_FadeUserMsgId == INVALID_MESSAGE_ID)
    {
        g_FadeUserMsgId = GetUserMessageId("Fade");
    }

    int clients[1];
    clients[0] = client;

    Handle message = StartMessageEx(g_FadeUserMsgId, clients, 1);
    if (GetUserMessageType() == UM_Protobuf)
    {
        PbSetInt(message, "duration", duration);
        PbSetInt(message, "hold_time", holdTime);
        PbSetInt(message, "flags", flags);
        PbSetColor(message, "clr", color);
    }
    else
    {
        BfWriteShort(message, duration);
        BfWriteShort(message, holdTime);
        BfWriteShort(message, flags);
        BfWriteByte(message, color[0]);
        BfWriteByte(message, color[1]);
        BfWriteByte(message, color[2]);
        BfWriteByte(message, color[3]);
    }

    EndMessage();
}
