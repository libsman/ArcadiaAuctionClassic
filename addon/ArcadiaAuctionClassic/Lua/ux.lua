-- Presentation only. Never sends auction requests or changes purchase validation.
local U = {}
AAC.UX = U
local translations = {
 EN={"Price/each","Loading offers: %d / %d (partial)","Checking properties: %d / %d","%d matching offers","%dx %s\nTotal: %s %s","Click to sort. Gold and diamonds are grouped separately. Hover a price for details.","Fee","You receive","Listing","Promotion","G","D"},
 DE={"Preis/Stück","Lade Angebote: %d / %d (Teilergebnis)","Prüfe Eigenschaften: %d / %d","%d passende Angebote","%dx %s\nGesamt: %s %s","Zum Sortieren klicken. Gold und Diamanten werden getrennt gruppiert. Maus über den Preis für Details.","Provision","Du erhältst","Einstellen","Bewerbung","G","D"},
 ES={"Precio/ud.","Cargando ofertas: %d / %d (parcial)","Comprobando atributos: %d / %d","%d ofertas coincidentes","%dx %s\nTotal: %s %s","Pulsa para ordenar. Oro y diamantes se agrupan por separado. Pasa el ratón por el precio para ver detalles.","Comisión","Recibes","Publicación","Promoción","O","D"},
 FR={"Prix/unité","Chargement : %d / %d (partiel)","Vérification des propriétés : %d / %d","%d offres correspondantes","%dx %s\nTotal : %s %s","Cliquez pour trier. Or et diamants sont regroupés séparément. Survolez le prix pour les détails.","Commission","Vous recevez","Mise en vente","Promotion","O","D"},
 PL={"Cena/szt.","Wczytywanie: %d / %d (część wyników)","Sprawdzanie właściwości: %d / %d","Pasujące oferty: %d","%dx %s\nRazem: %s %s","Kliknij, aby sortować. Złoto i diamenty są grupowane oddzielnie. Najedź na cenę, aby zobaczyć szczegóły.","Prowizja","Otrzymasz","Wystawienie","Promocja","Z","D"},
 RU={"Цена/шт.","Загрузка: %d / %d (не все результаты)","Проверка свойств: %d / %d","Подходящих предложений: %d","%dx %s\nВсего: %s %s","Нажмите для сортировки. Золото и алмазы сгруппированы отдельно. Наведите указатель на цену для подробностей.","Комиссия","Вы получите","Размещение","Продвижение","З","А"},
 TR={"Birim fiyat","Yükleniyor: %d / %d (kısmi)","Özellikler kontrol ediliyor: %d / %d","%d eşleşen teklif","%dx %s\nToplam: %s %s","Sıralamak için tıklayın. Altın ve elmas ayrı gruplanır. Ayrıntılar için fiyatın üzerine gelin.","Komisyon","Alacağınız","Listeleme","Tanıtım","A","E"},
 JP={"単価","読込中: %d / %d（途中結果）","属性を確認中: %d / %d","一致する出品: %d件","%dx %s\n合計: %s %s","クリックで並べ替え。ゴールドとダイヤモンドは別々に表示。価格にカーソルを合わせると詳細を表示。","手数料","受取額","出品","宣伝","金","ダ"},
 KR={"개당 가격","불러오는 중: %d / %d (일부 결과)","속성 확인 중: %d / %d","일치하는 판매: %d개","%dx %s\n합계: %s %s","클릭하여 정렬합니다. 골드와 다이아몬드는 따로 묶습니다. 가격에 마우스를 올리면 자세히 표시됩니다.","수수료","받는 금액","등록","홍보","금","다"},
 CN={"单价","加载中: %d / %d（部分结果）","检查属性: %d / %d","匹配的拍卖: %d","%dx %s\n总计: %s %s","点击排序。金币和钻石分别排列。将鼠标移到价格上查看详情。","佣金","实收","上架","推广","金","钻"},
 TW={"單價","載入中: %d / %d（部分結果）","檢查屬性: %d / %d","符合的拍賣: %d","%dx %s\n總計: %s %s","點擊排序。金幣和鑽石分別排列。將滑鼠移到價格上查看詳情。","佣金","實收","上架","推廣","金","鑽"},
}
local language = type(GetLanguage)=="function" and tostring(GetLanguage()):upper():sub(1,2) or "EN"
if not translations[language] then language="EN" end
U.language=language
U.text={}
for i,key in ipairs({"header","loading","filtering","done","buy","hint","fee","income","listing","promotion","gold","diamonds"}) do
 U.text[key]=translations[language][i]
