--Floppy Block v.0.2
--Автор: newbie
 
local term = require("term")
local event = require("event")
local computer = require("computer")
local component = require("component")
local fs = require("filesystem")
local gpu = component.gpu
local serialization = require("serialization")
local xSize, ySize = gpu.getResolution()
local width = 30
local height = 22
local startXPosPlayer = 8
local tempPosPlayer = 10
local nicknames
local records
local name
local count = 0
local tCount = 0
local colors = {
    player = 0x00FF00,
    bg = 0x000000,
    floor = 0xFF4500,
    walls = 0xFFD700,
    text = 0xFFFFFF,
    button = 0x4F4F4F
}
local quit = false
local game = true
local fin = false
local function start()
    term.clear()
    gpu.setForeground(colors.player)
    gpu.set(6, 10, "Кликни чтоб начать")
    gpu.set(5, 11, "Жми кнопки чтоб жить")
    gpu.setForeground(colors.text)
    local e = {event.pull("touch")}
    name = e[6]
    computer.addUser(name)--Эту строку лучше коментить если игру ставите на личный комп
end
local function paintWall()
    local function up() --cлушалка
    if tempPosPlayer <= 2 then --проверка на удар сверху
        fin = true
        game = false
        event.ignore("key_down", up)
    end
    gpu.set(startXPosPlayer, tempPosPlayer, "  ")
    tempPosPlayer = tempPosPlayer - 1
    gpu.setBackground(colors.player)
    gpu.set(startXPosPlayer, tempPosPlayer, "  ")
    gpu.setBackground(colors.bg)
    os.sleep(0.1)
    end
    tempPosPlayer = 10
    while game do
        gpu.set(2, 3, tostring(tCount))
        --Делает нам на случайной высоте отвертие в 5 блоков
        local randomY = math.modf(math.random(2,15))
        for i = 1, 29 do
            local a = 29 - i
            gpu.setBackground(colors.walls) 
            for i=2, randomY do
                gpu.set(a, i, "  ")
            end
            for i = randomY + 5, 21 do
                gpu.set(a, i, "  ") 
            end
            local function checkWall()
                rand = randomY + 5
                if startXPosPlayer + 1 == a then  --лобовое столкновение сверху
                    if randomY>= tempPosPlayer -1 then
                        tempPosPlayer = 21
                    end 
                elseif startXPosPlayer == a then  --удар в верхний угол задним пикселем
                    if randomY>= tempPosPlayer - 1 then
                        tempPosPlayer = 21
                    end 
                elseif startXPosPlayer == a+1 then  --совпадение второго пикселя с задним вверху
                    if randomY>= tempPosPlayer-1 then
                        tempPosPlayer = 21
                    end
                elseif startXPosPlayer == a+2 then  --совпадение второго пикселя с задним вверху
                    if randomY>= tempPosPlayer-1 then
                        tempPosPlayer = 21
                    end
                end
                if startXPosPlayer + 1 == a then  --лобовое столкновение снизу
                    if tempPosPlayer+1 >= rand then
                        tempPosPlayer = 21
                    end
                elseif startXPosPlayer  == a then --удар в нижний угол задним пикселем
                    if tempPosPlayer+1 >= rand then
                        tempPosPlayer = 21
                    end 
                elseif startXPosPlayer == a+1 then  --совпадение второго пикселя с задним сверху
                    if tempPosPlayer +1 >= rand then
                        tempPosPlayer = 21
                    end
                elseif startXPosPlayer == a+2 then  --совпадение второго пикселя с задним сверху
                    if tempPosPlayer +1 >= rand then
                        tempPosPlayer = 21
                    end
                end
            end
                checkWall()
                if tempPosPlayer>=21 then --проверка на удар снизу
                    fin = true
                    game = false
                    event.ignore("key_down", up)
                    break
                end
                --отрисовка, перерисовка игрока
                gpu.setBackground(colors.bg)
                gpu.set(startXPosPlayer, tempPosPlayer, "  ")
                tempPosPlayer = tempPosPlayer + 1
                gpu.setBackground(colors.player)
                gpu.set(startXPosPlayer, tempPosPlayer, "  ")
                gpu.setBackground(colors.bg)
                os.sleep(0.2)
                event.listen("key_down", up)
                if startXPosPlayer == a then
                    tCount = tCount + 1
                    gpu.set(2, 3, tostring(tCount))
                end
            gpu.setBackground(colors.bg)
            for i=2, randomY do
                gpu.set(a, i, "   ")
            end
            for i = randomY + 5, 21 do
                gpu.set(a, i, "   ")
            end
            if fin then
                break
            end
        end
    end
