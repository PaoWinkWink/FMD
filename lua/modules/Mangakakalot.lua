local dirurl = '/manga_list?type=newest&category=all&state=all&page='

function GetRedirectUrl(document)
  local x = TXQuery.Create(document)
  local s = x.xpathstring('//script[contains(., "window.location.assign")]')
  if (s ~= '') and (s ~= nil) then
    return GetBetween('("', '")', s)
  end
  return ''
end

function getinfo()
  local u = MaybeFillHost(module.rooturl, url)
  if http.get(u) then
    local s = GetRedirectUrl(http.Document)
    if (s ~= '') and (s ~= nil) then
      u = s
      if not http.GET(u) then return false; end
    end
    mangainfo.url=u
    local x=TXQuery.Create(http.document)
    mangainfo.title=x.xpathstring('//ul[@class="manga-info-text"]/li/h1')
    if (Pos('email', mangainfo.title) > 0) and (Pos('protected', mangainfo.title) > 0) then
      mangainfo.title = Trim(x.xpathstring('//title/substring-after(substring-before(., "Manga Online"), "Read")'))
    end
    mangainfo.coverlink=MaybeFillHost(module.RootURL, x.xpathstring('//div[@class="manga-info-pic"]/img/@src'))
    mangainfo.authors=x.xpathstringall('//ul[@class="manga-info-text"]/li[contains(., "Author")]/a')
    mangainfo.genres=x.xpathstringall('//ul[@class="manga-info-text"]/li[contains(., "Genre")]/a')
    mangainfo.status = MangaInfoStatusIfPos(x.xpathstring('//ul[@class="manga-info-text"]/li[contains(., "Status")]'))
    mangainfo.summary=x.xpathstringall('//div[@id="noidungm"]/text()', '')
    x.xpathhrefall('//div[@class="chapter-list"]/div[@class="row"]/span/a', mangainfo.chapterlinks, mangainfo.chapternames)
    InvertStrings(mangainfo.chapterlinks,mangainfo.chapternames)
    return no_error
  else
    return net_problem
  end
end

function getpagenumber()
  function spliturl(u)
    local pos = 0
    for i = 1, 3 do
      local p = string.find(u, '/', pos+1, true)
      if p == nil then break; end
      pos = p
    end
    return string.sub(u, 1, pos-1), string.sub(u, pos)
  end
  task.pagelinks.clear()
  task.pagenumber=0
  local u = MaybeFillHost(module.rooturl, url)
  if http.get(u) then
    local s = GetRedirectUrl(http.document)
    if (s ~= '') and (s ~= nil) then
      local host, _ = spliturl(s)
      local _, path = spliturl(u)
      if not http.get(host .. path) then return false; end
    end
    local x=TXQuery.Create(http.Document)
    x.xpathstringall('//div[@id="vungdoc"]/img/@src', task.pagelinks)
    return true
  else
    return false
  end
end

function getnameandlink()
  if http.get(module.rooturl .. dirurl .. IncStr(url)) then
    local x = TXQuery.Create(http.Document)
    x.XPathHREFAll('//div[@class="truyen-list"]/div[@class="list-truyen-item-wrap"]/h3/a', links, names)
    return no_error
  else
    return net_problem
  end
end

function getdirectorypagenumber()
  if http.GET(module.RootURL .. dirurl .. '1') then
    x = TXQuery.Create(http.Document)
    local s = x.xpathstring('//div[@class="group-page"]/a[contains(., "Last")]/@href')
    page = tonumber(s:match('page=(%d+)'))
    if page == nil then page = 1; end
    return true
  else
    return false
  end
end

function AddWebsiteModule(name, url)
  local m = NewModule()
  m.website = name
  m.rooturl = url
  m.category = 'English'
  m.lastupdated = 'March 12, 2018'
  m.sortedlist = true
  m.ongetinfo='getinfo'
  m.ongetpagenumber='getpagenumber'
  m.ongetnameandlink='getnameandlink'
  m.ongetdirectorypagenumber = 'getdirectorypagenumber'
  return m
end 

function Init()
  AddWebsiteModule('Mangakakalot', 'http://mangakakalot.com')
  AddWebsiteModule('Manganelo', 'http://manganelo.com')
end