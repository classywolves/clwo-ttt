#pragma semicolon 1

/*
* Base CS:GO plugin requirements.
*/
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <timers>

/*
* Custom include files.
*/
#include <ttt>
#include <colorvariables>
#include <generics>

public Plugin myinfo =
{
    name = "TTT Blood Lust",
    author = "c0rp3n",
    description = "TTT Bloodlust Traitor anti delaying mechanism.",
    version = "1.0.0",
    url = ""
};

UserMsg g_FadeUserMsgId = INVALID_MESSAGE_ID;

Handle bloodLustTimers[MAXPLAYERS+1] = { INVALID_HANDLE, ... };

float bloodLustStartTime = 45.0;
float bloodLustFinalTime = 30.0;

public OnPluginStart()
{
    PrintToServer("[BLO] Loaded successfully");
}

public void TTT_OnRoundStart(int innocents, int traitors)
{
    LoopClients(i)
    {
        if (TTT_GetClientRole(i) == TTT_TEAM_TRAITOR)
        {
            bloodLustTimers[i] = CreateTimer(bloodLustStartTime, BloodLustStart, GetClientUserId(i));
        }
        else
        {
            ClearTimer(bloodLustTimers[i]);
        }
    }
}

public void TTT_OnClientDeath(int victim, int attacker)
{
    if (TTT_GetClientRole(attacker) == TTT_TEAM_TRAITOR)
    {
        BloodLustReset(attacker);
    }
}

public void TTT_OnRoundEnd(int winner)
{
    LoopValidClients(i)
    {
        ClearTimer(bloodLustTimers[i]);
    }
}

public Action BloodLustStart(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    if (TTT_GetClientRole(client) != TTT_TEAM_TRAITOR || !IsAliveClient(client))
    {
        ClearTimer(bloodLustTimers[client]);

        return Plugin_Continue;
    }

    TTT_Message(client, "{red}You are longing for blood!  Better kill again soon, lest there lie concequences.");
    //ShowOverlayToClient(client, traitorBloodLustOverlay);
    BloodLustScreenColor(client);
    ClearTimer(bloodLustTimers[client]);
    bloodLustTimers[client] = CreateTimer(bloodLustFinalTime, BloodLustFinal, GetClientUserId(client));

    return Plugin_Continue;
}

public Action BloodLustFinal(Handle timer, int userid) {
    int client = GetClientOfUserId(userid);
    if (TTT_GetClientRole(client) != TTT_TEAM_TRAITOR || !IsAliveClient(client)) {
        ClearTimer(bloodLustTimers[client]);

        return Plugin_Continue;
    }

    TTT_Message(client, "{red}You have gone without blood for too long; you are now revealed to the players around you.");
    SetEntityRenderColor(client, 255, 0, 0, 255);
    ClearTimer(bloodLustTimers[client]);

    return Plugin_Continue;
}

public void BloodLustReset(int client) {
    SetEntityRenderColor(client, 255, 255, 255, 255);
    ClearScreenColor(client);

    ClearTimer(bloodLustTimers[client]);
    bloodLustTimers[client] = CreateTimer(bloodLustStartTime, BloodLustStart, GetClientUserId(client));
}

public void BloodLustScreenColor(int client) 
{
    int color[4] = { 255, 0, 0 , 63 };
    int duration = 480;
    int holdTime = 120000;
    int flags = 0x0001 | 0x0008; // fade in and stay out.

    SetScreenColor(client, color, duration, holdTime, flags);
}

public void ClearScreenColor(int client) {
    int color[4] = { 0, 0, 0 , 0 };
    int duration = 0;
    int holdTime = 0;
    int flags = 0x0010; // purge.

    SetScreenColor(client, color, duration, holdTime, flags);
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
