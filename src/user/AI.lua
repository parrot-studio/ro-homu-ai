--------------------------------------------------
-- RO Homuncls AI for "FILIR"
-- 
-- @auther parrot
-- @ver 2.1
-- 
-- "RAGNAROK ONLINE"
-- Gravity Corp. & Lee Myoungjin(studio DTDS). All Rights Reserved.
-- GungHo Online Entertainment, Inc. All Rights Reserved 
-- 
---- �C������ ----
-- 
-- v1.0 2006/03/25 �R�����g�}��
-- v1.1 2006/03/27 GetMyEnemy�C��
-- v1.2 2006/03/30 ���G�͈͎w��
-- v1.3 2006/04/03 ������h�~
-- v1.4 2006/04/09 �X�L�������g�p
-- 
-- v2.0 2006/04/23 �؂�ւ��R�}���h����
-- v2.1 2007/08/25 �t���b�g���[�u�̎���������
--------------------------------------------------


require "./AI/Const.lua"
require "./AI/Util.lua"					

-----------------------------
-- state
-----------------------------
IDLE_ST					= 0
FOLLOW_ST					= 1
CHASE_ST					= 2
ATTACK_ST					= 3
MOVE_CMD_ST					= 4
STOP_CMD_ST					= 5
ATTACK_OBJECT_CMD_ST			= 6
ATTACK_AREA_CMD_ST			= 7
PATROL_CMD_ST				= 8
HOLD_CMD_ST					= 9
SKILL_OBJECT_CMD_ST			= 10
SKILL_AREA_CMD_ST				= 11
FOLLOW_CMD_ST				= 12
----------------------------



------------------------------------------
-- global variable
------------------------------------------
MyState				= IDLE_ST	-- �ŏ��̏�Ԃ͋x��
MyEnemy				= 0		-- �G id
MyDestX				= 0		-- �ړI�n x���W
MyDestY				= 0		-- �ړI�n y���W
MyPatrolX				= 0		-- ��@�ړI�n x���W
MyPatrolY				= 0		-- ��@�ړI�n y���W
ResCmdList				= List.new()	-- �\��R�}���h���X�g
MyID					= 0		-- �z�����N���X id
MySkill					= 0		-- �z�����N���X�̃X�L��
MySkillLevel				= 0		-- �z�����N���X�̃X�L�����x��
------------------------------------------

------------------------------------------
-- skill id
------------------------------------------
S_MOONLIT = 8009
S_FLEETMV = 8010
S_OVERSPD = 8011
------------------------------------------

