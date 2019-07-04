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
#include <colorvariables>
#include <generics>
#include <chat-processor>
#include <ttt_ranks>

public Plugin myinfo =
{
    name = "CLWO Chat",
    author = "c0rp3n",
    description = "Processes chat for CLWO TTT & Course.",
    version = "1.0.0",
    url = ""
};

int g_iReplyTo[MAXPLAYERS + 1];

public OnPluginStart()
{
    LoadTranslations("common.phrases");

    RegisterCmds();

    PrintToServer("[CHT] Loaded successfully");
}

public void RegisterCmds()
{
    RegConsoleCmd("sm_msg", Command_Msg, "sm_msg <name or #userid> <message> - sends private message");
    RegConsoleCmd("sm_r", Command_Reply, "sm_reply <message> - replies to previous private message");
    RegConsoleCmd("sm_reply", Command_Reply, "sm_reply <message> - replies to previous private message");
}

public Action CP_OnChatMessage(int& author, ArrayList recipients, char[] flagstring, char[] name, char[] message, bool& processcolors, bool& removecolors)
{
    if (message[0] != '@') // Not staff / all say or pm.
    {
        char buffer[16];
        char teamColor[6];
        char staffTag[64];

        int rank = GetPlayerRank(author);
        if (rank > RANK_PLEB)
        {
            GetRankTag(rank, buffer);
            Format(staffTag, 64, "{default}[{lime}%s{default}]", buffer);
        }

        switch (GetClientTeam(author))
        {
            case CS_TEAM_SPECTATOR:
            {
                Format(teamColor, 12, "grey2");
            }
            case CS_TEAM_T, CS_TEAM_CT:
            {
                Format(teamColor, 12, "teamcolor");
            }
        }

        //Remove colors from message
        CRemoveColors(message, _CV_MAX_MESSAGE_LENGTH);
        RemoveHexColors(message, message, _CV_MAX_MESSAGE_LENGTH);

        //Remove colors from name
        CRemoveColors(name, MAX_NAME_LENGTH);

        // Format message name
        Format(name, MAX_NAME_LENGTH, "%s {%s}%s{default}", staffTag, teamColor, name);
    }

    return Plugin_Changed;
}

public Action Command_Msg(int client, int args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_msg <name or #userid> <message>");
		return Plugin_Handled;
	}

	char text[192], arg[64];
	GetCmdArgString(text, sizeof(text));

	int len = BreakString(text, arg, sizeof(arg));
	
	int target = FindTarget(client, arg, true, false);

	if (target == -1)
		return Plugin_Handled;

	SendPrivateChat(client, target, text[len]);

	return Plugin_Handled;
}

public Action Command_Reply(int client, int args)
{
    if (args < 1)
    {
        ReplyToCommand(client, "[SM] Usage: sm_reply <message>");
        return Plugin_Handled;  
    }
    int target = g_iReplyTo[client];
    if (!IsValidClient(target)) {
        ReplyToCommand(client, "[SM] No one to reply to.");
        return Plugin_Handled;
    }

    char text[256];
    GetCmdArgString(text, sizeof(text));

    SendPrivateChat(client, target, text);
    
    return Plugin_Handled;      
}


void SendPrivateChat(int client, int target, char[] message)
{
    //Remove colors from message
    CRemoveColors(message, _CV_MAX_MESSAGE_LENGTH);
    RemoveHexColors(message, message, _CV_MAX_MESSAGE_LENGTH);

    //Get names and remove colors
    char clientName[MAX_NAME_LENGTH], targetName[MAX_NAME_LENGTH];
    GetClientName(client, clientName, sizeof(clientName));
    CRemoveColors(clientName, sizeof(clientName));

    GetClientName(target, targetName, sizeof(targetName));
    CRemoveColors(targetName, sizeof(targetName));

    if (!client)
    {
        PrintToServer("(Private to %N) %N: %s", targetName, client, message);
    }
    else if (target == client)
    {
        CPrintToChat(client, "[{grey}me{gold} -> {grey}me{default}] %s", message);
    } else {
        g_iReplyTo[target] = client;
        CPrintToChat(target, "[{grey}%s{gold} -> {grey}me{default}] %s", clientName, message);
        CPrintToChat(client, "[{grey}me{gold} -> {grey}%s{default}] %s", targetName, message);
    }

    LogAction(client, target, "\"%L\" triggered sm_psay to \"%L\" (text %s)", client, target, message);
}

stock RemoveHexColors(const char[] input, char[] output, int size) {
	int x = 0;
	for (int i=0; input[i] != '\0'; i++) {

		if (x+1 == size) {
			break;
		}

		char character = input[i];

		if (character > 0x10) {
			output[x++] = character;
		}
	}

	output[x] = '\0';
}