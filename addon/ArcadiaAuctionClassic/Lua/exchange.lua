-- Classic presentation for the installed client Exchange API. No native UI code copied.
local X={view="home",pages={orders=1,ask=1,bid=1},rows={},revision=0}
AAC.Exchange=X
local fallback={EXCHANGE="Exchange",FX_REFRESH="Refresh",FX_DIAMONDS_FOR_GOLD="Buy diamonds",FX_GOLD_FOR_DIAMONDS="Sell diamonds",
 FX_GOLD_PER_DIAMOND="Gold / diamond",FX_DIAMONDS="Diamonds",FX_OFFERS="Offers",FX_YOURS="Yours",FX_AMOUNT="Diamonds",
 FX_MAX_PRICE="Maximum gold / diamond",FX_MIN_PRICE="Minimum gold / diamond",FX_YOU_RECEIVE="You receive",FX_FEE="Fee",
 FX_LIST_OFFER="Place offer",FX_LIST_FOOTER="The balance is reserved. Fees apply when the order is filled.",
 FX_CANCEL="Cancel offer",FX_CANCEL_TITLE="Cancel this offer?",FX_NO_OFFERS="No offers",FX_LAST_PRICE="Last price",
 FX_24H="24h change",FX_VOLUME="24h volume",FX_ALT_TITLE="Other characters",MY_AUCTIONS="My offers",
 FX_ERR_DISABLED="Exchange is unavailable.",FX_ERR_DATA="Check amount and price.",FX_ERR_MONEY="Insufficient balance.",
 FX_ERR_MAX="Order limit reached.",FX_ERR_TOO_FAST="Please wait before trying again.",FX_ERR_FEE="Amount too small after fees.",
 FX_ERR_OWNER="This order belongs to another character.",FX_ERR_CHANGED="Offer changed. Review it again.",
 FX_CANCELLED="Offer cancelled.",FX_LISTED="Offer accepted.",BO_REFUND_BY_MAIL="Any refund arrives by mail.",
 FX_BUY="Buy diamonds",FX_SELL="Sell diamonds",FX_FEE_NONE="No fee",FX_NOT_AVAILABLE="Currently unavailable."}
local extra={
 EN={"Confirm trade","Reserved balance","Waiting for server…","No reply yet. Check your offers before trying again.","Trade confirmed","Available quantity","Remaining / total","Owner"},
 DE={"Tausch bestätigen","Reservierter Betrag","Warte auf Server…","Noch keine Antwort. Vor einem weiteren Versuch eigene Angebote prüfen.","Tausch bestätigt","Verfügbare Menge","Offen / Gesamt","Besitzer"},
 ES={"Confirmar cambio","Saldo reservado","Esperando al servidor…","Sin respuesta. Comprueba tus ofertas antes de reintentar.","Cambio confirmado","Cantidad disponible","Pendiente / total","Propietario"},
 FR={"Confirmer l’échange","Solde réservé","En attente du serveur…","Pas de réponse. Vérifiez vos offres avant de réessayer.","Échange confirmé","Quantité disponible","Restant / total","Propriétaire"},
 PL={"Potwierdź wymianę","Zarezerwowana kwota","Oczekiwanie na serwer…","Brak odpowiedzi. Sprawdź oferty przed kolejną próbą.","Wymiana potwierdzona","Dostępna ilość","Pozostało / razem","Właściciel"},
 RU={"Подтвердить обмен","Зарезервировано","Ожидание сервера…","Нет ответа. Проверьте свои заявки перед повтором.","Обмен подтверждён","Доступное количество","Осталось / всего","Владелец"},
 TR={"Takası onayla","Ayrılan bakiye","Sunucu bekleniyor…","Yanıt yok. Yeniden denemeden önce tekliflerinizi kontrol edin.","Takas onaylandı","Mevcut miktar","Kalan / toplam","Sahibi"},
 JP={"交換を確認","予約残高","サーバー応答待ち…","応答がありません。再試行前に自分の注文を確認してください。","交換完了","利用可能な数量","残り / 合計","所有者"},
 KR={"교환 확인","예약 잔액","서버 응답 대기 중…","응답이 없습니다. 다시 시도하기 전에 내 주문을 확인하세요.","교환 완료","가능 수량","남은 수량 / 합계","소유자"},
 CN={"确认兑换","预留余额","等待服务器…","尚无回复。再次尝试前请检查自己的订单。","兑换已确认","可用数量","剩余 / 总计","所有者"},
 TW={"確認兌換","預留餘額","等待伺服器…","尚無回覆。再次嘗試前請檢查自己的訂單。","兌換已確認","可用數量","剩餘 / 總計","擁有者"},
}
local lex=extra[AAC.UX.language or "EN"] or extra.EN
function X.T(key)
 local original=key
 key=({FX_AMOUNT="FX_DIAMONDS",FX_BUY="FX_BUY_DIAMONDS",FX_SELL="FX_SELL_DIAMONDS"})[key] or key
 local text=TEXT("UI_AUCTIONHUB_"..key)
 if text and text~="" and text~="UI_AUCTIONHUB_"..key then return text end
 return fallback[original] or fallback[key] or key
