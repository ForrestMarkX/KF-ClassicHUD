class KFDamageMutator extends Info;

struct RepInfoS
{
    var DamageReplicationInfo DRI;
    var KFPlayerController KFPC;
};

final function CheckDamageDone(array<RepInfoS> DamageReplicationInfos, KFPlayerController LastDamageDealer, int Damage, vector LastDamagePosition, class<KFDamageType> LastDamageDMGType)
{
	local int i;
	
	i = DamageReplicationInfos.Find('KFPC', LastDamageDealer);
	if( i != INDEX_NONE )
		DamageReplicationInfos[i].DRI.ClientNumberMsg(Damage,LastDamagePosition,LastDamageDMGType);
}