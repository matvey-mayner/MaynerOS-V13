local component = require("component")
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