------------------------------------------
-- mode flag
------------------------------------------
MODE_ACTIVE       = 0	 -- ��U���[�h
MODE_NONACTIVE    = 1	 -- ���U���[�h
MyActiveMode = MODE_NONACTIVE	 -- ��U���[�h�t���O
ActiveModeCounter = 0	 -- �R�}���h�J�E���^�[

MODE_SKILL       = 0	 -- �X�L���g�p�s��
MODE_NONSKILL    = 1	 -- �X�L���g�p��
MySkillMode = MODE_SKILL	 -- �X�L���g�p�t���O
SkillModeCounter = 0	 -- �R�}���h�J�E���^�[

MODE_FLEET       = 0	 -- �t���b�g���[�u�g�p�s��
MODE_NONFLEET    = 1	 -- �t���b�g���[�u�g�p��
MyFleetMode = MODE_FLEET	 -- �t���b�g���[�u�g�p�t���O
FleetModeCounter = 0	 -- �t���b�g���[�u�J�E���^�[
------------------------------------------




------------- command process  ---------------------

function	OnMOVE_CMD (x,y)
	
	TraceAI ("OnMOVE_CMD")

	if ( x == MyDestX and y == MyDestY and MOTION_MOVE == GetV(V_MOTION,MyID)) then
		return		-- �ړI�n�ƌ��ݒn������̏ꍇ�́A�������Ȃ�
	end

	local curX, curY = GetV (V_POSITION,MyID)
	if (math.abs(x-curX)+math.abs(y-curY) > 15) then		-- �ړI�n����苗���ȏ�Ȃ� (�T�[�o�[�ŉ������͏������Ȃ�����)
		List.pushleft (ResCmdList,{MOVE_CMD,x,y})			-- ���̖ړI�n�ւ̈ړ���\�񂷂�
		x = math.floor((x+curX)/2)							-- ���Ԓn�_�ֈړ�����
		y = math.floor((y+curY)/2)							-- 
	end

	Move (MyID,x,y)	
	
	MyState = MOVE_CMD_ST
	MyDestX = x
	MyDestY = y
	MyEnemy = 0
	MySkill = 0

	CheckMoveCommand()

end




function	OnSTOP_CMD ()

	TraceAI ("OnSTOP_CMD")

	if (GetV(V_MOTION,MyID) ~= MOTION_STAND) then
		Move (MyID,GetV(V_POSITION,MyID))
	end
	MyState = IDLE_ST
	MyDestX = 0
	MyDestY = 0
	MyEnemy = 0
	MySkill = 0

end




function	OnATTACK_OBJECT_CMD (id)

	TraceAI ("OnATTACK_OBJECT_CMD")

	MySkill = 0
	MyEnemy = id
	MyState = CHASE_ST

end




function	OnATTACK_AREA_CMD (x,y)

	TraceAI ("OnATTACK_AREA_CMD")

	if (x ~= MyDestX or y ~= MyDestY or MOTION_MOVE ~= GetV(V_MOTION,MyID)) then
		Move (MyID,x,y)	
	end
	MyDestX = x
	MyDestY = y
	MyEnemy = 0
	MyState = ATTACK_AREA_CMD_ST
	
end



function	OnPATROL_CMD (x,y)

	TraceAI ("OnPATROL_CMD")

	MyPatrolX , MyPatrolY = GetV (V_POSITION,MyID)
	MyDestX = x
	MyDestY = y
	Move (MyID,x,y)
	MyState = PATROL_CMD_ST

end




function	OnHOLD_CMD ()

	TraceAI ("OnHOLD_CMD")

	MyDestX = 0
	MyDestY = 0
	MyEnemy = 0
	MyState = HOLD_CMD_ST

end




function	OnSKILL_OBJECT_CMD (level,skill,id)

	TraceAI ("OnSKILL_OBJECT_CMD")

	MySkillLevel = level
	MySkill = skill
	MyEnemy = id
	MyState = CHASE_ST

	TraceAI ("SKILL_ID = "..skill)

end




function	OnSKILL_AREA_CMD (level,skill,x,y)

	TraceAI ("OnSKILL_AREA_CMD")

	Move (MyID,x,y)
	MyDestX = x
	MyDestY = y
	MySkillLevel = level
	MySkill = skill
	MyState = SKILL_AREA_CMD_ST

	TraceAI ("SKILL_ID = "..skill)
	
end




function	OnFOLLOW_CMD ()

	-- �ҋ@���߂́A�ҋ@��ԂƋx����Ԃ��݂��ɓ]��������
	if (MyState ~= FOLLOW_CMD_ST) then
		MoveToOwner (MyID)
		MyState = FOLLOW_CMD_ST
		MyDestX, MyDestY = GetV (V_POSITION,GetV(V_OWNER,MyID))
		MyEnemy = 0 
		MySkill = 0
		TraceAI ("OnFOLLOW_CMD")
	else
		MyState = IDLE_ST
		MyEnemy = 0 
		MySkill = 0
		TraceAI ("FOLLOW_CMD_ST --> IDLE_ST")
	end

end




function	ProcessCommand (msg)

	if		(msg[1] == MOVE_CMD) then
		OnMOVE_CMD (msg[2],msg[3])
		TraceAI ("MOVE_CMD")
	elseif	(msg[1] == STOP_CMD) then
		OnSTOP_CMD ()
		TraceAI ("STOP_CMD")
	elseif	(msg[1] == ATTACK_OBJECT_CMD) then
		OnATTACK_OBJECT_CMD (msg[2])
		TraceAI ("ATTACK_OBJECT_CMD")
	elseif	(msg[1] == ATTACK_AREA_CMD) then
		OnATTACK_AREA_CMD (msg[2],msg[3])
		TraceAI ("ATTACK_AREA_CMD")
	elseif	(msg[1] == PATROL_CMD) then
		OnPATROL_CMD (msg[2],msg[3])
		TraceAI ("PATROL_CMD")
	elseif	(msg[1] == HOLD_CMD) then
		OnHOLD_CMD ()
		TraceAI ("HOLD_CMD")
	elseif	(msg[1] == SKILL_OBJECT_CMD) then
		OnSKILL_OBJECT_CMD (msg[2],msg[3],msg[4],msg[5])
		TraceAI ("SKILL_OBJECT_CMD")
	elseif	(msg[1] == SKILL_AREA_CMD) then
		OnSKILL_AREA_CMD (msg[2],msg[3],msg[4],msg[5])
		TraceAI ("SKILL_AREA_CMD")
	elseif	(msg[1] == FOLLOW_CMD) then
		OnFOLLOW_CMD ()
		TraceAI ("FOLLOW_CMD")
	end
end




-------------- state process  --------------------


function	OnIDLE_ST ()
	
	TraceAI ("OnIDLE_ST")

	local cmd = List.popleft(ResCmdList)
	if (cmd ~= nil) then		
		ProcessCommand (cmd)	-- �\��R�}���h���� 
		return 
	end

	local	object = GetOwnerEnemy (MyID)
	if (object ~= 0) then							-- MYOWNER_ATTACKED_IN
		MyState = CHASE_ST
		MyEnemy = object
		TraceAI ("IDLE_ST -> CHASE_ST : MYOWNER_ATTACKED_IN")
		return 
	end

	object = GetMyEnemy (MyID)
	if (object ~= 0) then							-- ATTACKED_IN
		MyState = CHASE_ST
		MyEnemy = object
		TraceAI ("IDLE_ST -> CHASE_ST : ATTACKED_IN")
		return
	end

	local distance = GetDistanceFromOwner(MyID)
	if ( distance > 3 or distance == -1) then		-- MYOWNER_OUTSIGNT_IN
		MyState = FOLLOW_ST
		TraceAI ("IDLE_ST -> FOLLOW_ST")
		return;
	end

end




function	OnFOLLOW_ST ()

	TraceAI ("OnFOLLOW_ST")

	if (GetDistanceFromOwner(MyID) <= 3) then		--  DESTINATION_ARRIVED_IN 
		MyState = IDLE_ST
		TraceAI ("FOLLOW_ST -> IDLE_ST")
		return;
	elseif (GetV(V_MOTION,MyID) == MOTION_STAND) then
		MoveToOwner (MyID)
		TraceAI ("FOLLOW_ST -> FOLLOW_ST")
		return;
	end

end




function	OnCHASE_ST ()

	TraceAI ("OnCHASE_ST")

-- �G�������������H
	if (true == IsOutOfSight(MyID,MyEnemy)) then	-- ENEMY_OUTSIGHT_IN
		MyState = IDLE_ST
		MyEnemy = 0
		MyDestX, MyDestY = 0,0
		TraceAI ("CHASE_ST -> IDLE_ST : ENEMY_OUTSIGHT_IN")
		return
	end

-- ��l�������������H
	local max_dis = 10 -- ��l�Ƃ̍ő勗��
	local dis = GetDistanceFromOwner(MyID)
	if (dis > max_dis) then	-- ��l���痣�ꂽ�H
		MoveToOwner (MyID) -- ��l�̂��΂�
		MyState = FOLLOW_ST -- �ǔ���Ԃ�
		MyEnemy = 0 -- �G��������
		TraceAI ("CHASE_ST -> FOLLOW_ST : MASTER_OUTSIGHT_IN")
		return
	end

	if (true == IsInAttackSight(MyID,MyEnemy)) then  -- ENEMY_INATTACKSIGHT_IN
		MyState = ATTACK_ST
		TraceAI ("CHASE_ST -> ATTACK_ST : ENEMY_INATTACKSIGHT_IN")
		return
	end

	local x, y = GetV (V_POSITION,MyEnemy)
	if (MyDestX ~= x or MyDestY ~= y) then			-- DESTCHANGED_IN
		MyDestX, MyDestY = GetV (V_POSITION,MyEnemy);
		Move (MyID,MyDestX,MyDestY)
		TraceAI ("CHASE_ST -> CHASE_ST : DESTCHANGED_IN")
		return
	end

end




function	OnATTACK_ST ()

	TraceAI ("OnATTACK_ST")
	
	if (true == IsOutOfSight(MyID,MyEnemy)) then	-- ENEMY_OUTSIGHT_IN
		MyState = IDLE_ST
		TraceAI ("ATTACK_ST -> IDLE_ST")
		return 
	end

	if (MOTION_DEAD == GetV(V_MOTION,MyEnemy)) then   -- ENEMY_DEAD_IN
		MyState = IDLE_ST
		TraceAI ("ATTACK_ST -> IDLE_ST")
		return
	end

-- ��l�������������H
	local max_dis = 10 -- ��l�Ƃ̍ő勗��
	local dis = GetDistanceFromOwner(MyID)
	if (dis > max_dis) then	-- ��l���痣�ꂽ�H
		MoveToOwner (MyID) -- ��l�̂��΂�
		MyState = FOLLOW_ST -- �ǔ���Ԃ�
		MyEnemy = 0 -- �G��������
		TraceAI ("CHASE_ST -> FOLLOW_ST : MASTER_OUTSIGHT_IN")
		return
	end
		
	if (false == IsInAttackSight(MyID,MyEnemy)) then  -- ENEMY_OUTATTACKSIGHT_IN
		MyState = CHASE_ST
		MyDestX, MyDestY = GetV (V_POSITION,MyEnemy);
		Move (MyID,MyDestX,MyDestY)
		TraceAI ("ATTACK_ST -> CHASE_ST  : ENEMY_OUTATTACKSIGHT_IN")
		return
	end
	
	if (MySkill == 0) then














		local my_sp
		local ememy_hp
		my_sp = GetV (V_SP,MyID)/GetV (V_MAXSP,MyID)
		ememy_hp = GetV (V_HP,MyEnemy)/GetV (V_MAXHP,MyEnemy)
		if (my_sp > 0.5 and ememy_hp > 0.5 and MySkillMode == MODE_SKILL) then 
-- SP50%�EHP50%�ŃX�L���g�p�\���[�h
			SkillObject (MyID,5,S_MOONLIT,MyEnemy)
		else
			Attack (MyID,MyEnemy)
		end
	else
		SkillObject (MyID,MySkillLevel,MySkill,MyEnemy)
		MySkill = 0
	end
	TraceAI ("ATTACK_ST -> ATTACK_ST  : ENERGY_RECHARGED_IN")
	return


end




function	OnMOVE_CMD_ST ()

	TraceAI ("OnMOVE_CMD_ST")

	local x, y = GetV (V_POSITION,MyID)
	if (x == MyDestX and y == MyDestY) then				-- DESTINATION_ARRIVED_IN
		MyState = IDLE_ST
	end
end




function OnSTOP_CMD_ST ()


end




function OnATTACK_OBJECT_CMD_ST ()

	

end




function OnATTACK_AREA_CMD_ST ()

	TraceAI ("OnATTACK_AREA_CMD_ST")

	local	object = GetOwnerEnemy (MyID)
	if (object == 0) then							
		object = GetMyEnemy (MyID) 
	end

	if (object ~= 0) then							-- MYOWNER_ATTACKED_IN or ATTACKED_IN
		MyState = CHASE_ST
		MyEnemy = object
		return
	end

	local x , y = GetV (V_POSITION,MyID)
	if (x == MyDestX and y == MyDestY) then			-- DESTARRIVED_IN
			MyState = IDLE_ST
	end

end




function OnPATROL_CMD_ST ()

	TraceAI ("OnPATROL_CMD_ST")

	local	object = GetOwnerEnemy (MyID)
	if (object == 0) then							
		object = GetMyEnemy (MyID) 
	end

	if (object ~= 0) then							-- MYOWNER_ATTACKED_IN or ATTACKED_IN
		MyState = CHASE_ST
		MyEnemy = object
		TraceAI ("PATROL_CMD_ST -> CHASE_ST : ATTACKED_IN")
		return
	end

	local x , y = GetV (V_POSITION,MyID)
	if (x == MyDestX and y == MyDestY) then			-- DESTARRIVED_IN
		MyDestX = MyPatrolX
		MyDestY = MyPatrolY
		MyPatrolX = x
		MyPatrolY = y
		Move (MyID,MyDestX,MyDestY)
	end

end




function OnHOLD_CMD_ST ()

	TraceAI ("OnHOLD_CMD_ST")
	
	if (MyEnemy ~= 0) then
		local d = GetDistance(MyEnemy,MyID)
		if (d ~= -1 and d <= GetV(V_ATTACKRANGE,MyID)) then
				Attack (MyID,MyEnemy)
		else
			MyEnemy = 0;
		end
		return
	end


	local	object = GetOwnerEnemy (MyID)
	if (object == 0) then							
		object = GetMyEnemy (MyID)
		if (object == 0) then						
			return
		end
	end

	MyEnemy = object

end




function OnSKILL_OBJECT_CMD_ST ()
	
end




function OnSKILL_AREA_CMD_ST ()

	TraceAI ("OnSKILL_AREA_CMD_ST")

	local x , y = GetV (V_POSITION,MyID)
	if (GetDistance(x,y,MyDestX,MyDestY) <= GetV(V_SKILLATTACKRANGE,MyID,MySkill)) then	-- DESTARRIVED_IN
		SkillGround (MyID,MySkillLevel,MySkill,MyDestX,MyDestY)
		MyState = IDLE_ST
		MySkill = 0
	end

end







function OnFOLLOW_CMD_ST ()

	TraceAI ("OnFOLLOW_CMD_ST")

	local ownerX, ownerY, myX, myY
	ownerX, ownerY = GetV (V_POSITION,GetV(V_OWNER,MyID)) -- ������
	myX, myY = GetV (V_POSITION,MyID)					  -- ���� 
	
	local d = GetDistance (ownerX,ownerY,myX,myY)

	if ( d <= 3) then									-- 3�Z���ȉ��̋����Ȃ�
		return 
	end

	local motion = GetV (V_MOTION,MyID)
	if (motion == MOTION_MOVE) then					-- �ړ���
		d = GetDistance (ownerX, ownerY, MyDestX, MyDestY)
		if ( d > 3) then									-- 4�Z���ȏ�̋����Ȃ�
			MoveToOwner (MyID)
			MyDestX = ownerX
			MyDestY = ownerY
			return
		end
	else									-- ���̓��� 
		MoveToOwner (MyID)
		MyDestX = ownerX
		MyDestY = ownerY
		return
	end
	
end








function	GetOwnerEnemy (myid)
	local result = 0
	local owner  = GetV (V_OWNER,myid)
	local actors = GetActors ()
	local enemys = {}
	local index = 1
	local target
	for i,v in ipairs(actors) do
		if (v ~= owner and v ~= myid) then
			target = GetV (V_TARGET,v)
			if (target == owner) then
				if (IsMonster(v) == 1) then
					enemys[index] = v
					index = index+1
				else
					local motion = GetV(V_MOTION,i)
					if (motion == MOTION_ATTACK or motion == MOTION_ATTACK2) then
						enemys[index] = v
						index = index+1
					end
				end
			end
		end
	end

	local min_dis = 100
	local dis
	for i,v in ipairs(enemys) do
		dis = GetDistance2 (myid,v)
		if (dis < min_dis) then
			result = v
			min_dis = dis
		end
	end
	
	return result
end





function	GetMyEnemy (myid)
	local result = 0
	local owner  = GetV (V_OWNER,myid)
	local actors = GetActors ()
	local enemys = {}
	local index = 1
	local target
	local get_flg = 0 -- �G�����t���O

-- �������U������G��T��
	for i,v in ipairs(actors) do
		if (v ~= owner and v ~= myid) then
			target = GetV (V_TARGET,v)
			if (target == myid) then
				enemys[index] = v
				index = index+1
				get_flg = 1 -- �G����
			end
		end
	end

-- ���̓G��T��
	if (get_flg == 0 and MyActiveMode == MODE_ACTIVE) then
	-- �������U������G�����Ȃ��H �� ��������U���[�h�H
		local max_dis = 10 -- ���G�͈�
		local target_dis
		for i,v in ipairs(actors) do -- �G��T��
			if (v ~= owner and v ~= myid) then
				target_dis = GetDistance2 (myid,v) -- �����v�Z
				if (target_dis < max_dis) then -- �߂��Ƃ���ɂ���H
					if (1 == IsMonster(v))	then
						target = GetV (V_TARGET,v) -- �Ώۂ̃^�[�Q�b�g�m�F
						if (target == 0) then -- �^�[�Q�b�g�����Ȃ�
							enemys[index] = v
							index = index+1
							get_flg = 1
						end
					end
				end
			end
		end
	end

-- ��ԋ߂��G��T��
	if (get_flg == 1) then -- �G������
		local min_dis = 100
		local dis
		for i,v in ipairs(enemys) do
			dis = GetDistance2 (myid,v)
			if (dis < min_dis) then
				result = v
				min_dis = dis
			end
		end
	end

	return result
end



function CheckMoveCommand()

	local ownerX, ownerY
	ownerX, ownerY = GetV (V_POSITION,GetV(V_OWNER,MyID)) -- ��l�̍��W

-- ��U�E���U�؂�ւ�
	if (MyDestY == ownerY) then
		if (ActiveModeCounter == 0 and MyDestX == ownerX+1) then -- �E
			ActiveModeCounter = 1
		elseif (ActiveModeCounter == 1 and MyDestX == ownerX-1) then -- ��
			ActiveModeCounter = 2
		elseif (ActiveModeCounter == 2 and MyDestX == ownerX+1) then -- �E
			ActiveModeCounter = 0
			if (MyActiveMode == MODE_NONACTIVE) then -- ��U�؂�ւ�
				MyActiveMode = MODE_ACTIVE
			else
				MyActiveMode = MODE_NONACTIVE
			end
		else
			ActiveModeCounter = 0
		end
	else
		ActiveModeCounter = 0
	end


-- �X�L���g�p�؂�ւ�
	if (MyDestX == ownerX) then
		if (SkillModeCounter == 0 and MyDestY == ownerY+1) then -- ��
			SkillModeCounter = 1
		elseif (SkillModeCounter == 1 and MyDestY == ownerY-1) then -- ��
			SkillModeCounter = 2
		elseif (SkillModeCounter == 2 and MyDestY == ownerY+1) then -- ��
			SkillModeCounter = 0
			if (MySkillMode == MODE_NONSKILL) then -- �X�L���؂�ւ�
				MySkillMode = MODE_SKILL
			else
				MySkillMode = MODE_NONSKILL
			end
		else
			SkillModeCounter = 0
		end
	else
		SkillModeCounter = 0
	end

-- �t���b�g���[�u�g�p�؂�ւ�
	if (FleetModeCounter == 0 and MyDestX == ownerX-1 and MyDestY == ownerY) then -- ��
		FleetModeCounter = 1
	elseif (FleetModeCounter == 1 and MyDestX == ownerX and MMyDestY == ownerY+1) then -- ��
		FleetModeCounter = 2
	elseif (FleetModeCounter == 2 and MyDestX == ownerX-1 and MyDestY == ownerY) then -- ��
		FleetModeCounter = 0
		if (MyFleetMode == MODE_NONFLEET) then -- �X�L���؂�ւ�
			MyFleetMode = MODE_FLEET
		else
			MyFleetMode = MODE_NONFLEET
		end
	else
		FleetModeCounter = 0
	end
end




function AI(myid)

	MyID = myid
	local msg	= GetMsg (myid)			-- command
	local rmsg	= GetResMsg (myid)		-- reserved command

	
	if msg[1] == NONE_CMD then
		if rmsg[1] ~= NONE_CMD then
			if List.size(ResCmdList) < 10 then
				List.pushright (ResCmdList,rmsg) -- �\��R�}���h�ۑ�
			end
		end
	else
		List.clear (ResCmdList)	-- �V�����R�}���h�����͂��ꂽ��A�\��R�}���h�͍폜����
		ProcessCommand (msg)	-- �R�}���h���� 
	end

		
	-- ��ԏ��� 
 	if (MyState == IDLE_ST) then
		OnIDLE_ST ()
	elseif (MyState == CHASE_ST) then					
		OnCHASE_ST ()
	elseif (MyState == ATTACK_ST) then
		OnATTACK_ST ()
	elseif (MyState == FOLLOW_ST) then
		OnFOLLOW_ST ()
	elseif (MyState == MOVE_CMD_ST) then
		OnMOVE_CMD_ST ()
	elseif (MyState == STOP_CMD_ST) then
		OnSTOP_CMD_ST ()
	elseif (MyState == ATTACK_OBJECT_CMD_ST) then
		OnATTACK_OBJECT_CMD_ST ()
	elseif (MyState == ATTACK_AREA_CMD_ST) then
		OnATTACK_AREA_CMD_ST ()
	elseif (MyState == PATROL_CMD_ST) then
		OnPATROL_CMD_ST ()
	elseif (MyState == HOLD_CMD_ST) then
		OnHOLD_CMD_ST ()
	elseif (MyState == SKILL_OBJECT_CMD_ST) then
		OnSKILL_OBJECT_CMD_ST ()
	elseif (MyState == SKILL_AREA_CMD_ST) then
		OnSKILL_AREA_CMD_ST ()
	elseif (MyState == FOLLOW_CMD_ST) then
		OnFOLLOW_CMD_ST ()
	end

end
