Scriptname saeEventsTracker extends Quest

slaInternalScr Property slaUtil Auto
SexLabFramework Property SexLab Auto
Actor Property PlayerRef Auto
GlobalVariable Property saeConsoleDebug Auto
sslThreadController Property Controller Auto Hidden
int Property PlayerSex Auto Hidden

bool Property ConsoleDebug 
	bool Function Get()
		return saeConsoleDebug.GetValueInt() == 1
	EndFunction
EndProperty

Event OnInit()
	Maintenance()
EndEvent

Function Maintenance()	
	RegisterForModEvent("AnimationStart", "OnAnimationStart")
	RegisterForModEvent("AnimationEnd", "OnAnimationEnd")		
	RegisterForModEvent("StageEnd", "OnAnimationStageEnd")		
EndFunction

Event OnAnimationStart(string EventName, string argString, Float argNum, form sender)
	sslThreadController c = SexLab.GetController(argString as int)

	;assuming that there can be only one animation involving a player
	if c.HasPlayer
		Controller = c
		PlayerSex = SexLab.GetGender(PlayerRef) ;0 male, 1 female
	endif
EndEvent

Event OnAnimationEnd(string EventName, string argString, Float argNum, form sender)
	if Controller != none
		Controller = none
	endif
EndEvent

Event OnAnimationStageEnd(string EventName, string argString, Float argNum, form sender)
	if Controller != none
		Actor victim = Sexlab.HookVictim(argString)
		sslBaseAnimation animation = SexLab.HookAnimation(argString)

		float lewdness = (SexLab.Stats.GetSkillLevel(PlayerRef, SexLab.Stats.kLewd) as float)

		float arousalBonus = 10.0 ;base arousal bonus
		bool isPlayerBeingRaped = false
		if victim != None && victim == PlayerRef
			isPlayerBeingRaped = true
			 arousalBonus =  lewdness ;for rape, base arousal bonus depends on lewdness
		endif

		float currentArousal = slaUtil.GetActorArousal(PlayerRef)
		if lewdness >= 5.0 && isPlayerBeingRaped ;if very lewd, small arousal increase from forced sex
			arousalBonus = 1.0
		endif

		int playerPosition = GetPlayerPositionInAnimation(animation,argString)

		if animation.HasTag("Anal")
			if playerPosition == MalePosition
				if PlayerSex == 0 && SexLab.Stats.IsGay(PlayerRef) && animation.HasTag("MM")
					arousalBonus += (lewdness * 1.5)
				endif
			endif
			if playerPosition == FemalePosition
				if PlayerSex == 0 && SexLab.Stats.IsGay(PlayerRef); males get more arousal from buttsex only if they are gay
					arousalBonus += lewdness
				endif
				if PlayerSex == 1 ;female
					if lewdness >= 1.0 && isPlayerBeingRaped
						arousalBonus += lewdness
					elseif lewdness >= 2.0 && isPlayerBeingRaped == false
						arousalBonus += 5.0
					endif
				endif
			endif
		endif

		if animation.HasTag("Vaginal")
			if PlayerSex == 0 && playerPosition == MalePosition && SexLab.Stats.IsGay(PlayerRef) == false;straiht guys get aroused by this...
				arousalBonus += (5.0 + lewdness)			
			endif			
			if playerPosition == FemalePosition
				if animation.HasTag("Dirty") || animation.HasTag("Forced")
					arousalBonus += lewdness
				elseif  animation.HasTag("Dirty") == false
					arousalBonus += SexLab.Stats.GetSkillLevel(PlayerRef, SexLab.Stats.kPure)
				endif
			endif
		endif

		if animation.HasTag("Kissing")
			if PlayerSex == 0
				arousalBonus += 5.0
			elseif PlayerSex == 1 ;females get slightly more from kissing
				arousalBonus += 8.0
			endif
		endif

		if animation.HasTag("Fisting")
			if playerPosition == FemalePosition && lewdness >= 2.0
				arousalBonus += (lewdness / 1.5)				
			endif

			if playerPosition == MalePosition
				if PlayerSex == 0 && lewdness >= 1.0
					arousalBonus += lewdness
				endif
				if PlayerSex == 1 && lewdness >= 2.0 ;females higher lewdness threshold to enjoy fisting
					arousalBonus += lewdness
				endif
			endif
		endif

		if animation.HasTag("Blowjob")
			if PlayerSex == 0
				arousalBonus += (lewdness + 2.5)
			endif

			if PlayerSex == 1 && playerPosition == FemalePosition
				if animation.HasTag("Forced")
					arousalBonus += lewdness
				else
					arousalBonus += (1.0 + lewdness)
				endif
			endif
		endif

		slaUtil.UpdateActorExposure(PlayerRef, arousalBonus as int, "arousal increase on animation stage end")
		if ConsoleDebug
			MiscUtil.PrintConsole("OnAnimationStageEnd(), lewdness:" + lewdness + ", arousalBonus:" + arousalBonus)
		endif
	endif
EndEvent

int Function GetPlayerPositionInAnimation(sslBaseAnimation animation,string argString)
	Actor[] actorList = SexLab.HookActors(argString)
	int i = 0;
	While i < actorList.length
		if actorList[i] == PlayerRef
			return animation.getGender(i) % 3 ; 0 -> male, 1 -> female, 2 -> creature
		endif
		i += 1
	endwhile
EndFunction

int property MalePosition = 0 Autoreadonly
int property FemalePosition = 1 Autoreadonly
int property CreaturePosition = 2 Autoreadonly

sslActorAlias Function GetPlayerAliasFrom(sslThreadController controller)
	int i = 0
	while i < controller.ActorAlias.Length
		if controller.ActorAlias[i].GetActorRef() != none && controller.ActorAlias[i].GetActorRef() == PlayerRef
			return controller.ActorAlias[i]
		endif
		i += 1
	endwhile	
EndFunction