end
AAC_GENERAL_PRICE_PER_UNIT_HEADER=U.text.header
AAC_GENERAL_UNITS_PER_PRICE_HEADER=U.text.header
AAC_BROWSE_PPU=U.text.header
U.text.goldRate=({EN="Gold/Dia",DE="Gold/Dia",ES="Oro/Dia",FR="Or/Dia",PL="Złoto/Dia",RU="Золото/алм.",TR="Altın/Elmas",JP="金/ダイヤ",KR="골드/다이아",CN="金币/钻石",TW="金幣/鑽石"})[language]
U.text.goldHint=({EN="More gold per diamond is cheaper.",DE="Mehr Gold pro Diamant ist günstiger.",ES="Más oro por diamante es más barato.",FR="Plus d’or par diamant est plus avantageux.",PL="Więcej złota za diament oznacza lepszą ofertę.",RU="Чем больше золота за алмаз, тем выгоднее.",TR="Elmas başına daha fazla altın daha avantajlıdır.",JP="ダイヤ1個あたりのゴールドが多いほどお得です。",KR="다이아몬드당 골드가 많을수록 유리합니다.",CN="每颗钻石兑换的金币越多越划算。",TW="每顆鑽石兌換的金幣越多越划算。"})[language]
local saleCopy={
 EN={"Standard fee","Expected net","Net after standard sale fee; listing and promotion costs are separate. Diamond buyouts between game accounts linked to the same PlayerNet account can be fee-free, up to 100,000 Diamonds per PlayerNet account per day.","Classic auction house","Original auction house"},
 DE={"Reguläre Provision","Voraussichtlich netto","Netto nach regulärer Verkaufsprovision; Einstell- und Bewerbungskosten separat. Diamanten-Sofortkäufe zwischen Spielaccounts desselben PlayerNet-Accounts können gebührenfrei sein, bis 100.000 Diamanten pro PlayerNet-Account und Tag.","Classic-Auktionshaus","Original-Auktionshaus"},
 ES={"Comisión normal","Neto estimado","Neto tras la comisión normal; publicación y promoción aparte. Las compras inmediatas con diamantes entre cuentas del mismo PlayerNet pueden estar exentas, hasta 100.000 diamantes por cuenta PlayerNet al día.","Subasta Classic","Subasta original"},
 FR={"Commission normale","Net estimé","Net après commission normale ; mise en vente et promotion séparées. Les achats immédiats en diamants entre comptes du même PlayerNet peuvent être exonérés, jusqu’à 100 000 diamants par compte PlayerNet et par jour.","Enchères Classic","Enchères originales"},
 PL={"Zwykła prowizja","Szacowane netto","Netto po zwykłej prowizji; wystawienie i promocja osobno. Zakupy natychmiastowe za diamenty między kontami tego samego PlayerNet mogą być bez prowizji, do 100 000 diamentów na konto PlayerNet dziennie.","Aukcje Classic","Oryginalne aukcje"},
 RU={"Обычная комиссия","Ожидаемое нетто","После обычной комиссии; размещение и продвижение отдельно. Выкуп за алмазы между игровыми аккаунтами одного PlayerNet может быть без комиссии, до 100 000 алмазов на аккаунт PlayerNet в день.","Аукцион Classic","Оригинальный аукцион"},
 TR={"Normal komisyon","Tahmini net","Normal komisyon sonrası; listeleme ve tanıtım ayrı. Aynı PlayerNet hesabına bağlı oyun hesapları arasındaki elmasla hemen alımlar, PlayerNet hesabı başına günde 100.000 elmasa kadar komisyonsuz olabilir.","Classic müzayede","Orijinal müzayede"},
 JP={"通常手数料","予想手取額","通常手数料差引後。出品・宣伝費は別です。同一PlayerNetアカウントに紐づくゲームアカウント間のダイヤ即決購入は、PlayerNetアカウントごとに1日100,000ダイヤまで手数料免除の対象になります。","Classicオークション","標準オークション"},
 KR={"일반 수수료","예상 실수령액","일반 수수료 차감 후 금액이며 등록 및 홍보 비용은 별도입니다. 동일 PlayerNet에 연결된 게임 계정 간 다이아몬드 즉시 구매는 PlayerNet 계정당 하루 100,000 다이아몬드까지 수수료가 면제될 수 있습니다.","Classic 경매장","기본 경매장"},
 CN={"常规佣金","预计实收","扣除常规佣金后的金额；上架和推广费用另计。同一PlayerNet账号下游戏账号之间的钻石一口价购买，每个PlayerNet账号每天最多100,000钻石可免佣金。","Classic拍卖行","原版拍卖行"},
 TW={"一般佣金","預計實收","扣除一般佣金後的金額；上架和推廣費用另計。同一PlayerNet帳號下遊戲帳號之間的鑽石直購，每個PlayerNet帳號每天最多100,000鑽石可免佣金。","Classic拍賣行","原版拍賣行"},
}
local sale= saleCopy[language]
U.text.standardFee, U.text.expectedNet = sale[1], sale[2]
AAC_SALE_NOTE=sale[3]
AAC_HELP="/aac classic: "..sale[4].."\n/aac native: "..sale[5]
AAC_TOOLS_UNKNOWN_COMMAND=AAC_HELP
AAC_SALE_CONFIRM_INCOME="\n"..U.text.standardFee.." (%g%%): %d %s\n"..U.text.expectedNet..": %d %s"
AAC_LISTING_COST=U.text.listing
AAC_PROMOTION_COST=U.text.promotion
AAC_SALE_INCOME=U.text.standardFee.." %.2f%%: %d %s | "..U.text.expectedNet..": %d %s"
-- Both long tooltips and compact cells use the exact same raw stack price.
function U.UnitPrice(item)
 local count=tonumber(item.count) or 0
 local price=tonumber(item.buyoutPrice) or 0
 if count<=0 or price<=0 then return nil end
 return price/count
