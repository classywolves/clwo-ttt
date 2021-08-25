bool g_bStoreLoaded = false;

public void OnAllPluginsLoaded()
{
    g_bStoreLoaded = Store_CheckLibraryExists();
    if (g_bStoreLoaded && Store_IsReady())
    {
        Store_OnRegister();
    }
}

public void OnLibraryAdded(const char[] name)
{
    if (Store_CheckLibraryName(name))
    {
        g_bStoreLoaded = true;
    }
}

public void OnLibraryRemoved(const char[] name)
{
    if (Store_CheckLibraryName(name))
    {
        g_bStoreLoaded = false;
    }
}
