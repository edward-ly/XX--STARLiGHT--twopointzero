--[[local function obf(st)
    return base64decode(st)
end

local function asdf()
    return _G[obf('VG9FbnVtU2hvcnRTdHJpbmc=')](_G[obf('R0FNRVNUQVRF')][obf('R2V0Q29pbk1vZGU=')](_G[obf('R0FNRVNUQVRF')]))
end]]
Branch.FirstScreen = function()
	return "ScreenMDSplash"
end

Branch.WarningOrAlert = function()
	if _VERSION ~= "Lua 5.3" and tonumber(VersionDate()) < 20190328 then
		return "ScreenOldSM"
	else
		if SN3Debug then
			return "ScreenDevBuild"
		else
			return "ScreenPotatoPC"
		end
	end
end

Branch.AfterOLDSM = function()
	if PREFSMAN:GetPreference('DisplayColorDepth') == 16 or PREFSMAN:GetPreference('TextureColorDepth') == 16 then
		return "ScreenGraphicsAlert"
	else
		if SN3Debug then
			return "ScreenDevBuild"
		else
			return "ScreenPotatoPC"
		end
	end
end

Branch.AttractStart = function()
	local mode = GAMESTATE:GetCoinMode()
	local screen = Var"LoadingScreen"
	if mode == "CoinMode_Home" then
		-- Only really matters if you hit Start from ScreenInit
		return "ScreenLogo"
	elseif mode == "CoinMode_Free" then
		-- Start in Free Play mode goes directly into game
		return "ScreenLogo"
	else
	-- Inserting a credit in Pay mode goes to logo screen
		return "ScreenLogo"
	end
end

Branch.StartGame = function()
	-- XXX: we don't theme this screen
	if SONGMAN:GetNumSongs() == 0 and SONGMAN:GetNumAdditionalSongs() == 0 then
		return "ScreenHowToInstallSongs"
	end
	if PROFILEMAN:GetNumLocalProfiles() >= 1 then
		return "ScreenSelectProfile"
	else
		if PREFSMAN:GetPreference("MemoryCards") then
			return "ScreenSelectProfile"
		else
			return "ScreenDDRNameEntry"
		end
	end
end

Branch.SelectMusicOrCourse = function()
	if IsNetSMOnline() then
		return "ScreenNetSelectMusic"
	elseif GAMESTATE:IsCourseMode() then
		return "ScreenSelectCourse"
	else
		if GetExtraStage() then
			return "ScreenSelectMusicExtra"
		else
			return "ScreenSelectMusic"
		end
	end
end

Branch.BackOutOfPlayerOptions = function()
	return SelectMusicOrCourse()
end

Branch.TitleMenu = function()
	local coinMode = GAMESTATE:GetCoinMode()
	if coinMode == 'CoinMode_Home' then
		return "ScreenSelectMode"
	else
		return "ScreenWarning"
	end
end

Branch.AfterSelectStyle = function()
	if IsNetConnected() then
		ReportStyle()
	end
	if IsNetSMOnline() then
		return SMOnlineScreen()
	end
	if IsNetConnected() then
		return "ScreenNetRoom"
	end
	return "ScreenProfileLoad"

	--return CHARMAN:GetAllCharacters() ~= nil and "ScreenSelectCharacter" or "ScreenGameInformation"
end

Branch.AfterCaution = function()
	if GAMESTATE:IsCourseMode() then
		return "ScreenSelectCourse"
	else
		return "ScreenSelectMusic"
	end
end

Branch.AfterGameplay = function()
	return "ScreenEvaluationNormal"
end

Branch.AfterEvaluation = function()
	if GetExtraStage() then
		for pn in ivalues(GAMESTATE:GetHumanPlayers()) do
			local po = GAMESTATE:GetPlayerState(pn):GetPlayerOptionsArray("ModsLevel_Preferred")
			
			if IsExtraStage1() then
				if not table.search(po, '4Lives') and not table.search(po, '1Lives') then
					GAMESTATE:ApplyPreferredModifiers(pn, '4 lives,battery,failimmediate')
				end
			else
				GAMESTATE:ApplyPreferredModifiers(pn, '1 lives,battery,failimmediate')
			end
			
			GAMESTATE:AddStageToPlayer(pn)
		end
	end
	
	if GAMESTATE:IsCourseMode() then
		return "ScreenDataSaveSummary"
	elseif (GAMESTATE:GetSmallestNumStagesLeftForAnyHumanPlayer() >= 1)
		or (GetCurTotalStageCost() < PREFSMAN:GetPreference("SongsPerPlay")) then
		return "ScreenProfileSave"
	else
		return "ScreenEvaluationSummary"
	end
end

Branch.AfterProfileSave = function()
	if not GAMESTATE:IsEventMode() and STATSMAN:GetCurStageStats():AllFailed() then
		for pn in ivalues(GAMESTATE:GetHumanPlayers()) do
			local po = GAMESTATE:GetPlayerState(pn):GetPlayerOptionsArray("ModsLevel_Preferred")
			
			if table.search(po,'1Lives') or table.search(po,'4Lives') then
				local rem = PREFSMAN:GetPreference("SongsPerPlay")-GetCurTotalStageCost()
				
				for i=1, rem do
					GAMESTATE:AddStageToPlayer(pn)
				end
			end
		end
		
		if GAMESTATE:GetSmallestNumStagesLeftForAnyHumanPlayer() > 0 then
			return SelectMusicOrCourse()
		else
			return "ScreenEvaluationSummary"
		end
	elseif GAMESTATE:GetSmallestNumStagesLeftForAnyHumanPlayer() == 0 then
		return GameOverOrContinue()
	else
		return SelectMusicOrCourse()
	end
end