end
function U.Number(value, compact)
 local comma=language=="DE" or language=="ES" or language=="FR" or language=="PL" or language=="RU" or language=="TR"
 local digits=compact and (math.abs(value)>=1000 and 0 or 4) or 8
 if value~=0 and math.abs(value)<0.001 then digits=math.min(14,math.max(digits,math.ceil(-math.log(math.abs(value))/math.log(10))+3)) end
 local s=string.format("%."..digits.."f",value)
 if digits>0 then s=s:gsub("0+$",""):gsub("%.$","") end
 if value>0 and tonumber(s)==0 then return comma and "<0,00000000000001" or "<0.00000000000001" end
 local approximate=compact and tonumber(s)~=value
 local whole,fraction=s:match("^([^%.]+)%.?(.*)$")
 local sep=comma and "." or ","
 if language=="FR" or language=="PL" or language=="RU" then sep=" " end
 local sign,raw=s:match("^(%-?)(%d+)")
 whole=raw:reverse():gsub("(%d%d%d)","%1"..sep):reverse()
 if whole:sub(1,#sep)==sep then whole=whole:sub(#sep+1) end
 return (approximate and "~" or "")..sign..whole..(fraction~="" and (comma and "," or ".")..fraction or "")
end
function U.GoldLot(item) return tonumber(item.itemid)==200000 and item.moneyMode=="account" end
function U.Value(item)
 local price=U.UnitPrice(item)
 if price and U.GoldLot(item) then return item.count/item.buyoutPrice end
 return price
end
function U.UnitText(item, full, goldHeader)
 local price=U.Value(item)
 if not price then return "—" end
 if U.GoldLot(item) then
  local s=U.Number(price,not full)
  return full and s.." "..U.text.goldRate or "|cffffd45c"..s..(goldHeader and "" or " "..U.text.gold.."/"..U.text.diamonds).."|r"
 end
 local diamond=item.moneyMode=="account"
 local currency=full and TEXT(diamond and "SYS_MONEY_TYPE_1" or "SYS_MONEY_TYPE_0") or U.text[diamond and "diamonds" or "gold"]
 local s=U.Number(price,not full).." "..currency
 if full then return s end
 return (diamond and "|cff70cfff" or "|cffffd45c")..s.."|r"
end
local function compare(a,b,descending)
 local x,y=U.Value(a),U.Value(b)
 if (x==nil)~=(y==nil) then return x~=nil end
 local ac,bc=a.moneyMode or "copper",b.moneyMode or "copper"
 if ac~=bc then
  local rank={copper=1,account=2}
  return (rank[ac] or 3)<(rank[bc] or 3) or ((rank[ac] or 3)==(rank[bc] or 3) and ac<bc)
 end
 if U.GoldLot(a)~=U.GoldLot(b) then return U.GoldLot(a) end
 if x and y and x~=y then
  if U.GoldLot(a) then descending=not descending end
  if descending then return x>y end
  return x<y
 end
 return tostring(a.auctionid or "")<tostring(b.auctionid or "")
end
function AAC.Tools.SortUnitLess(a,b) return compare(a,b,false) end
function AAC.Tools.SortUnitMore(a,b) return compare(a,b,true) end
function U.Status(loading,filtering,cached,total,checked,matched)
 if loading then return string.format(U.text.loading,cached,total) end
 if filtering then return string.format(U.text.filtering,checked,total) end
 return string.format(U.text.done,matched)
end
