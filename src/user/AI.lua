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
---- 修正履歴 ----
-- 
-- v1.0 2006/03/25 コメント挿入
-- v1.1 2006/03/27 GetMyEnemy修正
-- v1.2 2006/03/30 索敵範囲指定
-- v1.3 2006/04/03 横殴り防止
-- v1.4 2006/04/09 スキル自動使用
-- 
-- v2.0 2006/04/23 切り替えコマンド実装
-- v2.1 2007/08/25 フリットムーブの自動化実装
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
MyState				= IDLE_ST	-- 最初の状態は休息
MyEnemy				= 0		-- 敵 id
MyDestX				= 0		-- 目的地 x座標
MyDestY				= 0		-- 目的地 y座標
MyPatrolX				= 0		-- 偵察目的地 x座標
MyPatrolY				= 0		-- 偵察目的地 y座標
ResCmdList				= List.new()	-- 予約コマンドリスト
MyID					= 0		-- ホムンクルス id
MySkill					= 0		-- ホムンクルスのスキル
MySkillLevel				= 0		-- ホムンクルスのスキルレベル
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
MODE_ACTIVE       = 0	 -- 先攻モード
MODE_NONACTIVE    = 1	 -- 非先攻モード
MyActiveMode = MODE_NONACTIVE	 -- 先攻モードフラグ
ActiveModeCounter = 0	 -- コマンドカウンター

MODE_SKILL       = 0	 -- スキル使用不可
MODE_NONSKILL    = 1	 -- スキル使用可
MySkillMode = MODE_SKILL	 -- スキル使用フラグ
SkillModeCounter = 0	 -- コマンドカウンター

MODE_FLEET       = 0	 -- フリットムーブ使用不可
MODE_NONFLEET    = 1	 -- フリットムーブ使用可
MyFleetMode = MODE_FLEET	 -- フリットムーブ使用フラグ
FleetModeCounter = 0	 -- フリットムーブカウンター
------------------------------------------




------------- command process  ---------------------

function	OnMOVE_CMD (x,y)
	
	TraceAI ("OnMOVE_CMD")

	if ( x == MyDestX and y == MyDestY and MOTION_MOVE == GetV(V_MOTION,MyID)) then
		return		-- 目的地と現在地が同一の場合は、処理しない
	end

	local curX, curY = GetV (V_POSITION,MyID)
	if (math.abs(x-curX)+math.abs(y-curY) > 15) then		-- 目的地が一定距離以上なら (サーバーで遠距離は処理しないため)
		List.pushleft (ResCmdList,{MOVE_CMD,x,y})			-- 元の目的地への移動を予約する
		x = math.floor((x+curX)/2)							-- 中間地点へ移動する
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

	-- 待機命令は、待機状態と休息状態を互いに転換させる
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
		ProcessCommand (cmd)	-- 予約コマンド処理 
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

-- 敵を見失ったか？
	if (true == IsOutOfSight(MyID,MyEnemy)) then	-- ENEMY_OUTSIGHT_IN
		MyState = IDLE_ST
		MyEnemy = 0
		MyDestX, MyDestY = 0,0
		TraceAI ("CHASE_ST -> IDLE_ST : ENEMY_OUTSIGHT_IN")
		return
	end

-- 主人を見失ったか？
	local max_dis = 10 -- 主人との最大距離
	local dis = GetDistanceFromOwner(MyID)
	if (dis > max_dis) then	-- 主人から離れた？
		MoveToOwner (MyID) -- 主人のそばへ
		MyState = FOLLOW_ST -- 追尾状態へ
		MyEnemy = 0 -- 敵を初期化
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

