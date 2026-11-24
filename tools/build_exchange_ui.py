"""Generate the classic Exchange XML; existing Lua transaction flow stays intact."""
from pathlib import Path
from xml.sax.saxutils import escape
from xml.dom import minidom

def anchor(x,y):
    return f'<Anchors><Anchor point="TOPLEFT"><Offset><AbsDimension x="{x}" y="{y}"/></Offset></Anchor></Anchors>'
def size(w,h): return f'<Size><AbsDimension x="{w}" y="{h}"/></Size>'
def backdrop():
    return '''<Backdrop edgeFile="Interface\AuctionFrame\AuctionFrame-Tooltip-Border" bgFile="Interface\AuctionFrame\AuctionFrame-Tooltip-Background"><EdgeSize><AbsValue val="16"/></EdgeSize><TileSize><AbsValue val="16"/></TileSize><BackgroundInsets><AbsInset left="8" right="8" top="8" bottom="8"/></BackgroundInsets></Backdrop>'''
def label(name,x,y,w,h=20,header=False,font=12):
    return f'<FontString name="AAC_Exchange{name}" inherits="{"GameFontYellow" if header else "GameFontHighlight"}" justifyH="LEFT" justifyV="TOP">{size(w,h)}{anchor(x,y)}<FontHeight><AbsValue val="{font}"/></FontHeight></FontString>'
def button(name,x,y,w,click,text='',h=26):
    return f'<Button name="AAC_Exchange{name}" inherits="UIPanelButtonTemplate" text="{escape(text)}">{size(w,h)}{anchor(x,y)}<Scripts><OnClick>{escape(click)}</OnClick></Scripts></Button>'
def edit(name,x,y,w):
    return f'<EditBox name="AAC_Exchange{name}" inherits="UIPanelEditBoxTemplate" numeric="true" letters="12">{size(w,24)}{anchor(x,y)}<Scripts><OnTextChanged>AAC.Exchange.Render()</OnTextChanged><OnEscapePressed>this:ClearFocus()</OnEscapePressed><OnEnterPressed>this:ClearFocus(); AAC.Exchange.Render()</OnEnterPressed></Scripts></EditBox>'
def row(name,x,y,w,side,cols,height=33):
    cells=''.join(label(name+field,cx,9,cw,20) for field,cx,cw in cols)
    line=f'<Texture file="Interface\AuctionFrame\AuctionSeparate-HorizontalLine">{size(w-8,2)}{anchor(4,height-2)}</Texture>'
    return f'''<Button name="AAC_Exchange{name}" enableMouse="true">{size(w,height)}{anchor(x,y)}<Layers><Layer>{line}{cells}</Layer></Layers><HighlightTexture file="Interface\Buttons\ListItemHighlight" alphaMode="ADD"/><Scripts><OnClick>AAC.Exchange.Select("{side}",this)</OnClick><OnEnter>GameTooltip:SetOwner(this,"ANCHOR_TOP",0,0); GameTooltip:SetText(this.details or ""); GameTooltip:Show()</OnEnter><OnLeave>GameTooltip:Hide()</OnLeave></Scripts></Button>'''
def panel(name,x,y,w,h,labels,frames):
    return f'<Frame name="AAC_Exchange{name}">{size(w,h)}{anchor(x,y)}{backdrop()}<Layers><Layer>{"".join(labels)}</Layer></Layers><Frames>{"".join(frames)}</Frames></Frame>'

columns=[('Kind',10,165),('Quantity',185,155),('Price',350,135),('Time',495,115),('Owner',620,150)]
labels=[label('Orders'+field+'Head',x+8,15,w,32,True) for field,x,w in columns]
labels.append(label('ordersPage',225,320,80))
frames=[row('orders'+str(i),8,48+(i-1)*48,782,'orders',columns,44) for i in range(1,6)]
frames += [button('ordersPrev',15,315,70,'AAC.Exchange.Page("orders",-1)','<'),button('ordersNext',413,315,70,'AAC.Exchange.Page("orders",1)','>'),button('Cancel',530,315,250,'AAC.Exchange.Action("cancel")')]
orders=panel('OrdersPanel',8,48,798,350,labels,frames)
offerCards=[]
def coin(kind,x,y):
    return f'<Texture file="Interface\\MoneyFrame\\MoneyIcons">{size(20,20)}{anchor(x,y)}<TexCoords left="{kind/64}" right="{(kind+1)/64}" top="0" bottom="1"/></Texture>'
