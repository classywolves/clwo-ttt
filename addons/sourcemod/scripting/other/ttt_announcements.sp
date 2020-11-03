#include <colorlib>

char messages[][255] = {
  "Check us out today at {purple}https://CLWO.eu/{lightgreen}!",
  "Current Map: {purple}{currentmap}",
  "Come talk to us over at {purple}https://discord.clwo.eu{lightgreen}!",
  "Issue joining a team? Type {purple}!t {lightgreen}in chat."
}

public OnPluginStart() {
  CreateTimer(30.0, Timer_Announcement, _, TIMER_REPEAT);
}

public Action Timer_Announcement(Handle timer) {
  static int currentMessage = 0;

  char message[255], currentMap[255];

  GetCurrentMap(currentMap, sizeof(currentMap));

  strcopy(message, sizeof(message), messages[currentMessage]);
  ReplaceString(message ,sizeof(message), "{currentmap}", currentMap);

  CPrintToChatAll("{orchid}[{green}T{darkred}T{blue}T{orchid}]{lightgreen} %s", message);

  currentMessage++;
  if (currentMessage >= sizeof(messages)) currentMessage = 0;

  return Plugin_Continue;
}