-- フィーリル用動作オブジェクト
-- Homunculusを継承し、必要な部分を書き換える
Filir = {}
Filir.new = function(id)
  local this = Homunculus.new(id)
  this.switchCounterForFirstAttack = 0 -- 先制スイッチカウンタ

  -- 先制スイッチチェック
  this.checkFiratAttackSwitch = function(self)
    -- 主人の右 -> 左 -> 右
    local ox, oy = self:getPosition(self.owner)
    if (self.distY == oy) then
      if (self.switchCounterForFirstAttack == 0 and self.distX == ox+1) then
        self.switchCounterForFirstAttack = 1
      elseif (self.switchCounterForFirstAttack == 0 and self.distX == ox-1) then
        self.switchCounterForFirstAttack = 2
      elseif (self.switchCounterForFirstAttack == 2 and self.distX == ox+1) then
        -- コマンド完成 -> スイッチ反転
        self.switchCounterForFirstAttack = 0
        self:setFirstAttack((not self:isFirstAttack()))
      else
        -- スイッチリセット
        self.switchCounterForFirstAttack = 0
      end
    else
      -- スイッチリセット
      self.switchCounterForFirstAttack = 0
    end
  end

  -- onMoveCommandActionをoverride
  this.Homunculus_onMoveCommandAction = this.onMoveCommandAction
  this.onMoveCommandAction = function(self)
    -- 親クラスの処理実行
    self:Homunculus_onMoveCommandAction()

    -- スイッチ処理
    self:checkFiratAttackSwitch()
  end

  return this
end
