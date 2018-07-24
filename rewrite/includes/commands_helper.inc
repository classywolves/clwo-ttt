#if defined _commands_helper_included
  #endinput
#endif
#define _commands_helper_included

/*
 * Custom methodmaps
 */
#include <player_methodmap>

public Player GetTarget(Player player, int arg) {
  char target[128];

  GetCmdArg(arg, target, sizeof(target));

  return player.TargetOne(target, true);
}

public void GetExtension(char[] message, int messageSize, int position, int args) {
  char buffer[256];

  // They've included a reason!
  GetCmdArg(3, message, messageSize);

  for (int i = 4; i <= args; i++) {
    GetCmdArg(i, buffer, sizeof(buffer));
    Format(message, messageSize, "%s %s", message, buffer);
  }
}