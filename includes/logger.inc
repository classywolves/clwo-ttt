#if defined _log_processor_included
  #endinput
#endif
#define _log_processor_included

ConVar g_debug;
ConVar g_logLevel;
Handle g_LogForward;
char moduleName[256];
char logName[256];

enum LogLevels {
   Info,
   Success,
   Warn,
   Error
}
 
// Forward usage: Action OnLog(char[] name, int level, int client, const char[] message)

public void OnPluginStart()
{
   g_LogForward = CreateGlobalForward("OnLog", ET_Event, Param_String, Param_Cell, Param_Cell, Param_String);
   g_logLevel = CreateConVar("sm_debug_logLevel", "0", "Set debug log level");
   g_debug = CreateConVar("sm_debug", "", "Set which plugin we are debugging");

   if (g_logLevel != null) {
      g_logLevel.AddChangeHook(OnLevelChange);
      g_debug.AddChangeHook(OnNameChange);
   }
}

public void OnLevelChange(ConVar convar, char[] oldValue, char[] newValue) {
   // I have no idea what you would want to do here, but have at it.
}

public void OnNameChange(ConVar convar, char[] oldValue, char[] newValue) {
   strcopy(moduleName, sizeof(moduleName), oldValue);
}
 
public APLRes AskPluginLoad2(Handle plugin, bool late, char[] error, int err_max)
{
   RegPluginLibrary("logger");
}

public void setLogSource(char name[50]) {
   moduleName = name
}

public Action log(int level, int client, char[] message, any ...) {
   // Format message
   int len = strlen(message) + 255;
   char[] fmtMessage = new char[len];
   VFormat(fmtMessage, len, message, 4);

   char strLevel[5];
   switch (level) {
      case Info: { strLevel = "🔍"; }
      case Success: { strLevel = "√"; }
      case Warn: { strLevel = "‼"; }
      case Error: { strLevel = "×"; }
   }
   // Current debug module
   char time[16], layout[512];
   FormatTime(time, strlen(time), "%T");
   Format(layout, strlen(layout), "[%s] [%7s] %s %s", time, strLevel, fmtMessage);

   Action result;

   Call_StartForward(g_LogForward);
   Call_PushString(moduleName);
   Call_PushCell(level);
   Call_PushCell(client);
   Call_PushString(fmtMessage);
   Call_Finish(result);

   if (result == Plugin_Handled || result == Plugin_Stop) {
      return result;
   }

   // If level is above minimum level log and we're logging this module, log to developers.
   if (level >= g_logLevel.IntValue && strcmp(logName, moduleName, false)) {
      // etc.
   }

   if (strcmp(logName, moduleName, false)) {
      // Log all messages to console.
      PrintToServer(layout);
   }

   // Always log to file.

   return result;
}