-- フィーリル用動作オブジェクト
-- Homunculusを継承し、必要な部分を書き換える
Filir = {}
Filir.new = function(id)

  ------------------------------------------
  -- skill id
  ------------------------------------------
  S_MOONLIGHT   = 8009
  S_FLEETMOVE   = 8010
  S_OVEREDSPEED = 8011
  ------------------------------------------

  local this = Homunculus.new(id)
  this.switchCounterForFirstAttack = 0 -- 先制スイッチカウンタ
  this.autoSkill = true -- 自動スキル使用スイッチ

  this.spRatioForAutoSkill = 0.5 -- これ以上の割合でSPが残っていたら自動スキル使用

  -- 先制スイッチチェック
  this.checkFiratAttackSwitch = function(self, x, y)
    -- 主人の右 -> 左 -> 右
    local ox, oy = self:getPosition(self.owner)
    if (y == oy) then
      if (self.switchCounterForFirstAttack == 0 and x == ox+1) then
        self.switchCounterForFirstAttack = 1
      elseif (self.switchCounterForFirstAttack == 1 and x == ox-1) then
        self.switchCounterForFirstAttack = 2
      elseif (self.switchCounterForFirstAttack == 2 and x == ox+1) then
        -- コマンド完成 -> スイッチ反転
        self.switchCounterForFirstAttack = 0
        self:switchFirstAttack()
      else
        -- スイッチリセット
        self.switchCounterForFirstAttack = 0
      end
    else
      -- スイッチリセット
      self.switchCounterForFirstAttack = 0
    end
  end

  -- executeMoveCommandをoverride
  this.Homunculus_executeMoveCommand = this.executeMoveCommand
  this.executeMoveCommand = function(self, x, y)
    -- 親クラスの処理実行
    self:Homunculus_executeMoveCommand(x, y)

    -- スイッチ処理
    self:checkFiratAttackSwitch(x, y)
  end

  -- 残存SPの割合
  this.leftSpRatio = function(self)
    return (self:getMySp() / self:getMyMaxSp())
  end

  -- ムーンライト使用判定
  -- スイッチがONで、SPが一定以上残っていて、SPに依存する一定の確率で使用
  this.judgeAutoSkillForMoonlight = function(self)
    -- スイッチがOFF
    if (not self.autoSkill) then
      return false
    end

    -- SPが十分ではない
    local sr = self:leftSpRatio()
    if sr < self.spRatioForAutoSkill then
      return false
    end

    -- 残りSP割合に依存するランダム判定
    -- 例：sr=0.9なら90%の確率で使用する
    -- math.random()は0から1のランダム値
    if math.random() > sr then
      return false
    end

    return true
  end

  -- attackをoverride
  -- スキルの自動使用を組み込む
  this.attack = function(self)
    -- 条件を満たしていればスキル攻撃する
    if self:judgeAutoSkillForMoonlight() then
      self:setSkill(S_MOONLIGHT, 1)
      self:useSkill(self.enemy)
    else
      self:attackEnemy()
    end
  end

  return this
end
