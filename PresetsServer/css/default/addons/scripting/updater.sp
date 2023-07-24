#pragma semicolon 1

/* SM Includes */
#include <sourcemod>
#include <SteamWorks>

#pragma semicolon 1
#pragma newdecls required

/* Plugin Info */
#define PLUGIN_NAME      "Updater"
#define PLUGIN_VERSION   "1.3.0-Dev 2"

public Plugin myinfo = {
	name = PLUGIN_NAME,
	author = "GoD-Tony & J_Tanzanite",
	description = "Automatically updates SourceMod plugins and files",
	version = PLUGIN_VERSION,
	url = ""
};

/* Globals */
//#define DEBUG		// This will enable verbose logging. Useful for developers testing their updates.

#define STEAMWORKS_AVAILABLE()   (GetFeatureStatus(FeatureType_Native, "SteamWorks_WriteHTTPResponseBodyToFile") == FeatureStatus_Available)

#define EXTENSION_ERROR   "This plugin requires the SteamWorks extensions to function."
#define TEMP_FILE_EXT     "temp" // All files are downloaded with this extension first.
#define MAX_URL_LENGTH    256

#define UPDATE_URL   "https://raw.githubusercontent.com/J-Tanzanite/updater/main/updatefile.txt"

enum UpdateStatus {
	Status_Idle,
	Status_Checking,      // Checking for updates.
	Status_Downloading,   // Downloading an update.
	Status_Updated,       // Update is complete.
	Status_Error,         // An error occured while downloading.
};

bool g_bGetDownload;
bool g_bGetSource;

Handle g_hPluginPacks = INVALID_HANDLE;
Handle g_hDownloadQueue = INVALID_HANDLE;
Handle g_hRemoveQueue = INVALID_HANDLE;
bool g_bDownloading = false;

static Handle _hUpdateTimer = INVALID_HANDLE;
static float _fLastUpdate = 0.0;
static char _sDataPath[PLATFORM_MAX_PATH];

/* Core Includes */
#include "updater/plugins.sp"
#include "updater/filesys.sp"
#include "updater/download.sp"
#include "updater/api.sp"

/* Plugin Functions */
public APLRes AskPluginLoad2(Handle myself, bool late, char []error, int err_max)
{
	API_Init();
	RegPluginLibrary("updater");

	return APLRes_Success;
}