-- 主人を見失ったか？
	local max_dis = 10 -- 主人との最大距離
	local dis = GetDistanceFromOwner(MyID)
	if (dis > max_dis) then	-- 主人から離れた？
		MoveToOwner (MyID) -- 主人のそばへ
		MyState = FOLLOW_ST -- 追尾状態へ
		MyEnemy = 0 -- 敵を初期化
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
-- SP50%・HP50%でスキル使用可能モード
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
	ownerX, ownerY = GetV (V_POSITION,GetV(V_OWNER,MyID)) -- 持ち主
	myX, myY = GetV (V_POSITION,MyID)					  -- 自分 
	
	local d = GetDistance (ownerX,ownerY,myX,myY)

	if ( d <= 3) then									-- 3セル以下の距離なら
		return 
	end

	local motion = GetV (V_MOTION,MyID)
	if (motion == MOTION_MOVE) then					-- 移動中
		d = GetDistance (ownerX, ownerY, MyDestX, MyDestY)
		if ( d > 3) then									-- 4セル以上の距離なら
			MoveToOwner (MyID)
			MyDestX = ownerX
			MyDestY = ownerY
			return
		end
	else									-- 他の動作 
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
	local get_flg = 0 -- 敵発見フラグ

-- 自分を攻撃する敵を探す
	for i,v in ipairs(actors) do
		if (v ~= owner and v ~= myid) then
			target = GetV (V_TARGET,v)
			if (target == myid) then
				enemys[index] = v
				index = index+1
				get_flg = 1 -- 敵発見
			end
		end
	end

-- 他の敵を探す
	if (get_flg == 0 and MyActiveMode == MODE_ACTIVE) then
	-- 自分を攻撃する敵がいない？ ＆ 自分が先攻モード？
		local max_dis = 10 -- 索敵範囲
		local target_dis
		for i,v in ipairs(actors) do -- 敵を探す
			if (v ~= owner and v ~= myid) then
				target_dis = GetDistance2 (myid,v) -- 距離計算
				if (target_dis < max_dis) then -- 近いところにいる？
					if (1 == IsMonster(v))	then
						target = GetV (V_TARGET,v) -- 対象のターゲット確認
						if (target == 0) then -- ターゲットがいない
							enemys[index] = v
							index = index+1
							get_flg = 1
						end
					end
				end
			end
		end
	end

-- 一番近い敵を探す
	if (get_flg == 1) then -- 敵がいる
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
	ownerX, ownerY = GetV (V_POSITION,GetV(V_OWNER,MyID)) -- 主人の座標

-- 先攻・非先攻切り替え
	if (MyDestY == ownerY) then
		if (ActiveModeCounter == 0 and MyDestX == ownerX+1) then -- 右
			ActiveModeCounter = 1
		elseif (ActiveModeCounter == 1 and MyDestX == ownerX-1) then -- 左
			ActiveModeCounter = 2
		elseif (ActiveModeCounter == 2 and MyDestX == ownerX+1) then -- 右
			ActiveModeCounter = 0
			if (MyActiveMode == MODE_NONACTIVE) then -- 先攻切り替え
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


-- スキル使用切り替え
	if (MyDestX == ownerX) then
		if (SkillModeCounter == 0 and MyDestY == ownerY+1) then -- 上
			SkillModeCounter = 1
		elseif (SkillModeCounter == 1 and MyDestY == ownerY-1) then -- 下
			SkillModeCounter = 2
		elseif (SkillModeCounter == 2 and MyDestY == ownerY+1) then -- 上
			SkillModeCounter = 0
			if (MySkillMode == MODE_NONSKILL) then -- スキル切り替え
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

-- フリットムーブ使用切り替え
	if (FleetModeCounter == 0 and MyDestX == ownerX-1 and MyDestY == ownerY) then -- 左
		FleetModeCounter = 1
	elseif (FleetModeCounter == 1 and MyDestX == ownerX and MMyDestY == ownerY+1) then -- 上
		FleetModeCounter = 2
	elseif (FleetModeCounter == 2 and MyDestX == ownerX-1 and MyDestY == ownerY) then -- 左
		FleetModeCounter = 0
		if (MyFleetMode == MODE_NONFLEET) then -- スキル切り替え
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
				List.pushright (ResCmdList,rmsg) -- 予約コマンド保存
			end
		end
	else
		List.clear (ResCmdList)	-- 新しいコマンドが入力されたら、予約コマンドは削除する
		ProcessCommand (msg)	-- コマンド処理 
	end

		
	-- 状態処理 
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
