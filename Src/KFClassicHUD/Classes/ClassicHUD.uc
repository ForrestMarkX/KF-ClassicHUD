class ClassicHUD extends KFMutator;

const GFxListenerPriority = 80000;

var KFPawn LastHitZed;
var int LastHitHP;
var KFPlayerController LastDamageDealer;
var vector LastDamagePosition;
var class<KFDamageType> LastDamageDMGType;

struct RepInfoS
{
    var DamageReplicationInfo DRI;
    var KFPlayerController KFPC;
};
var array<RepInfoS> DamageReplicationInfos;

var transient KFPlayerController KFPC;
var transient KFGFxHudWrapper HUD;
var transient GFxClikWidget HUDChatInputField, PartyChatInputField;

simulated function PostBeginPlay()
{
    Super.PostBeginPlay();
    if( WorldInfo.NetMode != NM_DedicatedServer )
        InitializeHUD();
        
    if( WorldInfo.Game != None )
        WorldInfo.Game.HUDType = class'ClassicKFHUD'; 
}

function NetDamage(int OriginalDamage, out int Damage, Pawn Injured, Controller InstigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType, Actor DamageCauser)
{
    Super.NetDamage(OriginalDamage, Damage, Injured, InstigatedBy, HitLocation, Momentum, DamageType, DamageCauser);

    if( LastDamageDealer!=None )
    {
        ClearTimer('CheckDamageDone');
        CheckDamageDone();
    }
    
    if( Damage>0 && InstigatedBy != None )
    {
        if( KFPawn_Monster(Injured) != None && KFPlayerController(InstigatedBy) != None )
        {
            LastDamageDealer = KFPlayerController(InstigatedBy);

            LastHitZed = KFPawn(Injured);
            LastHitHP = LastHitZed.Health;
            LastDamagePosition = HitLocation;
            LastDamageDMGType = class<KFDamageType>(DamageType);
            SetTimer(0.1,false,'CheckDamageDone');
        }
    }
}

final function CheckDamageDone()
{
    local int Damage, i;

    if( LastDamageDealer!=None && LastHitZed!=None && LastHitHP!=LastHitZed.Health )
    {
        Damage = LastHitHP-Max(LastHitZed.Health,0);
        if( Damage>0 )
        {
            i = DamageReplicationInfos.Find('KFPC', LastDamageDealer);
            if( i != INDEX_NONE )
                DamageReplicationInfos[i].DRI.ClientNumberMsg(Damage,LastDamagePosition,LastDamageDMGType);
        }
    }
    LastDamageDealer = None;
}

function NotifyLogin(Controller C)
{
	if( KFPlayerController(C) != None )
		CreateReplicationInfo(KFPlayerController(C));
		
    Super.NotifyLogin(C);
}

function NotifyLogout(Controller C)
{
	if( KFPlayerController(C) != None )
		DestroyReplicationInfo(KFPlayerController(C));
	
    Super.NotifyLogout(C);
}

function CreateReplicationInfo(KFPlayerController C)
{
    local RepInfoS Info;
    
    Info.DRI = Spawn(class'DamageReplicationInfo', C);
    Info.KFPC = C;
    
    Info.DRI.KFPC = C;
    
    DamageReplicationInfos.AddItem(Info);
}

function DestroyReplicationInfo(KFPlayerController C)
{
    local int i;
    
    i = DamageReplicationInfos.Find('KFPC', C);
    if( i != INDEX_NONE )
    {
        DamageReplicationInfos[i].DRI.Destroy();
        DamageReplicationInfos.RemoveItem(DamageReplicationInfos[i]);
    }
}

// Peelz fam, thanks for this
simulated function InitializeHUD()
{
    KFPC = KFPlayerController(GetALocalPlayerController());
    HUD = KFGFxHudWrapper(KFPC.myHUD);
    if( HUD == None )
    {
        SetTimer(0.5f, false, nameof(InitializeHUD));
        return;
    }
    
    WriteToChat("<Classic HUD> Initialized!", "FFFF00");
    WriteToChat("<Classic HUD> Type !settings or use OpenSettingsMenu in console to configure!", "00FF00");
        
    InitializePartyChatHook();
    InitializeHUDChatHook();
}

simulated delegate OnPartyChatInputKeyDown(GFxClikWidget.EventData Data)
{
    OnChatKeyDown(PartyChatInputField, Data);
}

simulated delegate OnHUDChatInputKeyDown(GFxClikWidget.EventData Data)
{
    if (OnChatKeyDown(HUDChatInputField, Data))
        HUD.HUDMovie.HudChatBox.ClearAndCloseChat();
}

simulated function bool OnChatKeyDown(GFxClikWidget InputField, GFxClikWidget.EventData Data)
{
    local GFXObject InputDetails;
    local int KeyCode;
    local string EventType;
    local string KeyEvent;
    local string Text;

    InputDetails = Data._this.GetObject("details");
    KeyCode = InputDetails.GetInt("code");
    EventType = InputDetails.GetString("type");
    KeyEvent = InputDetails.GetString("value");

    if (EventType != "key") return false;

    if (KeyCode == 13 && (KeyEvent == "keyHold" || KeyEvent == "keyDown"))
    {
        Text = InputField.GetText();
        switch (Locs(Text))
        {
            case "!settings":
                ClassicKFHUD(KFPC.MyHUD).OpenSettingsMenu();
                break;
            default:
                return false;
        }

        InputField.SetText("");

        return true;
    }

    return false;
}

simulated function InitializePartyChatHook()
{
    if (KFPC.MyGFxManager == None || KFPC.MyGFxManager.PartyWidget == None || KFPC.MYGFxManager.PartyWidget.PartyChatWidget == None)
    {
        SetTimer(1.f, false, nameof(InitializePartyChatHook));
        return;
    }

    KFPC.MyGFxManager.PartyWidget.PartyChatWidget.SetVisible(true);
    PartyChatInputField = GFxClikWidget(KFPC.MyGFxManager.PartyWidget.PartyChatWidget.GetObject("ChatInputField", class'GFxClikWidget'));
    PartyChatInputField.AddEventListener('CLIK_input', OnPartyChatInputKeyDown, false, GFxListenerPriority, false);
}

simulated function InitializeHUDChatHook()
{
    if (HUD == None || HUD.HUDMovie == None || HUD.HUDMovie.HudChatBox == None)
    {
        SetTimer(1.f, false, nameof(InitializeHUDChatHook));
        return;
    }

    HUDChatInputField = GFxClikWidget(HUD.HUDMovie.HudChatBox.GetObject("ChatInputField", class'GFxClikWidget'));
    HUDChatInputField.AddEventListener('CLIK_input', OnHUDChatInputKeyDown, false, GFxListenerPriority, false);;
}

simulated function WriteToChat(string Message, string HexColor)
{
    if (KFPC.MyGFxManager.PartyWidget != None && KFPC.MyGFxManager.PartyWidget.PartyChatWidget != None)
        KFPC.MyGFxManager.PartyWidget.PartyChatWidget.AddChatMessage(Message, HexColor);

    if (HUD != None && HUD.HUDMovie != None && HUD.HUDMovie.HudChatBox != None)
        HUD.HUDMovie.HudChatBox.AddChatMessage(Message, HexColor);
}

defaultproperties
{
    Role=ROLE_Authority
    RemoteRole=ROLE_SimulatedProxy
    bAlwaysRelevant=true
}