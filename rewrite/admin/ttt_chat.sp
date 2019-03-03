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

    PrintToServer("[CHT] Loaded successfully");
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
