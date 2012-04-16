いろいろなメモ書き
===============

設計方針
---------------
- できるだけLuaのオブジェクト的な記述をおこなう
- 宣言的なコードにより、継承を容易にする
- あまり複雑な仕組みは入れず、いじりやすくする
- できるだけ他の人がいじりやすいようにコメントは入れたい・・・が・・・


Luaにおけるオブジェクトと継承
---------------
Luaのオブジェクトはプロトタイプベースっぽく見えるが、ちょっと違う。
文法でそれっぽく見せているだけで、実際にはtableという仕組みしかない。
全体にJavaScriptやRubyっぽくみえるので、そのあたりの仕組みを知っていれば理解が早いかも。

```Lua
Homu = {} -- ある種のクラス名
Homu.new = function(id) -- コンストラクタに相当
  local this = {} -- オブジェクトの本体
  this.hp = 100   -- プロパティ

  -- メソッドの定義
  -- thisにfunctionオブジェクトを格納する、という書き方
  -- 第一引数にselfを書くのがポイント
  this.cureHp = function(self, point)
    -- この「self」はインスタンス自身を指している
    self.hp = self.hp + point
  end

  this.useHealSkill = function(self)
    -- この呼び出し方がポイント
    -- Luaのシンタックスシュガーにより、それっぽいコードを実現している部分
    self:cureHp(100)

    -- 「self:cureHp(100)」という書き方は、第一引数にレシーバ自身を暗黙的に渡している
    -- 実際には「self.cureHp(self, 100)」の意味
  end

  -- selfを引数に取らないメソッド
  this.printDebug = function(str)
    -- インスタンスを参照しない＝クラスメソッド的な扱い
  end

  return this -- newの最後にメソッドやプロパティを構築したオブジェクトを返す
end

homuId = 10000
homu = Hoge.new(homuId) -- インスタンス生成

-- これも「homu.useHealSkill(homu)」に等しい
homu:useHealSkill()

-- printDebugはselfを取らないので、「.」で呼び出さないとおかしなことに
homu.printDebug("回復したよ")

-- 個人的な感覚では、selfを取るメソッドはインスタンスメソッド、取らないのはクラスメソッド扱い
-- 使い分けが面倒なら全部self渡しでいい気がするけど、乱暴すぎるだろうか
-- 元々「OOPっぽい書き方」だしね・・・
-- そもそもプロパティアクセスは「homu.hp」の形式なわけで
-- メソッド名で判断できるように、ルールを決めるとか必要かも


-- 継承
Yakitori = {} -- Homuを継承するつもりのオブジェクト
Yakitori.new = function(id)
  local this = Homu.new(id) -- Homeのインスタンスをthisに入れる

  -- override
  -- Homuが持つメソッドの中で、必要なもののみ上書きで再定義している
  this.useHealSkill = function(self)
    self:cureHp(200) -- このcureHpはHomuで定義されたものが呼ばれる
  end

  return this -- 継承したオブジェクトを返す
end

tori = Yakitori.new(homuId) -- 継承したオブジェクト
tori:useHealSkill() -- 200回復する
tori.hp -- 300を返す
```
