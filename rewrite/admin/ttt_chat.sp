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
#include <chat-processor>
#include <ttt_ranks>
#include <commands_helper>

/*
 * Custom methodmaps
 */
#include <player_methodmap>

public Plugin myinfo =
{
	name = "TTT Chat",
	author = "Popey & iNilo & Corpen",
	description = "TTT Custom rank and access system.",
	version = "1.0.0",
	url = ""
};

public OnPluginStart() {
  RegisterCmds();

  PrintToServer("[CHT] Loaded successfully");
}

public void RegisterCmds() {
  AddCommandListener(Command_PSay, "sm_psay");
  AddCommandListener(Command_PSay, "sm_msg");
}

public Action CP_OnChatMessage(int& author, ArrayList recipients, char[] flagstring, char[] name, char[] message, bool& processcolors, bool& removecolors) {
  Player player = Player(author);

  if (isPM(message)) {
    int separation = FindCharInString(message, ' ');
    message[separation] = '\0';

    Player target = player.TargetOne(message[2], true);

    if (target.Client < 1) {
      return Plugin_Stop;
    }

    sendPM(player, target, message[separation + 1]);
    return Plugin_Stop;
  }

  if (isAll(message)) {
    isTeamChat(flagstring) || !player.Staff ? sendAdmin(player, message[1]) : sendAll(player, message[1]);
    return Plugin_Stop;
  }

  char deadTag[64], teamTag[64], rankTag[64], teamColour[64];

  if (!player.Alive) Format(deadTag, sizeof(deadTag), "[DEAD]");
  if (isTeamChat(flagstring)) Format(teamTag, sizeof(teamTag), "[{grey}TEAM{default}]")
  getRankTag(player, rankTag);

  if (player.Terrorist) teamColour = "{team1}";
  else if (player.Spectator) teamColour = "{purple}";
  else if (player.CounterTerrorist) teamColour = "{team2}";

  Format(name, MAXLENGTH_NAME, "%s%s%s%s%s", deadTag, teamTag, rankTag, teamColour, name);

  return Plugin_Changed;
}

public Action Command_PSay(int client, const char[] command, int args) {
  Player player = Player(client);

  if (args < 2) {
    player.Error("Invalid Usage: /msg <target> <msg...>");
    return Plugin_Handled;
  }

  Player target = GetTarget(player, 1);

  if (target.Client < 1) {
    return Plugin_Handled;
  }

  char message[512];
  GetExtension(message, sizeof(message), 2, args);

  sendPM(player, target, message);

  return Plugin_Handled;
}

public void getRankTag(Player player, char rankTag[64]) {
  char rankName[64];

  player.GetRankName(rankName, USER_RANK_CHAT_NAME);

  if (rankName[0] != '\0') Format(rankTag, sizeof(rankTag), "{default}[{blue}%s{default}]", rankName);
}

public bool isPM(char[] message) {
  return message[0] == '@' && message[1] == '@';
}

public bool isAll(char[] message) {
  return message[0] == '@'
}

public bool isTeamChat(char[] flagstring) {
  return StrContains(flagstring, "team", false) != -1 ||  StrContains(flagstring, "Cstrike_Chat_CT", false) != -1 ||  StrContains(flagstring, "Cstrike_Chat_T", false) != -1
}

public void sendPM(Player author, Player target, char[] message) {
  char targetName[64], authorName[64];

  target.Name(targetName);
  author.Name(authorName);

  CPrintToChat(target.Client, "[{grey}%s {default}-> {grey}me{default}]: {grey}%s", targetName, message);
  CPrintToChat(author.Client, "[{grey}me {default}-> {grey}%s{default}]: {grey}%s", authorName, message);
}

public void sendAdmin(Player author, char[] message) {
  char rankTag[64], authorName[64], fMessage[512];
  getRankTag(author, rankTag)
  author.Name(authorName);

  Format(fMessage, sizeof(fMessage), "[ADMIN]%s%s: {grey}%s", rankTag, authorName, message)


  LoopStaff(client) {
    CPrintToChat(client, fMessage);
  }
}

public void sendAll(Player author, char[] message) {
  char rankTag[64], authorName[64], fMessage[512];
  getRankTag(author, rankTag)
  author.Name(authorName);

  Format(fMessage, sizeof(fMessage), "%s{purple}%s{default}: %s", rankTag, authorName, message)

  LoopValidClients(client) {
    CPrintToChat(client, fMessage)
  }
}
