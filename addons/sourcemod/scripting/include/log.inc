#if defined _log_included
  #endinput
#endif
#define _log_included

#include <dynamic>
#include <generics>

enum LogLevel { Info, Success, Warn, Error };
char consoleIcons[][] = { "i", "√", "‼", "×" };
char chatIcons[][] = { "i", "√", "!", "×" }; // Chat supports a few less characters
char chatColour[][] = { "{grey}", "{green}", "{yellow}", "{red}" };
char logLevel[][] = { "3", "4", "5", "6" }; // Used for logstash levels

methodmap Logger < Dynamic {
  public Logger() {
    Dynamic dynamic = Dynamic();

    return view_as<Logger>(dynamic);
  }

  public void name(char logger_name[32]) {
    this.SetString("name", logger_name);

    char file[1024];
    BuildPath(Path_SM, file, PLATFORM_MAX_PATH, "/logs/modules/%s", logger_name);

    this.SetHandle("file", OpenFile(file, "a"));
  }

  public void _logToFile(LogLevel level, char[] str) {
    // Check if we're all setup
    Handle logFile = this.GetHandle("file");

    if (!IsValidHandle(logFile)) {
      PrintToServer("We do not have a valid logFile handle.");
      return;
    }

    // Get logfile name
    char name[32];
    this.GetString("name", name, sizeof(name));

    // Get long time format
    char time[48];
    FormatTime(time, sizeof(time), "%F %T");

    // Format it into a logstash compatible format
    char layout[768];
    Format(layout, sizeof(layout), "%s - %s - %s - %s", time, name, logLevel[level], str);

    // Print to the file
    WriteFileLine(logFile, layout);
  }

  public void _logToConsole(LogLevel level, char[] str, int client = 0) {
    // Get short time format
    char time[16];
    FormatTime(time, sizeof(time), "%T");

    // Get logfile name
    char name[32];
    this.GetString("name", name, sizeof(name));

    // Format it into a logstash compatible format
    char layout[512];
    Format(layout, sizeof(layout), "[%s] [%7s] %s %s", time, name, consoleIcons[level], str);

    // Print to the server
    if (client) {
      PrintToConsole(client, layout);
    } else {
      PrintToServer(layout);
    }
  }

  public void _logToPlayer(int client, LogLevel level, char[] str) {
    // Get short time format
    char time[16];
    FormatTime(time, sizeof(time), "%T");

    // Get logfile name
    char name[32];
    this.GetString("name", name, sizeof(name));

    // Format it into a logstash compatible format
    char layout[512];
    Format(layout, sizeof(layout), "{purple}[%s] %s%s %s", name, chatColour[level], chatIcons[level], str);

    // Print to the client
    //PrintToServer(layout);
  }

  public void _log(LogLevel level, char[] str, int len) {
    // Always log to file
    this._logToFile(level, str);

    if (level >= Warn) {
      // Log to console
      this._logToConsole(level, str);

      // Log to players console
      for (int client = 1; client < MaxClients; client++) {
        if (IsValidClient(client) && CheckCommandAccess(client, "log", ADMFLAG_BAN)) {
          this._logToConsole(level, str, client);
        }
      }
    }
  }

  public void Log(const char[] str, any ...) {
    int len = strlen(str) + 255;
    char[] fStr = new char[len];
    VFormat(fStr, len, str, 2);

    this._log(Info, fStr, strlen(fStr));
  }

  public void Success(const char[] str, any ...) {
    int len = strlen(str) + 255;
    char[] fStr = new char[len];
    VFormat(fStr, len, str, 2);

    this._log(Success, fStr, strlen(fStr));
  }

  public void Warn(const char[] str, any ...) {
    int len = strlen(str) + 255;
    char[] fStr = new char[len];
    VFormat(fStr, len, str, 2);

    this._log(Warn, fStr, strlen(fStr));
  }

  public void Error(const char[] str, any ...) {
    int len = strlen(str) + 255;
    char[] fStr = new char[len];
    VFormat(fStr, len, str, 2);

    this._log(Error, fStr, strlen(fStr));
  }
}