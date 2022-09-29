
up.game:event('Unit-HurtOther',function(_,source,target,skill,damage,damageType)
    if not damage then return end
    local data = {
        source = source,
        target = target,
        skill = skill,
        damage = damage:float(),
        damageType = DamageAttackType[damageType],
    }
    source:event_dispatch('Unit-HurtOther',data)
    target:event_dispatch('Unit-BeHurt',data)
end)