end
-- Simple exchange copy, independent of native technical order-book labels.
local simple={
 EN={"Get gold","Get diamonds","Manage offers","Quick exchange","You give","You receive","Fee already deducted","Diamonds to exchange (before fees)","Actual exchange: %s diamonds.","Choose an amount. Check what you receive. Confirm the exchange.","Review exchange","Fee included: %s"},
 DE={"Gold erhalten","Diamanten erhalten","Angebote verwalten","Einfach tauschen","Du gibst","Du erhältst","Gebühr bereits abgezogen","Tauschmenge in Diamanten (vor Gebühr)","Tatsächliche Tauschmenge: %s Diamanten.","Menge wählen. Ergebnis prüfen. Tausch bestätigen.","Tausch prüfen","Enthaltene Gebühr: %s"},
 ES={"Obtener oro","Obtener diamantes","Gestionar ofertas","Cambio rápido","Entregas","Recibes","Comisión ya descontada","Diamantes a cambiar (antes de comisión)","Cambio real: %s diamantes.","Elige la cantidad. Revisa lo que recibes. Confirma el cambio.","Revisar cambio","Comisión incluida: %s"},
 FR={"Obtenir de l’or","Obtenir des diamants","Gérer les offres","Échange rapide","Vous donnez","Vous recevez","Frais déjà déduits","Diamants à échanger (avant frais)","Quantité échangée : %s diamants.","Choisissez le montant. Vérifiez le résultat. Confirmez l’échange.","Vérifier l’échange","Frais inclus : %s"},
 PL={"Otrzymaj złoto","Otrzymaj diamenty","Zarządzaj ofertami","Szybka wymiana","Oddajesz","Otrzymujesz","Opłata już odliczona","Diamenty do wymiany (przed opłatą)","Wymieniana ilość: %s diamentów.","Wybierz ilość. Sprawdź wynik. Potwierdź wymianę.","Sprawdź wymianę","Uwzględniona opłata: %s"},
 RU={"Получить золото","Получить алмазы","Управление заявками","Быстрый обмен","Вы отдаёте","Вы получаете","Комиссия уже вычтена","Алмазы для обмена (до комиссии)","Объём обмена: %s алмазов.","Выберите количество. Проверьте результат. Подтвердите обмен.","Проверить обмен","Комиссия включена: %s"},
 TR={"Altın al","Elmas al","Teklifleri yönet","Hızlı takas","Verdiğiniz","Alacağınız","Ücret zaten düşüldü","Takas edilecek elmas (ücret öncesi)","Gerçek takas miktarı: %s elmas.","Miktarı seçin. Alacağınızı kontrol edin. Takası onaylayın.","Takası incele","Dahil edilen ücret: %s"},
 JP={"ゴールドを受け取る","ダイヤを受け取る","注文の管理","簡単交換","支払う金額","受け取る金額","手数料差引済み","交換するダイヤ数（手数料差引前）","実際の交換数量：ダイヤ%s個。","数量を選び、受取額を確認して交換を確定します。","交換内容を確認","含まれる手数料：%s"},
 KR={"골드 받기","다이아몬드 받기","주문 관리","간편 교환","지불 금액","받는 금액","수수료 차감 완료","교환할 다이아몬드 (수수료 차감 전)","실제 교환 수량: 다이아몬드 %s개.","수량을 선택하고 받을 금액을 확인한 후 교환을 확정하세요.","교환 검토","포함된 수수료: %s"},
 CN={"获取金币","获取钻石","管理挂单","快捷兑换","你支付","你获得","已扣除手续费","兑换钻石数量（扣费前）","实际兑换数量：%s颗钻石。","选择数量，查看到账金额，再确认兑换。","查看兑换","已含手续费：%s"},
 TW={"取得金幣","取得鑽石","管理掛單","快捷兌換","你支付","你獲得","已扣除手續費","兌換鑽石數量（扣費前）","實際兌換數量：%s顆鑽石。","選擇數量，查看到帳金額，再確認兌換。","查看兌換","已含手續費：%s"},
}
local simpleKeys={gold=1,diamonds=2,manage=3,home=4,give=5,receive=6,included=7,amount=8,partial=9,intro=10,trade=11,fee=12}
function X.SimpleText(key)
 return (simple[AAC.UX.language or "EN"] or simple.EN)[simpleKeys[key]] or key
end
local offerText={
 EN={"Offer gold","Offer diamonds","Gold to offer","Diamonds to offer","Rate: gold per diamond","You offer","You receive (before fee)","The fee is deducted when exchanged.","Review offer","My offers","Other characters","New offer","Your offered amount is reserved until exchanged or cancelled."},
 DE={"Gold anbieten","Diamanten anbieten","Goldmenge","Diamantenmenge","Kurs: Gold pro Diamant","Du bietest","Du erhältst (vor Gebühr)","Die Gebühr wird beim Tausch abgezogen.","Angebot prüfen","Meine Angebote","Andere Charaktere","Neues Angebot","Dein angebotener Betrag wird bis zum Tausch oder Abbruch reserviert."},
 ES={"Ofrecer oro","Ofrecer diamantes","Cantidad de oro","Cantidad de diamantes","Cambio: oro por diamante","Ofreces","Recibes (antes de comisión)","La comisión se descuenta al realizar el cambio.","Revisar oferta","Mis ofertas","Otros personajes","Nueva oferta","El importe ofrecido se reserva hasta el cambio o la cancelación."},
 FR={"Proposer de l’or","Proposer des diamants","Quantité d’or","Quantité de diamants","Taux : or par diamant","Vous proposez","Vous recevez (avant frais)","Les frais sont déduits lors de l’échange.","Vérifier l’offre","Mes offres","Autres personnages","Nouvelle offre","Le montant proposé est réservé jusqu’à l’échange ou l’annulation."},
 PL={"Zaoferuj złoto","Zaoferuj diamenty","Ilość złota","Ilość diamentów","Kurs: złoto za diament","Oferujesz","Otrzymasz (przed opłatą)","Opłata jest odliczana przy wymianie.","Sprawdź ofertę","Moje oferty","Inne postacie","Nowa oferta","Oferowana kwota jest rezerwowana do wymiany lub anulowania."},
 RU={"Предложить золото","Предложить алмазы","Количество золота","Количество алмазов","Курс: золото за алмаз","Вы предлагаете","Вы получите (до комиссии)","Комиссия вычитается при обмене.","Проверить заявку","Мои заявки","Другие персонажи","Новая заявка","Предложенная сумма резервируется до обмена или отмены."},
 TR={"Altın teklif et","Elmas teklif et","Altın miktarı","Elmas miktarı","Kur: elmas başına altın","Teklifiniz","Alacağınız (ücret öncesi)","Ücret takas gerçekleştiğinde düşülür.","Teklifi incele","Tekliflerim","Diğer karakterler","Yeni teklif","Teklif ettiğiniz tutar takasa veya iptale kadar ayrılır."},
 JP={"ゴールドを提供","ダイヤを提供","ゴールドの量","ダイヤの数","レート：ダイヤ1個あたりのゴールド","提供する金額","受取額（手数料差引前）","手数料は交換時に差し引かれます。","注文内容を確認","自分の注文","他のキャラクター","新しい注文","提供する金額は交換またはキャンセルまで確保されます。"},
 KR={"골드 제공","다이아몬드 제공","골드 수량","다이아몬드 수량","환율: 다이아몬드 1개당 골드","제공 금액","받을 금액 (수수료 차감 전)","수수료는 교환 시 차감됩니다.","주문 검토","내 주문","다른 캐릭터","새 주문","제공 금액은 교환 또는 취소까지 예약됩니다."},
 CN={"提供金币","提供钻石","金币数量","钻石数量","汇率：每颗钻石的金币数","你提供","你将获得（扣费前）","手续费在兑换时扣除。","查看挂单","我的挂单","其他角色","新建挂单","提供的金额将预留至兑换或取消。"},
 TW={"提供金幣","提供鑽石","金幣數量","鑽石數量","匯率：每顆鑽石的金幣數","你提供","你將獲得（扣費前）","手續費在兌換時扣除。","查看掛單","我的掛單","其他角色","建立掛單","提供的金額將預留至兌換或取消。"},
}
local offerKeys={gold=1,diamonds=2,goldAmount=3,diamondAmount=4,rate=5,give=6,receive=7,fee=8,review=9,own=10,alt=11,new=12,reserve=13}
function X.OfferText(key) return (offerText[AAC.UX.language or "EN"] or offerText.EN)[offerKeys[key]] or key end
local totalLabels={EN="Total price",DE="Gesamtpreis",ES="Precio total",FR="Prix total",PL="Cena całkowita",RU="Общая цена",TR="Toplam fiyat",JP="合計価格",KR="총 가격",CN="总价",TW="總價"}
local publicCopy={
 EN={"All offers","Players offer gold","Players offer diamonds","Average: 1 diamond = %s gold · before fee"},
 DE={"Alle Angebote","Spieler bieten Gold","Spieler bieten Diamanten","Ø 1 Diamant = %s Gold · vor Gebühr"},
 ES={"Todas las ofertas","Jugadores ofrecen oro","Jugadores ofrecen diamantes","Media: 1 diamante = %s oro · antes de comisión"},
 FR={"Toutes les offres","Les joueurs proposent de l’or","Les joueurs proposent des diamants","Moyenne : 1 diamant = %s or · avant frais"},
 PL={"Wszystkie oferty","Gracze oferują złoto","Gracze oferują diamenty","Średnio: 1 diament = %s złota · przed opłatą"},
 RU={"Все заявки","Игроки предлагают золото","Игроки предлагают алмазы","В среднем: 1 алмаз = %s золота · до комиссии"},
 TR={"Tüm teklifler","Oyuncular altın sunuyor","Oyuncular elmas sunuyor","Ortalama: 1 elmas = %s altın · ücret öncesi"},
 JP={"すべての注文","プレイヤーがゴールドを提供","プレイヤーがダイヤを提供","平均：ダイヤ1個 = %sゴールド（手数料差引前）"},
 KR={"모든 주문","플레이어의 골드 제공","플레이어의 다이아몬드 제공","평균: 다이아몬드 1개 = %s 골드 · 수수료 전"},
 CN={"所有挂单","玩家提供金币","玩家提供钻石","平均：1钻石 = %s金币 · 扣费前"},
 TW={"所有掛單","玩家提供金幣","玩家提供鑽石","平均：1鑽石 = %s金幣 · 扣費前"},
}
function X.PublicText(i) return (publicCopy[AAC.UX.language or "EN"] or publicCopy.EN)[i] end
local function num(n) return AAC.UX.Number(tonumber(n) or 0,false) end
local function money(n,mode) return num(n).." "..TEXT(mode=="account" and "SYS_MONEY_TYPE_1" or "SYS_MONEY_TYPE_0") end
local function integer(n) return type(n)=="number" and n==n and n>0 and n<math.huge and n==math.floor(n) end
local function available()
 for _,name in ipairs({"GetAuctionExchangeInfo","AuctionExchangeQuote","AuctionExchangeRequest","GetAuctionExchangeNumOffers",
 "GetAuctionExchangeOffer","AuctionExchangeTrade","AuctionExchangeCreate","AuctionExchangeCancel","GetAuctionExchangeNumMyOrders","GetAuctionExchangeMyOrder"}) do
  if type(_G[name])~="function" then return false end
 end
 return true
