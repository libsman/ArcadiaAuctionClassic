-- Short instructions and settings labels shared by the Classic frames.
local keys=[[disableHistory showUnit exactUnit decimals helpTitle commandsTitle stepsTitle searchStep filterStep excludeStep exampleStep cardsStep sortStep buysStep salesStep]]
local rows={
EN=[[Do not save price history|Show price per unit|Show more decimal places|Decimal places|Quick guide|Filter commands|Filter in three steps|1. Enter the item name under Search.|2. Enter a word from its tooltip in Filter.|3. Click Search. Only matching offers remain.|Example: search for a mana stone and filter by the name of its stat.|Use $notowned to find monster cards you do not own.|Click a column heading to sort offers.|Manage bids and buy orders under My purchases.|Sell items and manage exchanges under My offers.]],
DE=[[Preisverlauf nicht speichern|Preis pro Stück anzeigen|Mehr Nachkommastellen anzeigen|Nachkommastellen|Kurzanleitung|Filterbefehle|Filtern in drei Schritten|1. Gegenstandsnamen unter Suchen eingeben.|2. Ein Wort aus dem Tooltip in Filter eingeben.|3. Suchen anklicken. Nur passende Angebote bleiben.|Beispiel: Manastein suchen und nach dem Namen seines Stats filtern.|Mit $notowned findest du Monsterkarten, die dir noch fehlen.|Zum Sortieren auf eine Spaltenüberschrift klicken.|Gebote und Kaufaufträge unter Meine Käufe verwalten.|Gegenstände verkaufen und Tausch unter Meine Angebote verwalten.]],
ES=[[No guardar el historial de precios|Mostrar precio por unidad|Mostrar más decimales|Decimales|Guía rápida|Comandos de filtro|Filtrar en tres pasos|1. Escribe el nombre del objeto en Buscar.|2. Escribe una palabra de su descripción en Filtro.|3. Pulsa Buscar. Solo quedan ofertas coincidentes.|Ejemplo: busca una piedra de maná y filtra por su atributo.|Usa $notowned para encontrar cartas que aún no tienes.|Pulsa un encabezado para ordenar las ofertas.|Gestiona pujas y órdenes de compra en Mis compras.|Vende objetos y gestiona intercambios en Mis ofertas.]],
FR=[[Ne pas enregistrer l’historique des prix|Afficher le prix à l’unité|Afficher plus de décimales|Décimales|Guide rapide|Commandes de filtre|Filtrer en trois étapes|1. Saisissez le nom de l’objet dans Rechercher.|2. Saisissez un mot de son infobulle dans Filtre.|3. Cliquez sur Rechercher pour filtrer les offres.|Exemple : cherchez une pierre de mana et filtrez par le nom de son attribut.|Utilisez $notowned pour trouver les cartes que vous n’avez pas.|Cliquez sur un en-tête pour trier les offres.|Gérez les enchères et ordres d’achat dans Mes achats.|Vendez et gérez les échanges dans Mes offres.]],
PL=[[Nie zapisuj historii cen|Pokaż cenę za sztukę|Pokaż więcej miejsc po przecinku|Miejsca po przecinku|Krótki poradnik|Polecenia filtra|Filtrowanie w trzech krokach|1. Wpisz nazwę przedmiotu w Szukaj.|2. Wpisz słowo z opisu przedmiotu w Filtr.|3. Kliknij Szukaj. Zostaną pasujące oferty.|Przykład: szukaj kamienia many i filtruj po nazwie jego atrybutu.|Użyj $notowned, aby znaleźć brakujące karty potworów.|Kliknij nagłówek kolumny, aby posortować oferty.|Licytacje i zlecenia kupna znajdziesz w Moje zakupy.|Sprzedaż i wymianę obsłużysz w Moje oferty.]],
RU=[[Не сохранять историю цен|Показывать цену за штуку|Показывать больше знаков после запятой|Знаки после запятой|Краткая справка|Команды фильтра|Фильтр в три шага|1. Введите название предмета в поиске.|2. Введите слово из описания предмета в фильтр.|3. Нажмите поиск. Останутся подходящие предложения.|Пример: найдите камень маны и укажите название его атрибута в фильтре.|Команда $notowned находит карты, которых у вас нет.|Нажмите заголовок столбца для сортировки.|Ставки и заказы находятся в разделе Мои покупки.|Продажи и обмен находятся в разделе Мои предложения.]],
TR=[[Fiyat geçmişini kaydetme|Birim fiyatı göster|Daha fazla ondalık basamak göster|Ondalık basamaklar|Kısa rehber|Filtre komutları|Üç adımda filtreleme|1. Ara bölümüne eşya adını yazın.|2. Filtreye eşya açıklamasından bir kelime yazın.|3. Ara düğmesine basın. Eşleşen teklifler kalır.|Örnek: mana taşı arayın ve özellik adına göre filtreleyin.|Sahip olmadığınız canavar kartları için $notowned kullanın.|Sıralamak için sütun başlığına tıklayın.|Teklifleri ve alım emirlerini Alımlarım bölümünde yönetin.|Satışları ve takasları Tekliflerim bölümünde yönetin.]],
JP=[[価格履歴を保存しない|単価を表示|小数点以下を詳しく表示|小数点以下の桁数|簡単ガイド|フィルターコマンド|3ステップで絞り込み|1. 検索欄にアイテム名を入力。|2. フィルター欄に説明文の単語を入力。|3. 検索すると一致する出品だけが残ります。|例：マナストーンを検索し、属性名で絞り込みます。|$notownedで未所持のモンスターカードを探せます。|列見出しをクリックすると並べ替えられます。|入札と購入注文は購入管理にあります。|出品と交換は自分の出品で管理できます。]],
KR=[[가격 기록 저장 안 함|개당 가격 표시|소수점 더 자세히 표시|소수 자릿수|간단 안내|필터 명령어|세 단계로 필터링|1. 검색에 아이템 이름을 입력하세요.|2. 필터에 아이템 설명의 단어를 입력하세요.|3. 검색을 누르면 일치하는 매물만 남습니다.|예: 마나석을 검색한 뒤 속성 이름으로 필터링하세요.|$notowned로 보유하지 않은 몬스터 카드를 찾습니다.|열 제목을 클릭하면 정렬됩니다.|입찰과 구매 주문은 내 구매에서 관리합니다.|판매와 교환은 내 매물에서 관리합니다.]],
CN=[[不保存价格历史|显示单价|显示更多小数位|小数位数|简明指南|筛选命令|三步筛选|1. 在搜索栏输入物品名称。|2. 在筛选栏输入物品说明中的词。|3. 点击搜索，只保留匹配的商品。|例如：搜索魔石，再按属性名称筛选。|使用 $notowned 查找尚未拥有的怪物卡片。|点击列标题可排序。|在我的购买中管理竞价和求购。|在我的商品中管理出售和兑换。]],
TW=[[不儲存價格歷史|顯示單價|顯示更多小數位|小數位數|簡明指南|篩選指令|三步篩選|1. 在搜尋欄輸入物品名稱。|2. 在篩選欄輸入物品說明中的詞。|3. 點擊搜尋，只保留符合的商品。|例如：搜尋魔石，再按屬性名稱篩選。|使用 $notowned 尋找尚未擁有的怪物卡片。|點擊欄位標題可排序。|在我的購買中管理競價和求購。|在我的商品中管理出售和兌換。]],
}
local compactRows={
 EN=[[History|Material prices per base unit|Use average when no last price exists|Filter processing speed]],
 DE=[[Verlauf|Materialpreise je Basiseinheit|Ohne letzten Preis Durchschnitt nutzen|Verarbeitungstempo der Filter]],
 ES=[[Historial|Materiales por unidad básica|Usar media si no hay último precio|Velocidad de los filtros]],
 FR=[[Historique|Matériaux par unité de base|Utiliser la moyenne sans dernier prix|Vitesse des filtres]],
 PL=[[Historia|Materiały za jednostkę bazową|Użyj średniej bez ostatniej ceny|Szybkość filtrowania]],
 RU=[[История|Материалы за базовую единицу|Средняя цена, если последней нет|Скорость фильтров]],
 TR=[[Geçmiş|Temel birim başına malzeme fiyatı|Son fiyat yoksa ortalamayı kullan|Filtre işleme hızı]],
 JP=[[履歴|素材の基本単位価格|前回価格がなければ平均を使う|フィルター処理速度]],
 KR=[[내역|재료 기본 단위 가격|최근 가격이 없으면 평균 사용|필터 처리 속도]],
 CN=[[历史|材料基础单位价格|无上次价格时使用均价|筛选处理速度]],
 TW=[[歷史|材料基本單位價格|無上次價格時使用均價|篩選處理速度]],
}
AAC.FrontendLocale={rows=rows,keys=keys}
function AAC.FrontendLocale.Apply(language)
    local lang=tostring(language or AAC.TradingLocale.language or "EN"):sub(1,2):upper()
    lang=({JA="JP",KO="KR"})[lang] or lang
    local values={};for value in ((rows[lang] or rows.EN).."|"):gmatch("(.-)|") do values[#values+1]=value end
    local i=0;for key in keys:gmatch("%S+") do i=i+1;AAC.TradingTranslations[key]=values[i] end
    assert(i==#values,"AAC frontend translation count mismatch")
    local compact={};for value in ((compactRows[lang] or compactRows.EN).."|"):gmatch("(.-)|") do compact[#compact+1]=value end
    AAC.TradingTranslations.historyShort=compact[1]
    AAC.TradingTranslations.materialUnit=compact[2]
    AAC.TradingTranslations.averageFallback=compact[3]
    AAC.TradingTranslations.filterTempo=compact[4]
    AACLocale.Messages.SETTINGS_DISABLE_SAVE=AAC.TradingTranslations.disableHistory
    AACLocale.Messages.SETTINGS_DISABLE_SAVE_HEADER=AAC.TradingTranslations.disableHistory
    AACLocale.Messages.SETTINGS_DISABLE_SAVE_TEXT=""
end
AAC.FrontendLocale.Apply()