end
local pathToRecords = "records.txt" --путь к файлу с рекордами
local function saveRecord() --Сохраняем рекорды
    local file = io.open(pathToRecords, "w")
    local array = {["nicknames"] = nicknames, ["records"] = records}
    file:write(serialization.serialize(array))
    file:close()
end
local function loadRecord()  --Загружаем рекорды
    if fs.exists(pathToRecords) then
        local array = {}
        local file = io.open(pathToRecords, "r")
        local str = file:read("*a")
        array = serialization.unserialize(str)
        file:close()
        nicknames = array.nicknames
        records = array.records
    else --или создаем новые дефолтные пустые таблицы
        fs.makeDirectory(fs.path(pathToRecords))
            nicknames = {}
            records = {}
            saveRecord()
    end
end
local function checkName(name)  --Проверка на наличие имени в базе
    for i =1, #nicknames do
        if name == nicknames[i] then
            count = records[i]
            return false
        end
    end
    return true
end
local function addPlayer()  --Создаем учетку пользователю если его нет в базе
    if checkName(name) then
        table.insert(nicknames, name)
        table.insert(records, count)
        saveRecord()
    end
end
local function gameOver() --Игра окончена
    gpu.setBackground(colors.bg)
    term.clear()
    gpu.setForeground(colors.player)
    gpu.set(10,11,"GAME OVER!")
    gpu.set(8,14,"You count:   "..tostring(tCount))
    gpu.setForeground(colors.text)
    count = 0 
    tCount = 0 
    game = true 
    fin = false
    computer.removeUser(name) --опять же коментим эту строку если комп не публичный
end
local function saveCount() --сохраняем наши заработанные очки
    for i = 1, #nicknames do
        if name == nicknames[i] then
            count = records[i]
            if tCount > count then
                records[i] = tCount
            end
        end
    end
    saveRecord()
end
local function sortTop() --Сортируем Топ игроков
    for i=1, #records do
      for j=1, #records-1 do
        if records[j] < records[j+1] then
          local r = records[j+1]
          local n = nicknames[j+1]
          records[j+1] = records[j]
          nicknames[j+1] = nicknames[j]
          records[j] = r
          nicknames[j] = n
        end
      end
    end
    saveRecord()
end
function paintScene() --Рисуем сцену
    term.clear()
    gpu.setBackground(colors.floor)
    gpu.set(0,1,"                               ")
    gpu.set(0,22,"                               ")
    gpu.setBackground(colors.bg)
end
local function printRecords()  --Выводим рекорды на экран
    term.clear()
    local xPosName = 5
    local xPosRecord = 20
    local yPos = 1
    loadRecord()
        gpu.setForeground(colors.player)
        gpu.set(11,1,"Top - 15")
    if #nicknames <= 15 then
    for i = 1, #nicknames do
        yPos= yPos+1
        gpu.set(xPosName, yPos, nicknames[i] )
        gpu.set(xPosRecord, yPos, tostring(records[i]))
    end
    else
        for i = 1, 15 do
        yPos= yPos+1
        gpu.set(xPosName, yPos, nicknames[i] )
        gpu.set(xPosRecord, yPos, tostring(records[i]))
        end
    end
    gpu.setForeground(colors.text)
    os.sleep(10)
    floppyBlock()
