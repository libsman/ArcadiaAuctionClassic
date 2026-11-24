"""Generate trading helpers using the existing native Classic templates."""
from pathlib import Path
from xml.sax.saxutils import escape
from xml.dom import minidom

def size(w,h): return f'<Size><AbsDimension x="{w}" y="{h}"/></Size>'
def anchor(x,y): return f'<Anchors><Anchor point="TOPLEFT"><Offset><AbsDimension x="{x}" y="{y}"/></Offset></Anchor></Anchors>'
def label(n,x,y,w,h=20,yellow=False):
 return f'<FontString name="AAC_Trading{n}" inherits="{ "GameFontNormal" if yellow else "GameFontHighlight"}" justifyH="LEFT" justifyV="MIDDLE">{size(w,h)}{anchor(x,y)}</FontString>'
def button(n,x,y,w,action,text='',parent=''):
 return f'<Button name="AAC_Trading{n}" inherits="UIPanelButtonTemplate" text="{escape(text)}"'+(f' parent="{parent}"' if parent else '')+f'>{size(w,24)}{anchor(x,y)}<Scripts><OnClick>{escape(action)}</OnClick></Scripts></Button>'
def edit(n,x,y,w):
 return f'<EditBox name="AAC_Trading{n}" inherits="UIPanelEditBoxTemplate" numeric="true" letters="12">{size(w,24)}{anchor(x,y)}<Scripts><OnTextChanged>AAC.TradingUI.PriceChanged("{n}")</OnTextChanged><OnEditFocusLost>AAC.TradingUI.SettleTotal()</OnEditFocusLost><OnEnterPressed>this:ClearFocus();AAC.TradingUI.SettleTotal()</OnEnterPressed><OnEscapePressed>this:ClearFocus()</OnEscapePressed></Scripts></EditBox>'
def box(): return r'<Backdrop edgeFile="Interface\AuctionFrame\AuctionFrame-Tooltip-Border" bgFile="Interface\AuctionFrame\AuctionFrame-Tooltip-Background"><EdgeSize><AbsValue val="16"/></EdgeSize><TileSize><AbsValue val="16"/></TileSize><BackgroundInsets><AbsInset left="8" right="8" top="8" bottom="8"/></BackgroundInsets></Backdrop>'
def frame(n,x,y,w,h,labels,frames): return f'<Frame name="AAC_Trading{n}">{size(w,h)}{anchor(x,y)}<Layers><Layer>{labels}</Layer></Layers><Frames>{frames}</Frames></Frame>'

def line(x,y,w,h,vertical=False):
 file='AuctionSeparate-VerticalLine' if vertical else 'AuctionSeparate-HorizontalLine'
 return fr'<Texture file="Interface\AuctionFrame\{file}">{size(w,h)}{anchor(x,y)}</Texture>'
def check(n,x,y,w,mode):
 return f'<CheckButton name="AAC_Trading{n}" inherits="AAC_SettingsCheckButtonTemplate">{size(20,20)}{anchor(x,y)}<Layers><Layer>{label(n+"Caption",22,0,w,20)}</Layer></Layers><Scripts><OnClick>AAC.TradingUI.Open("{mode}")</OnClick></Scripts></CheckButton>'
rows=''
for i in range(1,8):
 n='Row'+str(i)
 icon=f'<Texture name="AAC_Trading{n}Icon">{size(32,32)}{anchor(5,4)}</Texture>'
 cells=icon+label(n+'Name',46,0,256,40,True)+label(n+'Quantity',310,0,80,40)+label(n+'Price',408,0,118,40).replace('justifyH="LEFT"','justifyH="RIGHT"')+label(n+'Info',562,0,210,40)
 cells+=fr'<Texture name="AAC_Trading{n}PriceIcon" file="Interface\MoneyFrame\MoneyIcons">{size(14,14)}{anchor(536,13)}</Texture>'
 cells+=line(300,3,5,34,True)+line(398,3,5,34,True)+line(552,3,5,34,True)
 rows+=f'<Button name="AAC_Trading{n}" inherits="AAC_TemplateListItem">{size(780,40)}{anchor(10,26+(i-1)*40)}<Layers><Layer>{cells}</Layer></Layers><Scripts><OnClick>AAC.TradingUI.Select(this.row)</OnClick><OnEnter>AAC.TradingUI.Tooltip(this.row,this)</OnEnter><OnLeave>GameTooltip:Hide()</OnLeave></Scripts></Button>'
