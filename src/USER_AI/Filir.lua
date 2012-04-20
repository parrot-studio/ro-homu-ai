-- フィーリル用動作オブジェクト
-- Homunculusを継承し、必要な部分を書き換える
Filir = {}
Filir.new = function(id)
  if id == nil then return end

  local this = Homunculus.new(id)
  this.className = 'Filir' -- 自身のクラス名

  this.spRatioForAutoSkill = 0.5 -- これ以上の割合でSPが残っていたら自動スキル使用

  this.moveCommandBuffer = Array.new(3) -- コマンド入力用履歴バッファ
  this.COMMAND_FIRST_ATTACK = Array.create(3, {'R', 'L', 'R'}) -- 右左右
  this.COMMAND_AUTO_SKILL   = Array.create(3, {'U', 'D', 'U'}) -- 上下上

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

  -- 残存SPの割合
  this.leftSpRatio = function(self)
    return (self:getMySp() / self:getMyMaxSp())
  end

  -- ムーンライト使用判定
  -- スイッチがONで、SPが一定以上残っていて、SPに依存する一定の確率で使用
  this.judgeAutoSkillForMoonlight = function(self)
    -- スイッチがOFF
    if (not self:isAutoSkill()) then return false end

    -- SPが十分ではない
    local sr = self:leftSpRatio()
    if sr < self.spRatioForAutoSkill then return false end

    -- 残りSP割合に依存するランダム判定
    -- 例：sr=0.9なら90%の確率で使用する
    -- math.random()は0から1のランダム値
    if math.random() > sr then return false end

    return true
  end

  -- attackをoverride
  -- スキルの自動使用を組み込む
  this.attack = function(self)
    -- 条件を満たしていればスキル攻撃する
    if self:judgeAutoSkillForMoonlight() then
      self:setSkill(SKILL_MOONLIGHT, 1)
      self:useSkill(self.enemy)
    else
      self:attackEnemy()
    end
  end

  return this
end