def offer_edit(name,x,y,w,side,field):
    return edit(name,x,y,w).replace('numeric="true" letters="12"','letters="18"').replace('AAC.Exchange.Render()</OnTextChanged>',f'AAC.Exchange.OfferChanged("{side}","{field}")</OnTextChanged>')
for side,x,kind in (('bid',8,0),('ask',410,1)):
    prefix='Offer'+side
    labels=[coin(kind,20,20),label(prefix+'Title',48,18,328,28,True,18),
        label(prefix+'AmountLabel',20,57,354,22),coin(kind,354,82),
        label(prefix+'TotalLabel',20,111,354,22),coin(1-kind,354,136),label(prefix+'RateLabel',20,165,354,22),coin(0,354,190),
        label(prefix+'PayLabel',20,222,170,20),label(prefix+'Pay',20,244,170,24,True,14),
        label(prefix+'ReceiveLabel',210,222,170,20),label(prefix+'Receive',210,244,170,24,True,14),
        label(prefix+'Fee',20,272,354,26,False,11),label(prefix+'Note',20,299,354,14,False,10)]
    frames=[offer_edit(prefix+'Amount',20,80,324,side,'Amount'),offer_edit(prefix+'Total',20,134,324,side,'Total'),offer_edit(prefix+'Rate',20,188,324,side,'Rate'),
        button(prefix+'Create',20,315,354,f'AAC.Exchange.CreateOffer("{side}")')]
    offerCards.append(panel(prefix+'Card',x,0,396,350,labels,frames))
offers='<Frame name="AAC_ExchangeOfferPanel">'+size(814,350)+anchor(0,48)+'<Frames>'+''.join(offerCards)+'</Frames></Frame>'
# Reuse classic backgrounds/buttons and the native gold/diamond sprite, with colored cards.
quick=[]
for side,x,kind in (('bid',0,0),('ask',415,1)):
 prefix='Quick'+side
 color=('0.85','0.62','0.10') if kind==0 else ('0.18','0.52','0.85')
 tint=fr'<Texture name="AAC_Exchange{prefix}Tint" file="interface\icons\rankings\BarFill">{size(395,70)}{anchor(2,2)}<Color r="{color[0]}" g="{color[1]}" b="{color[2]}" a="0.2"/></Texture>'
 icon=coin(kind,16,18).replace(size(20,20),size(28,28))
 def colored(text):
  return text.replace('</FontString>',f'<Color r="{1 if kind==0 else 0.4}" g="{0.82 if kind==0 else 0.78}" b="{0.26 if kind==0 else 1}"/></FontString>')
 labels=[tint,icon,colored(label(prefix+'Title',58,24,333,28,True,18)),label(prefix+'AmountLabel',14,64,371,22),
  label(prefix+'Rate',14,140,371,27,False,10),label(prefix+'PayLabel',14,171,371,18),label(prefix+'Pay',14,191,371,26,False,16),
  label(prefix+'ReceiveLabel',14,225,371,18),colored(label(prefix+'Receive',14,245,371,28,True,20)),
  label(prefix+'Included',14,275,371,16,False,11),label(prefix+'Note',14,294,371,26,False,10)]
 quickedit=edit(prefix+'Amount',14,86,371).replace('numeric="true" letters="12"','letters="18"').replace('AAC.Exchange.Render()</OnTextChanged>',f'AAC.Exchange.QuickAmountChanged("{side}")</OnTextChanged>')
 frames=[quickedit,button(prefix+'Trade',14,322,371,f'AAC.Exchange.Trade("{side}")')]
 labels.append(label(prefix+'Empty',20,95,270,60))
 frames.append(button(prefix+'Custom',14,294,371,f'AAC.Exchange.Custom("{side}")'))
 for i,n in enumerate((25,100,500,1000),1):
  rowname=prefix+'Row'+str(i)
  cells=[coin(kind,8,3),colored(label(rowname+'Net',32,3,174,22,True,16)),coin(1-kind,8,25).replace(size(20,20),size(14,14)),label(rowname+'Cost',32,25,174,16,False,11)]
  frames.append(panel(rowname,14,76+(i-1)*49,371,45,cells,[button(rowname+'Buy',293,9,70,f'AAC.Exchange.QuickRow("{side}",{n})',h=26)]))
 quick.append(panel(prefix+'Card',x,0,399,354,labels,frames))