public void OnPluginStart()
{
	if (!STEAMWORKS_AVAILABLE())
		SetFailState(EXTENSION_ERROR);

	LoadTranslations("common.phrases");

	// Convars.
	Handle hCvar = INVALID_HANDLE;

	hCvar = CreateConVar("sm_updater_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_NOTIFY | FCVAR_DONTRECORD);
	OnVersionChanged(hCvar, "", "");
	HookConVarChange(hCvar, OnVersionChanged);

	hCvar = CreateConVar("sm_updater", "2", "Determines update functionality. (1 = Notify, 2 = Download, 3 = Include source code)", 0, true, 1.0, true, 3.0);
	OnSettingsChanged(hCvar, "", "");
	HookConVarChange(hCvar, OnSettingsChanged);

	// Commands.
	RegAdminCmd("sm_updater_check", Command_Check, ADMFLAG_RCON, "Forces Updater to check for updates.");
	RegAdminCmd("sm_updater_status", Command_Status, ADMFLAG_RCON, "View the status of Updater.");


	// Initialize arrays.
	g_hPluginPacks = CreateArray();
	g_hDownloadQueue = CreateArray();
	g_hRemoveQueue = CreateArray();

	// Temp path for checking update files.
	BuildPath(Path_SM, _sDataPath, sizeof(_sDataPath), "data/updater.txt");

#if !defined DEBUG
	// Add this plugin to the autoupdater.
	Updater_AddPlugin(GetMyHandle(), UPDATE_URL);
#endif

	// Check for updates every 24 hours.
	_hUpdateTimer = CreateTimer(60.0*60.0*24.0, Timer_CheckUpdates, _, TIMER_REPEAT);
}

public void OnAllPluginsLoaded()
{
	// Check for updates on startup.
	TriggerTimer(_hUpdateTimer, true);
}

public Action Timer_CheckUpdates(Handle timer)
{
	Updater_FreeMemory();

	// Update everything!
	int maxPlugins = GetMaxPlugins();
	for (int i = 0; i < maxPlugins; i++)
	{
		if (Updater_GetStatus(i) == Status_Idle)
		{
			Updater_Check(i);
		}
	}

	_fLastUpdate = GetTickedTime();

	return Plugin_Continue;
}

public Action Command_Check(int client, int args)
{
	// This delay #### is annoying, lets tone it down.
	float fNextUpdate = _fLastUpdate + 10.0;

	if (fNextUpdate > GetTickedTime())
	{
		ReplyToCommand(client, "[Updater] Please wait %.0f seconds before trying again.", (fNextUpdate - GetTickedTime()) + 0.5);
	}
	else
	{
		ReplyToCommand(client, "[Updater] Checking for updates.");
		TriggerTimer(_hUpdateTimer, true);
	}

	return Plugin_Handled;
}

public Action Command_Status(int client, int args)
{
	char sFilename[64];
	Handle hPlugin = INVALID_HANDLE;
	int maxPlugins = GetMaxPlugins();

	ReplyToCommand(client, "[Updater] -- Status Begin --");
	ReplyToCommand(client, "Plugins being monitored for updates:");

	for (int i = 0; i < maxPlugins; i++)
	{
		hPlugin = IndexToPlugin(i);

		if (IsValidPlugin(hPlugin))
		{
			GetPluginFilename(hPlugin, sFilename, sizeof(sFilename));
			ReplyToCommand(client, "  [%i]  %s", i, sFilename);
		}
	}

	ReplyToCommand(client, "Last update check was %.1f seconds ago.", GetTickedTime() - _fLastUpdate);
	ReplyToCommand(client, "[Updater] --- Status End ---");

	return Plugin_Handled;
}

public void OnVersionChanged(Handle convar, const char []oldValue, const char []newValue)
{
	if (!StrEqual(newValue, PLUGIN_VERSION))
		SetConVarString(convar, PLUGIN_VERSION);
}

public void OnSettingsChanged(Handle convar, const char []oldValue, const char []newValue)
{
	switch (GetConVarInt(convar))
	{
		case 1: // Notify only.
		{
			g_bGetDownload = false;
			g_bGetSource = false;
		}

		case 2: // Download updates.
		{
			g_bGetDownload = true;
			g_bGetSource = false;
		}

		case 3: // Download with source code.
		{
			g_bGetDownload = true;
			g_bGetSource = true;
		}
	}
}

#if !defined DEBUG
public void Updater_OnPluginUpdated()
{
	Updater_Log("Reloading Updater plugin... updates will resume automatically.");

	// Reload this plugin.
	char filename[64];
	GetPluginFilename(INVALID_HANDLE, filename, sizeof(filename));
	ServerCommand("sm plugins reload %s", filename);
}
#endif

void Updater_Check(int index)
{
	if (Fwd_OnPluginChecking(IndexToPlugin(index)) == Plugin_Continue)
	{
		char url[MAX_URL_LENGTH];
		Updater_GetURL(index, url, sizeof(url));
		Updater_SetStatus(index, Status_Checking);
		AddToDownloadQueue(index, url, _sDataPath);
	}
}

void Updater_FreeMemory()
{
	// Make sure that no threads are active.
	if (g_bDownloading || GetArraySize(g_hDownloadQueue))
		return;

	// Remove all queued plugins.
	int index;
	int maxPlugins = GetArraySize(g_hRemoveQueue);
	for (int i = 0; i < maxPlugins; i++)
	{
		index = PluginToIndex(GetArrayCell(g_hRemoveQueue, i));

		if (index != -1)
			Updater_RemovePlugin(index);
	}

	ClearArray(g_hRemoveQueue);

	// Remove plugins that have been unloaded.
	for (int i = 0; i < GetMaxPlugins(); i++)
	{
		if (!IsValidPlugin(IndexToPlugin(i)))
		{
			Updater_RemovePlugin(i);
			i--;
		}
	}
}

void Updater_Log(const char []format, any ...)
{
	char buffer[256];
	char path[PLATFORM_MAX_PATH];
	VFormat(buffer, sizeof(buffer), format, 2);
	BuildPath(Path_SM, path, sizeof(path), "logs/Updater.log");
	LogToFileEx(path, "%s", buffer);
}

#if defined DEBUG
void Updater_DebugLog(const char []format, any ...)
{
	char buffer[256];
	char path[PLATFORM_MAX_PATH];
	VFormat(buffer, sizeof(buffer), format, 2);
	BuildPath(Path_SM, path, sizeof(path), "logs/Updater_Debug.log");
	LogToFileEx(path, "%s", buffer);
}
#endif
