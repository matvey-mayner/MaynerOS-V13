local computer = require("computer")

print "cheking update's"
os.execute("wget -f https://raw.githubusercontent.com/Matveymayner/AppShop/main/AppShop.lua")
print "Done!"
os.execute("reboot")
-- Функция для вывода строки команд
local function printCommands()
  print("1. Woker Installer (Virus)   2. MaynerOS V12  3. MineOS  4. Fastboot  5. Pong")
end
 
-- Функция для обработки команд
local function handleCommand(command)
  if command == "1" then
    os.execute("pastebin get Vg2PtDN6 Woker Installer (Virus).lua")
  elseif command == "2" then
    os.execute("pastebin get mGJhpBzj MaynerOS V12 Installer.lua")
  elseif command == "3" then
    os.execute("pastebin get vhg5uu1b MineOS Installer.lua")
  elseif command == "4" then
    os.execute("wget -f https://raw.githubusercontent.com/Matveymayner/fastboot/main/master/master/autorun.lua")
    os.execute("wget -f https://raw.githubusercontent.com/Matveymayner/fastboot/main/eeprom_code.lua")
  elseif command == "5" then
    os.execute("pastebin get gGHCE9MK Pong.lua")
  else
    message("Invalid command.")
  end
end

-- Главный цикл программы
while true do
  printCommands()
  io.write("> ")
  local command = io.read()
  handleCommand(command)
end