end
function X.Blocked() return X.pending~=nil or X.confirmation~=nil end
function X.Status(text)
 X.status=text
 if AAC_ExchangeStatus then AAC_ExchangeStatus:SetText(text or "") end
end
local function errorText(code)
 return X.T(({[1]="FX_ERR_DISABLED",[2]="FX_ERR_DATA",[3]="FX_ERR_MONEY",[4]="FX_ERR_MAX",[5]="FX_ERR_TOO_FAST",[6]="FX_ERR_FEE",[7]="FX_ERR_OWNER",[8]="FX_ERR_CHANGED"})[tonumber(code)] or "FX_ERR_DATA")
end
local function ownOrder(id)
 for i=1,GetAuctionExchangeNumMyOrders() or 0 do
  local oid,side,price,quantity,filled,remaining=GetAuctionExchangeMyOrder(i)
  if oid==id then return {id=oid,side=side,price=price,quantity=quantity,filled=filled or 0,remaining=remaining or 0} end
 end
end
local function snapshot(kind,side,quantity,limit)
 if not available() or not X.ready or not AAC.CanRequest() then return nil,X.T("FX_ERR_DISABLED") end
 if kind=="cancel" then return ownOrder(quantity),X.T("FX_ERR_OWNER") end
 local _,_,_,rate,enabled,minQ,maxQ,maxP=GetAuctionExchangeInfo()
 if enabled==false or enabled==0 or not AAC.FeatureEnabled(9096) then return nil,X.T("FX_ERR_DISABLED") end
 if (side~="ask" and side~="bid") or not integer(quantity) or (minQ and quantity<minQ) or (maxQ and maxQ>0 and quantity>maxQ)
  or (limit~=nil and limit~=0 and not integer(limit)) or (maxP and maxP>0 and (limit or 0)>maxP) then return nil,X.T("FX_ERR_DATA") end
 local q={side=side,quantity=quantity,limit=(limit or 0)>0 and limit or nil,rate=rate}
 if kind=="create" then
  if not q.limit then return nil,X.T("FX_ERR_DATA") end
  q.payMode=side=="bid" and "copper" or "account"
  q.escrow=side=="bid" and quantity*q.limit or quantity
 else
  local offers,filled,average,total,fee,feeMode,escrow=AuctionExchangeQuote(side,quantity,q.limit)
  if not offers or offers<=0 or not integer(filled) or not total or total<0 or not fee or fee<0
    or (feeMode~="account" and feeMode~="copper") then return nil,X.T("FX_NO_OFFERS") end
  -- API can quote only part of the wanted amount (or an indivisible lot).
  -- Requote the exact amount that will be submitted, just as the native trade sends it.
  if filled~=quantity then
   local o,f,a,t,c,m,e=AuctionExchangeQuote(side,filled,q.limit)
   if f~=filled or not o or o<=0 then return nil,X.T("FX_ERR_CHANGED") end
   offers,average,total,fee,feeMode,escrow=o,a,t,c,m,e
  end
  if type(total)~="number" or type(fee)~="number" or total<0 or fee<0 or (feeMode~="account" and feeMode~="copper") then return nil,X.T("FX_ERR_DATA") end
  q.quantity,q.offers,q.total,q.fee,q.feeMode,q.average=filled,offers,total,fee,feeMode,average
  q.payMode=side=="ask" and "copper" or "account"
  q.receiveMode=side=="ask" and "account" or "copper"
  q.pay=side=="ask" and total or filled
  q.net=math.max(0,(side=="ask" and filled or total)-fee)
  q.escrow=escrow or q.pay
 end
 if type(q.escrow)~="number" or q.escrow<0 or q.escrow>(GetPlayerMoney(q.payMode) or 0) then return nil,X.T("FX_ERR_MONEY") end
 return q
end
local compareKeys={"id","side","price","quantity","filled","limit","rate","offers","total","fee","feeMode","escrow","payMode","net"}
local function same(a,b)
 if not a or not b then return false end
 for _,k in ipairs(compareKeys) do if a[k]~=b[k] then return false end end
 return true
end
local function free()
 return AAC.CanRequest() and not X.Blocked() and not AAC.Market.Blocked()
  and not (AAC.Market.IsClosing and AAC.Market.IsClosing())
  and not (AAC.Market.HasConfirmation and AAC.Market.HasConfirmation())
