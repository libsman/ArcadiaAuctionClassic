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
    cells+=f'<Texture name="AAC_Exchange{name}Icon" file="Interface/Icons/crystal_01.dds">{size(18,18)}{anchor(8,8)}</Texture>'
    line=f'<Texture file="Interface\AuctionFrame\AuctionSeparate-HorizontalLine">{size(w-8,2)}{anchor(4,height-2)}</Texture>'
    return f'''<Button name="AAC_Exchange{name}" enableMouse="true">{size(w,height)}{anchor(x,y)}<Layers><Layer>{line}{cells}</Layer></Layers><HighlightTexture file="Interface\Buttons\ListItemHighlight" alphaMode="ADD"/><Scripts><OnClick>AAC.Exchange.Select("{side}",this)</OnClick><OnEnter>GameTooltip:SetOwner(this,"ANCHOR_TOP",0,0); GameTooltip:SetText(this.details or ""); GameTooltip:Show()</OnEnter><OnLeave>GameTooltip:Hide()</OnLeave></Scripts></Button>'''
def panel(name,x,y,w,h,labels,frames):
    return f'<Frame name="AAC_Exchange{name}">{size(w,h)}{anchor(x,y)}{backdrop()}<Layers><Layer>{"".join(labels)}</Layer></Layers><Frames>{"".join(frames)}</Frames></Frame>'

columns=[('Kind',32,145),('Quantity',185,155),('Price',350,135),('Time',495,115),('Owner',620,150)]
labels=[label('Orders'+field+'Head',x+8,15,w,32,True) for field,x,w in columns]
labels.append(label('ordersPage',96,185,75))
labels.append(label('OrdersCount',260,185,260,22,True))
frames=[row('orders'+str(i),8,40+(i-1)*34,782,'orders',columns,34) for i in range(1,5)]
frames += [button('ordersPrev',15,180,70,'AAC.Exchange.Page("orders",-1)','<'),button('ordersNext',175,180,70,'AAC.Exchange.Page("orders",1)','>'),button('Cancel',540,180,240,'AAC.Exchange.Action("cancel")')]
orders=panel('OrdersPanel',5,200,800,214,labels,frames)
offerCards=[]
def coin(kind,x,y):
    return f'<Texture file="Interface\\MoneyFrame\\MoneyIcons">{size(16,16)}{anchor(x,y)}<TexCoords left="{kind/64}" right="{(kind+1)/64}" top="0" bottom="1"/></Texture>'

def currency_choice(parent,side,y,kind):
    name=parent+'Choose'+side
    return f'<CheckButton name="AAC_Exchange{name}" inherits="MoneyModeRadioButtonTemplate">{size(16,16)}{anchor(16,y)}<Layers><Layer>'+coin(kind,16,0)+label(name+'Caption',40,0,120,20)+'</Layer></Layers><Scripts><OnClick>AAC.Exchange.OfferDirection("'+side+'")</OnClick></Scripts></CheckButton>'
def offer_edit(name,x,y,w,side,field):
    return edit(name,x,y,w).replace('numeric="true" letters="12"','letters="18"').replace('AAC.Exchange.Render()</OnTextChanged>',f'AAC.Exchange.OfferChanged("{side}","{field}")</OnTextChanged>').replace('</Scripts>',f'<OnEditFocusLost>AAC.Exchange.OfferChanged("{side}","{field}",true)</OnEditFocusLost></Scripts>')
for side,x,kind in (('bid',0,0),('ask',0,1)):
    prefix='Offer'+side
    labels=[label(prefix+'Title',16,10,175,22,True),
        label(prefix+'AmountLabel',16,88,175,20),coin(kind,167,115),
        label(prefix+'TotalLabel',212,10,245,22,True),coin(1-kind,443,39),
        label(prefix+'RateLabel',212,79,245,22,True),coin(0,443,108),
        label(prefix+'PayLabel',490,10,120,20),label(prefix+'Pay',490,31,120,23,True,12),
        label(prefix+'ReceiveLabel',620,10,166,20),label(prefix+'Receive',620,31,166,23,True,12),
        label(prefix+'Fee',490,60,294,27,False,11),label(prefix+'Note',490,88,294,30,False,10)]
    for line_x in (194,474):
        labels.append(f'<Texture file="Interface/AuctionFrame/AuctionSeparate-VerticalLine">{size(4,142)}{anchor(line_x,8)}</Texture>')
    frames=[offer_edit(prefix+'Amount',16,112,140,side,'Amount'),offer_edit(prefix+'Total',212,36,220,side,'Total'),offer_edit(prefix+'Rate',212,105,220,side,'Rate'),
        button(prefix+'Create',490,126,294,f'AAC.Exchange.CreateOffer("{side}")'),
        currency_choice(prefix,'bid',36,0),currency_choice(prefix,'ask',62,1)]
    offerCards.append(panel(prefix+'Card',x,0,800,162,labels,frames))
offers='<Frame name="AAC_ExchangeOfferPanel">'+size(800,162)+anchor(5,32)+'<Frames>'+''.join(offerCards)+'</Frames></Frame>'
# Approved native preview: flat cards, one-line prices, original item icons/buttons.
def quick_icon(kind,x,y,s,name=''):
    path='Interface/Icons/coin_03.dds' if kind==0 else 'Interface/Icons/crystal_01.dds'
    named=f' name="AAC_Exchange{name}"' if name else ''
    return f'<Texture{named} file="{path}">{size(s,s)}{anchor(x,y)}</Texture>'
