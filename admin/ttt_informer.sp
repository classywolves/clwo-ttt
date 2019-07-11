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
#include <sourcecomms>
#include <ttt_messages>
#include <ttt_ranks>
#include <ttt_targeting>
#include <generics>

public OnPluginStart()
{
  RegisterCmds();
  HookEvents();
  InitDBs();

  LoadTranslations("common.phrases");
  
  PrintToServer("[INF] Loaded succcessfully");
}

public void RegisterCmds() {
  RegConsoleCmd("sm_imute", Command_InformerMute, "Mute, but for informers!");
  RegConsoleCmd("sm_igag", Command_InformerGag, "Gag, but for informers!");
  RegConsoleCmd("sm_ikick", Command_InformerKick, "Kick, but for informers!");
}

public void HookEvents() {
}

public void InitDBs() {
}

public Action Command_InformerMute(int client, int args) {
  // Usage is "/imute <target> <time> <reason>"
  // Player is not tmod or above AND is not an active informer.
  if (GetPlayerRank(client) != RANK_INFORMER) {
    TTT_Error(client, "You do not have access to this command!");
    return Plugin_Handled;
  }

  if (args < 1) {
    TTT_Usage(client, "sm_imute <target> [time] <reason>");
    return Plugin_Handled;
  }

  char reason[255], mini[255], arg1[128], arg2[128], buffer[128];
  int time;

  GetCmdArg(1, arg1, sizeof(arg1));
  int target = TTT_Target(arg1, client, true, false, false);

  if (target == -1) {
    return Plugin_Handled;
  }

  //Check if client has not been muted already
  if (SourceComms_GetClientMuteType(target) != bNot) {
    TTT_Error(client, "This player is already muted!");
    return Plugin_Handled;
  }

  if (args == 1) {
    // We do not have a reason or a time, default to empty string and 5 minutes.
    time = 5;
    reason = "";
  }

  if (args >= 2) {
    GetCmdArg(2, arg2, sizeof(arg2));
    time = StringToInt(arg2);

    if (time < 1) {
      TTT_Error(client, "Invalid time frame entered.");
      return Plugin_Handled;
    }

    if (time > 60) {
      time = 60;
      TTT_Error(client, "The time has been reduced to 60 minutes, the maximum amount of time an informer can mute for.");
    }
  }

  if (args >= 3) {
    // They've included a reason!
    GetCmdArg(3, reason, sizeof(reason));

    for (int i = 4; i <= args; i++) {
      GetCmdArg(i, buffer, sizeof(buffer));
      Format(reason, sizeof(reason), "%s %s", reason, buffer);
    }

    Format(mini, sizeof(mini), "%s", reason);
    Format(reason, sizeof(reason), "%s - ", reason);
  }

  Format(reason, sizeof(reason), "%sMuted by %L", reason, client);

  SourceComms_SetClientMute(target, true, time, true, reason);
  if (args >= 3) {
    TTT_MessageAll("{yellow}%N {default}has been muted for {orange}%i {default}minutes by {yellow}%N {default}due to {grey}'%s'", target, time, client, mini);
  } else {
    TTT_MessageAll("{yellow}%N {default}has been muted for {orange}%i {default}minutes by {yellow}%N", target, time, client);
  }

  return Plugin_Handled;
}

public Action Command_InformerGag(int client, int args) {
  // Usage is "/igag <target> <time> <reason>"
  // Player is not tmod or above AND is not an active informer.
  if (GetPlayerRank(client) != RANK_INFORMER) {
    TTT_Error(client, "You do not have access to this command!");
    return Plugin_Handled;
  }

  if (args < 1) {
    TTT_Usage(client, "sm_igag <target> [time] <reason>");
    return Plugin_Handled;
  }

  char reason[255], mini[255], arg1[128], arg2[128], buffer[128];
  int time;

  GetCmdArg(1, arg1, sizeof(arg1));
  int target = TTT_Target(arg1, client, true, false, false);

  if (target == -1) {
    return Plugin_Handled;
  }

  //Check if target is not gagged already
  if (SourceComms_GetClientGagType(target) != bNot) {
    TTT_Error(client, "This player is already gagged!");
    return Plugin_Handled;
  }

  if (args == 1) {
    // We do not have a reason or a time, default to empty string and 5 minutes.
    time = 5;
    reason = "";
  }

  if (args >= 2) {
    GetCmdArg(2, arg2, sizeof(arg2));
    time = StringToInt(arg2);

    if (time < 1) {
      TTT_Error(client, "Invalid time frame entered.");
      return Plugin_Handled;
    }

    if (time > 60) {
      time = 60;
      TTT_Error(client, "The time has been reduced to 60 minutes, the maximum amount of time an informer can gag for.");
    }
  }

  if (args >= 3) {
    // They've included a reason!
    GetCmdArg(3, reason, sizeof(reason));

    for (int i = 4; i <= args; i++) {
      GetCmdArg(i, buffer, sizeof(buffer));
      Format(reason, sizeof(reason), "%s %s", reason, buffer);
    }

    Format(mini, sizeof(mini), "%s", reason);
    Format(reason, sizeof(reason), "%s - ", reason);
  }

  Format(reason, sizeof(reason), "%sGagged by %L", reason, client);

  SourceComms_SetClientGag(target, true, time, true, reason);
  if (args >= 3) {
    TTT_MessageAll("{yellow}%N {default}has been gagged for {orange}%i {default}minutes by {yellow}%N {default}due to {grey}'%s'", target, time, client, mini);
  } else {
    TTT_MessageAll("{yellow}%N {default}has been gagged for {orange}%i {default}minutes by {yellow}%N", target, time, client);
  }

  return Plugin_Handled;
}

public Action Command_InformerKick(int client, int args) {
  // Usage is "/ikick <target> <reason>"
  // Player is not tmod or above AND is not an active informer.
  if (GetPlayerRank(client) != RANK_INFORMER) {
    TTT_Error(client, "You do not have access to this command!");
    return Plugin_Handled;
  }

  if (args < 1) {
    TTT_Usage(client, "sm_ikick <target> <reason>");
    return Plugin_Handled;
  }

  char reason[255], mini[255], arg1[128], buffer[128];

  GetCmdArg(1, arg1, sizeof(arg1));
  int target = TTT_Target(arg1, client, true, false, false);

  if (target == -1) {
    return Plugin_Handled;
  }

  if (args == 1) {
    // No reason given.
    reason = "";
  }

  if (args >= 2) {
    // They've included a reason!
    GetCmdArg(2, reason, sizeof(reason));

    for (int i = 3; i <= args; i++) {
      GetCmdArg(i, buffer, sizeof(buffer));
      Format(reason, sizeof(reason), "%s %s", reason, buffer);
    }

    Format(mini, sizeof(mini), "%s", reason);
    Format(reason, sizeof(reason), "%s - ", reason);
  }

  Format(reason, sizeof(reason), "%sKicked by %L", reason, client);

  KickClient(target, reason);
  if (args >= 3) {
    TTT_MessageAll("{yellow}%N {default}has been kicked by {yellow}%N {default}due to {grey}'%s'", target, client, mini);
  } else {
    TTT_MessageAll("{yellow}%N {default}has been kicked by {yellow}%N", target, client);
  }

  return Plugin_Handled;
}