end
function main()
start()
addPlayer()
paintScene()
paintWall()
saveCount()
gameOver()
os.sleep(3)
floppyBlock()
end
function floppyBlock()
    term.clear()
    event.shouldInterrupt = function() return false end --Alt+ Ctrl + C не пашет, так же на ваше усмотрение
    gpu.setResolution(width, height)
    gpu.setForeground(colors.player)
    loadRecord()
    gpu.set(9,5,"Flappy Block")
    gpu.setBackground(colors.button)
    gpu.set(12,15," Play ")
    gpu.set(11,17," Top-15 ")
    gpu.set(12,20," Quit ")
    gpu.setBackground(colors.bg)
    while true do
        local e = {event.pull("touch")}
        if e[4] == 15 then
            if e[3]>12 then
                if e[3]<18 then main() end  
            end
        elseif e[4] == 17 then
            if e[3]>11 then
                if e[3]<19 then
                    sortTop()
                    printRecords()
                end
            end
        elseif e[4] == 20 then
            if e[3]>12 then
                if e[3]<18 then
                    if e[6] == "newbie" then --В эту строку заносим ник того кто может закрыть игру, если ненужно,
                        --коментим ее
                        gpu.setForeground(colors.text)
                        gpu.setResolution(xSize,ySize)
                        term.clear()
                        quit = true
                        break
                    end --и тут
                end
            end
        end
    if quit then break end
    end
end
floppyBlock()local component = require("component")
local gpu = component.gpu
local term = require("term")
local serialization = require("serialization")
local computer = require("computer")
local thread = require("thread")
local event = require("event")

gpu.setResolution(60,30)

gpu.setResolution(30,15)

term.clear()

print("Welcome to the snake game!")
os.sleep(1)

if component.isAvailable("chat_box") then
    cb = component.chat_box
    cb1 = true
    cb.say("Debug Enabled")
else
    cb1 = false
end

function dbc(t1)
    if cb1 then
        cb.say(t1)
    end
end

local function rgb (r, g, b)
	return (r * 256 * 256 + g * 256 + b)
end

function pixel(x,y,c,char,char_c)
    oldColor = gpu.getBackground()
    if char then
        oldColor2 = gpu.getForeground()
        gpu.setForeground(char_c)
    end

    gpu.setBackground(c)

    if char then
        gpu.fill(x*2-1,y,2,1,char)
    else
        gpu.fill(x*2-1,y,2,1," ")
    end

    gpu.setBackground(oldColor)
    if char then
        gpu.setForeground(oldColor2)
    end
end

function getpixelc(x,y)
    char, color, colorB = gpu.get(x*2-1,y)
    return colorB
end

function move(dir,coord)
    if dir == 1 then
        coord.y = coord.y-1
        if coord.y == 1 then
            coord.y = 29
        end
    end
    if dir == 2 then
        coord.x = coord.x+1
        if coord.x == 30 then
            coord.x = 2
        end
    end
    if dir == 3 then
        coord.y = coord.y+1
        if coord.y == 30 then
            coord.y = 2
        end
    end
    if dir == 4 then
        coord.x = coord.x-1
        if coord.x == 1 then
            coord.x = 29
        end
    end
    return coord
end

function checkedge(dir,coords)
    if dir == 1 then
        return (coord.y ~= 1)
    end
    if dir == 2 then
        return (coord.x ~= 30)
    end
    if dir == 3 then
        return (coord.y ~= 30)
    end
    if dir == 4 then
        return (coord.x ~= 1)
    end
end

function checkfront(dir,coords)
    if dir == 1 then
        dbc(tostring(getpixelc(coords.x,coords.y-1)))
        return getpixelc(coords.x,coords.y-1)
    end
    if dir == 2 then
        dbc(tostring(getpixelc(coords.x+1,coords.y)))
        return getpixelc(coords.x+1,coords.y)
    end
    if dir == 3 then
        dbc(tostring(getpixelc(coords.x,coords.y+1)))
        return getpixelc(coords.x,coords.y+1)
    end
    if dir == 4 then
        dbc(tostring(getpixelc(coords.x-1,coords.y)))
        return getpixelc(coords.x-1,coords.y)
    end
end