end
function X.Describe(kind,q)
 if kind=="cancel" then return X.T("FX_CANCEL_TITLE").."\n"..money(q.quantity-q.filled,"account").." @ "..money(q.price,"copper") end
 if kind=="create" then
  return X.OfferText("give")..": "..money(q.escrow,q.payMode)
   .."\n"..X.OfferText("receive")..": "..money(q.side=="bid" and q.quantity or q.quantity*q.limit,q.side=="bid" and "account" or "copper")
   .."\n"..X.OfferText("rate")..": "..num(q.limit)
   .."\n"..X.OfferText("fee").."\n"..X.OfferText("reserve")
 end
 local text=X.SimpleText("give")..": "..money(q.pay,q.payMode)
  .."\n"..X.SimpleText("receive")..": "..money(q.net,q.receiveMode)
  .."\n"..string.format(X.SimpleText("fee"),money(q.fee,q.feeMode))
 if q.escrow~=q.pay then text=text.."\n"..lex[2]..": "..money(q.escrow,q.payMode).."\n"..X.T("BO_REFUND_BY_MAIL") end
 return text
end
function X.Preview(kind,side,quantity,limit)
 if kind~="trade" and kind~="create" and kind~="cancel" then return false end
 if not free() then X.Status(lex[3]); return false end
 local q,err=snapshot(kind,side,tonumber(quantity),tonumber(limit))
 if not q then X.Status(err); return false end
 X.confirmation={kind=kind,q=q,generation=AAC.SessionGeneration,deadline=GetTime()+30}
 StaticPopup_Show("AAC_EXCHANGE_CONFIRM",X.Describe(kind,q))
 X.Render()
 return true
end
function X.Dismiss()
 X.confirmation=nil
 X.Render()
end
function X.Accept()
 local c=X.confirmation
 X.confirmation=nil
 if not c then return end
 if not free() or GetTime()>=c.deadline or c.generation~=AAC.SessionGeneration then X.Render(); return end
 local q,err=snapshot(c.kind,c.q.side,c.kind=="cancel" and c.q.id or c.q.quantity,c.q.limit)
 if not same(q,c.q) then X.Status(err or X.T("FX_ERR_CHANGED")); X.Render(); return end
 local fn=c.kind=="trade" and AuctionExchangeTrade or c.kind=="create" and AuctionExchangeCreate or AuctionExchangeCancel
 X.pending={action=string.upper(c.kind),id=c.kind=="cancel" and q.id or nil,deadline=GetTime()+20,
  buy=c.kind=="trade" and q.side=="ask" or c.kind=="create" and q.side=="bid"}
 local worked,ok,code
 if c.kind=="cancel" then worked,ok,code=pcall(fn,q.id) else worked,ok,code=pcall(fn,q.side,q.quantity,q.limit) end
 if not worked then
  -- An exception cannot prove that the request was not already sent. Keep ownership.
  X.Status(lex[4])
 elseif ok~=true then X.pending=nil; X.Status(errorText(code))
 else X.Status(lex[3]) end
 X.Render()
end
function X.Request(silent)
 if not AAC.CanRequest() or not available() or X.requested then return end
 if AAC.Market.IsClosing and AAC.Market.IsClosing() then return end
 X.requested=GetTime()+15; X.nextRefresh=GetTime()+8
 if not silent then X.Status(lex[3]) end
 local ok,result=pcall(AuctionExchangeRequest)
 if not ok or result==false then X.requested=nil; X.Status(X.T("FX_ERR_DATA")) end
end
function X.Close()
 X.confirmation=nil; X.ready=false; X.requested=nil
 StaticPopup_Hide("AAC_EXCHANGE_CONFIRM")
end
function X.Tick()
 if AAC_ExchangeFrame and AAC_ExchangeFrame:IsVisible() and AAC.CanRequest() and not X.pending and not X.confirmation
  and not X.requested and GetTime()>=(X.nextRefresh or 0) then X.Request(true) end
 if X.pending and GetTime()>X.pending.deadline then X.Status(lex[4]) end
 if X.requested and GetTime()>X.requested then X.requested=nil; X.Status(lex[4]) end
end
function X.Event(event,action,result,id,filled,received,fee,refund,side,resting)
 if event=="AUCTION_EXCHANGE_RESULT" then
  if not X.pending or action~=X.pending.action or (X.pending.id and tostring(id)~=tostring(X.pending.id)) then return end
  local p=X.pending
  X.pending=nil
  local text=tonumber(result)==0 and (action=="CANCEL" and X.T("FX_CANCELLED") or action=="CREATE" and X.T("FX_LISTED") or lex[5]) or errorText(result)
  if tonumber(result)==0 and action~="CANCEL" then
   if (tonumber(filled) or 0)==0 and (action=="TRADE" or tonumber(resting)==0) then
    text=X.T("FX_ERR_CHANGED").." "..X.T("BO_REFUND_BY_MAIL")
   elseif (tonumber(filled) or 0)>0 then
    local mode=p.buy and "account" or "copper"
    text=lex[5]..": "..money(filled,"account").." | "..X.T("FX_YOU_RECEIVE")..": "..money(received,mode).." | "..X.T("FX_FEE")..": "..money(fee,mode)
   end
  end
  if tonumber(refund) and tonumber(refund)>0 then text=text.." "..X.T("BO_REFUND_BY_MAIL") end
  X.Request(); X.Status(text)
 elseif event=="AUCTION_EXCHANGE_UPDATE" then
  if not AAC.CanRequest() then return end
  X.requested=nil; X.ready=true; X.revision=X.revision+1
  if not X.pending then X.Status("") end
 elseif event=="AUCTION_CLOSE" then X.Close() end
 X.Render()
end
StaticPopupDialogs.AAC_EXCHANGE_CONFIRM={text="%s",button1=TEXT("ACCEPT"),button2=TEXT("CANCEL"),hideOnEscape=1,
 OnAccept=function() X.Accept() end,OnCancel=function() X.Dismiss() end,OnHide=function() X.Dismiss() end}

