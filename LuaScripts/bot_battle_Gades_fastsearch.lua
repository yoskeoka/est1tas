--[[
	ランダム行動を複数回試行し、最も結果が良かったものを採用する
	全行動パターンの組み合わせを考えると、億をかるく超えるため処理不可 20^8 くらい?
	ある程度経験則からBOTに取らせる行動を限定し、少ない試行で最適解に近いものを探す
	戦闘突入直前の初期ステートをSL4から読み込む
	戦闘開始操作時をSL5,最新の撃破状態をSL6,最短撃破状態をSL7に保存 
]]

local frame	--現在検証中のフレーム
local search_count = 0 --初期フレームからの試行回数

--調査の限界
--超過した場合、遅すぎるので中断（手動戦闘結果より遅かったら意味がない）
local max_frame = 413000 --戦闘終了時（敵HPが0になった瞬間）の基準フレーム
local max_search = 80 --戦闘開始を遅らせて試行を始める最大フレーム数

local try_count = 200 --1つの戦闘開始フレームに対し、BOT戦闘を試行する回数

--調査中の最良結果フレーム
local best_frame = 9999999

--調査中の勝利回数とかも表示した方がLuaを中断する目安になっていい・・？


--botによるre-recordカウントをスキップするか *defualt false
movie.rerecordcounting(false)
print("re-recordcount: " .. movie.rerecordcount())

--現在時刻で乱数を初期化
math.randomseed(os.time())

state = savestate.create(4) --ステートを作成
try_state = savestate.create(5) --試行途中のフレームのステート

emu.speedmode("maximum")
--emu.speedmode("turbo")
--emu.speedmode("nothrottle")
--emu.speedmode("normal") --test use

local result = false
local retry = false --maxフレーム超過した場合にtrue、戦闘失敗扱いにする

--frameadvance( n time(s))
function fadv(n)
	for i=1,n do 
		emu.frameadvance()
	end
end

--保存したステートから戦闘開始するための入力
function start_command()
	joypad.set(1,{A=true})
	fadv(1)
end

--通常攻撃
function weapon_attack()
	joypad.set(1,{A=true})
	fadv(2)
	joypad.set(1,{A=true})
	fadv(2)
end

--防御
function guard()
	joypad.set(1,{A=true,right=true})
	fadv(2)
end

local power_drug00_count = 0	--パワードラッグの使用回数に制限
--パワードラッグ⇒No.00(主人公)
function power_drug00()
	
	power_drug00_count = power_drug00_count + 1 
	
	joypad.set(1,{A=true,left=true})
	fadv(5)	--一覧ロード時間に若干差がある？ため1フレーム余裕を持たせる
	joypad.set(1,{down=true})
	fadv(2)
	joypad.set(1,{A=true})
	fadv(4)
	joypad.set(1,{A=true})
	fadv(3)
	
end

local power_drug01_count = 0	--パワードラッグの使用回数に制限
--パワードラッグ⇒No.01(アグロス)
function power_drug01()

	power_drug01_count = power_drug01_count + 1 
	
	joypad.set(1,{A=true,left=true})
	fadv(5)	--一覧ロード時間に若干差がある？ため1フレーム余裕を持たせる
	joypad.set(1,{down=true})
	fadv(2)
	joypad.set(1,{A=true})
	fadv(4)
	joypad.set(1,{right=true})
	fadv(2)
	joypad.set(1,{A=true})
	fadv(3)
end

--ミラクロース⇒No.00（主人公）
function miracle_00()
	joypad.set(1,{A=true,left=true})
	fadv(5)	--一覧ロード時間に若干差がある？ため1フレーム余裕を持たせる
	joypad.set(1,{up=true})
	fadv(2)
	joypad.set(1,{A=true})
	fadv(4)
	joypad.set(1,{A=true})
	fadv(3)
end

--ミラクロース⇒No.01（アグロス）
function miracle_01()
	joypad.set(1,{A=true,left=true})
	fadv(5)	--一覧ロード時間に若干差がある？ため1フレーム余裕を持たせる
	joypad.set(1,{up=true})
	fadv(2)
	joypad.set(1,{A=true})
	fadv(4)
	joypad.set(1,{right=true})
	fadv(2)
	joypad.set(1,{A=true})
	fadv(3)

end

--ミラクロース⇒No.02（ジュリナ）
function miracle_02()
	joypad.set(1,{A=true,left=true})
	fadv(5)	--一覧ロード時間に若干差がある？ため1フレーム余裕を持たせる
	joypad.set(1,{up=true})
	fadv(2)
	joypad.set(1,{A=true})
	fadv(4)
	joypad.set(1,{down=true})
	fadv(2)
	joypad.set(1,{A=true})
	fadv(3)
