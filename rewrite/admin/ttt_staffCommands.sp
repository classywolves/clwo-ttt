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
#include <datapack>

/*
* Custom methodmaps.
*/
#include <player_methodmap>

public Plugin myinfo = {
    name = "TTT Staff Commands",
    author = "Popey & c0rp3n",
    description = "General staff commands for CLWO TTT.",
    version = "1.0.0",
    url = ""
};

public OnPluginStart() {
    RegisterCmds();
    //HookEvents();
    //InitDBs();

    PrintToServer("[SCM] Loaded successfully");
}

public void RegisterCmds() {
    RegConsoleCmd("sm_bantimes", Command_BanTimes, "List Common Time Lengths.");
    RegConsoleCmd("sm_forcespec", Command_ForceSpectator, "Moves a player to spectator.");
    RegConsoleCmd("sm_reloadplugin", Command_ReloadPlugin, "Reloads the passed plugin.");
    RegConsoleCmd("sm_slaynr", Command_SlayNextRound, "Slay a player before roles are assigned for the next round.");
    RegConsoleCmd("sm_tp", Command_Teleport, "Allows a staff member to teleport another player.");
    RegConsoleCmd("sm_teleport", Command_Teleport, "Allows a staff member to teleport another player.");
}

public Action Command_BanTimes(int client, int args) {
    if (!Player(client).Access(RANK_INFORMER, true)) { return Plugin_Handled; }

    CPrintToChat(client, "{purple}[TTT] {yellow}The following are some common ban times:");
    CPrintToChat(client, "{purple}[TTT] {yellow} - {blue}1 {yellow}hour  --> {blue}60    {yellow}minutes");
    CPrintToChat(client, "{purple}[TTT] {yellow} - {blue}1 {yellow}day   --> {blue}1440  {yellow}minutes");
    CPrintToChat(client, "{purple}[TTT] {yellow} - {blue}2 {yellow}days  --> {blue}2880  {yellow}minutes");
    CPrintToChat(client, "{purple}[TTT] {yellow} - {blue}1 {yellow}week  --> {blue}10080 {yellow}minutes");
    CPrintToChat(client, "{purple}[TTT] {yellow} - {blue}1 {yellow}month --> {blue}40320 {yellow}minutes");

    return Plugin_Handled;
}

public Action Command_ForceSpectator(int client, int args) {
    Player player = Player(client);
    if (!player.Access(RANK_INFORMER, true)) { return Plugin_Handled; }

    if (args < 1) {
        player.Error("Usage: sm_forcespec <target>.");
        return Plugin_Handled;
    }

    char buffer[MAX_NAME_LENGTH];
    GetCmdArg(1, buffer, MAX_NAME_LENGTH);
    Player target = player.TargetOne(buffer, true);
    if (!target.ValidClient) { return Plugin_Handled; }

    target.Team = CS_TEAM_SPECTATOR;
    CPrintToChat(target.Client, "{purple}[TTT] {yellow}You were forced to spectator by %N.", client);

    return Plugin_Handled;
}

public Action Command_ReloadPlugin(int client, int args) {
    Player player = Player(client);
    if (!player.Access(RANK_ADMIN, true)) { return Plugin_Handled; }

    if (args < 1) {
        player.Error("Usage: sm_reload <plugin>.");
        return Plugin_Handled;
    }

    char plugin[128]
    GetCmdArg(1, plugin, sizeof(plugin));

    char load[1024], reload[1024];
    ServerCommandEx(reload, sizeof(reload), "sm plugins reload %s", plugin);
    PrintToConsole(client, reload);
    ServerCommandEx(load, sizeof(load), "sm plugins load %s", plugin);
    PrintToConsole(client, load);
    CPrintToChat(client, "{purple}[TTT] {yellow}Reloaded {green}%s {yellow}successfully!", plugin);

    return Plugin_Handled;
}

public Action Command_SlayNextRound(int client, int args) {
    Player player = Player(client);
    if (!player.Access(RANK_INFORMER, true)) {
        return Plugin_Handled;
    }

    if (args < 1) {
        player.Error("Invalid Usage: sm_slaynr <target name>");
        return Plugin_Handled;
    }

    char targetName[128];
    GetCmdArg(1, targetName, sizeof(targetName));
    Player playerTarget = player.TargetOne(targetName);

    TTT_AddRoundSlays(playerTarget.Client, 1, false);

    return Plugin_Handled;
}

public Action Command_Teleport(int client, int args) {
    Player player = Player(client);
    if (!player.Access(RANK_INFORMER, true)) { return Plugin_Handled; }

    if (args < 1) {
        player.Error("Usage: sm_teleport <target> [player].");
        return Plugin_Handled;
    }

    char buffer[MAX_NAME_LENGTH];
    GetCmdArg(1, buffer, MAX_NAME_LENGTH);
    Player target = player.TargetOne(buffer, true);
    if (!target.ValidClient) { return Plugin_Handled; }

    float pos[3];
    if (args == 1) {
        if (!player.RayTrace(pos))
        {
            player.Error("Please look at a valid location.");
            return Plugin_Handled;
        }
    }
    else {
        GetCmdArg(2, buffer, MAX_NAME_LENGTH);
        Player recipient = player.TargetOne(buffer, true);
        if (!recipient.ValidClient) { return Plugin_Handled; }

        recipient.Pos(pos);
    }

    target.SetPos(pos);
    CPrintToChatAll("{purple}[TTT] {blue}%N {yellow}teleported {blue}%N.", player.Client, target.Client);

    return Plugin_Handled;
}
