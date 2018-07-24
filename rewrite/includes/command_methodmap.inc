#if defined _command_methodmap_included
  #endinput
#endif
#define _command_methodmap_included

#include <dynamic>

methodmap Command < Dynamic
{
  public Command(const char[] command)
  {
    Dynamic dynamic = Dynamic();

    dynamic.SetString("command", command);

    return view_as<Command>(dynamic);
  }

  public void Clean() {
    this.Dispose();
  }
}