end

local doren_count = 0	--ドレン使用回数に制限
--ドレン（ルフィア）
function doren()

	doren_count = doren_count + 1

	joypad.set(1,{A=true,up=true})
	fadv(5)	--一覧ロード時間に若干差がある？ため1フレーム余裕を持たせる
	joypad.set(1,{up=true})
	fadv(2)
	joypad.set(1,{A=true})
	fadv(4)
	joypad.set(1,{A=true})
	fadv(3)
end

--エストナ（ルフィア）
function estna_01()
	joypad.set(1,{A=true,up=true})
	fadv(5)	--一覧ロード時間に若干差がある？ため1フレーム余裕を持たせる
	joypad.set(1,{A=true})
	fadv(4)
	joypad.set(1,{A=true})
	fadv(3)
end

--エストナ（ジュリナ）
function estna_02()
	joypad.set(1,{A=true,up=true})
	fadv(5)	--一覧ロード時間に若干差がある？ため1フレーム余裕を持たせる
	joypad.set(1,{right=true})
	fadv(2)
	joypad.set(1,{right=true})
	fadv(2)
	joypad.set(1,{up=true})
	fadv(2)
	joypad.set(1,{A=true})
	fadv(4)
	joypad.set(1,{A=true})
	fadv(3)
end

--戦闘ロジック用変数をリセット
function reset_var()
	power_drug00_count = 0
	power_drug01_count = 0
	doren_count = 0
end

--各キャラの選択行動にはあまり状況判断ロジックを入れない
--⇒意外な行動が乱数調整に役立ち、結果短縮につながる可能性がある

--主人公の行動
function pattern_00()

	--パーティのHPによる判断
	p1hp_max = memory.readword(0x7E16F0)
	p1hp = memory.readword(0x7E158F)
	p2hp_max = memory.readword(0x7E16F2)
	p2hp = memory.readword(0x7E1591)
	p3hp_max = memory.readword(0x7E16F4)
	p3hp = memory.readword(0x7E1593)
	p4hp_max = memory.readword(0x7E16F6)
	p4hp = memory.readword(0x7E1595)

	r = math.random(5)
	if r == 1 then
		--ジュリナが倒れていた場合
		if p4hp == 0 then
			miracle_02()
		else
			pattern_00()	--再度行動選択
		end
		
	elseif r == 2 then
		--アグロスが倒れていた場合
		if p3hp == 0 then
			miracle_01()
		else
			pattern_00()	--再度行動選択
		end
	else 
		weapon_attack()
	end
end

--ルフィアの行動
function pattern_01()

	--パーティのHPによる判断
	p1hp_max = memory.readword(0x7E16F0)
	p1hp = memory.readword(0x7E158F)
	p2hp_max = memory.readword(0x7E16F2)
	p2hp = memory.readword(0x7E1591)
	p3hp_max = memory.readword(0x7E16F4)
	p3hp = memory.readword(0x7E1593)
	p4hp_max = memory.readword(0x7E16F6)
	p4hp = memory.readword(0x7E1595)
	
	--パーティの状態による判断（正常：0、まひ：+1、せきか：+2、どく：+16、戦闘不能：+32、ムージル：+64）
	p1st = memory.readbyte(0x7E158B) --主人公状態
	p2st = memory.readbyte(0x7E158C) --ルフィア状態
	p3st = memory.readbyte(0x7E158D) --アグロス状態
	p4st = memory.readbyte(0x7E158E) --ジュリナ状態
	
	--PT全員のHPが半分より減っている場合はエストナを使用する確率を上げる
	if p1hp_max - p1hp > p1hp_max / 2 and p2hp_max - p2hp > p2hp_max / 2 and p3hp_max - p3hp > p3hp_max / 2 and p4hp_max - p4hp > p4hp_max / 2 then
		r = math.random(2)
		if r == 1 then
			if p2st < 64 then	--ムージルの状態でない
				estna_01()
				return
			end
		end
	end	

	r = math.random(6)
	if r == 1 then
		--主人公が生きていればパワードラッグを使用（3回まで）
		if p1hp > 0 and power_drug00_count < 3 then
			power_drug00()	
		else
			pattern_01() --再度行動選択
		end
	elseif r == 2 then
		--アグロスが生きていればパワードラッグを使用（3回まで）
		if p3hp > 0 and power_drug01_count < 3 then
			power_drug01()	
		else
			pattern_01() --再度行動選択
		end
	elseif r == 3 then
		--ドレンは2回まで、ムージルの状態でない
		if doren_count < 2 and  p2st < 64 then
			doren()
		else
			pattern_01() --再度行動選択
		end
	elseif r == 4 then
		weapon_attack()
	elseif r == 5 then
		if p2st < 64 then	--ムージルの状態でない
			estna_01()
		else
			pattern_01() --再度行動選択
		end
	else
		guard()
	end
	
