class ClassicHUD extends KFMutator;

var KFPawn LastHitZed;
var int LastHitHP;
var KFPlayerController LastDamageDealer;
var vector LastDamagePosition;
var class<KFDamageType> LastDamageDMGType;
var KFDamageMutator DamageMutator;
var array<RepInfoS> DamageReplicationInfos;

simulated function PreBeginPlay()
{
    Super.PreBeginPlay();
	DamageMutator = Spawn(class'KFDamageMutator');
}

function PostBeginPlay()
{
    Super.PostBeginPlay();
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
            TimerHelper.SetTimer(0.1,false,'CheckDamageDone');
        }
    }
}

final function CheckDamageDone()
{
    local int Damage;

    if( LastDamageDealer!=None && LastHitZed!=None && LastHitHP!=LastHitZed.Health )
    {
        Damage = LastHitHP-Max(LastHitZed.Health,0);
        if( Damage>0 )
			DamageMutator.CheckDamageDone(DamageReplicationInfos, LastDamageDealer, Damage, LastDamagePosition, LastDamageDMGType);
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
    
	for( i=0; i<DamageReplicationInfos.Length; i++ )
    {
		if( DamageReplicationInfos[i].KFPC == C )
		{
			DamageReplicationInfos[i].DRI.Destroy();
			DamageReplicationInfos.RemoveItem(DamageReplicationInfos[i]);
			break;
		}
    }
}

defaultproperties
{
}