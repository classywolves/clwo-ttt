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

public OnPluginStart()
{
    LoadTranslations("common.phrases");

    RegisterCmds();

    PrintToServer("[CHT] Loaded successfully");
}

public void RegisterCmds()
{
    RegConsoleCmd("sm_msg", Command_Msg, "sm_msg <name or #userid> <message> - sends private message");
}

public Action CP_OnChatMessage(int& author, ArrayList recipients, char[] flagstring, char[] name, char[] message, bool& processcolors, bool& removecolors)
{
    if (message[0] != '@') // Not staff / all say or pm.
    {
        char buffer[64];
        char teamColor[6];
        char staffTag[64];

        GetRankName(GetPlayerRank(author), buffer, USER_RANK_CHAT_NAME);
        if (buffer[0] != 0x00)
        {
            Format(staffTag, 64, "{default}[{blue}%s{default}]", buffer);
        }

        switch (GetClientTeam(author))
        {
            case CS_TEAM_SPECTATOR:
            {
                Format(teamColor, 6, "team0");
            }
            case CS_TEAM_T:
            {
                Format(teamColor, 6, "team1");
            }
            case CS_TEAM_CT:
            {
                Format(teamColor, 6, "team1");
            }
        }

        // Format message name
        Format(name, MAXLENGTH_NAME, "%s {%s}%s", staffTag, teamColor, name);
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

	char text[192], arg[64], message[192];
	GetCmdArgString(text, sizeof(text));

	int len = BreakString(text, arg, sizeof(arg));
	BreakString(text[len], message, sizeof(message));

	int target = FindTarget(client, arg, true, false);

	if (target == -1)
		return Plugin_Handled;

	SendPrivateChat(client, target, message);

	return Plugin_Handled;
}

void SendPrivateChat(int client, int target, const char[] message)
{
	if (!client)
	{
		PrintToServer("(Private to %N) %N: %s", target, client, message);
	}
	else if (target != client)
	{
		PrintToChat(client, " \x01\x0B\x04%t: \x01%s", "Private say to", target, client, message);
	}

	PrintToChat(target, " \x01\x0B\x04%t: \x01%s", "Private say to", target, client, message);
	LogAction(client, target, "\"%L\" triggered sm_psay to \"%L\" (text %s)", client, target, message);
}