def flat_panel(name,x,y,w,h,labels,frames,background=False):
    bg='<Backdrop bgFile="Interface/AuctionFrame/AuctionFrame-Tooltip-Background"><TileSize><AbsValue val="16"/></TileSize></Backdrop>' if background else ''
    return f'<Frame name="AAC_Exchange{name}">{size(w,h)}{anchor(x,y)}{bg}<Layers><Layer>{"".join(labels)}</Layer></Layers><Frames>{"".join(frames)}</Frames></Frame>'
def quick_label(*args,**kwargs):
    result=label(*args,**kwargs).replace('justifyV="TOP"','justifyV="MIDDLE"')
    if args[0].endswith(('NetHead','CostHead','Included')):
        result=result.replace('</FontString>','<Color r="0.741176" g="0.721569" b="0.658824"/></FontString>')
    return result
quick=[]
for side,x,kind in (('bid',0,0),('ask',415,1)):
 prefix='Quick'+side
 icon=quick_icon(kind,18,19,24)
 def colored(text):
  return text.replace('</FontString>',f'<Color r="{1 if kind==0 else 0.4}" g="{0.82 if kind==0 else 0.78}" b="{0.26 if kind==0 else 1}"/></FontString>')
 labels=[icon,colored(quick_label(prefix+'Title',52,21,327,26,True,18)),label(prefix+'AmountLabel',14,64,371,22),
  quick_label(prefix+'NetHead',18,65,150,18,False,11),quick_label(prefix+'CostHead',176,65,110,18,False,11).replace('justifyH="LEFT"','justifyH="RIGHT"'),
  label(prefix+'Rate',18,258,361,28,False,10),quick_label(prefix+'PayLabel',207,137,172,18,False,11),quick_label(prefix+'Pay',207,162,172,26,False,16),
  quick_label(prefix+'ReceiveLabel',18,137,172,18,False,11),colored(quick_label(prefix+'Receive',41,162,149,26,True,16)),
  quick_icon(kind,18,167,16,prefix+'ReceiveIcon'),quick_icon(1-kind,207,167,16,prefix+'PayIcon'),
  quick_label(prefix+'Included',18,287,361,18,False,11),label(prefix+'Note',18,220,361,32,False,11)]
 quickedit=edit(prefix+'Amount',18,88,361).replace('numeric="true" letters="12"','letters="18"').replace('AAC.Exchange.Render()</OnTextChanged>',f'AAC.Exchange.QuickAmountChanged("{side}")</OnTextChanged>').replace('</Scripts>',f'<OnEditFocusLost>AAC.Exchange.QuickAmountChanged("{side}",true)</OnEditFocusLost></Scripts>')
 frames=[quickedit,button(prefix+'Trade',165,315,214,f'AAC.Exchange.Trade("{side}")',h=28)]
 labels.append(label(prefix+'Empty',20,95,270,60))
 frames.append(button(prefix+'Custom',18,315,361,f'AAC.Exchange.Custom("{side}")',h=28))
 for i,n in enumerate((1000,500,100,25),1):
  rowname=prefix+'Row'+str(i)
  cells=[quick_icon(kind,0,6,16),colored(quick_label(rowname+'Net',23,3,130,22,True,16)),quick_icon(1-kind,252,8,13,rowname+'CostIcon'),quick_label(rowname+'Cost',153,5,91,20,False,12).replace('justifyH="LEFT"','justifyH="RIGHT"')]
  frames.append(flat_panel(rowname,18,91+(i-1)*46,363,40,cells,[button(rowname+'Buy',283,0,78,f'AAC.Exchange.QuickRow("{side}",{n})',h=28)]))
 quick.append(flat_panel(prefix+'Card',x,0,399,362,labels,frames,True))
home='<Frame name="AAC_ExchangeQuickPanel">'+size(814,362)+anchor(0,40)+'<Frames>'+''.join(quick)+'</Frames></Frame>'
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
xml+='<Frame name="AAC_ExchangeFrame" parent="AAC_AuctionFrame" hidden="true" enableMouse="false">'+size(814,432)+anchor(16,40)+'<Layers><Layer>'+label('Heading',12,10,400,22,True,14)+label('Status',12,412,790,18,False,11)+'</Layer></Layers><Frames>'+home+market+offers+orders+''.join(nav)+'''</Frames><Scripts><OnShow>AAC.Exchange.Show()</OnShow><OnHide>AAC.Exchange.Dismiss(); StaticPopup_Hide("AAC_EXCHANGE_CONFIRM")</OnHide><OnLoad>this:RegisterEvent("AUCTION_EXCHANGE_UPDATE"); this:RegisterEvent("AUCTION_EXCHANGE_RESULT"); this:RegisterEvent("PLAYER_MONEY"); this:RegisterEvent("AUCTION_CLOSE")</OnLoad><OnEvent>AAC.Exchange.Event(event,arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9)</OnEvent></Scripts></Frame>'''
xml+='<Frame name="AAC_ExchangeNavigation" parent="AAC_AuctionFrame" hidden="true">'+size(450,28)+anchor(24,46)+'<Frames>'+'</Frames></Frame></Ui>'
Path('addon/ArcadiaAuctionClassic/Xml/aac_exchange.xml').write_text(minidom.parseString(xml).toprettyxml(indent='  '),encoding='utf-8')
