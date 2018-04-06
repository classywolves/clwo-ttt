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
  Player player = Player(client);

  // Player is not tmod or above AND is not an active informer.
  if (!player.Access("tmod") && !player.ActiveInformer()) {
    player.Error("You do not have access to this command!");
    return Plugin_Handled;
  }

  if (args < 1) {
    player.Error("Invalid Usage: /imute <target> <time> <reason>")
    return Plugin_Handled;
  }

  char reason[255], mini[255], arg1[128], arg2[128], buffer[128];
  int time;

  GetCmdArg(1, arg1, sizeof(arg1));
  Player target = player.TargetOne(arg1, true)

  if (target.Client == -1) {
    return Plugin_Handled;
  }

  if (target.Muted) {
    player.Error("This player is already muted!")
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
      player.Error("Invalid time frame entered.");
      return Plugin_Handled;
    }

    if (time > 60) {
      time = 60;
      player.Error("The time has been reduced to 60 minutes, the maximum amount of time an informer can mute for.");
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

  target.Mute(time, reason);
  if (args >= 3) {
    CPrintToChatAll("{purple}[TTT] {yellow}%N has been muted for %i minutes by %N due to '%s'", target.Client, time, player.Client, mini);
  } else {
    CPrintToChatAll("{purple}[TTT] {yellow}%N has been muted for %i minutes by %N", target.Client, time, player.Client);
  }

  return Plugin_Handled;
}

public Action Command_InformerGag(int client, int args) {
  // Usage is "/igag <target> <time> <reason>"
  Player player = Player(client);

  // Player is not tmod or above AND is not an active informer.
  if (!player.Access("tmod") && !player.ActiveInformer()) {
    player.Error("You do not have access to this command!");
    return Plugin_Handled;
  }

  if (args < 1) {
    player.Error("Invalid Usage: /igag <target> <time> <reason>")
    return Plugin_Handled;
  }

  char reason[255], mini[255], arg1[128], arg2[128], buffer[128];
  int time;

  GetCmdArg(1, arg1, sizeof(arg1));
  Player target = player.TargetOne(arg1, true)

  if (target.Client == -1) {
    return Plugin_Handled;
  }

  if (target.Gagged) {
    player.Error("This player is already gagged!")
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
      player.Error("Invalid time frame entered.");
      return Plugin_Handled;
    }

    if (time > 60) {
      time = 60;
      player.Error("The time has been reduced to 60 minutes, the maximum amount of time an informer can gag for.");
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

  target.Gag(time, reason);
  if (args >= 3) {
    CPrintToChatAll("{purple}[TTT] {yellow}%N has been gagged for %i minutes by %N due to '%s'", target.Client, time, player.Client, mini);
  } else {
    CPrintToChatAll("{purple}[TTT] {yellow}%N has been gagged for %i minutes by %N", target.Client, time, player.Client);
  }

  return Plugin_Handled;
}

public Action Command_InformerKick(int client, int args) {
  // Usage is "/ikick <target> <reason>"
  Player player = Player(client);

  // Player is not tmod or above AND is not an active informer.
  if (!player.Access("tmod") && !player.ActiveInformer()) {
    player.Error("You do not have access to this command!");
    return Plugin_Handled;
  }

  if (args < 1) {
    player.Error("Invalid Usage: /ikick <target> <reason>")
    return Plugin_Handled;
  }

  char reason[255], mini[255], arg1[128], buffer[128];

  GetCmdArg(1, arg1, sizeof(arg1));
  Player target = player.TargetOne(arg1, true)

  if (target.Client == -1) {
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

  target.Kick(reason);
  if (args >= 3) {
    CPrintToChatAll("{purple}[TTT] {green}%N {yellow}has been kicked by {green}%N{yellow} %s", target.Client, player.Client, mini);
  } else {
    CPrintToChatAll("{purple}[TTT] {green}%N {yellow}has been kicked by {green}%N", target.Client, player.Client);
  }

  return Plugin_Handled;
}