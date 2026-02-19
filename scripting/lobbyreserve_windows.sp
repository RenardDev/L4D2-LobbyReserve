#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sourcescramble>

Handle g_hGameConf = null;

MemoryPatch g_Patch1;
MemoryPatch g_Patch2;
MemoryPatch g_Patch3;
MemoryPatch g_Patch4;
MemoryPatch g_Patch5;
MemoryPatch g_Patch6;

bool g_bEnabled = false;

public Plugin myinfo =
{
    name        = "[L4D2] LobbyReserve (WINDOWS)",
    author      = "Ren",
    description = "",
    version     = "1.0.1",
    url         = ""
};

public void OnPluginStart()
{
    g_hGameConf = LoadGameConfigFile("l4d2_lobbyreserve_runtime_windows");
    if (!g_hGameConf)
    {
        SetFailState("Failed to load gamedata: l4d2_lobbyreserve_runtime_windows.");
    }

    g_Patch1 = MemoryPatch.CreateFromConf(g_hGameConf, "Patch1");
    g_Patch2 = MemoryPatch.CreateFromConf(g_hGameConf, "Patch2");
    g_Patch3 = MemoryPatch.CreateFromConf(g_hGameConf, "Patch3");
    g_Patch4 = MemoryPatch.CreateFromConf(g_hGameConf, "Patch4");
    g_Patch5 = MemoryPatch.CreateFromConf(g_hGameConf, "Patch5");
    g_Patch6 = MemoryPatch.CreateFromConf(g_hGameConf, "Patch6");

    if (!ValidateAll())
    {
        SetFailState("Patch validation failed (Windows).");
    }

    CheckPlayerState();
}

bool ValidateAll()
{
    return g_Patch1.Validate()
        && g_Patch2.Validate()
        && g_Patch3.Validate()
        && g_Patch4.Validate()
        && g_Patch5.Validate()
        && g_Patch6.Validate();
}

void EnablePatches()
{
    if (g_bEnabled)
        return;

    g_Patch1.Enable();
    g_Patch2.Enable();
    g_Patch3.Enable();
    g_Patch4.Enable();
    g_Patch5.Enable();
    g_Patch6.Enable();

    g_bEnabled = true;
    LogMessage("LobbyReserve patches ENABLED (WINDOWS)");
}

void DisablePatches()
{
    if (!g_bEnabled)
        return;

    g_Patch1.Disable();
    g_Patch2.Disable();
    g_Patch3.Disable();
    g_Patch4.Disable();
    g_Patch5.Disable();
    g_Patch6.Disable();

    g_bEnabled = false;
    LogMessage("LobbyReserve patches DISABLED (WINDOWS)");
}

public void OnClientPutInServer(int client)
{
    if (!IsRealPlayer(client))
        return;

    CheckPlayerState();
}

public void OnClientDisconnect(int client)
{
    CreateTimer(0.5, Timer_CheckEmpty, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_CheckEmpty(Handle timer)
{
    CheckPlayerState();
    return Plugin_Stop;
}

void CheckPlayerState()
{
    if (GetRealPlayerCount() > 0)
    {
        EnablePatches();
    }
    else
    {
        DisablePatches();
    }
}

int GetRealPlayerCount()
{
    int nCount = 0;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsRealPlayer(i))
        {
            nCount++;
        }
    }

    return nCount;
}

bool IsRealPlayer(int client)
{
    return (client >= 1 && client <= MaxClients)
        && IsClientInGame(client)
        && !IsFakeClient(client);
}

public void OnPluginEnd()
{
    DisablePatches();

    if (g_hGameConf)
    {
        CloseHandle(g_hGameConf);
        g_hGameConf = null;
    }
}