headers=label('ItemHead',56,4,256,20,True)+label('QuantityHead',320,4,80,20,True)+label('PriceHead',418,4,142,20,True)+label('InfoHead',572,4,210,20,True)+line(8,24,784,4)
listing=frame('List',0,64,800,310,headers,rows).replace('<Layers>',box()+'<Layers>',1)
# The same horizontal item / amount / price / confirmation arrangement as My Offers.
formlabels=label('ItemLabel',12,4,212,20,True)+label('QuantityLabel',244,4,126,20,True)+label('PriceLabel',392,4,180,20,True)+label('TotalLabel',596,4,190,20,True)
formlabels+=line(8,26,784,4)+line(228,3,5,112,True)+line(376,3,5,112,True)+line(580,3,5,112,True)
formlabels+=label('Totals',596,32,190,52)+label('OrderTotalLabel',392,57,176,18,True)
icon=f'<Texture name="AAC_TradingItemIcon">{size(24,24)}{anchor(8,12)}</Texture>'
slot=f'<Button name="AAC_TradingItemSlot" enableMouse="true" inherits="AAC_SellItemButtonTemplate">{size(212,48)}{anchor(10,32)}{box()}<Layers><Layer>{icon}{label("ItemName",40,4,164,40,True)}</Layer></Layers><Scripts><OnClick>AAC.TradingUI.Drop()</OnClick><OnReceiveDrag>AAC.TradingUI.Drop()</OnReceiveDrag><OnEnter>AAC.TradingUI.Tooltip({{link=AAC.TradingUI.itemLink}},this)</OnEnter><OnLeave>GameTooltip:Hide()</OnLeave></Scripts></Button>'
# Do not inherit the sell item's staging scripts: this slot selects an item only.
slot=slot.replace('inherits="AAC_SellItemButtonTemplate"','')
radios=''
for name,x,mode,kind in [('Gold',244,'copper',0),('Diamond',302,'account',1)]:
 icon=fr'<Texture file="Interface\MoneyFrame\MoneyIcons">{size(16,16)}{anchor(20,0)}<TexCoords left="{kind/64}" right="{(kind+1)/64}" top="0" bottom="1"/></Texture>'
 radios+=f'<CheckButton name="AAC_Trading{name}" inherits="MoneyModeRadioButtonTemplate">{size(16,16)}{anchor(x,77)}<Layers><Layer>{icon}</Layer></Layers><Scripts><OnClick>AAC.TradingUI.Currency("{mode}")</OnClick></Scripts></CheckButton>'
form=frame('Form',0,88,800,124,formlabels,slot+edit('Quantity',244,40,120)+edit('Price',392,30,176)+edit('OrderTotal',392,78,176)+radios+button('FormAction',596,88,190,'AAC.TradingUI.Action()'))
form=form.replace('<Frame name="AAC_TradingForm">','<Frame name="AAC_TradingForm" enableMouse="true">').replace('<Layers>',box()+'<Layers>',1).replace('</Frames></Frame>','</Frames><Scripts><OnReceiveDrag>AAC.TradingUI.Drop()</OnReceiveDrag></Scripts></Frame>')
buttons=button('Back',682,0,118,'AAC.TradingUI.Back()')
buttons+=check('All',8,34,170,'all')+check('Buyers',210,34,200,'sellable')+check('Mine',440,34,220,'mine')
buttons+=button('New',210,406,250,'AAC.TradingUI.NewOrder()')
buttons+=button('Prev',0,406,45,'AAC.TradingUI.Page(-1)','<')+button('Next',122,406,45,'AAC.TradingUI.Page(1)','>')+button('Action',550,406,250,'AAC.TradingUI.ListAction()')
buttons+=button('Reload',520,0,150,'AAC.TradingUI.Refresh()')
picker=label('FindLabel',12,30,650,20,True)+label('FindStatus',24,250,730,28)
findedit=f'<EditBox name="AAC_TradingFindText" inherits="UIPanelEditBoxTemplate" letters="100">{size(558,24)}{anchor(12,52)}<Scripts><OnTextChanged>AAC.TradingUI.FindChanged()</OnTextChanged><OnEscapePressed>this:ClearFocus()</OnEscapePressed></Scripts></EditBox>'
findrows=''
for i in range(1,6):
 findrows+=f'<Button name="AAC_TradingPick{i}" inherits="AAC_TemplateListItem" enableMouse="true" hidden="true">{size(752,28)}{anchor(16,250+(i-1)*28)}<Layers><Layer><Texture name="AAC_TradingPick{i}Icon">{size(24,24)}{anchor(8,2)}</Texture>{label("Pick"+str(i)+"Name",44,0,700,28,True)}</Layer></Layers><Scripts><OnClick>AAC.TradingUI.PickFound({i})</OnClick><OnEnter>AAC.TradingUI.Tooltip(this.row,this)</OnEnter><OnLeave>GameTooltip:Hide()</OnLeave></Scripts></Button>'
findframe=frame('Finder',0,0,800,414,picker,findedit+findrows)
labels=label('Title',8,0,500,24,True)+label('Hint',8,376,528,26)+label('Detail',8,376,784,26)+label('Page',50,406,68,24)+label('FormHelp',12,85,212,36)+label('OwnHeading',12,228,750,20,True)
panel=f'<Frame name="AAC_TradingPanel" parent="AAC_AuctionFrame" hidden="true" enableMouse="true">{size(800,434)}{anchor(21,40)}<Layers><Layer>{labels}</Layer></Layers><Frames>{buttons}{listing}{form}{findframe}</Frames><Scripts><OnUpdate>AAC.TradingUI.FindTick()</OnUpdate></Scripts></Frame>'
entries=button('SellPrices',424,40,126,'AAC.TradingUI.Open("prices")',parent='AAC_SellFrame')+button('SellRecent',554,40,126,'AAC.TradingUI.Open("recent")',parent='AAC_SellFrame')
nav=frame('PurchasesNav',21,40,400,24,'',button('Bids',0,0,150,'AAC.TradingUI.ShowBids()')+button('Orders',158,0,180,'AAC.TradingUI.ShowOrders()')).replace('<Frame name="AAC_TradingPurchasesNav">','<Frame name="AAC_TradingPurchasesNav" parent="AAC_AuctionFrame" hidden="true">')
xml='<Ui xmlns="https://chroniclesofarcadia.com/">'+panel+entries+nav+'</Ui>'
out=Path(__file__).resolve().parents[1]/'addon/ArcadiaAuctionClassic/Xml/aac_trading.xml'
out.write_bytes(minidom.parseString(xml).toprettyxml(indent='  ',encoding='utf-8').replace(b'\n',b'\r\n'))
print(out)