end

--アグロスの行動
function pattern_02()

	--パーティのHPによる判断
	p1hp_max = memory.readword(0x7E16F0)
	p1hp = memory.readword(0x7E158F)
	p2hp_max = memory.readword(0x7E16F2)
	p2hp = memory.readword(0x7E1591)
	p3hp_max = memory.readword(0x7E16F4)
	p3hp = memory.readword(0x7E1593)
	p4hp_max = memory.readword(0x7E16F6)
	p4hp = memory.readword(0x7E1595)

	--主人公、ジュリナが倒れている場合はミラクロースを使用する確率を上げる
	if p1hp == 0 then
		r = math.random(3)
		if r >= 2 then
			miracle_00()
			return
		end
	end
	
	if p4hp == 0 then
		r = math.random(3)
		if r >= 2 then
			miracle_02()
			return
		end
	end

	r = math.random(6)
	if r == 1 then
		miracle_00()
	elseif r == 2 then
		miracle_02()
	elseif r == 3 then
		--主人公が生きていればパワードラッグを使用（3回まで）
		if p1hp > 0 and power_drug00_count < 3 then
			power_drug00()	
		else
			pattern_03()	--再度行動選択
		end
	else
		weapon_attack()
	end
end
--なぜかたまにアグロスが指定動作以外のことをする・・・⇒課題

--ジュリナの行動
function pattern_03()

	--パーティのHPによる判断
	p1hp_max = memory.readword(0x7E16F0)
	p1hp = memory.readword(0x7E158F)
	p2hp_max = memory.readword(0x7E16F2)
	p2hp = memory.readword(0x7E1591)
	p3hp_max = memory.readword(0x7E16F4)
	p3hp = memory.readword(0x7E1593)
	p4hp_max = memory.readword(0x7E16F6)
	p4hp = memory.readword(0x7E1595)
	
	--パーティの状態による判断（正常：0、まひ：+1、せきか：+2、どく：+16、戦闘不能：+32、ムージル：+64）
	p1st = memory.readbyte(0x7E158B) --主人公状態
	p2st = memory.readbyte(0x7E158C) --ルフィア状態
	p3st = memory.readbyte(0x7E158D) --アグロス状態
	p4st = memory.readbyte(0x7E158E) --ジュリナ状態
		
	--主人公、アグロスが倒れている場合はミラクロースを使用する確率を上げる
	if p1hp == 0 then
		r = math.random(3)
		if r >= 2 then
			miracle_00()
			return
		end
	end
	
	if p3hp == 0 then
		r = math.random(3)
		if r >= 2 then
			miracle_01()
			return
		end
	end

	r = math.random(6)
	if r == 1 then
		--主人公が生きていればパワードラッグを使用（3回まで）
		if p1hp > 0 and power_drug00_count < 3 then
			power_drug00()	
		else
			pattern_03()	--再度行動選択
		end
	elseif r == 2 then
		--アグロスが生きていればパワードラッグを使用（3回まで）
		if p3hp > 0 and power_drug01_count < 3 then
			power_drug01()	
		else
			pattern_03()	--再度行動選択
		end
	elseif r == 3 then
		weapon_attack()
	elseif r == 4 then
		miracle_00()
	elseif r == 5 then
		miracle_01()
	else
		guard()
	end
end

--ターンを持っているキャラを判断※0x7e1434の値は隊列依存
function input_command()

	local turn = memory.readbyte(0x7e1434)
	
	--[[
		以下の隊列の場合
		00:主人公	01:アグロス
		02:ジュリナ	欠員（03:ルフィア）
	]]
	--主人公のターン
	if turn == 0 then
		pattern_00()
	end
	
	--ルフィアのターン
	if turn == 3 then
		pattern_01()
	end
	
	--アグロスのターン
	if turn == 1 then
		pattern_02()
	end
	
	--ジュリナのターン
	if turn == 2 then
		pattern_03()
	end

end