home='<Frame name="AAC_ExchangeQuickPanel">'+size(814,354)+anchor(0,40)+'<Frames>'+''.join(quick)+'</Frames></Frame>'
labels=[label('EmptyBook',30,80,500,26),label('BookTitle',16,10,550,28,True,14),label('RatePriceHead',44,43,230,24,True),label('RateQuantityHead',440,43,220,24,True),label('RatePage',100,305,170,20)]
frames=[]
for i in range(1,8):
 cells=coin(0,8,8)+label('Rate'+str(i)+'Price',30,10,230,22)+label('Rate'+str(i)+'Quantity',430,10,220,22)
 frames.append(f'<Button name="AAC_ExchangeRate{i}" inherits="AAC_TemplateListItem" enableMouse="true">{size(792,32)}{anchor(10,70+(i-1)*32)}<Layers><Layer>{cells}</Layer></Layers><Scripts><OnClick>AAC.Exchange.SelectRate(this)</OnClick><OnMouseWheel>AAC.Exchange.Scroll(-delta)</OnMouseWheel></Scripts></Button>')
frames += [button('RatePrev',15,300,65,'AAC.Exchange.Scroll(-7)','<'),button('RateNext',734,300,65,'AAC.Exchange.Scroll(7)','>')]
book=panel('RateList',0,40,814,330,labels,frames).replace('<Frame name="AAC_ExchangeRateList">','<Frame name="AAC_ExchangeRateList" enableMouse="true">').replace('</Frames></Frame>','</Frames><Scripts><OnMouseWheel>AAC.Exchange.Scroll(-delta)</OnMouseWheel></Scripts></Frame>')
market='<Frame name="AAC_ExchangeMarketPanel">'+size(814,370)+anchor(0,40)+'<Frames>'+book+button('Directionbid',0,4,185,'AAC.Exchange.SetDirection("bid")')+button('Directionask',191,4,185,'AAC.Exchange.SetDirection("ask")')+'</Frames></Frame>'
nav=[button('New',600,6,206,'AAC.Exchange.Manage()'),button('Back',600,6,206,'AAC.Exchange.SetOrders()'),button('Books',600,6,206,'AAC.Exchange.Books()'),button('Home',600,6,206,'AAC.Exchange.Home()')]
xml='<Ui xmlns="https://chroniclesofarcadia.com/">'
xml+='<Frame name="AAC_ExchangeFrame" parent="AAC_AuctionFrame" hidden="true" enableMouse="true">'+size(814,432)+anchor(16,40)+'<Layers><Layer>'+label('Heading',12,10,400,22,True,14)+label('Status',12,412,790,18,False,11)+'</Layer></Layers><Frames>'+home+market+offers+orders+''.join(nav)+'''</Frames><Scripts><OnShow>AAC.Exchange.Show()</OnShow><OnHide>AAC.Exchange.Dismiss(); StaticPopup_Hide("AAC_EXCHANGE_CONFIRM")</OnHide><OnLoad>this:RegisterEvent("AUCTION_EXCHANGE_UPDATE"); this:RegisterEvent("AUCTION_EXCHANGE_RESULT"); this:RegisterEvent("PLAYER_MONEY"); this:RegisterEvent("AUCTION_CLOSE")</OnLoad><OnEvent>AAC.Exchange.Event(event,arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9)</OnEvent></Scripts></Frame>'''
xml+='<Frame name="AAC_ExchangeNavigation" parent="AAC_AuctionFrame" hidden="true">'+size(450,28)+anchor(24,46)+'<Frames>'+button('NavAuctions',0,0,150,'AAC.Exchange.Legacy()')+button('NavExchange',156,0,220,'AAC.Exchange.OpenFromNavigation()')+'</Frames></Frame></Ui>'
Path('addon/ArcadiaAuctionClassic/Xml/aac_exchange.xml').write_text(minidom.parseString(xml).toprettyxml(indent='  '),encoding='utf-8')
