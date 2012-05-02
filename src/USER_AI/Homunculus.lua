-- ホムンクルスの基本動作オブジェクト
-- 継承先で必要なメソッドのみ書き換えることを想定
-- できるだけフラグで動作を変えられるようにしたい
Homunculus = {}
Homunculus.new = function(id)
  if id == nil then return end

  local this = {}
  this.className = 'Homunculus' -- 自身のクラス名
  this.id = id -- 自身のid
  this.state = IDLE_ST -- 現在の状態
  this.enemy = nil -- ターゲットしている敵のid
  this.owner = GetV(V_OWNER, id) -- 主人のid
  this.commands = Array.new(RES_COMMAND_SIZE) -- 予約コマンドバッファ
  this.distX = -1 -- 目的地:X座標
  this.distY = -1 -- 目的地:Y座標
  this.patrolX = -1 -- パトロール用位置バッファ:X座標
  this.patrolY = -1 -- パトロール用位置バッファ:Y座標
  this.skill = nil   -- 使おうとしているスキル
  this.skillLv = nil -- 使おうとしているスキルのLv
  this.smoothMoveCounter = 0 -- 等速移動用カウンタ

  -- 主人との至近距離
  this.aroundDistance = Config.AroundDistance
  -- 索敵範囲
  this.searchDistance = Config.SearchDistance
  -- 主人との最大距離
  this.followDistance = Config.FollowDistance

  -- 設定情報
  this.setting = Setting.new(SETTING_FILE_NAME)

  -- デバッグ出力
  this.putsDebug = function(self, msg)
    if msg == nil or msg == '' then
      return
    end
    local log = self.className..' :: '..msg

    if Config.UseTraceAI then
      TraceAI(log)
    end

    if (not Config.DebugMode) then
      return
    end

    if self.logger == nil then
      self.logger = Logger.new(DEBUG_LOG_FILE_NAME)
    end

    self.logger:write(log)
  end

  -----------------------------
  -- ステータス関係
  -----------------------------

  -- 自身と主人以外のデータは取れない

  -- 現在のHP取得
  this.getHp = function(self, id)
    return GetV(V_HP, id)
  end

  -- 現在のSP取得
  this.getSp = function(self, id)
    return GetV(V_SP, id)
  end

  -- MAXHP取得
  this.getMaxHp = function(self, id)
    return GetV(V_MAXHP, id)
  end

  -- MAXSP取得
  this.getMaxSp = function(self, id)
    return GetV(V_MAXSP, id)
  end

  -- 現在のHP取得（自分自身）
  this.getMyHp = function(self)
    return self:getHp(self.id)
  end

  -- 現在のSP取得（自分自身）
  this.getMySp = function(self)
    return self:getSp(self.id)
  end

  -- MAXHP取得（自分自身）
  this.getMyMaxHp = function(self, id)
    return self:getMaxHp(self.id)
  end

  -- MAXSP取得（自分自身）
  this.getMyMaxSp = function(self, id)
    return self:getMaxSp(self.id)
  end

  -- 現在のHP取得（主人）
  this.getOwnerHp = function(self)
    return self:getHp(self.owner)
  end

  -- 現在のSP取得（主人）
  this.getOwnerSp = function(self)
    return self:getSp(self.owner)
  end

  -- MAXHP取得（主人）
  this.getOwnerMaxHp = function(self, id)
    return self:getMaxHp(self.owner)
  end

  -- MAXSP取得（主人）
  this.getOwnerMaxSp = function(self, id)
    return self:getMaxSp(self.owner)
  end

  -- 残存HPの割合%（自分自身）
  this.leftMyHpRatio = function(self)
    return (self:getMyHp() / self:getMyMaxHp()) * 100
  end

  -- 残存SPの割合%（自分自身）
  this.leftMySpRatio = function(self)
    return (self:getMySp() / self:getMyMaxSp()) * 100
  end

  -- 残存HPの割合%（主人）
  this.leftOwnerHpRatio = function(self)
    return (self:getOwnerHp() / self:getOwnerMaxHp()) * 100
  end

  -- 残存SPの割合%（主人）
  this.leftOwnerSpRatio = function(self)
    return (self:getOwnerSp() / self:getOwnerMaxSp()) * 100
  end

  -- 積極的モードか？
  -- 指定割合よりもHPが残っている
  this.isPositive = function(self)
    if self:leftMyHpRatio() > Config.HpRatioForPositive then
      return true
    end
    return false
  end

  -- 消極的モードか？
  -- 指定割合よりもHPが減っている
  this.isNegative = function(self)
    if self:leftMyHpRatio() < Config.HpRatioForNegative then
      return true
    end
    return false
  end

  -- IDから対象が何者かを判断する
  -- 大雑把な分類だけで、具体的な分類は考慮しない
  -- モンスターかの判別はisMonster()の方を
  this.checkIdType = function(self, id)
    if id == nil then return end

    -- プレイヤー
    if id >= MIN_PLAYERS_ID then
      return 'PLAYER'
    end

    -- タイプから判別する
    local t = GetV(V_HOMUNTYPE, id)
    if (t >= 1 and t <= 16) then
      -- ホムの種類・・・だけど、スーパーホムは考慮してない
      return 'HOMUNCULUS'
    elseif (t >= 46 and t <= 999) then
      -- NPCの種類・・・だけど、本当はもっと厳密？
      return 'NPC'
    elseif (t >= 1001) then
      -- 1001以上にはプレイヤーもいるけど、idで先に除外されている
      -- 上界不明
      return 'MONSTER'
    else
      -- 知らないのでnil
      return
    end
  end

  -----------------------------
  -- 設定関係
  -----------------------------

  -- 保存用key名
  -- クラス名で名前空間を分ける
  this.createSettingKey = function(self, key)
    return self.className..':'..key
  end

  -- 設定保存
  this.setSetting = function(self, key, val)
    self.setting:set(self:createSettingKey(key), val)
  end

  -- 設定取得
  this.getSetting = function(self, key)
    return self.setting:get(self:createSettingKey(key))
  end

  -- 指定された設定をON
  this.setSwitchSettingOn = function(self, key)
    self:setSetting(key, '1')
  end

  -- 指定された設定をOFF
  this.setSwitchSettingOff = function(self, key)
    self:setSetting(key, '0')
  end

  -- 指定されたスイッチはONか？
  this.isSwitchSettingOn = function(self, key)
    if (self:getSetting(key) == '1') then
      return true
    end
    return false
  end

  -- 先制モード設定:ON
  this.setFirstAttackOn = function(self)
    self:setSwitchSettingOn(SETTING_KEY_FIRST_ATTACK)
  end

  -- 先制モード設定:OFF
  this.setFirstAttackOff = function(self)
    self:setSwitchSettingOff(SETTING_KEY_FIRST_ATTACK)
  end

  -- 先制モードか？
  -- 未設定ならfalse
  this.isFirstAttack = function(self)
    return self:isSwitchSettingOn(SETTING_KEY_FIRST_ATTACK)
  end

  -- 先制モードスイッチ反転
  this.switchFirstAttack = function(self)
    if self:isFirstAttack() then
      self:setFirstAttackOff()
    else
      self:setFirstAttackOn()
    end
  end

  -- 自動スキル使用設定:ON
  this.setAutoSkillOn = function(self)
    self:setSwitchSettingOn(SETTING_KEY_AUTO_SKILL)
  end

  -- 自動スキル使用設定:OFF
  this.setAutoSkillOff = function(self)
    self:setSwitchSettingOff(SETTING_KEY_AUTO_SKILL)
  end

  -- 自動スキルモードか？
  -- 未設定ならfalse
  this.isAutoSkill = function(self)
    return self:isSwitchSettingOn(SETTING_KEY_AUTO_SKILL)
  end

  -- 自動スキルスイッチ反転
  this.switchAutoSkill = function(self)
    if self:isAutoSkill() then
      self:setAutoSkillOff()
    else
      self:setAutoSkillOn()
    end
  end

  -----------------------------
  -- 座標関係
  -----------------------------

  -- 位置座標取得
  this.getPosition = function(self, id)
    return GetV(V_POSITION, id)
  end

  -- 二点間の距離取得 / 引数が負なら-1
  this.getDistance = function(self, x1, y1, x2, y2)
    if (x1 < 0 or x2 < 0 or y1 < 0 or y2 < 0) then
      return -1
    end
    return math.floor(math.sqrt((x1-x2)^2+(y1-y2)^2))
  end

  -- 二者間の距離取得
  this.getDistanceBetween = function(self, id1, id2)
    local x1, y1 = self:getPosition(id1)
    local x2, y2 = self:getPosition(id2)
    return self:getDistance(x1, y1, x2, y2)
  end

  -- 自身から相手への距離取得
  this.distanceFor = function(self, id)
    return self:getDistanceBetween(self.id, id)
  end

  -- 主人への距離取得
  this.distanceForOwner = function(self)
    return self:distanceFor(self.owner)
  end

  -- 見失う距離か？
  this.isOutOfSightDistance = function(self, d)
    if (d < 0 or d > 20) then
      return true
    end
    return false
  end

  -- 主人のそばにいる？
  this.isAroundOwner = function(self)
    local d = self:distanceForOwner()
    if (d < 0 or d > this.aroundDistance) then
      return false
    end
    return true
  end

  -- 主人と離れすぎか？
  this.isOverFollowDistance = function(self)
    local d = self:distanceForOwner()
    if (d < 0 or d > self.followDistance) then
      return true
    end
    return false
  end

  -- 自分の位置座標取得
  this.getSelfPosition = function(self)
    return self:getPosition(self.id)
  end

  -- 主人の位置座標取得
  this.getOwnerPosition = function(self)
    return self:getPosition(self.owner)
  end

  -- 二点間の距離取得（ベクトル的な距離ではなく、ゲーム内のセル数基準）
  this.getCellDistance = function(self, x1, y1, x2, y2)
    if (x1 < 0 or x2 < 0 or y1 < 0 or y2 < 0) then
      return -1
    end
    return (math.abs(x1 - x2) + math.abs(y1 - y2))
  end

  -----------------------------
  -- モーション関係
  -----------------------------

  -- 対象はそのモーションをとっているか？
  this.isMotion = function(self, id, motion)
    if (GetV(V_MOTION, id) == motion) then
      return true
    end
    return false
  end

  -- 対象は立っているか？
  this.isStandMotion = function(self, id)
    return self:isMotion(id, MOTION_STAND)
  end

  -- 対象は移動中か？
  this.isMoveMotion = function(self, id)
    return self:isMotion(id, MOTION_MOVE)
  end

  -- 対象は攻撃中か？
  this.isAttackMotion = function(self, id)
    return (self:isMotion(id, MOTION_ATTACK) or self:isMotion(id, MOTION_ATTACK2))
  end

  -- 対象は死亡しているか？
  this.isDeadMotion = function(self, id)
    return self:isMotion(id, MOTION_DEAD)
  end

  -- 対象は被弾しているか？
  this.isDamageMotion = function(self, id)
    return self:isMotion(id, MOTION_DAMAGE)
  end

  -- 対象はかがんでいるか？
  this.isBenddownMotion = function(self, id)
    return self:isMotion(id, MOTION_BENDDOWN)
  end

  -- 対象は座っているか？
  this.isSitMotion = function(self, id)
    return self:isMotion(id, MOTION_SIT)
  end

  -- 対象はスキルを使っているか？
  this.isSkillMotion = function(self, id)
    return self:isMotion(id, MOTION_SKILL)
  end

  -- 対象は詠唱中か？
  this.isCastingMotion = function(self, id)
    return self:isMotion(id, MOTION_CASTING)
  end

  -- 対象は戦闘っぽい行動を取っているか？
  this.isBattleMotion = function(self, id)
    return ( self:isAttackMotion(id) or self:isSkillMotion(id) or self:isCastingMotion(id) )
  end

  -----------------------------
  -- 移動関係
  -----------------------------

  -- 目的値を設定
  this.setDist = function(self, x, y)
    self.distX = x
    self.distY = y
  end

  -- 目的地リセット
  this.resetDist = function(self)
    self.distX = -1
    self.distY = -1
  end

  -- 目的地が存在するか？
  this.hasDist = function(self)
    if (self.distX < 0 or self.distY < 0) then
      return false
    end
    return true
  end

  -- 目的地へ移動（distX/distYの場所へ）
  this.moveToDist = function(self)
    if self:hasDist() then
      Move(self.id, self.distX, self.distY)
    end
  end

  -- 指定ポイントへ移動（distX/distYを更新）
  this.moveTo = function(self, x, y)
    self:setDist(x, y)
    self:moveToDist()
  end

  -- 目的地までの距離
  this.getDistanceToDist = function(self)
    if (not self:hasDist()) then
      return -1
    end

    local x, y = self:getSelfPosition()
    return self:getDistance(x, y, self.distX, self.distY)
  end

  -- 主人へ向かって移動（目的地は更新しない）
  this.moveToOwner = function(self)
    MoveToOwner(self.id)
  end

  -- 主人へ向かって移動（目的地も更新する）
  this.moveToOwnerPosition = function(self)
    local x, y = self:getOwnerPosition()
    self:setDist(x, y)
    self:moveToOwner()
  end

  -- 自分は立っている状態か？
  this.isStanding = function(self)
    return self:isStandMotion(self.id)
  end

  -- 自分は移動中か？
  this.isMoving = function(self)
    return self:isMoveMotion(self.id)
  end

  -- 目的地にたどり着いた？
  this.isArrive = function(self)
    local x, y = self:getSelfPosition()
    if (x == self.distX and y == self.distY) then
      return true
    end
    return false
  end

  -- パトロール開始
  -- 現座標と指定された座標との往復を開始する
  this.startPatrol = function(self, dx, dy)
    local sx, sy = self:getSelfPosition()
    self.patrolX = sx
    self.patrolY = sy
    self:moveTo(dx, dy)
  end

  -- パトロール巡回
  -- 位置の入れ替えをおこなう
  this.moveForPatrol = function(self)
    local x, y = self:getSelfPosition()
    local px = self.patrolX
    local py = self.patrolY
    self.patrolX = x
    self.patrolY = y
    self:moveTo(px, py)
  end

  -- 移動停止
  -- 今の場所に移動＝停止して、目的値をクリアする
  this.stopMoving = function(self)
    local sx, sy = self:getSelfPosition()
    self:moveTo(sx, sy)
    self:resetDist()
  end

  -- 主人をなめらかに追尾する
  -- ケミWikiのホム等速移動参照
  this.moveToOwnerSmoothly = function(self)
    self.smoothMoveCounter = self.smoothMoveCounter + 1
    -- 停止時だけでなく、移動中も位置を更新することで、なめらかに追いかける
    if (self:isStanding() or self:isMoving()) then
      -- ただし処理（パケット）が増えすぎるので、ある程度抑制を入れる
      if (self.smoothMoveCounter >= Config.SmoothMoveDelay) then
        -- おそらくケミWikiの実装を素直に取り入れると動かない
        -- 「主人の位置」にmoveしようとするため、すでにキャラがいると認識され動かない？
        self:moveToOwnerPosition()
        self.smoothMoveCounter = 0
      end
    end
  end

  -----------------------------
  -- 索敵関係
  -----------------------------

  -- モンスターかの判定
  this.isMonster = function(self, id)
    if (IsMonster(id) == 1) then
      return true
    end
    return false
  end

  -- 攻撃対象取得
  this.targetFor = function(self, id)
    local t = GetV(V_TARGET, id)
    if t == 0 then
      return
    end
    return t
  end

  -- 攻撃対象をリセット
  this.resetEnemy = function(self)
    self.emeny = nil
    self:resetDist()
  end

  -- フリーなモンスターか？
  this.isFreeMonster = function(self, id)
    -- モンスターじゃない
    if (not self:isMonster(id)) then
      return false
    end

    -- 何もしていない（モンスターNPC対策）
    if Config.ExcludeStandMonster and self:isStandMotion(id) then
      return false
    end

    -- ターゲットが存在し、自身でも主人でもない（横殴り対策）
    local t = self:targetFor(id)
    if t ~= nil and t ~= self.id and t ~= self.owner then
      return false
    end

    return true
  end

  -- 対象から一番近いものをtableから探す
  this.nearestFor = function(self, id, t)
    if t == nil then return end

    local rsl = nil
    local min = 100
    for i,v in ipairs(t) do
      local d = self:getDistanceBetween(id, v)
      if (d < min) then
        rsl = v
        min = d
      end
    end

    return rsl
  end

  -- 指定された対象を攻撃する相手を取得
  this.getAttackerFor = function(self, id)
    local enemys
    local index = 1
    enemys = {}

    for i,v in ipairs(GetActors()) do -- 周囲のオブジェクトをparse
      if v ~= id then -- 対象自身は除外
        if self:targetFor(v) == id then -- 対象がターゲット？
          -- モンスターか、自分に攻撃モーションを取るのは敵
          if self:isMonster(v) or self:isAttackMotion(v) then
            enemys[index] = v
            index = index + 1
          end
        end
      end
    end

    if index > 1 then
      return enemys
    else
      return
    end
  end

  -- 主人の攻撃対象を取得
  this.getEnemyForOwner = function(self)
    -- 主人を攻撃するもので、一番近いもの
    return self:nearestFor(self.owner, self:getAttackerFor(self.owner))
  end

  -- 自身の攻撃対象を取得
  this.getEnemyForSelf = function(self)
    -- 自分を攻撃するもので、一番近いもの
    return self:nearestFor(self.id, self:getAttackerFor(self.id))
  end

  -- 主人と自分を攻撃する敵を取得
  -- Configで設定された優先順位に従う
  this.getEnemyForOurs = function(self)
    if Config.AttackPriorityForSelf then
      return (self:getEnemyForSelf() or self:getEnemyForOwner())
    else
      return (self:getEnemyForOwner() or self:getEnemyForSelf())
    end
  end

  -- 索敵する
  this.searchEnemy = function(self)
    -- 敵を探す
    local enemys
    local index = 1
    enemys = {}
    for i,v in ipairs(GetActors()) do
      -- 自身と主人は除外
      if (v ~= self.id and v ~= self.owner) then
        -- 攻撃してもよいモンスターか？
        if self:isFreeMonster(v) then
          -- 索敵範囲内
          if self:distanceFor(v) <= self.searchDistance then
            enemys[index] = v
            index = index + 1
          end
        end
      end
    end

    -- 一番近いやつ
    return self:nearestFor(self.id, enemys)
  end

  -- 敵は死んでいる？（あるいは存在しない？）
  this.isEnemyDead = function(self)
    if self.enemy == nil then
      return true
    end

    if self:isDeadMotion(self.enemy) then
      return true
    end

    return false
  end

  -----------------------------
  -- 攻撃・スキル関係
  -----------------------------

  -- スキル予約
  this.setSkill = function(self, sid, slv)
    self.skill = sid
    self.skillLv = slv
  end

  -- スキルリセット
  this.resetSkill = function(self)
    self.skill = nil
    self.skillLv = nil
  end

  -- スキル使用準備できているか？
  this.isSkillReady = function(self)
    if (self.skill and self.skillLv) then
      return true
    end
    return false
  end

  -- 単体スキル使用
  -- tid:ターゲット
  this.useSkill = function(self, tid)
    if (not self:isSkillReady()) then
      return
    end

    SkillObject(self.id, self.skillLv, self.skill, tid)
    self:resetSkill()
  end

  -- 範囲スキル使用
  -- distに展開ポイントを格納しておく
  this.useGroundSkill = function(self)
    if (self.isSkillReady() and self:hasDist()) then
      SkillGround(self.id, self.skillLv, self.skill, self.distX, self.distY)
      self:resetSkill()
    end
  end

  -- スキルの射程
  this.skillRange = function(self, sid)
    if sid == nil then
      return -1
    end
    return GetV(V_SKILLATTACKRANGE, self.id, sid)
  end

  -- 直接攻撃射程
  this.attackRange = function(self)
    return GetV(V_ATTACKRANGE, self.id)
  end

  -- 自身が攻撃可能な相手か？
  this.isInAttackSight = function(self, id)
    local d = self:distanceFor(id)
    if self:isOutOfSightDistance(d) then
      return false
    end

    -- スキル待機中ならスキルの射程
    local range = 0
    if self:isSkillReady() then
      range = self:skillRange(self.skill)
    else
      range = self:attackRange()
    end

    if (range < d) then
      return false
    end

    return true
  end

  -- 敵を攻撃可能？
  this.isEnemyInAttackSight = function(self)
    if self.enemy == nil then
      return false
    end
    return self:isInAttackSight(self.enemy)
  end

  -- 敵が外に出たか？
  this.isEnemyOutOfSight = function(self)
    -- そもそも敵がいない
    if self.enemy == nil then
      return true
    end

    -- 敵が画面外
    local d = self:distanceFor(self.enemy)
    if self:isOutOfSightDistance(d) then
      return true
    end

    -- 敵が索敵範囲の外に出た
    if d > this.searchDistance then
      return true
    end

    return false
  end

  -- 通常攻撃
  this.attackEnemy = function(self)
    if self.enemy == nil then return end
    Attack(self.id, self.enemy)
  end

  -- 攻撃
  -- とりあえず単純な実装
  -- 継承先で再実装を期待している
  this.attack = function(self)
    self:attackEnemy()
  end

  -----------------------------
  -- 状態遷移
  -----------------------------

  -- 待機状態へ
  this.stateToIdle = function(self)
    self.state = IDLE_ST
    self:resetEnemy()
    self:resetSkill()
  end

  -- 追跡状態へ
  this.stateToChase = function(self, id)
    self.state = CHASE_ST
    self.enemy = id
  end

  -- 追尾状態へ
  this.stateToFollow = function(self)
    self.state = FOLLOW_ST
    self:moveToOwner()
    self:resetEnemy()
    self:resetSkill()
  end

  -- 攻撃状態へ
  this.stateToAttack = function(self)
    self.state = ATTACK_ST
  end

  -----------------------------
  -- 各Action
  -----------------------------

  -- 待機状態Action
  this.onIdleAction = function(self)
    self:putsDebug("onIdleAction")

    -- 予約コマンド処理
    local cmd = self:getCommand()
    if cmd then
      self:executeCommand(cmd)
      return
    end

    -- 消極的モードならば自分自身への攻撃以外は索敵しない
    local enemy = nil
    if (not self:isNegative()) then
      -- 自分たちへの攻撃判定
      enemy = self:getEnemyForOurs()
      if enemy then
        self:stateToChase(enemy)
        self:putsDebug("IDLE_ST -> CHASE_ST : ATTACKED_IN")
        return
      end

      --　必要ならば索敵
      -- 先制スイッチ&積極的モード
      if (self:isFirstAttack() and self:isPositive()) then
        enemy = self:searchEnemy()
        if enemy then
          self:stateToChase(enemy)
          self:putsDebug("IDLE_ST -> CHASE_ST : ATTACK")
          return
        end
      end
    else
      -- 自分自身への攻撃判定
      enemy = self:getEnemyForSelf()
      if enemy then
        self:stateToChase(enemy)
        self:putsDebug("IDLE_ST -> CHASE_ST : ATTACKED_IN")
        return
      end
    end

    -- やることがなければ主人の元に戻る
    -- 主人が座っていたら戻らない
    if (not self:isAroundOwner()) and (not self:isSitMotion(self.owner)) then
      self:moveToOwnerPosition()
      self:stateToFollow()
      self:putsDebug("IDLE_ST -> FOLLOW_ST")
      return
    end
  end

  -- 追跡状態Action
  this.onChaseAction = function(self)
    self:putsDebug("onChaseAction")

    -- 敵を見失った？
    if self:isEnemyOutOfSight() then
      self:stateToIdle()
      self:putsDebug("CHASE_ST -> IDLE_ST : ENEMY_OUTSIGHT_IN")
      return
    end

    -- 主人を見失った？
    if self:isOverFollowDistance() then
      self:stateToFollow()
      self:putsDebug("CHASE_ST -> IDLE_ST : MASTER_OUTSIGHT_IN")
      return
    end

    -- 攻撃範囲に入った？
    if self:isEnemyInAttackSight() then
      self:stateToAttack()
      self:putsDebug("CHASE_ST -> ATTACK_ST : ENEMY_INATTACKSIGHT_IN")
      return
    end

    -- 攻撃対象の移動先更新と追尾
    local x, y = self:getPosition(self.enemy)
    if (self.distX ~= x or self.distY ~= y) then
      self:moveTo(x, y)
      self:putsDebug("CHASE_ST -> CHASE_ST : DESTCHANGED_IN")
      return
    end
  end

  -- 攻撃状態Action
  this.onAttackAction = function(self)
    self:putsDebug("onAttackAction")

    -- 敵を見失った？
    if self:isEnemyOutOfSight() then
      self:stateToIdle()
      self:putsDebug("ATTACK_ST -> IDLE_ST : ENEMY_OUTSIGHT_IN")
      return
    end

    -- 主人を見失った？
    if self:isOverFollowDistance() then
      self:stateToFollow()
      self:putsDebug("ATTACK_ST -> FOLLOW_ST : MASTER_OUTSIGHT_IN")
      return
    end

    -- 敵が死んだ？
    if self:isEnemyDead() then
      self:stateToIdle()
      self:putsDebug("ATTACK_ST -> IDLE_ST : ENEMY_DEAD")
      return
    end

    -- 敵が攻撃範囲外？
    if (not self:isEnemyInAttackSight()) then
      self:stateToChase(self.enemy)
      local x, y = self:getPosition(self.enemy)
      self:moveTo(x, y)
      self:putsDebug("ATTACK_ST -> CHASE_ST : ENEMY_MOVED")
      return
    end

    -- 攻撃
    self:putsDebug("ATTACK_ST -> ATTACK_ST  : ENERGY_RECHARGED_IN")
    if self:isSkillReady() then
      -- スキルが設定されていればスキル
      self:useSkill(self.enemy)
    else
      -- 通常攻撃
      self:attack()
    end
  end

  -- 追尾状態Action
  this.onFollowAction = function(self)
    self:putsDebug("onFollowAction")

    -- 主人に追いついた
    if self:isAroundOwner() then
      self:stateToIdle()
      self:putsDebug("FOLLOW_ST -> IDLE_ST")
      return
    end

    -- 主人を追いかける
    self:moveToOwnerSmoothly()
    self:putsDebug("FOLLOW_ST -> FOLLOW_ST")
  end

  -- 移動コマンドAction
  this.onMoveCommandAction = function(self)
    self:putsDebug("onMoveCommandAction")

    -- たどり着いたら待機へ
    if self:isArrive() then
      self:stateToIdle()
    end
  end

  this.onStopCommandAction = function(self)
    -- コマンド実行時にIdleへ移行するので、ここに来ない
  end

  this.onAttackObjectCommandAction = function(self)
    -- コマンド実行時にChaseに移行するので、ここに来ない
  end

  -- 範囲攻撃コマンドAction
  this.onAttackAreaCommandAction = function(self)
    self:putsDebug("onAttackAreaCommandAction")

    -- 何かコマンドの目的がよくわからないけど、とりあえずそのまま実装してみる
    -- 範囲内に敵がいればそれを追う的な感じ？
    local enemy = self:getEnemyForOurs()
    if enemy then
      self:stateToChase(enemy)
      return
    end

    if self:isArrive() then
      self:stateToIdle()
    end
  end

  -- パトロールコマンドAction
  this.onPatrolCommandAction = function(self)
    self:putsDebug("onPatrolCommandAction")

    -- 敵がいたら追跡
    local enemy = self:getEnemyForOurs()
    if enemy then
      self:stateToChase(enemy)
      self:putsDebug("PATROL_CMD_ST -> CHASE_ST : ATTACKED_IN")
      return
    end

    -- 巡回移動
    if self:isArrive() then
      self:moveForPatrol()
      return
    end
  end

  -- 固定コマンドAction
  -- 全く動かないが、敵に攻撃が届くならする
  this.onHoldCommandAction = function(self)
    self:putsDebug("onHoldCommandAction")

    if self.enemy then
      -- 動くつもりはないが、攻撃対象が射程内なら攻撃する
      if self:isEnemyInAttackSight() then
        self:attackEnemy()
      else
        self:resetEnemy()
      end
    else
      -- 動くつもりはないが、敵は認識しておく
      local enemy = self:getEnemyForOurs()
      if enemy then
        self.enemy = enemy
      end
    end
  end

  this.onSkillObjectCommandAction = function(self)
    -- デフォルトでは何も実装されていない
  end

  -- 範囲スキル使用
  this.onSkillAreaCommandAction = function(self)
    self:putsDebug("onSkillAriaCommandAction")

    if (not self:isSkillReady()) then return end

    -- 指定ポイントが射程内ならスキル使用
    if self:getDistanceToDist() <= self:skillRange(self.skill) then
      self:useGroundSkill()
      self:stateToIdle()
    end
  end

  -- 追尾コマンドAction
  this.onFollowCommandAction = function(self)
    self:putsDebug("onFollowCommandAction")

    -- 主人の近くなら何もしない
    if self:isAroundOwner() then return end

    -- デフォルトAIでは「移動中かつ"主人と目的地が3より離れている"場合」目的地を更新している
    -- 面倒だから無条件に更新しちゃう
    -- 問題が出たら直す

    -- 主人に向かって移動
    self:moveToOwnerPosition()
  end

  -----------------------------
  -- 命令関係
  -----------------------------

  -- 命令予約バッファに追加する
  this.addCommand = function(self, com)
    self.commands:add(com)
  end

  -- 命令予約バッファに優先的に追加する
  this.addPriorityCommand = function(self, com)
    self.commands:unshift(com)
  end

  -- 命令予約バッファをクリアする
  this.clearCommands = function(self)
    self.commands:clear()
  end

  -- 命令予約バッファの先頭を取得
  this.getCommand = function(self)
    return self.commands:shift()
  end

  -- 移動コマンド実行
  this.executeMoveCommand = function(self, x, y)
    self:putsDebug("executeMoveCommand")

    -- 目的地が同一で移動中なら何もしない
    if (x == self.distX and y == self.distY and self:isMoving()) then
      return
    end

    -- 目的地が一定距離以上なら中間点を取って移動
    -- サーバーで遠距離は処理しないため
    if self:getCellDistance(x, y, sx, sy) > 15 then
      -- 元の目的値を次のコマンドとして予約
      self:addPriorityCommand({MOVE_CMD, x, y})
      -- 中間地点へ移動する
      x = math.floor((x+sx)/2)
      y = math.floor((y+sy)/2)
    end

    -- 移動
    self.state = MOVE_CMD_ST
    self:resetEnemy()
    self:resetSkill()
    self:moveTo(x, y)
  end

  -- 停止コマンド実行
  this.executeStopCommand = function(self)
    self:putsDebug("executeStopCommand")

    -- 今の場所で移動停止
    if (not self:isStanding()) then
      self:stopMoving()
    end

    -- 待機状態へ
    self:stateToIdle()
  end

  -- 攻撃コマンド実行
  this.executeAttackObjectCommand = function(self, id)
    self:putsDebug("executeAttackObjectCommand")

    -- 対象を追跡
    self:resetSkill()
    self:stateToChase(id)
  end

  -- 範囲攻撃コマンド実行
  -- 範囲攻撃というより、ある範囲内にいる敵を狙う感じ？
  this.executeAttackAreaCommand = function(self, x, y)
    self:putsDebug("executeAttackAreaCommand")

    -- 目的値まで移動
    if (x ~= self.distX or y ~= self.distY or (not self:isMoving())) then
      self:moveTo(x, y)
    else
      self:setDist(x, y)
    end

    -- 範囲攻撃状態へ
    self:resetEnemy()
    self.state = ATTACK_AREA_CMD_ST
  end

  -- パトロールコマンド実行
  this.executePatrolCommand = function(self, x, y)
    self:putsDebug("executePatrolCommand")

    -- パトロール開始
    self:startPatrol(x, y)
    self.state = PATROL_CMD_ST
  end

  -- 固定コマンド実行
  this.executeHoldCommand = function(self)
    self:putsDebug("executeHoldCommand")

    -- 動作を停止して固定状態へ
    self:resetDist()
    self:resetEnemy()
    self.state = HOLD_CMD_ST
  end

  -- スキルコマンド実行
  this.executeSkillObjectCommand = function(self, slv, sid, tid)
    self:putsDebug("executeSkillObjectCommand")

    -- スキルセットして追跡
    self:setSkill(sid, slv)
    self:stateToChase(tid)
  end

  -- 範囲スキルコマンド実行
  this.executeSkillAreaCommand = function(self, slv, sid, x, y)
    self:putsDebug("executeSkillAreaCommand")

    -- 移動してスキル準備
    self:setSkill(sid, slv)
    self:moveTo(x, y)
    self.state = SKILL_AREA_CMD_ST
  end

  -- 追尾コマンド実行
  this.executeFollowCommand = function(self)
    self:putsDebug("executeFollowCommand")

    -- 待機状態と休息状態を互いに転換させる
    if self.state ~= FOLLOW_CMD_ST then
      self.state = FOLLOW_CMD_ST
      self:resetEnemy()
      self:resetSkill()
      self:moveToOwnerPosition()
    else
      self:stateToIdle()
    end
  end

  -- コマンドを実行する
  this.executeCommand = function(self, msg)
    if (msg[1] == MOVE_CMD) then
      self:executeMoveCommand(msg[2], msg[3])
    elseif (msg[1] == STOP_CMD) then
      self:executeStopCommand()
    elseif (msg[1] == ATTACK_OBJECT_CMD) then
      self:executeAttackObjectCommand(msg[2])
    elseif (msg[1] == ATTACK_AREA_CMD) then
      self:executeAttackAreaCommand(msg[2], msg[3])
    elseif (msg[1] == PATROL_CMD) then
      self:executePatrolCommand(msg[2], msg[3])
    elseif (msg[1] == HOLD_CMD) then
      self:executeHoldCommand()
    elseif (msg[1] == SKILL_OBJECT_CMD) then
      self:executeSkillObjectCommand(msg[2], msg[3], msg[4])
    elseif (msg[1] == SKILL_AREA_CMD) then
      self:executeSkillAreaCommand(msg[2], msg[3], msg[4], msg[5])
    elseif (msg[1] == FOLLOW_CMD) then
      -- ALT+TのデフォルトはFollowだが、ConfigでHoldに指定できる
      if Config.FollowCommandToHold then
        self:executeHoldCommand()
      else
        self:executeFollowCommand()
      end
    end
  end

  -- クライアントからの命令を受け付ける
  this.applyCommandFromClient = function(self)
    -- 命令取得
    local cmd  = GetMsg(self.id)     -- command
    local rcmd = GetResMsg (self.id) -- reserved command

    -- 命令処理 or 予約
    if cmd[1] == NONE_CMD then
      if rcmd[1] ~= NONE_CMD then
        self:addCommand(rcmd)
      end
    else
      self:clearCommands()
      self:executeCommand(cmd)
    end
  end

  -- stateActionの定義
  this.stateActions = {}
  this.stateActions[IDLE_ST] = this.onIdleAction
  this.stateActions[CHASE_ST] = this.onChaseAction
  this.stateActions[ATTACK_ST] = this.onAttackAction
  this.stateActions[FOLLOW_ST] = this.onFollowAction
  this.stateActions[MOVE_CMD_ST] = this.onMoveCommandAction
  this.stateActions[STOP_CMD_ST] = this.onStopCommandAction
  this.stateActions[ATTACK_OBJECT_CMD_ST] = this.onAttackObjectCommandAction
  this.stateActions[ATTACK_AREA_CMD_ST] = this.onAttackAreaCommandAction
  this.stateActions[PATROL_CMD_ST] = this.onPatrolCommandAction
  this.stateActions[HOLD_CMD_ST] = this.onHoldCommandAction
  this.stateActions[SKILL_OBJECT_CMD_ST] = this.onSkillObjectCommandAction
  this.stateActions[SKILL_AREA_CMD_ST] = this.onSkillAreaCommandAction
  this.stateActions[FOLLOW_CMD_ST] = this.onFollowCommandAction

  -- 状態に応じたアクション実行
  this.executeStateAction = function(self)
    local sa = self.stateActions[self.state]
    if sa then
      sa(self)
    end
  end

  this.action = function(self)
    -- クライアントから渡されたコマンド読み出しと実行
    self:applyCommandFromClient()

    -- 状態に応じたアクション実行
    self:executeStateAction()
  end

  return this
end
