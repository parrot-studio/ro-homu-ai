-- フィーリル用動作オブジェクト
-- Homunculusを継承し、必要な部分を書き換える
Filir = {}
Filir.new = function(id)
  if id == nil then return end

  local this = Homunculus.new(id)
  this.className = 'Filir' -- 自身のクラス名

  this.moveCommandBuffer = Array.new(3) -- コマンド入力用履歴バッファ
  this.COMMAND_FIRST_ATTACK = Array.create(3, {'R', 'L', 'R'}) -- 右左右
  this.COMMAND_AUTO_SKILL   = Array.create(3, {'U', 'D', 'U'}) -- 上下上

  -- ムーンライト使用前提SP割合%
  -- これ以上の割合でSPが残っていたら自動ムーンライト使用
  this.spRatioForAutoMoolight = 50
  -- ムーンライト使用Lv乱数表
  this.MOONLIGHT_LV_TABLE = Array.create(10, {1,1,1,1,1,3,3,3,5,5})

  -- フリットムーブ使用前提SP割合%
  -- これ以下の割合しかSPが残ってなかったら自動フリットムーブ使用
  this.spRatioForAutoFleetMove = 20
  -- フリットムーブ時間管理用Settingキー
  this.SETTING_KEY_FLEET_MOVE = 'FleetMove'
  -- フリットムーブの情報定義テーブル
  this.FLEET_MOVE_TABLE = {
    {term=60, delay=60,  sp=30},
    {term=55, delay=70,  sp=40},
    {term=50, delay=80,  sp=50},
    {term=45, delay=90,  sp=60},
    {term=40, delay=120, sp=70},
  }

  -- 対象からの方向取得
  -- 対象と隣接しない位置の場合はnil
  this.aroundDirection = function(self, id, x, y)
    -- 対象の位置
    local ox, oy = self:getPosition(id)

    -- 周囲八方向
    if (x == ox and y == oy+1) then return 'U'
    elseif (x == ox and y == oy-1) then return 'D'
    elseif (x == ox+1 and y == oy) then return 'R'
    elseif (x == ox-1 and y == oy) then return 'L'
    elseif (x == ox-1 and y == oy+1) then return 'UL'
    elseif (x == ox+1 and y == oy+1) then return 'UR'
    elseif (x == ox-1 and y == oy-1) then return 'DL'
    elseif (x == ox+1 and y == oy-1) then return 'DR'
    else return end
  end

  -- 主人からの方向取得
  -- 主人と隣接しない位置の場合はnil
  this.aroundDirectionForOwner = function(self, x, y)
    return self:aroundDirection(self.owner, x, y)
  end

  -- 移動を使ったコマンドを格納する
  -- 主人と関係ない位置を指定されたらクリアする
  this.addMoveCommandBuffer = function(self, x, y)
    local d = self:aroundDirectionForOwner(x, y)
    if d then
      -- コマンドとして有効ならpush
      self.moveCommandBuffer:push(d)
    else
      -- 他の座標ならコマンドリセット
      self.moveCommandBuffer:clear()
    end
  end

  -- 指定されたコマンドが完成したか？
  this.isMoveCommandComplete = function(self, com)
    return self.moveCommandBuffer:isEqual(com)
  end

  -- 先制スイッチチェック
  -- コマンドと一致したらスイッチを反転させる
  this.checkFiratAttackSwitch = function(self)
    if self:isMoveCommandComplete(self.COMMAND_FIRST_ATTACK) then
      self:switchFirstAttack()
      self.moveCommandBuffer:clear()
    end
  end

  -- 自動スキルスイッチチェック
  -- コマンドと一致したらスイッチを反転させる
  this.checkAutoSkillSwitch = function(self)
    if self:isMoveCommandComplete(self.COMMAND_AUTO_SKILL) then
      self:switchAutoSkill()
      self.moveCommandBuffer:clear()
    end
  end

  -- フリットムーブの最終使用時間書き込み
  -- 実際に使用されたかは考慮しない
  this.setLastFleetMoveTime = function(self, lv)
    if lv == nil then return end
    local val = string.format("%d:%d", lv, os.time())
    self:setSetting(self.SETTING_KEY_FLEET_MOVE, val)
  end

  -- フリットムーブ使用情報読み込み
  -- lv, timeの組を返す（存在しなければnil）
  this.getLastFleetMove = function(self)
    local val = self:getSetting(self.SETTING_KEY_FLEET_MOVE)
    if val == nil then return end
    local s, e, lv, time =  string.find(val, "^(%d+):(%d+)$")
    if lv == nil or time == nil then return end
    return lv*1, time*1
  end

  -- フリットムーブが使用可能か？
  this.isCanUseFleetMove = function(self)
    -- 最後に使用した時間取得
    local lv, time = self:getLastFleetMove()
    -- 存在しない => 使える
    if lv == nil or time == nil then
      return true
    end

    -- Lvに応じたスキル情報取得
    local sd = self.FLEET_MOVE_TABLE[lv]
    if sd == nil then
      return false
    end

    -- ディレイが終わっているか？
    if time + sd.delay < os.time() then
      return true
    else
      return false
    end
  end

  -- フリットムーブの効果時間内か？
  this.isOnFleetMove = function(self)
    -- 最後に使用した時間取得
    local lv, time = self:getLastFleetMove()
    -- 存在しない => 効果時間内ではない
    if lv == nil or time == nil then
      return false
    end

    -- Lvに応じたスキル情報取得
    local sd = self.FLEET_MOVE_TABLE[lv]
    if sd == nil then
      return false
    end

    -- 効果時間が終わっているか？
    if time + sd.term < os.time() then
      return false
    end
    return true
  end

  -- ムーンライト使用判定
  -- スイッチがONで、SPが一定以上残っていて、SPに依存する一定の確率で使用
  this.judgeAutoSkillForMoonlight = function(self)
    -- スイッチがOFF
    if (not self:isAutoSkill()) then
      return false
    end

    -- 別なスキルを使おうとしている
    if self:isSkillReady() then
      return false
    end

    -- フリットムーブ中なのでムーンライトが使えない
    if self:isOnFleetMove() then
      return false
    end

    -- SPが十分ではない
    local sr = self:leftMySpRatio()
    if sr < self.spRatioForAutoMoolight then
      return false
    end

    -- 残りSP割合に依存するランダム判定
    -- 例：sr=90なら50%の確率で使用する
    if math.random(100) > (sr - self.spRatioForAutoMoolight + 10) then
      return false
    end

    return true
  end

  -- ムーンライト使用Lv判定
  this.judgeUseLvForMoonlight = function(self)
    return self.MOONLIGHT_LV_TABLE:pickup()
  end

  -- フリットムーブ使用判定
  this.judgeAutoSkillForFleetMove = function(self, lv)
    -- スイッチがOFF
    if (not self:isAutoSkill()) then
      return false
    end

    -- 別なスキルを使おうとしている
    if self:isSkillReady() then
      return false
    end

    -- SPが残っているため、ムーンライトの方が使いやすい
    if self:leftMySpRatio() > self.spRatioForAutoFleetMove then
      return false
    end

    -- ディレイ中
    if (not self:isCanUseFleetMove()) then
      return false
    end

    -- SP不足
    if self:getMySp() < self.FLEET_MOVE_TABLE[lv].sp then
      return false
    end

    return true
  end

  -----------------------------
  -- override methods
  -----------------------------

  -- useSkillをoverride
  this.Homunculus_useSkill = this.useSkill
  this.useSkill = function(self, tid)
    -- フリットムーブを最後に使用した時間をセット
    if self.skill == SKILL_FLEETMOVE then
      self:setLastFleetMoveTime(self.skillLv)
    end

    -- 親クラスの処理
    self:Homunculus_useSkill(tid)
  end

  -- attackをoverride
  -- スキルの自動使用を組み込む
  this.attack = function(self)
    -- 条件を満たしていればスキル攻撃する
    if self:judgeAutoSkillForMoonlight() then
      self:setSkill(SKILL_MOONLIGHT, self:judgeUseLvForMoonlight())
      self:useSkill(self.enemy)
    else
      self:attackEnemy()
    end
  end

  -- onChaseActionをoverride
  this.Homunculus_onChaseAction = this.onChaseAction
  this.onChaseAction = function(self)
    -- 親クラスの処理
    self:Homunculus_onChaseAction()

    -- 処理の結果、追跡中or攻撃態勢ならフリットムーブ使用判定
    if self.state == CHASE_ST or self.state == ATTACK_ST then
      -- オートではLv1のみを使う
      if self:judgeAutoSkillForFleetMove(1) then
        self:setSkill(SKILL_FLEETMOVE, 1)
        self:useSkill(self.id)
      end
    end
  end

  -- executeMoveCommandをoverride
  this.Homunculus_executeMoveCommand = this.executeMoveCommand
  this.executeMoveCommand = function(self, x, y)
    -- 親クラスの処理実行
    self:Homunculus_executeMoveCommand(x, y)

    -- スイッチ処理
    self:addMoveCommandBuffer(x, y)
    self:checkFiratAttackSwitch()
    self:checkAutoSkillSwitch()
  end

  return this
end
