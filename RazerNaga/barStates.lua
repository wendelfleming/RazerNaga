--[[
	barStates.lua
		A thingy for mapping stateIds to macro states
--]]

local states = {}

local getStateIterator = function(type, i)
	for j = i + 1, #states do
		local state = states[j]
		if state and ((not type) or state.type == type) then
			return j, state
		end
	end
end

local BarStates = {
	add = function(_, state, index)
		if index then
			return table.insert(states, index, state)
		end
		return table.insert(states, state)
	end,

	getAll = function(_, type)
		return getStateIterator, type, 0
	end,

	get = function(_, id)
		for i, v in pairs(states) do
			if v.id == id then
				return v
			end
		end
	end,

	map = function(_, f)
		local results = {}
		for _, v in ipairs(states) do
			if f(v) then
				table.insert(results, v)
			end
		end
		return results
	end,
}
RazerNaga.BarStates = BarStates

local addState = function(stateType, stateId, stateValue, stateText)
	return BarStates:add{
		type = stateType,
		id = stateId,
		value = stateValue,
		text = stateText
	}
end

--keybindings
addState('modifier', 'selfcast', '[mod:SELFCAST]', AUTO_SELF_CAST_KEY_TEXT)
addState('modifier', 'ctrlAltShift', '[mod:alt,mod:ctrl,mod:shift]', RazerNaga.BindingsLoader:GetLocalizedModiferName('ALT-CTRL-SHIFT'))
addState('modifier', 'ctrlAlt', '[mod:alt,mod:ctrl]', RazerNaga.BindingsLoader:GetLocalizedModiferName('ALT-CTRL'))
addState('modifier', 'altShift', '[mod:alt,mod:shift]', RazerNaga.BindingsLoader:GetLocalizedModiferName('ALT-SHIFT'))
addState('modifier', 'ctrlShift', '[mod:ctrl,mod:shift]', RazerNaga.BindingsLoader:GetLocalizedModiferName('CTRL-SHIFT'))
addState('modifier', 'alt', '[mod:alt]', ALT_KEY)
addState('modifier', 'ctrl', '[mod:ctrl]', CTRL_KEY)
addState('modifier', 'shift', '[mod:shift]', SHIFT_KEY)

--paging
for i = 2, 6 do
	addState('page', 'page' .. i, string.format('[bar:%d]', i), _G['BINDING_NAME_ACTIONPAGE' .. i])
end

--class
do
	local class = select(2, UnitClass('player'))

	local function newFormConditionLookup(spellID)
        return function()
            for i = 1, GetNumShapeshiftForms() do
                local _, _, _, formSpellID = GetShapeshiftFormInfo(i)

                if spellID == formSpellID then
                    return ("[form:%d]"):format(i)
                end
            end
        end
    end

	if class == 'DRUID' then
		addState('class', 'moonkin', '[bonusbar:4]', GetSpellInfo(24858))
		addState('class', 'bear', '[bonusbar:3]', GetSpellInfo(5487))
		addState('class', 'tree', newFormConditionLookup(33891), GetSpellInfo(33891))
		addState('class', 'prowl', '[bonusbar:1,stealth]', GetSpellInfo(5215))
		addState('class', 'cat', '[bonusbar:1]', GetSpellInfo(768))
	elseif class == 'ROGUE' then
		addState('class', 'stealth', '[bonusbar:1]', GetSpellInfo(1784))
		addState('class', 'shadowdance', '[form:2]', GetSpellInfo(1856))
	elseif class == 'PALADIN' then
		addState(
			"class",
			"crusader",
			newFormConditionLookup(32223),
			GetSpellInfo(32223)
		)

		addState(
			"class",
			"devotion",
			newFormConditionLookup(465),
			GetSpellInfo(465)
		)

		addState(
			"class",
			"retribution",
			newFormConditionLookup(183435),
			GetSpellInfo(183435)
		)

		addState(
			"class",
			"concentration",
			newFormConditionLookup(317920),
			GetSpellInfo(317920)
		)
	end

	local race = select(2, UnitRace('player'))
	if race == 'NightElf' then
		addState('class', 'shadowmeld', '[stealth]', GetSpellInfo(58984))
	end
end

--target reaction
addState('target', 'help', '[help]')
addState('target', 'harm', '[harm]')
addState('target', 'notarget', '[noexists]')


--automatic updating for UPDATE_SHAPESHIFT_FORMS
do
	local f = CreateFrame('Frame'); f:Hide()
	f:SetScript('OnEvent', function()
		if not InCombatLockdown() then
			RazerNaga.ActionBar:ForAll('UpdateStateDriver')
		end
	end)
	f:RegisterEvent('UPDATE_SHAPESHIFT_FORMS')
end
