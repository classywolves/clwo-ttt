#include <colorvariables>

char messages[][255] = {
  "An announcement has appeared."
}

public OnPluginStart() {
  CreateTimer(30.0, Timer_Announcement, _, TIMER_REPEAT);
}

public Action Timer_Announcement(Handle timer) {
  static int currentMessage = 0;

  CPrintToChatAll("[TTT] %s", messages[currentMessage]);

  currentMessage++;
  if (currentMessage >= sizeof(messages)) currentMessage = 0;

  return Plugin_Continue;
}