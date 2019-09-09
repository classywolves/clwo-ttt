#if defined _ttt_targeting_included
#endinput
#endif
#define _ttt_targeting_included

#include <ttt_messages>

stock int TTT_Target(char[] target, int client, bool respond = true, bool alive = false, bool immunity = false)
{
    int targets[MAXPLAYERS + 1];
    int filter = (alive ? COMMAND_FILTER_ALIVE : 0) | (immunity ? 0 : COMMAND_FILTER_NO_IMMUNITY) | COMMAND_FILTER_NO_MULTI;
    char targetName[MAX_NAME_LENGTH];
    bool translation;

    int result = ProcessTargetString(target, client, targets, sizeof(targets), filter, targetName, sizeof(targetName), translation);

    if (result == 1) {
        return targets[0];
    }

    if (respond) {
        if (result == -1) TTT_Error(client, "No targets were found.");
        if (result == -2) TTT_Error(client, "Target is not alive.");
        if (result == -3) TTT_Error(client, "Target is not dead.");
        if (result == -4) TTT_Error(client, "Target is not in game.");
        if (result == -5) TTT_Error(client, "Target is immune.");
        if (result == -6) TTT_Error(client, "Target is not human.");
        if (result == -7) TTT_Error(client, "Ambiguous target string.");
    }

    return result;
}

stock bool TTT_Targets(int[] targets, int admin, char[] target, bool respond = true, bool alive = false, bool immunity = false)
{
    int filter = (alive ? COMMAND_FILTER_ALIVE : 0) | (immunity ? 0 : COMMAND_FILTER_NO_IMMUNITY);
    char targetName[MAX_NAME_LENGTH];
    bool translation;

    int result = ProcessTargetString(target, admin, targets, sizeof(targets), filter, targetName, sizeof(targetName), translation);

    if (result == 1) {
        return true;
    }

    if (respond) {
        if (result == -1) TTT_Error(admin, "No targets were found.");
        if (result == -2) TTT_Error(admin, "Target is not alive.");
        if (result == -3) TTT_Error(admin, "Target is not dead.");
        if (result == -4) TTT_Error(admin, "Target is not in game.");
        if (result == -5) TTT_Error(admin, "Target is immune.");
        if (result == -6) TTT_Error(admin, "Target is not human.");
        if (result == -7) TTT_Error(admin, "Ambiguous target string.");
    }

    return result > 0;
}