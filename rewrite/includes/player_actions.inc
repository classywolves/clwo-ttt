#include <dynamic>

typeset ActionCallback {
  function void(float actions[2]);
}

methodmap PlayerActions < Dynamic {
  public PlayerActions(char steam_id[64]) {
    Dynamic actionInfo = Dynamic();

    actionInfo.SetString("SteamID", steam_id, 64);

    return view_as<Actions>(actionInfo);
  }

  property int GoodActions {
    public get() {
      char steam_id[64];

      this.GetString("SteamID", steam_id, 64);

      return this.GetInt("GoodActions");
    }

    public set(int goodActions) {
      this.SetInt("GoodActions", goodActions);
    }
  }

  property int BadActions {
    public get() {
      return this.GetInt("BadActions");
    }

    public set(int badActions) {
      this.SetInt("BadActions", badActions);
    }
  }

  public void Save(ActionCallback callback) {
    int test[2];

    test[0] = 2;
    test[1] = 1;


    callback(test);
  }
}