-- UI: bounded rows, independent paging, client-localized labels.
local function set(name,text) local f=_G["AAC_Exchange"..name]; if f then f:SetText(text or "") end end
local function enable(name,on) local f=_G["AAC_Exchange"..name]; if f then if on then f:Enable() else f:Disable() end end end
function X.Orders()
 local rows,seen={},{}
 local function add(id,side,price,quantity,filled,seconds,owner,isOwn)
  if not id or seen[tostring(id)] then return end
  seen[tostring(id)]=true
  rows[#rows+1]={id=id,side=side,price=price,quantity=quantity,filled=filled or 0,seconds=seconds or 0,owner=owner,isOwn=isOwn}
 end
 for i=1,GetAuctionExchangeNumMyOrders() or 0 do
  local id,side,price,quantity,filled,seconds=GetAuctionExchangeMyOrder(i)
  add(id,side,price,quantity,filled,seconds,type(UnitName)=="function" and UnitName("player") or nil,true)
 end
 if type(GetAuctionExchangeNumAltOrders)=="function" and type(GetAuctionExchangeAltOrder)=="function" then
  for i=1,GetAuctionExchangeNumAltOrders() or 0 do
   local id,side,price,quantity,filled,seconds,owner=GetAuctionExchangeAltOrder(i)
   add(id,side,price,quantity,filled,seconds,owner,false)
  end
 end
 return rows
end
function X.Book(side)
 local rows={}
 for i=1,GetAuctionExchangeNumOffers(side) or 0 do
  local price,quantity,count=GetAuctionExchangeOffer(side,i)
  if price and price>0 and quantity and quantity>0 then rows[#rows+1]={price=price,quantity=quantity,count=count} end
 end
 table.sort(rows,function(a,b) if side=="bid" then return a.price>b.price else return a.price<b.price end end)
 return rows
end
function X.RenderOrders()
 local rows=X.Orders(); X.rows.orders=rows
 local pages=math.max(1,math.ceil(#rows/4)); X.pages.orders=math.max(1,math.min(X.pages.orders,pages))
 set("OrdersCount",X.UIText(1)..": "..num(#rows))
 set("ordersPage",X.pages.orders.." / "..pages)
 enable("ordersPrev",X.pages.orders>1); enable("ordersNext",X.pages.orders<pages)
 for i=1,4 do
  local row=rows[(X.pages.orders-1)*4+i]; local frame=_G["AAC_Exchangeorders"..i]; frame.row=row
  for _,field in ipairs({"Kind","Quantity","Price","Time","Owner"}) do set("orders"..i..field,"") end
  if row then
   _G["AAC_Exchangeorders"..i.."Icon"]:Show()
   _G["AAC_Exchangeorders"..i.."Icon"]:SetTexture(row.side=="bid" and "Interface/Icons/coin_03.dds" or "Interface/Icons/crystal_01.dds")
   local dir=X.OfferText(row.side=="bid" and "gold" or "diamonds")
   frame.details=(row.owner and row.owner.." | " or "")..dir.." | "..num(row.quantity-row.filled).." / "..num(row.quantity).." | "..money(row.price,"copper").." | "..SecondsToTime(row.seconds)
   set("orders"..i.."Kind",dir); set("orders"..i.."Quantity",num((row.quantity-row.filled)*(row.side=="bid" and row.price or 1)))
   set("orders"..i.."Price",num(row.price)); set("orders"..i.."Time",SecondsToTime(row.seconds)); set("orders"..i.."Owner",row.owner or "—")
   if row.isOwn and X.selected==row.id then frame:LockHighlight() else frame:UnlockHighlight() end
   frame:Enable()
  else
   _G["AAC_Exchangeorders"..i.."Icon"]:Hide()
   frame.details=""; set("orders"..i.."Kind",i==1 and X.T("FX_NO_OFFERS") or "")
   frame:UnlockHighlight(); frame:Disable()
  end
 end
 enable("Cancel",free() and X.selected~=nil and ownOrder(X.selected)~=nil)
end
function X.Render()
 if not AAC_ExchangeFrame or not AAC_ExchangeFrame:IsVisible() then return end
 if not available() then X.Status(X.T("FX_NOT_AVAILABLE")); return end
 for _,pair in ipairs({{"QuickPanel",X.view=="home"},{"MarketPanel",X.view=="market"},{"OfferPanel",X.view=="offer" or X.view=="sell"},{"OrdersPanel",X.view=="orders" or X.view=="sell"},
   {"New",X.context=="sell" and X.view=="orders"},{"Back",X.view=="offer"},{"Books",X.view=="home"},{"Home",X.view=="market"}}) do
  local f=_G["AAC_Exchange"..pair[1]]; if pair[2] then f:Show() else f:Hide() end
 end
 if X.view=="sell" then X.RenderOffers(); X.RenderOrders()
 elseif X.view=="orders" then X.RenderOrders() elseif X.view=="offer" then X.RenderOffers() elseif X.view=="home" then X.RenderQuick() else X.RenderMarket() end
end
function X.ParseNumber(value)
 local text=tostring(value or "")
 if text:find("%.") and not text:match("^%d%d?%d?%.%d%d%d") then return nil end
 if text:find("%.") then
  local tail=text:match("^%d+%.(.*)$")
  for group in (tail.."."):gmatch("(.-)%.") do if not group:match("^%d%d%d$") then return nil end end
 end
 local digits=text:gsub("%.","")
 if not digits:match("^%d+$") then return nil end
 return tonumber(digits)
end
function X.GroupNumber(value)
 local t=string.format("%.0f",value); local n
 repeat t,n=t:gsub("^(%-?%d+)(%d%d%d)","%1.%2") until n==0
 return t
end
function X.OfferChanged(side,field,finish)
 if X.editingOffer then return end
 X.editingOffer=true; X.offerAnchor=X.offerAnchor or {}
 if field~="Amount" then X.offerAnchor[side]=field end
 local prefix="AAC_ExchangeOffer"..side
 local input=_G[prefix..field]; local raw=input:GetText()
 local digits=raw:gsub("%.","")
 local changed=digits:match("^%d+$") and tonumber(digits)
 -- Replacing the active text moves the native edit cursor. Group only on blur/Enter.
 if finish and changed and changed<1e14 then
  local formatted=X.GroupNumber(changed)
  if formatted~=raw then input:SetText(formatted) end
 end
 local function read(k)
  if k==field then return changed and changed<1e14 and changed or nil end
  return X.ParseNumber(_G[prefix..k]:GetText())
 end
 local amount,rate,total=read("Amount"),read("Rate"),read("Total")
 if amount and amount>0 then
  local key,value
  if X.offerAnchor[side]=="Total" then
   key="Rate"; if total and total>0 then value=side=="ask" and total/amount or amount/total end
  else key="Total"; if rate and rate>0 then value=side=="ask" and amount*rate or amount/rate end end
  _G[prefix..key]:SetText(value and value==math.floor(value) and value<1e14 and X.GroupNumber(value) or "")
 end
 X.editingOffer=false; X.Render()
end
local function offerInput(side)
 if side~="bid" and side~="ask" then return nil,nil end
 local amount=X.ParseNumber(_G["AAC_ExchangeOffer"..side.."Amount"]:GetText())
 local rate=X.ParseNumber(_G["AAC_ExchangeOffer"..side.."Rate"]:GetText())
 if not integer(amount) or not integer(rate) then return nil,rate end
 local quantity=side=="bid" and amount/rate or amount
 if not integer(quantity) then return nil,rate end
 local totalText=_G["AAC_ExchangeOffer"..side.."Total"]:GetText()
 if totalText~="" and X.ParseNumber(totalText)~=(side=="bid" and quantity or quantity*rate) then return nil,rate end
 return quantity,rate
end
function X.OfferDirection(side)
 if side~="ask" and side~="bid" then return end
 X.Dismiss(); X.offerSide=side; X.Render()
end
function X.RenderOffers()
 if X.view~="offer" and X.view~="sell" then return end
 for _,side in ipairs({"bid","ask"}) do
  local selected=side==(X.offerSide or "ask")
  local card=_G["AAC_ExchangeOffer"..side.."Card"]
  if selected then card:Show() else card:Hide() end
  for _,currency in ipairs({"bid","ask"}) do
   _G["AAC_ExchangeOffer"..side.."Choose"..currency]:SetChecked(currency==(X.offerSide or "ask"))
  end
  local quantity,rate=offerInput(side)
  local q,err=snapshot("create",side,quantity,rate)
  local prefix="Offer"..side
  set(prefix.."Pay",q and money(q.escrow,q.payMode) or "—")
  set(prefix.."Receive",q and money(side=="bid" and q.quantity or q.quantity*q.limit,side=="bid" and "account" or "copper") or "—")
  local entered=_G["AAC_Exchange"..prefix.."Amount"]:GetText()~="" and (_G["AAC_Exchange"..prefix.."Rate"]:GetText()~="" or _G["AAC_Exchange"..prefix.."Total"]:GetText()~="")
  set(prefix.."Note",not q and entered and err or "")
  enable(prefix.."Create",q~=nil and free())
 end
end
function X.CreateOffer(side)
 local quantity,rate=offerInput(side)
 X.Preview("create",side,quantity,rate)
end
function X.Manage() X.Dismiss(); X.view=X.context=="sell" and "sell" or "offer"; X.Render() end
function X.SetOrders() X.Dismiss(); X.view=X.context=="sell" and "sell" or "orders"; X.selected=nil; X.pages.orders=1; X.Render() end
function X.Page(side,delta) X.pages[side]=math.max(1,X.pages[side]+delta); X.Render() end
function X.Select(side,frame)
 if side~="orders" or not frame.row then return end
 X.selected=frame.row.isOwn and frame.row.id or nil; X.Render()
end
function X.Action(kind) if kind=="cancel" then X.Preview(kind,nil,X.selected) end end

-- Integrated classic list and compact quote. The transaction core above is shared.
local integratedCopy={
 EN={"Exchange (new)","Auctions","Available","Amount in diamonds","Best available rate","At this rate or better","Exchange"},
 DE={"Tausch (neu)","Auktionen","Verfügbar","Menge in Diamanten","Bester verfügbarer Kurs","Zu diesem Kurs oder günstiger","Tausch"},
 ES={"Cambio (nuevo)","Subastas","Disponible","Cantidad de diamantes","Mejor cambio disponible","A este cambio o mejor","Cambio"},
 FR={"Change (nouveau)","Enchères","Disponible","Quantité de diamants","Meilleur taux disponible","À ce taux ou mieux","Change"},
 PL={"Wymiana (nowa)","Aukcje","Dostępne","Liczba diamentów","Najlepszy dostępny kurs","Po tym kursie lub lepszym","Wymiana"},
 RU={"Обмен (новый)","Аукционы","Доступно","Количество алмазов","Лучший доступный курс","По этому курсу или лучше","Обмен"},
 TR={"Takas (yeni)","Müzayedeler","Mevcut","Elmas miktarı","Mevcut en iyi kur","Bu kurdan veya daha iyi","Takas"},
 JP={"交換（新）","オークション","利用可能","ダイヤの数量","利用可能な最良レート","このレート以上の条件で交換","交換"},
 KR={"교환 (신규)","경매","이용 가능","다이아몬드 수량","이용 가능한 최적 환율","이 환율 또는 더 좋은 환율","교환"},
 CN={"兑换（新）","拍卖","可用数量","钻石数量","当前最佳汇率","按此汇率或更优汇率","兑换"},
 TW={"兌換（新）","拍賣","可用數量","鑽石數量","目前最佳匯率","按此匯率或更優匯率","兌換"},
}
function X.UIText(i) return (integratedCopy[AAC.UX.language or "EN"] or integratedCopy.EN)[i] end
function X.SetDirection(side)
 if side~="bid" and side~="ask" then return end
 X.Dismiss(); X.side=side; X.limit=nil; X.offset=0; X.Render()
end
function X.SelectRate(frame)
 if not frame.row then return end
 X.Dismiss(); X.limit=frame.row.price; X.view="home"; X.custom=X.custom or {}; X.custom[X.side or "bid"]=true; X.Render()
end
function X.Home() X.Dismiss(); X.limit=nil; X.view="home"; X.Render() end
function X.Books() X.Dismiss(); X.view="market"; X.offset=0; X.Render() end
function X.Scroll(delta)
 X.offset=math.max(0,(X.offset or 0)+delta); X.Render()
end
function X.Preset(amount,side)
 side=side or X.side; if side~="bid" and side~="ask" then return end
 _G["AAC_ExchangeQuick"..side.."Amount"]:SetText(X.GroupNumber(amount)); X.Render()
end
function X.QuickAmountChanged(side,finish)
 if X.editingQuick then return end
 X.editingQuick=true
 local input=_G["AAC_ExchangeQuick"..side.."Amount"]; local raw=input:GetText()
 local digits=raw:gsub("%.",""); local n=digits:match("^%d+$") and tonumber(digits)
 if finish and n and n<1e14 then local formatted=X.GroupNumber(n); if formatted~=raw then input:SetText(formatted) end end
 X.editingQuick=false; X.Render()
end
function X.Trade(side)
 side=side or X.side; if side~="bid" and side~="ask" then return end
 X.Preview("trade",side,X.ParseNumber(_G["AAC_ExchangeQuick"..side.."Amount"]:GetText()),side==X.side and X.limit or 0)
end
function X.RenderMarket()
 local side=X.side or "bid"; local rows=X.Book(side); X.rows[side]=rows
 set("EmptyBook",#rows==0 and X.T("FX_NO_OFFERS") or "")
 X.offset=math.min(math.max(0,#rows-7),X.offset or 0)
 for i=1,7 do
  local f=_G["AAC_ExchangeRate"..i]; local row=rows[X.offset+i]; f.row=row
  set("Rate"..i.."Price",row and num(row.price) or (i==1 and X.T("FX_NO_OFFERS") or ""))
  set("Rate"..i.."Quantity",row and money(side=="bid" and row.price*row.quantity or row.quantity,side=="bid" and "copper" or "account") or "")
  if row then f:Show(); f:Enable() else f:Hide() end
  if row and row.price==X.limit then f:LockHighlight() else f:UnlockHighlight() end
 end
 set("RatePage",#rows==0 and "0 / 0" or (X.offset+1).."–"..math.min(#rows,X.offset+7).." / "..#rows)
 enable("RatePrev",X.offset>0); enable("RateNext",X.offset+7<#rows)
 for _,dir in ipairs({"bid","ask"}) do
  local f=_G["AAC_ExchangeDirection"..dir]; if dir==side then f:LockHighlight() else f:UnlockHighlight() end
 end
 set("BookTitle",X.PublicText(side=="bid" and 2 or 3))
end
local customLabels={EN="Other amount…",DE="Andere Menge …",ES="Otra cantidad…",FR="Autre quantité…",PL="Inna ilość…",RU="Другая сумма…",TR="Başka miktar…",JP="その他の数量…",KR="다른 수량…",CN="其他数量…",TW="其他數量…"}
function X.Custom(side)
 X.custom=X.custom or {}; X.custom[side]=not X.custom[side]; X.Render()
end
function X.QuickRow(side,amount) X.Preset(amount,side); X.Trade(side) end
local quickBuyLabels={EN="Buy",DE="Kaufen",ES="Comprar",FR="Acheter",PL="Kup",RU="Купить",TR="Satın al",JP="購入",KR="구매",CN="购买",TW="購買"}
local backLabels={EN="Back",DE="Zurück",ES="Volver",FR="Retour",PL="Wstecz",RU="Назад",TR="Geri",JP="戻る",KR="뒤로",CN="返回",TW="返回"}
function X.LayoutCustom(side,custom)
 local prefix="AAC_ExchangeQuick"..side
 local card=_G[prefix.."Card"]; local half=X.quickWidth or 399
 local column=(half-48)/2
 local function place(name,x,y,w)
  local f=_G[prefix..name]; f:ClearAllAnchors(); f:SetAnchor("TOPLEFT","TOPLEFT",card,x,y)
  if w then f:SetWidth(w) end
 end
 place("Custom",18,315,custom and 108 or half-38)
 place("Trade",136,315,half-154)
 place("AmountLabel",18,64,half-36); place("Amount",18,88,half-36)
 place("ReceiveLabel",18,137,column); place("Receive",41,162,column-23)
 place("PayLabel",30+column,137,column); place("Pay",53+column,162,column-23)
 place("PayIcon",30+column,167)
 place("Included",18,custom and 198 or 287,half-36)
 place("Note",18,222,half-36); place("Rate",18,263,half-36)
end
function X.RenderQuick()
 for _,side in ipairs({"bid","ask"}) do
  local prefix="Quick"..side
  local custom=X.custom and X.custom[side]
  for _,name in ipairs({"AmountLabel","Amount","Rate","PayLabel","Pay","ReceiveLabel","Receive","ReceiveIcon","PayIcon","Included","Note","Trade"}) do
   local f=_G["AAC_Exchange"..prefix..name]; if custom then f:Show() else f:Hide() end
  end
  X.LayoutCustom(side,custom)
  set(prefix.."Custom",custom and (backLabels[AAC.UX.language or "EN"] or backLabels.EN) or (customLabels[AAC.UX.language or "EN"] or customLabels.EN))
  local included=_G["AAC_Exchange"..prefix.."Included"]
  included:Show()
  for _,name in ipairs({"NetHead","CostHead"}) do
   local f=_G["AAC_Exchange"..prefix..name]; if custom then f:Hide() else f:Show() end
  end
  local any=false; local last; local reason; local count=0
  for i,n in ipairs({1000,500,100,25}) do
   local row=_G["AAC_Exchange"..prefix.."Row"..i]
   local q,err=snapshot("trade",side,n,side==X.side and X.limit or 0)
   if not reason then reason=err end
   set(prefix.."Row"..i.."Net",q and num(q.net) or "—")
   set(prefix.."Row"..i.."Cost",q and num(q.pay) or "—")
   set(prefix.."Row"..i.."Buy",quickBuyLabels[AAC.UX.language or "EN"] or quickBuyLabels.EN)
   enable(prefix.."Row"..i.."Buy",q~=nil and free())
   local signature=q and (q.quantity..":"..q.pay..":"..q.net)
   if not custom and q and signature~=last then
    row:ClearAllAnchors(); row:SetAnchor("TOPLEFT","TOPLEFT",_G["AAC_Exchange"..prefix.."Card"],18,91+count*46)
    row:Show(); any=true; count=count+1
   else row:Hide() end
   last=signature or last
  end
  set(prefix.."Empty",not custom and not any and (reason or X.T("FX_NO_OFFERS")) or "")
  local amount=X.ParseNumber(_G["AAC_Exchange"..prefix.."Amount"]:GetText())
  local limit=side==X.side and X.limit or nil
  local q,err=snapshot("trade",side,amount,limit or 0)
  set(prefix.."Rate",limit and (num(limit).." "..X.T("FX_GOLD_PER_DIAMOND").." · "..X.UIText(6)) or (q and string.format(X.PublicText(4),num(q.total/q.quantity)) or ""))
  set(prefix.."Pay",q and num(q.pay) or "—")
  set(prefix.."Receive",q and num(q.net) or "—")
  local note=q and string.format(X.SimpleText("fee"),money(q.fee,q.feeMode)) or err
  if q and q.quantity~=amount then note=string.format(X.SimpleText("partial"),num(q.quantity)).."\n"..note end
  set(prefix.."Note",note); enable(prefix.."Trade",q~=nil and free())
 end
end

function X.Show()
 X.custom={}
 X.view=X.context=="sell" and "sell" or "home"; X.side=X.side or "bid"; X.offset=0; X.limit=nil
 set("Heading",X.context=="browse" and X.UIText(1) or "")
 set("New",X.OfferText("new")); set("Back",X.OfferText("own"))
 set("Books",X.PublicText(1)); set("Home",X.SimpleText("home"))
 set("Directionbid",X.SimpleText("gold")); set("Directionask",X.SimpleText("diamonds"))
 set("RatePriceHead",X.T("FX_GOLD_PER_DIAMOND")); set("RateQuantityHead",X.UIText(3))
 for _,side in ipairs({"bid","ask"}) do
  local prefix="Quick"..side
  set(prefix.."Title",X.SimpleText(side=="bid" and "gold" or "diamonds"))
  set(prefix.."AmountLabel",X.UIText(4)); set(prefix.."PayLabel",X.SimpleText("give"))
  set(prefix.."ReceiveLabel",X.SimpleText("receive")); set(prefix.."Included",X.SimpleText("included"))
  set(prefix.."NetHead",X.SimpleText("receive")); set(prefix.."CostHead",X.SimpleText("give"))
  set(prefix.."Trade",X.SimpleText("trade"))
  local input=_G["AAC_Exchange"..prefix.."Amount"]; if input:GetText()=="" then input:SetText("100") end
 end
 for _,side in ipairs({"bid","ask"}) do
  local prefix="Offer"..side
  set(prefix.."Title",X.OfferText("give"))
  for _,currency in ipairs({"bid","ask"}) do
   set(prefix.."Choose"..currency.."Caption",TEXT(currency=="bid" and "SYS_MONEY_TYPE_0" or "SYS_MONEY_TYPE_1"))
  end
  set(prefix.."AmountLabel",X.OfferText(side=="bid" and "goldAmount" or "diamondAmount"))
  set(prefix.."TotalLabel",(totalLabels[AAC.UX.language or "EN"] or totalLabels.EN).." ("..TEXT(side=="ask" and "SYS_MONEY_TYPE_0" or "SYS_MONEY_TYPE_1")..")")
  set(prefix.."RateLabel",(AAC_GENERAL_PRICE_PER_UNIT_HEADER or "Price/each").." · "..X.T("FX_GOLD_PER_DIAMOND")); set(prefix.."PayLabel",X.OfferText("give"))
  set(prefix.."ReceiveLabel",X.OfferText("receive")); set(prefix.."Fee",X.OfferText("fee")); set(prefix.."Create",X.OfferText("review"))
 end
 set("Cancel",X.T("FX_CANCEL")); set("OrdersKindHead",X.OfferText("own"))
 set("OrdersQuantityHead",X.UIText(3))
 set("OrdersPriceHead",X.T("FX_GOLD_PER_DIAMOND")); set("OrdersTimeHead",TEXT("TIMEFLAG_STATE")); set("OrdersOwnerHead",lex[8])
 X.Request(); X.Render()
end
local browseParts={"Search","Filter","Currency","List","SearchButton","ResetButton","SavedSearchExpandButton","SavedSearchMinimizeButton","SavedSearchPlusButton","QueueExpandButton","QueueMinimizeButton","InfoLabel","HistoryButton","QueueButton","BidButton","BuyoutButton","BidMoneyInput"}
function X.Leave()
 X.Dismiss(); X.context=nil
 if AAC_SellAuctionContent then AAC_SellAuctionContent:Show() end
 if AAC_SellExchange then AAC_SellExchange:SetChecked(false) end
 if X.hiddenBrowse then
  for name,wasVisible in pairs(X.hiddenBrowse) do local f=_G[name]; if f and wasVisible then f:Show() end end
  X.hiddenBrowse=nil
 end
 if X.hiddenEditors then
  for name,wasVisible in pairs(X.hiddenEditors) do local f=_G[name]; if f and wasVisible then f:Show() end end
  X.hiddenEditors=nil
 end
 if AAC_ExchangeFrame then AAC_ExchangeFrame:Hide() end
end
function X.TabChanged(tab)
 if AAC_ExchangeNavigation then AAC_ExchangeNavigation:Hide() end
 X.hostTab=tab
 if AAC_SellExchangeLabel then AAC_SellExchangeLabel:SetText(X.UIText(1)) end
end
function X.SetSellMode(enabled)
 if enabled then
  AAC.Sell.ChangeAuctionType(false)
  X.Open("sell")
  AAC_SellExchange:SetChecked(true)
 else X.Leave() end
end
function X.UseMoneyAuction(enabled)
 if X.context=="sell" then X.Leave() end
 AAC.Sell.ChangeAuctionType(enabled)
end
function X.Legacy() AAC.Main.ClickTab(X.hostTab==3 and 3 or 6) end
function X.Open(context)
 X.Leave(); X.context=context; X.side="bid"
 -- Capture effective visibility before hiding a parent of either editor.
 X.hiddenEditors={AAC_HistoryEditBox=AAC_HistoryEditBox:IsVisible(),AAC_SellEditBox=AAC_SellEditBox:IsVisible()}
 if context=="browse" then
  AAC.Browse.Frame_StopUpdates()
  X.hiddenBrowse={}
  for _,part in ipairs(browseParts) do local name="AAC_Browse"..part; local f=_G[name]
   if f then X.hiddenBrowse[name]=f:IsVisible(); f:Hide() end
  end
 elseif context=="dashboard" then AAC_DashboardFrame:Hide()
 elseif context=="sell" then AAC_SellAuctionContent:Hide() end
 AAC_HistoryEditBox:Hide(); AAC_SellEditBox:Hide()
 local narrow=context=="browse"; local width=narrow and 650 or 814
 AAC_ExchangeFrame:ClearAllAnchors(); AAC_ExchangeFrame:SetAnchor("TOPLEFT","TOPLEFT",AAC_AuctionFrame,narrow and 178 or 16,40)
 AAC_ExchangeFrame:SetWidth(width)
 AAC_ExchangeFrame:SetFrameLevel(AAC_AuctionFrame:GetFrameLevel()+20)
 AAC_ExchangeNavigation:SetFrameLevel(AAC_AuctionFrame:GetFrameLevel()+30)
 AAC_ExchangeMarketPanel:SetWidth(width)
 AAC_ExchangeRateList:SetWidth(width)
 AAC_ExchangeStatus:SetWidth(width-24)
 for _,name in ipairs({"Books","Home"}) do
  local f=_G["AAC_Exchange"..name]; f:ClearAllAnchors(); f:SetAnchor("TOPRIGHT","TOPRIGHT",AAC_ExchangeFrame,-8,6)
 end
 local half=(width-16)/2
 X.quickWidth=half
 for n,side in ipairs({"bid","ask"}) do
  local prefix="AAC_ExchangeQuick"..side; local card=_G[prefix.."Card"]
  card:SetWidth(half); card:ClearAllAnchors(); card:SetAnchor("TOPLEFT","TOPLEFT",AAC_ExchangeQuickPanel,(n-1)*(half+16),0)
  for _,name in ipairs({"AmountLabel","Amount","Rate","PayLabel","Pay","ReceiveLabel","Receive","Included","Note","Trade"}) do _G[prefix..name]:SetWidth(half-28) end
  local custom=_G[prefix.."Custom"]; custom:SetWidth(half-38)
  for i=1,4 do
   local row=_G[prefix.."Row"..i]; row:SetWidth(half-36)
   local buyWidth=narrow and 64 or 78
   local buy=_G[prefix.."Row"..i.."Buy"]; buy:SetWidth(buyWidth); buy:ClearAllAnchors(); buy:SetAnchor("TOPRIGHT","TOPRIGHT",row,-2,0)
   local cost=_G[prefix.."Row"..i.."Cost"]; cost:SetWidth(narrow and 61 or 91); cost:ClearAllAnchors(); cost:SetAnchor("TOPRIGHT","TOPRIGHT",row,-buyWidth-41,5)
   local icon=_G[prefix.."Row"..i.."CostIcon"]; icon:ClearAllAnchors(); icon:SetAnchor("TOPRIGHT","TOPRIGHT",row,-buyWidth-20,8)
   local net=_G[prefix.."Row"..i.."Net"]; net:SetWidth(narrow and 84 or 130)
  end
  _G[prefix.."Title"]:SetWidth(half-72)
  local costHead=_G[prefix.."CostHead"]; costHead:ClearAllAnchors(); costHead:SetAnchor("TOPRIGHT","TOPRIGHT",card,narrow and -123 or -113,65)
 end
 local quantityX=math.floor(width*.55)
 AAC_ExchangeRateQuantityHead:ClearAllAnchors(); AAC_ExchangeRateQuantityHead:SetAnchor("TOPLEFT","TOPLEFT",AAC_ExchangeRateList,quantityX,43)
 AAC_ExchangeRateNext:ClearAllAnchors(); AAC_ExchangeRateNext:SetAnchor("TOPRIGHT","TOPRIGHT",AAC_ExchangeRateList,-15,300)
 for i=1,7 do
  local row=_G["AAC_ExchangeRate"..i]; row:SetWidth(width-22)
  local quantity=_G["AAC_ExchangeRate"..i.."Quantity"]
  quantity:ClearAllAnchors(); quantity:SetAnchor("TOPLEFT","TOPLEFT",row,quantityX-10,10)
 end
 AAC_ExchangeFrame:Show()
 -- Show() is dispatched by the client OnShow script. Navigation remains above the content.
end
function X.OpenFromNavigation() X.Open(X.hostTab==3 and "sell" or "dashboard") end
