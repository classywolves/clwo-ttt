#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#include <colorlib>
#include <ttt>
#include <generics>

#define BEACON_START 90.0

// Flags used in various timers
#define DEFAULT_TIMER_FLAGS TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE

public Plugin myinfo =
{
    name = "CLWO TTT Beacon",
    author = "c0rp3n",
    description = "Beacons players late into a round of TTT.",
    version = "0.1.0",
    url = ""
};

ConVar g_cvRoundLength  = null;
ConVar g_cvBeaconRadius = null;

Handle g_hBeaconsTimer = null;

// Serial Generator for Timer Safety
int g_iSerialGen                   = 0;
int g_BeaconSerial[MAXPLAYERS + 1] = { 0, ... };

// Sounds
char g_BlipSound[PLATFORM_MAX_PATH];

// Following are model indexes for temp entities
int g_BeamSprite        = -1;
int g_HaloSprite        = -1;

// Basic color arrays for temp entities
int g_ExternalBeaconColor[4];
int g_Team1BeaconColor[4];
int g_Team2BeaconColor[4];
int g_Team3BeaconColor[4];
int g_Team4BeaconColor[4];
int g_TeamUnknownBeaconColor[4];

public void OnPluginStart()
{
}

public void OnAllPluginsLoaded()
{
    g_cvRoundLength  = FindConVar("mp_roundtime");
    g_cvBeaconRadius = FindConVar("sm_beacon_radius");
}

public void OnMapStart()
{
    GameData gameConfig = new GameData("funcommands.games");
    if (gameConfig == null)
    {
        SetFailState("Unable to load game config funcommands.games");
        return;
    }

    if (gameConfig.GetKeyValue("SoundBlip", g_BlipSound, sizeof(g_BlipSound)) && g_BlipSound[0])
    {
        PrecacheSound(g_BlipSound, true);
    }

    char buffer[PLATFORM_MAX_PATH];
    if (gameConfig.GetKeyValue("SpriteBeam", buffer, sizeof(buffer)) && buffer[0])
    {
        g_BeamSprite = PrecacheModel(buffer);
    }

    if (gameConfig.GetKeyValue("SpriteHalo", buffer, sizeof(buffer)) && buffer[0])
    {
        g_HaloSprite = PrecacheModel(buffer);
    }

    if (gameConfig.GetKeyValue("ExternalBeaconColor", buffer, sizeof(buffer)) && buffer[0])
    {
        g_ExternalBeaconColor = ParseColor(buffer);
    }

    if (gameConfig.GetKeyValue("Team1BeaconColor", buffer, sizeof(buffer)) && buffer[0])
    {
        g_Team1BeaconColor = ParseColor(buffer);
    }

    if (gameConfig.GetKeyValue("Team2BeaconColor", buffer, sizeof(buffer)) && buffer[0])
    {
        g_Team2BeaconColor = ParseColor(buffer);
    }

    if (gameConfig.GetKeyValue("Team3BeaconColor", buffer, sizeof(buffer)) && buffer[0])
    {
        g_Team3BeaconColor = ParseColor(buffer);
    }

    if (gameConfig.GetKeyValue("Team4BeaconColor", buffer, sizeof(buffer)) && buffer[0])
    {
        g_Team4BeaconColor = ParseColor(buffer);
    }

    if (gameConfig.GetKeyValue("TeamUnknownBeaconColor", buffer, sizeof(buffer)) && buffer[0])
    {
        g_TeamUnknownBeaconColor = ParseColor(buffer);
    }

    delete gameConfig;
}

public void TTT_OnRoundStart(int roundid, int innocents, int traitors, int detectives)
{
    float beaconTime = (g_cvRoundLength.FloatValue * 60.0) - BEACON_START;
    g_hBeaconsTimer = CreateTimer(beaconTime, Timer_Beacons, TIMER_FLAG_NO_MAPCHANGE);
}

public void TTT_OnRoundEnd(int winner, Handle array)
{
    ClearTimer(g_hBeaconsTimer);
    KillAllBeacons();
}

public void OnMapEnd()
{
    KillAllBeacons();
}

////////////////////////////////////////////////////////////////////////////////
// Timers
////////////////////////////////////////////////////////////////////////////////

public Action Timer_Beacons(Handle timer)
{
    for (int i = 1; i <= MaxClients; ++i)
    {
        if (IsClientInGame(i) && IsPlayerAlive(i))
        {
            CreateBeacon(i);
        }
    }
}

////////////////////////////////////////////////////////////////////////////////
// Stocks
////////////////////////////////////////////////////////////////////////////////

void CreateBeacon(int client)
{
    g_BeaconSerial[client] = ++g_iSerialGen;
    CreateTimer(1.0, Timer_Beacon, client | (g_iSerialGen << 7), DEFAULT_TIMER_FLAGS);
}

void KillBeacon(int client)
{
    g_BeaconSerial[client] = 0;

    if (IsClientInGame(client))
    {
        SetEntityRenderColor(client, 255, 255, 255, 255);
    }
}

void KillAllBeacons()
{
    for (int i = 1; i <= MaxClients; ++i)
    {
        KillBeacon(i);
    }
}

public Action Timer_Beacon(Handle timer, any value)
{
    int client = value & 0x7f;
    int serial = value >> 7;

    if (!IsClientInGame(client)
        || !IsPlayerAlive(client)
        || g_BeaconSerial[client] != serial)
    {
        KillBeacon(client);
        return Plugin_Stop;
    }

    float vec[3];
    GetClientAbsOrigin(client, vec);
    vec[2] += 10;

    if (g_BeamSprite > -1 && g_HaloSprite > -1)
    {
        int teamBeaconColor[4];

        switch (GetClientTeam(client))
        {
            case 1: teamBeaconColor = g_Team1BeaconColor;
            case 2: teamBeaconColor = g_Team2BeaconColor;
            case 3: teamBeaconColor = g_Team3BeaconColor;
            case 4: teamBeaconColor = g_Team4BeaconColor;
            default: teamBeaconColor = g_TeamUnknownBeaconColor;
        }

        TE_SetupBeamRingPoint(vec, 10.0, g_cvBeaconRadius.FloatValue, g_BeamSprite, g_HaloSprite, 0, 15, 0.5, 5.0, 0.0, g_ExternalBeaconColor, 10, 0);
        TE_SendToAll();

        TE_SetupBeamRingPoint(vec, 10.0, g_cvBeaconRadius.FloatValue, g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, teamBeaconColor, 10, 0);
        TE_SendToAll();
    }

    if (g_BlipSound[0])
    {
        GetClientEyePosition(client, vec);

        static int clients[MAXPLAYERS + 1];
        int        count = 0;
        for (int i = 1; i < MaxClients; ++i)
        {
            if ((i != client) && IsClientInGame(i))
            {
                clients[count++] = i;
            }
        }

        //EmitAmbientSound(g_BlipSound, vec, client, SNDLEVEL_RAIDSIREN);
        EmitSound(clients, count, g_BlipSound, client, SNDCHAN_AUTO, SNDLEVEL_RAIDSIREN, SND_NOFLAGS, 1.0, 100, -1, vec);
    }

    return Plugin_Continue;
}

int[] ParseColor(const char[] buffer)
{
    char sColor[16][4];
    ExplodeString(buffer, ",", sColor, sizeof(sColor), sizeof(sColor[]));

    int iColor[4];
    iColor[0] = StringToInt(sColor[0]);
    iColor[1] = StringToInt(sColor[1]);
    iColor[2] = StringToInt(sColor[2]);
    iColor[3] = StringToInt(sColor[3]);

    return iColor;
}