--戦闘中に失敗と判断する基準
function failure()
	
	--失敗条件を満たしたら、フラグをtrueにする
	local fail_flag = false
	
	local total_damage = 0
	
	--パーティのHPによる判断
	p1hp_max = memory.readword(0x7E16F0)
	p1hp = memory.readword(0x7E158F)
	p2hp_max = memory.readword(0x7E16F2)
	p2hp = memory.readword(0x7E1591)
	p3hp_max = memory.readword(0x7E16F4)
	p3hp = memory.readword(0x7E1593)
	p4hp_max = memory.readword(0x7E16F6)
	p4hp = memory.readword(0x7E1595)
	
	--パーティの状態による判断（正常：0、まひ：+1、せきか：+2、どく：+16、戦闘不能：+32、ムージル：+64）
	p1st = memory.readbyte(0x7E158B) --主人公状態
	p2st = memory.readbyte(0x7E158C) --ルフィア状態
	p3st = memory.readbyte(0x7E158D) --アグロス状態
	p4st = memory.readbyte(0x7E158E) --ジュリナ状態
	
	
	--全員が倒れた場合、失敗
	if p1hp == 0 and p3hp == 0 and p4hp == 0 then	--ルフィアは抜けているため除外
		fail_flag = true
	end
		
	--失敗フラグが立っていなければ戦闘続行
	if fail_flag == false then
		return false
	end
	
	--上記条件以外
	return true

end

--bot試行内容
function attempt()
	
	--開始のための入力
	start_command()

	local turn = memory.readbyte(0x7e1434)	--戦闘中ターン所有
	-- FF:誰もターン持っていない（もしくは戦闘中でない）
	-- 00:1人目, 01:2人目, 02:3人目, 03:4人目
	
	local wait = true
	--戦闘開始～だれかがターンを持つまでフレームを進める
	while wait do

		emu.frameadvance()
		turn = memory.readbyte(0x7e1434)
		if turn ~= 255 then
			wait = false
		end
	end
	
	--戦闘中の判定
	local loop = true
	while loop do
	
		--ターンがある場合行動させる
		if turn ~= 255 then
			input_command()
		end
			
		en1hp = memory.readword(0x7EE542) --敵1HP
		
		--失敗条件を満たすか、ターゲットのHPが0になったら終了
		if failure() then
			result = false
			break
		end
		
		if en1hp == 0 then
			--print("enhp is 0")
			result = true
			break
		end
		
		emu.frameadvance()
		turn = memory.readbyte(0x7e1434)
		
	end
	
	reset_var() --戦闘ロジック用変数をリセット

end

--bot成功判定 
function success()
	
	if retry == true then
		retry = false
		
		return false
	end
	
	--撃破時にジュリナが倒れていた場合、失敗
	p4hp = memory.readword(0x7E1595)
	if p4hp == 0 then
		return false
	end
	
	return result
end

--予期せぬ動作でbotが停止した場合や戦闘が長い場合はmaxフレーム超過でリトライ
function callback()
	if max_frame < emu.framecount() then
		--print("retry at" .. emu.framecount())
		savestate.load(try_state)
		retry = true
	end
end
	
emu.registerafter(callback)

while true do

	savestate.load(state)	--初期ステートを読み出し
	
	fadv(search_count)	--試行フレームまで進める
	savestate.save(try_state)	--最新の試行フレームを保存しておく
	
	frame = emu.framecount()
	print("try at " .. frame-1 .. " frame, count " .. search_count)
	
	--ここに結果の判定方法を書く
	
	--botによる戦闘試行
	for i=1, try_count do
		
		--print("trying " .. i .." times")
		attempt()	--戦闘
		
		--撃破した場合
		if success() then
			
			local state_good = savestate.create(6)
			savestate.save(state_good)	--成功状態を保存
		
			if emu.framecount() < best_frame then
				local state_best = savestate.create(7)
				savestate.save(state_best) --最短を保存
				
				best_frame = emu.framecount()
				max_frame = best_frame	--今後の探索では最短結果より遅い場合打ち切る
				
				print("best state is saved, framecount: " .. best_frame )
			end
			
		end
		
		result = false --撃破フラグをリセット

		--次の試行のためにステートロード
		savestate.load(state)
		fadv(search_count)	--試行フレームまで進める

	end
	
	search_count = search_count + 1			
	--emu.frameadvance() --1フレーム進める
	
	if search_count > max_search then
		print("search end, for excess of max_search")
		break
	end
	
	
end
emu.speedmode("normal")
emu.pause() --エミュレーターを一時停止