local function regexEscape(str)
    return str:gsub("[%(%)%.%%%+%-%*%?%[%^%$%]]", "%%%1")
end
-- you can use return and set your own name if you do require() or dofile()

-- like this: str_replace = require("string-replace")
-- return function (str, this, that) -- modify the line below for the above to work
string.replace = function (str, this, that)
    return str:gsub(regexEscape(this), that:gsub("%%", "%%%%")) -- only % needs to be escaped for 'that'
end

function string.starts(String,Start)
  return string.sub(String,1,string.len(Start))==Start
end

--[[ function returning a random alphanumeric string of length k --]]
-- source: https://stackoverflow.com/a/72524363
function random_string(len)
  local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
  local n = string.len(alphabet)
  local pw = {}
  for i = 1, len
  do
      pw[i] = string.byte(alphabet, math.random(n))
  end
  return string.char(table.unpack(pw))
end



-- print a table to console
function dump(o)
  if type(o) == 'table' then
     local s = '{ '
     for k,v in pairs(o) do
        if type(k) ~= 'number' then k = '"'..k..'"' end
        s = s .. '['..k..'] = ' .. dump(v) .. ','
     end
     return s .. '} '
  else
     return tostring(o)
  end
end


-- split("a,b,c", ",") => {"a", "b", "c"}
function split(s, sep)
  local fields = {}
  
  local sep = sep or " "
  local pattern = string.format("([^%s]+)", sep)
  string.gsub(s, pattern, function(c) fields[#fields + 1] = c end)
  
  return fields
end


function os.capture(cmd, raw)
  local f = assert(io.popen(cmd, 'r'))
  local s = assert(f:read('*a'))
  f:close()
  if raw then return s end
  s = string.gsub(s, '^%s+', '')
  s = string.gsub(s, '%s+$', '')
  s = string.gsub(s, '[\n\r]+', ' ')
  return s
end

function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

function getOS()
  if package.config:sub(1,1) == '\\' then
    return "Windows"
  else
    return "Unix/Linux"
  end
end


function customModulo(n, number_of_slides)
  return 1 + (number_of_slides + ((n - 1) % number_of_slides)) % number_of_slides
end



constructing_slideshow = false

images_for_slideshow = {}


-- https://codepen.io/osef/pen/BaRqeLP


return {
    {
      Para = function (elem)
        if #elem.content == 1 and elem.content[1].text == '===carousel' and constructing_slideshow == false then
          constructing_slideshow = true
          print("constructing slideshow!")
          return ''
        elseif #elem.content == 1 and elem.content[1].text == '===carousel' and constructing_slideshow == true then
          print("slideshow has ended!")
          constructing_slideshow = false

          number_of_images_for_slideshow = #images_for_slideshow

          carousel_id = random_string(10)

          print("Carousel ID: " .. carousel_id)

          

          slideshow_html = '<div class="carousel-wrapper">'

          extra_css_file = io.open('styling/generated.css', 'w+')
          io.output(extra_css_file)

          for i, e in pairs(images_for_slideshow) do
            io.write('.carousel-'.. carousel_id .. ' ul { width: calc(100% * '.. tostring(number_of_images_for_slideshow) .. ');}')

            io.write('#slide-' .. tostring(i) .. '-' .. carousel_id .. ':checked ~ .left-arrow[for=slide')
            io.write(tostring(customModulo(i - 1, number_of_images_for_slideshow)) .. '-' .. carousel_id .. '], #slide')
            io.write(tostring(i) .. '-' .. carousel_id .. ':checked ~ .right-arrow[for=slide')
            io.write(tostring(customModulo(i + 1, number_of_images_for_slideshow)) .. '-' .. carousel_id .. '] { display: block; }')

            io.write('.nav-dot[for=slide-' .. tostring(i) .. '-' .. carousel_id .. '] {')
            io.write('left: calc(50% + (((' .. tostring(i) .. ' - 1) - ((' .. tostring(number_of_images_for_slideshow)  .. ' - 1) / 2)) * 5%)); }')
            
            io.write('#slide-' .. tostring(i) .. '-' .. carousel_id .. ':checked ~ .carousel ul {')
            io.write('left: calc(' .. '-100% * (' .. tostring(i) .. ' - 1)'  .. '); }')

            io.write('#slide-' .. tostring(i) .. '-' .. carousel_id .. ':checked ~ .nav-dot[for=slide-' .. tostring(i) .. '-' .. carousel_id .. '] {')
            io.write('opacity: 1; }')
          end

          io.close(extra_css_file)
          io.output(io.stdout)

          print(number_of_images_for_slideshow)

          for i, e in pairs(images_for_slideshow) do
            slideshow_html = slideshow_html .. '<input id="slide-' .. tostring(i) .. '-' .. carousel_id .. '" type="radio" name="controls"'

            if i == 1 then
              slideshow_html = slideshow_html .. 'checked="checked"'
            end

            slideshow_html = slideshow_html .. ">"
          end

          for i, e in pairs(images_for_slideshow) do
            slideshow_html = slideshow_html .. '<label for="slide-' .. tostring(i) .. '-' .. carousel_id .. '" class="nav-dot"></label>'
          end

          for i, e in pairs(images_for_slideshow) do
            slideshow_html = slideshow_html .. '<label for="slide-' .. tostring(i) .. '-' .. carousel_id .. '" class="left-arrow"> < </label>'
          end

          for i, e in pairs(images_for_slideshow) do
            slideshow_html = slideshow_html .. '<label for="slide-' .. tostring(i) .. '-' .. carousel_id .. '" class="right-arrow"> > </label>'
          end

          slideshow_html = slideshow_html .. '<div class="carousel carousel-' .. carousel_id .. '">'
          slideshow_html = slideshow_html .. '<ul class="carousel-center">'

          for i, e in pairs(images_for_slideshow) do

            slideshow_html = slideshow_html .. '<li>' .. e .. '</li>'

          end

          slideshow_html = slideshow_html .. '</ul>'
          slideshow_html = slideshow_html .. '</div>'
          slideshow_html = slideshow_html .. '</div>'

          return pandoc.RawBlock('html', slideshow_html)
        end

        if constructing_slideshow then
          print(elem.content[1].text)
          table.insert(images_for_slideshow, elem.content[1].text)
          return ''
        end

      end,

      Cite = function (elem)

        
      end,



      RawInline = function (raw)

          -- print(raw)
          -- if raw.format == 'html' and string.starts(raw.text, "<")

      end,

      CodeBlock = function (elem)
        if elem.classes[1] == 'pre' then
            s = elem.text
            s = string.gsub(s, "<", '&lt;')
            s = string.gsub(s, ">", '&gt;')
            s = string.gsub(s, '&lt;highlight&gt;', '<highlight>')
            s = string.gsub(s, '&lt;/highlight&gt;', '</highlight>')
            return pandoc.RawBlock('html','<pre>' .. s .. '</pre>')
        end
      end,

      Image = function(elem)
        os.setlocale("C")
        src_split = split(elem.src, ".")
        magick_cmd = "identify"
        if getOS() == 'Windows' then
          magick_cmd = "magick identify"
        end
        w_string = os.capture(magick_cmd .. " -ping -format '%w' markdown" .. elem.src)
        h_string = os.capture(magick_cmd .. " -ping -format '%h' markdown" .. elem.src)
        w_string1 = w_string:gsub("%D", "")
        h_string1 = h_string:gsub("%D", "")
        w = tonumber(w_string1)
        h = tonumber(h_string1)

        all_sizes = {3840, 2560, 1920, 1600, 1366, 1024, 768, 640, 480, 320, 240}
        sizes = {}

        i = 1
        for j, sz in ipairs(all_sizes) do
          if w >= sz then
            sizes[i] = sz
            i = i + 1
            end
        end

        full_element = '<img src="' .. src_split[1] .. '.webp' .. '"'

        full_element = full_element .. ' width="' .. w_string1 .. '" height="' .. h_string1 .. '"'

        if elem.attr.attributes['alternative_text'] then
          full_element = full_element .. ' alt="' .. elem.attr.attributes['alternative_text'] .. '"'
        end

        if tablelength(sizes) > 0 then
          full_element = full_element .. ' srcset="'
        end
        -- print(dump(src_split))
        for i, sz in ipairs(sizes) do
          full_element = full_element .. src_split[1] .. '-' .. tostring(sz) .. 'w.webp ' .. tostring(sz) .. 'w'
          -- print(i, tablelength(sizes))
          if i < tablelength(sizes) then
            full_element = full_element .. ', '
          end
        end
        if tablelength(sizes) > 0 then
          full_element = full_element .. '"'
        end
        full_element = full_element .. ' />'

        return pandoc.RawInline('html', full_element)
      end,
    }
  }