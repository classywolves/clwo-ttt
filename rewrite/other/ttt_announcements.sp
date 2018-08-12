#include <colorvariables>

char messages[][255] = {
  "Check us out today at {purple}https://CLWO.eu{/lightgreen}!.",
  "Current Map: {purple}{currentmap}",
  "Come talk to us over at {purple}https://discord.clwo.eu{lightgreen}!",
  "Issue joining a team? Do {purple}!t {lightgreen}in chat.",
  "Come talk to us over at {purple}https://discord.clwo.eu{lightgreen}!"
}

public OnPluginStart() {
  CreateTimer(30.0, Timer_Announcement, _, TIMER_REPEAT);
}

public Action Timer_Announcement(Handle timer) {
  static int currentMessage = 0;

  CPrintToChatAll("{orchid}[{green}T{darkred}T{blue}T{orchid}]{lightgreen} %s", messages[currentMessage]);

  currentMessage++;
  if (currentMessage >= sizeof(messages)) currentMessage = 0;

  return Plugin_Continue;
}