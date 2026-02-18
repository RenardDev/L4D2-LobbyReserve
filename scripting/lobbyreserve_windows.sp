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

bool g_bEnabled = false;

ConVar g_cvMinPlayers = null;
Handle g_hCheckTimer = null;

public Plugin myinfo =
{
    name        = "[L4D2] LobbyReserve (WINDOWS)",
    author      = "Ren",
    description = "",
    version     = "1.0.0",
    url         = ""
};

public void OnPluginStart()
{
    g_cvMinPlayers = CreateConVar(
        "l4d2_lobbyreserve_minplayers",
        "1",
        "Minimum number of real players required to ENABLE LobbyReserve patches (0 = always enabled).",
        FCVAR_NOTIFY,
        true, 0.0,
        true, 32.0
    );
    HookConVarChange(g_cvMinPlayers, OnMinPlayersChanged);

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

    if (!ValidateAll())
    {
        SetFailState("Patch validation failed (Windows).");
    }

    StartPeriodicCheck();
    CheckPlayerState();
}

public void OnMapStart()
{
    StartPeriodicCheck();
    CheckPlayerState();
}

void StartPeriodicCheck()
{
    if (g_hCheckTimer != null)
    {
        KillTimer(g_hCheckTimer);
        g_hCheckTimer = null;
    }

    g_hCheckTimer = CreateTimer(30.0, Timer_CheckPlayers, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_CheckPlayers(Handle timer)
{
    CheckPlayerState();
    return Plugin_Continue;
}

public void OnMinPlayersChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    CheckPlayerState();
}

bool ValidateAll()
{
    return g_Patch1.Validate()
        && g_Patch2.Validate()
        && g_Patch3.Validate()
        && g_Patch4.Validate()
        && g_Patch5.Validate();
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

    g_bEnabled = false;
    LogMessage("LobbyReserve patches DISABLED (WINDOWS)");
}

void CheckPlayerState()
{
    int nPlayers = GetRealPlayerCount();
    int nMinPlayers = g_cvMinPlayers.IntValue;

    if (nPlayers >= nMinPlayers)
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
    if (g_hCheckTimer != null)
    {
        KillTimer(g_hCheckTimer);
        g_hCheckTimer = null;
    }

    DisablePatches();

    if (g_hGameConf)
    {
        CloseHandle(g_hGameConf);
        g_hGameConf = null;
    }
}
