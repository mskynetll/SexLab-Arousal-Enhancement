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

		Actor[] actorList = SexLab.HookActors(argString)
		int i = 0;
		While i < actorList.length
			bool isVictim = (actorList[i] == victim)
			float arousalAdjustment = GetArousalAdjustmentForActor(actorList[i],animation,argString,Controller,i,isVictim)
			slaUtil.UpdateActorExposure(actorList[i], arousalAdjustment as int, "increase arousal at the end of animation stage")
			if ConsoleDebug
				string name = actorList[i].GetName()				
				MiscUtil.PrintConsole("OnAnimationStageEnd(), increase arousal for " + name + " by " + arousalAdjustment)
			endif			
			i += 1
		endwhile
	endif
EndEvent

int property MalePosition = 0 Autoreadonly
int property FemalePosition = 1 Autoreadonly
int property CreaturePosition = 2 Autoreadonly

float Function GetArousalAdjustmentForActor(Actor akActor,sslBaseAnimation animation,string argString,sslThreadController controller, int indexInController, bool isVictim)
	float lewdness = (SexLab.Stats.GetSkillLevel(akActor, SexLab.Stats.kLewd) as float)	
	
	float arousalBonus = 0.0 ;base arousal bonus
	int actorSex = SexLab.GetGender(akActor) ;0 male, 1 female, 2 creature

	if actorSex == 2
		return 10.0 ;creatures don't care about intricacies, they follow instincts
	endif

	bool isBeingRaped = false
	if isVictim
		isBeingRaped = true
		 arousalBonus =  lewdness ;for rape, base arousal bonus depends on lewdness
	endif

	float currentArousal = slaUtil.GetActorArousal(akActor)
	if lewdness >= 5.0 && isBeingRaped ;if very lewd, small arousal increase from forced sex
		arousalBonus = 1.0
	endif

	int positionInAnimation = animation.getGender(indexInController)
	if animation.HasTag("Anal")
		if positionInAnimation == MalePosition
			if actorSex == 0 && SexLab.Stats.IsGay(akActor) && animation.HasTag("MM")
				arousalBonus += (lewdness * 1.5)
			endif
		endif
		if positionInAnimation == FemalePosition
			if actorSex == 0 && SexLab.Stats.IsGay(akActor); males get more arousal from buttsex only if they are gay
				arousalBonus += lewdness
			endif
			if actorSex == 1 ;female
				if lewdness >= 1.0 && isBeingRaped
					arousalBonus += lewdness
				elseif lewdness >= 2.0 && isBeingRaped == false
					arousalBonus += 5.0
				endif
			endif
		endif
	endif

	if animation.HasTag("Vaginal")
		if actorSex == 0 && positionInAnimation == MalePosition && SexLab.Stats.IsGay(akActor) == false;straiht guys get aroused by this...
			arousalBonus += (5.0 + lewdness)			
		endif			
		if positionInAnimation == FemalePosition
			if animation.HasTag("Dirty") || animation.HasTag("Forced")
				arousalBonus += lewdness
			elseif  animation.HasTag("Dirty") == false
				arousalBonus += SexLab.Stats.GetSkillLevel(akActor, SexLab.Stats.kPure)
			endif
		endif
	endif
	if animation.HasTag("Kissing")
	if actorSex == 0
			arousalBonus += 5.0
		elseif actorSex == 1 ;females get slightly more from kissing
			arousalBonus += 8.0
		endif
	endif

	if animation.HasTag("Fisting")
		if positionInAnimation == FemalePosition && lewdness >= 2.0
			arousalBonus += (lewdness / 1.5)				
		endif
			if positionInAnimation == MalePosition
			if actorSex == 0 && lewdness >= 1.0
				arousalBonus += lewdness
			endif
			if actorSex == 1 && lewdness >= 2.0 ;females higher lewdness threshold to enjoy fisting
				arousalBonus += lewdness
			endif
		endif
	endif

	if animation.HasTag("Blowjob")
		if actorSex == 0
			arousalBonus += (lewdness + 2.5)
		endif
			if actorSex == 1 && positionInAnimation == FemalePosition
			if animation.HasTag("Forced")
				arousalBonus += lewdness
			else
				arousalBonus += (1.0 + lewdness)
			endif
		endif
	endif	
	return arousalBonus
EndFunction