function regenfruit()
    fruitcoord = {x=math.random(2,29),y=math.random(2,29)}
    fruitcolor = math.random(1,16777215)
end

function regenpoison()
    poisoncoord = {x=math.random(2,29),y=math.random(2,29)}
    poisoncolor = math.random(1,16777215)
end

while true do
    print("Choose a Difficulty:\n1. Easy (Slow)\n2. Medium (Semi-Fast)\n3. Hard (Fast)\n4. Hardcore (Very Fast)")

    diff1 = tonumber(io.read())

    if diff1 == 5 then gpu.setResolution(160,50) os.exit() end
    if diff1 > 0 and diff1 < 5 then gpu.setResolution(60,30) break else print("ERROR!") end
end

difflist = {
    {
        speed=0.2,
        bonus=5
    },
    {
        speed=0.15,
        bonus=10
    },
    {
        speed=0.10,
        bonus=15
    },
    {
        speed=0.05,
        bonus=20
    }
}

difficulty = {}
difficulty.speed = difflist[diff1].speed
difficulty.bonus = difflist[diff1].bonus

dir = 1

fruitcoord = {x=math.random(2,28),y=math.random(2,28)}
fruitcolor = 0x44FF44
drawfruit = true

poisoncoord = {x=math.random(2,28),y=math.random(2,28)}
poisoncolor = 0x44FF44
drawpoison = true

drawsnake = true
snakehead = {x=15,y=15}

player_name = ""

snakelength = 3

snakebody = {}

textures = {
    " ",
    "░"
}

score = 0

thread.create(function()
    while true do
        _, _, _, char1, player_name = event.pull("key_down")
        if char1 == 200 and dir ~= 3 then
            dir = 1
        end
        if char1 == 205 and dir ~= 4 then
            dir = 2
        end
        if char1 == 208 and dir ~= 1 then
            dir = 3
        end
        if char1 == 203 and dir ~= 2 then
            dir = 4
        end
    end
end)

while true do
    term.clear()

    gpu.setBackground(0x888888)
    gpu.setForeground(0xFFFFFF)
    gpu.fill(1,1,60,1," ")
    term.setCursor(1,1)
    term.write("Score: "..score.." ("..(snakelength-3).." fruits) Difficulty: "..diff1)
    gpu.setBackground(0x666666)
    gpu.fill(1,2,2,29," ")
    gpu.fill(59,2,2,29," ")
    gpu.fill(1,30,60,1," ")
    gpu.setBackground(0x000000)

    if drawfruit then
        pixel(fruitcoord.x,fruitcoord.y,fruitcolor)
    end
    if drawpoison then
        pixel(poisoncoord.x,poisoncoord.y,poisoncolor,"╳",0xFF0000)
    end
    if drawsnake then
        pixel(snakehead.x,snakehead.y,0xBBFF66)
        for i1=1, snakelength do
            if snakebody[i1] ~= nil then
                local ran1 = math.random(1,2)
                pixel(snakebody[i1].x,snakebody[i1].y,0x99FF44,"░",0x33BB11)
            end
        end
    end
    
    table.insert(snakebody,1,{x=snakehead.x,y=snakehead.y})
    if #snakebody > snakelength then snakebody[#snakebody] = nil end

    os.sleep(difficulty.speed)

    if checkfront(dir,snakehead) == 10092352 then
        computer.beep(200,0.5)
        break
    end

    snakehead = move(dir,snakehead)

    if snakehead.x == fruitcoord.x and snakehead.y == fruitcoord.y then
        score = score+100+difficulty.bonus
        snakelength = snakelength+1
        regenfruit()
        computer.beep(900,0.1)
    end
    if snakehead.x == poisoncoord.x and snakehead.y == poisoncoord.y then
        score = score-(120+difficulty.bonus)
        snakelength = snakelength-2
        regenpoison()
        computer.beep(300,0.1)
        if snakelength < 1 then
            computer.beep(200,0.5)
            break
        end
    end
end

term.clear()

print("Game Over!")
print("Score: "..score.." ("..(snakelength-3).." Fruits)")

os.sleep(5)

computer.shutdown(true)
