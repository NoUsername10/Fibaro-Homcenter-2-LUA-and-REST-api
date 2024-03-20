--
-- This code is taken from here:
-- https://forum.fibaro.com/topic/28094-solved-how-to-get-scene-id-within-its-code/?do=findComment&comment=137115
--

function printTable(tab,indt)
  if type(tab) ~= 'table' then
    print(string.format("%s%s",indt,tostring(tab)))
  elseif tab[1] then
    for i,j in ipairs(tab) do
      printTable(j,indt)
    end
  else
    for i,j in pairs(tab) do
      if type(j) == 'table' then
      	print(string.format("%sTable %s",indt,tostring(i)))
      	printTable(j,indt.."-")
      else
        print(string.format("%s%s=%s",indt,tostring(i),tostring(j)))
      end
    end
  end
end

printTable(_ENV,"")
