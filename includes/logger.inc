#if defined _log_processor_included
  #endinput
#endif
#define _log_processor_included

#include <player_methodmap>
#include <ttt_helpers>

ConVar g_debug;
ConVar g_logLevel;
Handle g_LogForward;

char ourName[256];
char debugName[256];

Handle logFile;

bool init = false;

enum LogLevels {
   Info,
   Success,
   Warn,
   Error
}
 
// Forward usage: Action OnLog(char[] name, int level, int client, const char[] message)

public void LogOnPluginStart()
{
   char folder[1024];
   BuildPath(Path_SM, folder, PLATFORM_MAX_PATH, "/logs/modules");
   if (!DirExists(folder)) {
      CreateDirectory(folder, 493);
   }

   cookie_player_verbose_log = RegClientCookie("player_verbose_log", "Log verbose to chat.", CookieAccess_Public);
   SetCookiePrefabMenu(cookie_player_verbose_log, CookieMenu_OnOff_Int, "Log verbose to chat.");
   g_LogForward = CreateGlobalForward("OnLog", ET_Event, Param_String, Param_Cell, Param_String);
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
   strcopy(debugName, sizeof(debugName), oldValue);
}
 
public APLRes AskPluginLoad2(Handle plugin, bool late, char[] error, int err_max)
{
   RegPluginLibrary("logger");
}

public void setLogSource(char[] name) {
   strcopy(ourName, sizeof(ourName), name);
   LogOnPluginStart();

   char file[1024];
   BuildPath(Path_SM, file, PLATFORM_MAX_PATH, "/logs/modules/%s", name);
   if (init) { logFile.Close(); }
   logFile = OpenFile(file, "a");

   init = true;
}

public Action log(LogLevels level, char[] message, any ...) {
   // Format message
   int len = strlen(message) + 255;
   char[] fmtMessage = new char[len];
   VFormat(fmtMessage, len, message, 3);

   char strLevel[5], strColour[20], wordLevel[32];
   switch (level) {
      case Info: { strLevel = "i"; strColour = "{grey}"; wordLevel = "6"; }
      case Success: { strLevel = "√"; strColour = "{green}"; wordLevel = "5"; }
      case Warn: { strLevel = "‼"; strColour = "{yellow}"; wordLevel = "4"; }
      case Error: { strLevel = "×"; strColour = "{red}"; wordLevel = "3"; }
   }
   // Current debug module
   char time[16], ltime[48], layout[512], clayout[768], flayout[768];
   FormatTime(time, sizeof(time), "%T");
   FormatTime(ltime, sizeof(ltime), "%F %T");

   Format(layout, sizeof(layout), "[%s] [%7s] %s %s", time, ourName, strLevel, fmtMessage);
   Format(flayout, sizeof(flayout), "%s - %s - %s - %s", ltime, ourName, wordLevel, fmtMessage);
   if (level != Warn) {
      Format(clayout, sizeof(clayout), "{purple}[%s] %s%s %s", ourName, strColour, strLevel, fmtMessage);
   } else {
      Format(clayout, sizeof(clayout), "{purple}[%s] %s! %s", ourName, strColour, fmtMessage);
   }

   if (!init) {
      PrintToServer("Error, you have not initialised this instance of logger, message: %s", layout);
      return Plugin_Handled;
   }

   Action result;

   Call_StartForward(g_LogForward);
   Call_PushString(ourName);
   Call_PushCell(level);
   Call_PushString(fmtMessage);
   Call_Finish(result);

   if (result == Plugin_Handled || result == Plugin_Stop) {
      return result;
   }

   // Print to file.
   WriteFileLine(logFile, flayout);

   if (strcmp(ourName, debugName, false) || level >= Warn) {
      // Log every level to the server.
      PrintToServer(layout);

      if (view_as<int>(level) >= g_logLevel.IntValue) {
         // Log to clients consoles.
         LoopValidClients(i) {
            if (Player(i).dev) {
               PrintToConsole(i, layout);

               if (Player(i).cookie_cache && Player(i).verbose_log) {
                  CPrintToChat(i, clayout);
               }
            }
         }
      }
   }

   return result;
}