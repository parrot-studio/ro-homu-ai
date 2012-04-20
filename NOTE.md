いろいろなメモ書き
===============

設計方針
---------------
- できるだけLuaのオブジェクト的な記述をおこなう
- 宣言的なコードにより、継承を容易にする
- あまり複雑な仕組みは入れず、いじりやすくする
- できるだけ他の人がいじりやすいようにコメントは入れたい・・・が・・・

TODO
---------------
- フィーリルのスキル自動使用の実装
 - SPをチェックして適切なスキルを
 - 他のホムは持ってないのでわからない
 - いじりたい人は継承したオブジェクトを作ればOK
 - Filir.luaを参照
- できるだけとどめを刺さない、汎用的な方法の検討
 - 高級なAIではいろいろな方法をとっているけども、そこそこの方法で何か・・・
- デバッグログの差し替え
 - TraceAIは未だに文字化けしているので
 - メソッドに切り出してあるから容易ではある
- コンパイル方法の調査
- 移動時のスタック回避
 - 壁際を移動指定すると固まる
 - 主人と距離が開けば戻ってはくるが・・・
- グローバルコンフィグの概念
 - スイッチの状態を記録するSettingと、全体の動作を切り替えるコンフィグを別にする
 - グローバルの方は他者の書き換えを想定
- ホムの等速追尾（from ケミWiki）
 - moveToOwnerの更新でいけそうな・・・
- 他の方のAIから良さそうな機能を検討する
 - あくまで個人的に必要かどうかの判断
 - 高機能化が目的ではないし

実装済み
---------------
- 手動スイッチの再実装
 - 先攻/非先攻
 - スキルの使用有無
- 汎用的な設定ファイルの読み書き
 - reloadのたびにスイッチを入れるのは面倒なので、設定ファイルに状態保存したい
- デバッグの出力を共通処理に切り出す
- スイッチ処理の一般化
 - 条件とカウンタの部分を抽象化できないか・・・？

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


-- super

-- 上記のコードは親クラスのメソッドを上書きしてしまう
-- superを実行したい場合の方法について検討

A = {} -- 親クラス（的なオブジェクト）
A.new = function()
  local this = {}

  this.hello = function(self, str)
    print("HELLO "..str)
  end

  return this
end

B = {} -- 子クラス（的なオブジェクト）
B.new = function()
  local this = A.new() -- 親クラスを継承

  this._hello = this.hello -- 親クラスのfunctionを別名で参照
  this.hello = function(self, str) -- 上書き
    self:_hello(str) -- 親クラスのhello
    print("hello "..str..'!!') -- 子クラスの実装
  end

  return this
end

a = A.new()
b = B.new()
a:hello('parrot') --> HELLO parrot
b:hello('parrot') --> HELLO parrot\nhello parrot!!
b:_hello('parrot') --> HELLO parrot

-- ただし、このやり方はBをさらに継承したCでどうするか、という問題がある
-- 連鎖的な呼び出しをうまく作れるか？
-- 手動でやろうとするとCがAの実装について知らないといけない

-- では、ルールでの回避はどうか
-- 例えば、「メソッド名に_を使わない」「overrideしたら 親クラス名_元メソッド名」とする
-- 直接の親クラスの名前は知っていていい・・・というか、知らないと継承不能であって

-- ということでやり直してみる

B = {} -- 子クラス（的なオブジェクト）
B.new = function()
  local this = A.new() -- 親クラスを継承

  this.A_hello = this.hello -- 親クラスのfunctionを別名で参照
  this.hello = function(self, str) -- 上書き
    self:A_hello(str) -- 親クラスのhello
    print("hello "..str..'!!') -- 子クラスの実装
  end

  return this
end

C = {} -- 孫クラス（的なオブジェクト）
C.new = function()
  local this = B.new() -- BはAの子クラスだが、Aの存在をCは知らない

  this.B_hello = this.hello -- あくまでBのhelloを保存している
  this.hello = function(self, str)
    self:B_hello(str) -- Bのhelloを呼んだつもり（内部的にAも呼ばれているのだが）
    print("Good Bye "..str) -- 孫クラスの実装
  end

  return this
end

c = C.new()
c:hello('parrot') --> HELLO parrot\nhello parrot!!\nGood Bye parrot

-- ｷﾀｺﾚ（ ﾟдﾟ）o彡ﾟ
```
