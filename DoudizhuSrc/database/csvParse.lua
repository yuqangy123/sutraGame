csvParse = csvParse or {}
  
-- 去掉字符串左空白  
local function trim_left(s)  
    return string.gsub(s, "^%s+", "");  
end  
  
  
-- 去掉字符串右空白  
local function trim_right(s)  
    return string.gsub(s, "%s+$", "");  
end  
  
-- 解析一行  
local function parseline(line)  
    local ret = {};  
  
    local s = line .. ",";  -- 添加逗号,保证能得到最后一个字段  
  
    while (s ~= "") do  
        --print(0,s);  
        local v = "";  
        local tl = true;  
        local tr = true;  
  
        while(s ~= "" and string.find(s, "^,") == nil) do  
            --print(1,s);  
            if(string.find(s, "^\"")) then  
                local _,_,vx,vz = string.find(s, "^\"(.-)\"(.*)");  
                --print(2,vx,vz);  
                if(vx == nil) then  
                    return nil;  -- 不完整的一行  
                end  
  
                -- 引号开头的不去空白  
                if(v == "") then  
                    tl = false;  
                end  
  
                v = v..vx;  
                s = vz;  
  
                --print(3,v,s);  
  
                while(string.find(s, "^\"")) do  
                    local _,_,vx,vz = string.find(s, "^\"(.-)\"(.*)");  
                    --print(4,vx,vz);  
                    if(vx == nil) then  
                        return nil;  
                    end  
  
                    v = v.."\""..vx;  
                    s = vz;  
                    --print(5,v,s);  
                end  
  
                tr = true;  
            else  
                local _,_,vx,vz = string.find(s, "^(.-)([,\"].*)");  
                --print(6,vx,vz);  
                if(vx~=nil) then  
                    v = v..vx;  
                    s = vz;  
                else  
                    v = v..s;  
                    s = "";  
                end  
                --print(7,v,s);  
  
                tr = false;  
            end  
        end  
  
        if(tl) then v = trim_left(v); end  
        if(tr) then v = trim_right(v); end  
  
        ret[table.getn(ret)+1] = v;  
        --print(8,"ret["..table.getn(ret).."]=".."\""..v.."\"");  
  
        if(string.find(s, "^,")) then  
            s = string.gsub(s,"^,", "");  
        end  
  
    end  
  
    return ret;  
end  
  
  
  
--解析csv文件的每一行  
local function getRowContent(file)  
    local content;  
  
    local check = false  
    local count = 0  
    while true do  
        local t = file:read()  
        if not t then  if count==0 then check = true end  break end  
        
        if not content then  
            content = t  
        else  
            content = content..t  
        end  
  
        local i = 1  
        while true do  
            local index = string.find(t, "\"", i)  
            if not index then break end  
            i = index + 1  
            count = count + 1  
        end  
  
        if count % 2 == 0 then check = true break end  
    end  
  
    if not check then  assert(1~=1) end  
    return content  
end  
  
  
  
--解析csv文件  
function csvParse.LoadCsv(fileName)  
    
    local datapath = "static_client/" .. fileName .. ".csv"
    local sourcePath = "res/" .. datapath

    local targetPlatform = cc.Application:getInstance():getTargetPlatform()
    if (cc.PLATFORM_OS_WINDOWS == targetPlatform) then
        sourcePath = "../../res/" .. datapath
        --sourcePath = "res/" .. datapath
    elseif (cc.PLATFORM_OS_IPHONE == targetPlatform) or (cc.PLATFORM_OS_IPAD == targetPlatform) or (cc.PLATFORM_OS_ANDROID == targetPlatform)  then
       
       sourcePath = cc.FileUtils:getInstance():getWritablePath() .. sourcePath
       --Game:initDataBase("res",Constant.DB_NAME)
    end
    print("读取csv文件："..datapath)

    local sourcePath = cc.FileUtils:getInstance():getStringFromFile(datapath)
    local xx = string.split(sourcePath, "\n")
    
    local  header = parseline(xx[3])
    local ret = {}
  
    local headerCount = #header
    for i=4,#xx do
        local data = {}
        if xx[i] ~= "" then
            local lineInfo = parseline(xx[i])
            for j=1,headerCount-1 do
                data[header[j]] = lineInfo[j]
            end
            ret[table.getn(ret)+1] = data
        end
    end
    
  
    return ret  
end