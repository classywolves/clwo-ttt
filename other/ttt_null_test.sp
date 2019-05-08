#include <sourcemod>

public OnPluginStart() {
  PrintToServer("Does INVALID_HANDLE == null: %b", INVALID_HANDLE == null)
}