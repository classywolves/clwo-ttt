#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#include <ttt>
#include <colorvariables>
#include <sourcecomms>
#include <generics>
#include <ttt_messages>
#include <voiceannounce_ex>

public Plugin myinfo =
{
    name = "TTT Voice Restrict",
    author = "c0rp3n",
    description = "A controllable voice restrictor for CLWO TTT.",
    version = "1.0.0",
    url = ""
};

bool voiceRestrictEnabled = false;

bool isPlayerSpeaking[MAXPLAYERS + 1] = { false, ... };
int lastTimeSpoken[MAXPLAYERS + 1] = { 0, ... };
int timeSpoken[MAXPLAYERS + 1] = { 0, ... };

public OnPluginStart()
{
    RegisterCmds();

    PrintToServer("[VCT] Loaded successfully");
}

public void RegisterCmds()
{
    RegConsoleCmd("sm_voicerestrict", Command_VoiceRestrict, "Restricts how long none staff memebers can use voice chat for.");
}

public void OnClientSpeakingEx(int client)
{
    if (voiceRestrictEnabled && !isPlayerSpeaking[client])
    {
        if (isPlayerSpeaking[client] || (GetUserFlagBits(client) & ADMFLAG_CHAT == ADMFLAG_CHAT)) { return; }

        isPlayerSpeaking[client] = true;

        int currentTime = GetTime();
        timeSpoken[client] -= currentTime - lastTimeSpoken[client];
        if (timeSpoken[client] < 0) { timeSpoken[client] = 0; }
        lastTimeSpoken[client] = currentTime;
    }
}

public void OnClientSpeakingEnd(int client)
{
    if (voiceRestrictEnabled && isPlayerSpeaking[client])
    {
        isPlayerSpeaking[client] = false;

        int currentTime = GetTime();
        timeSpoken[client] += currentTime - lastTimeSpoken[client];
        lastTimeSpoken[client] = currentTime;

        if (timeSpoken[client] > 240) {
            SourceComms_SetClientMute(client, true, 240, true, "You have been muted for excessive mic usage for the next 2 minutes.");
        }
    }
}

public Action Command_VoiceRestrict(int client, int args)
{
    if (args < 2) {
        voiceRestrictEnabled = !voiceRestrictEnabled;
    }
    else {
        char param[5];
        GetCmdArg(1, param, sizeof(param));
        if (strcmp(param, "true", false) || param[0] == '1') {
            voiceRestrictEnabled = true;
        }
        else if (strcmp(param, "false", false) || param[0] == '0') {
            voiceRestrictEnabled = false;
        }
        else {
            voiceRestrictEnabled = !voiceRestrictEnabled;
        }
    }
    
    CPrintToChatAll(TTT_MESSAGE ... "{default}Voice Restrict has now been %s.", voiceRestrictEnabled ? "{green}Enabled" : "{red}Disabled");

    return Plugin_Handled;
}
