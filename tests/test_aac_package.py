from pathlib import Path
import re
import unittest
import xml.etree.ElementTree as ET
from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1] / 'addon/ArcadiaAuctionClassic'

class ClassicPackageTests(unittest.TestCase):
    def test_offer_currency_controls_use_native_size_and_share_input_parent(self):
        root=ET.parse(ROOT/'Xml/aac_exchange.xml').getroot()
        ns={'u':'https://chroniclesofarcadia.com/'}
        nodes={e.get('name'):e for e in root.iter() if e.get('name')}
        for side in ('bid','ask'):
            card=nodes['AAC_ExchangeOffer'+side+'Card']
            children={e.get('name'):e for e in card.find('u:Frames',ns)}
            for currency in ('bid','ask'):
                name='AAC_ExchangeOffer'+side+'Choose'+currency
                self.assertIn(name,children,'Currency selectors must stay inside the input card when focus raises it')
                radio=children[name]
                self.assertEqual(radio.get('inherits'),'MoneyModeRadioButtonTemplate')
                icon=radio.find('u:Layers/u:Layer/u:Texture',ns)
                self.assertEqual(icon.find('u:Size/u:AbsDimension',ns).attrib,{'x':'16','y':'16'})
                self.assertEqual(icon.find('u:Anchors/u:Anchor/u:Offset/u:AbsDimension',ns).attrib,{'x':'16','y':'0'})
                text=radio.find('u:Layers/u:Layer/u:FontString',ns)
                self.assertEqual(text.find('u:Anchors/u:Anchor/u:Offset/u:AbsDimension',ns).get('x'),'40')

    def test_sell_modes_share_page_without_hiding_mode_controls(self):
        root=ET.parse(ROOT/'Xml/aac_sell.xml').getroot()
        ns={'u':'https://chroniclesofarcadia.com/'}
        nodes={e.get('name'):e for e in root.iter() if e.get('name')}
        direct=nodes['AAC_SellFrame'].find('u:Frames',ns)
        names={e.get('name') for e in direct}
        self.assertTrue({'AAC_SellAuctionContent','AAC_SellMoneyAuction','AAC_SellExchange'} <= names)
        inner={e.get('name') for e in nodes['AAC_SellAuctionContent'].iter()}
        self.assertTrue({'AAC_SellItemFrame','AAC_SellList','AAC_SellNumber','AAC_SellEditBox'} <= inner)
        exchange=ET.parse(ROOT/'Xml/aac_exchange.xml').getroot()
        self.assertNotIn('AAC_ExchangeNavExchange',{e.get('name') for e in exchange.iter()})
        frame=next(e for e in exchange.iter() if e.get('name')=='AAC_ExchangeFrame')
        self.assertEqual(frame.get('enableMouse'),'false','Transparent header must not eat clicks on mode checkboxes')

    def test_exchange_inputs_format_on_focus_lost(self):
        root=ET.parse(ROOT/'Xml/aac_exchange.xml').getroot()
        ns={'u':'https://chroniclesofarcadia.com/'}
        inputs=[n for n in root.iter() if n.tag.endswith('EditBox') and n.attrib.get('name','').startswith(('AAC_ExchangeOffer','AAC_ExchangeQuick'))]
        self.assertEqual(len(inputs),8)
        for node in inputs:
            changed=node.find('u:Scripts/u:OnTextChanged',ns).text
            lost=node.find('u:Scripts/u:OnEditFocusLost',ns).text
            self.assertNotIn(',true)',changed)
            self.assertIn(',true)',lost)

    def test_lua_files_compile_as_exact_client_bytes(self):
        lua = LuaRuntime(encoding=None)
        compile_bytes = lua.eval(b'function(source) local f,e=loadstring(source); return f~=nil,e end')
        for file in ROOT.rglob('*.lua'):
            with self.subTest(file=file.name):
                ok, error = compile_bytes(file.read_bytes())
                self.assertTrue(ok, str(error))

    def test_approved_native_quick_layout(self):
        root = ET.parse(ROOT/'Xml/aac_exchange.xml').getroot()
        nodes = {n.attrib.get('name'):n for n in root.iter() if n.attrib.get('name')}
        ns={'u':'https://chroniclesofarcadia.com/'}
        for side in ('bid','ask'):
            prefix='AAC_ExchangeQuick'+side
            card=nodes[prefix+'Card']
            self.assertNotIn('edgeFile',card.find('u:Backdrop',ns).attrib)
            self.assertEqual(card.find('u:Size/u:AbsDimension',ns).attrib,{'x':'399','y':'362'})
            icons=[n.attrib.get('file','') for n in card.iter() if n.tag.endswith('Texture')]
            self.assertIn('Interface/Icons/coin_03.dds',icons)
            self.assertIn('Interface/Icons/crystal_01.dds',icons)
            for i,amount in enumerate((1000,500,100,25),1):
                row=nodes[prefix+'Row'+str(i)]
                self.assertIsNone(row.find('u:Backdrop',ns))
                self.assertEqual(row.find('u:Anchors/u:Anchor/u:Offset/u:AbsDimension',ns).attrib,{'x':'18','y':str(91+(i-1)*46)})
                button=nodes[prefix+'Row'+str(i)+'Buy']
                self.assertEqual(button.attrib['inherits'],'UIPanelButtonTemplate')
                self.assertIn(str(amount),button.find('u:Scripts/u:OnClick',ns).text)

    def test_toc_and_xml_scripts_compile_without_duplicate_global_frames(self):
        lua = LuaRuntime()
        names = set()
        for line in (ROOT/'ArcadiaAuctionClassic.toc').read_text().splitlines():
            if not line or line.startswith('#') or '$language' in line:
                continue
            file = ROOT / line.replace('\\','/')
            self.assertTrue(file.is_file(), str(file))
            if file.suffix == '.lua':
                lua.execute('assert(loadstring(...))', file.read_text(encoding='utf-8-sig'))
            elif file.suffix == '.xml':
                tree = ET.parse(file)
                for node in tree.iter():
                    name = node.attrib.get('name','')
                    if name and not name.startswith('$'):
                        self.assertTrue(name.startswith('AAC'), (file,name))
                        self.assertNotIn(name,names,(file,name))
                        names.add(name)
                    if node.tag.rsplit('}',1)[-1] == 'Scripts':
                        for script in node:
                            lua.execute('assert(loadstring(...))', script.text or '')

    def test_every_language_has_english_fallback_and_private_translations(self):
        locales=list((ROOT/'Locales').glob('*.lua'))
        self.assertEqual(len(locales),11)
        for locale in locales:
            with self.subTest(locale=locale.name):
                lua=LuaRuntime()
                lua.execute('AAH_COMMAND_ZERO="native-zero"; function TEXT(k) return k end')
                lua.execute((ROOT/'Locales/EN.lua').read_text(encoding='utf-8-sig'))
                lua.execute(locale.read_text(encoding='utf-8-sig'))
                lua.execute((ROOT/'Lua/locale.lua').read_text(encoding='utf-8-sig'))
                lua.execute('''
                    for k,v in pairs(ENAACLocale.Messages) do assert(AACLocale.Messages[k]~=nil,k) end
                    for k,v in pairs(ENAACLocale.Commands) do assert(AACLocale.Commands[k]~=nil,k) end
                    assert(AAH_COMMAND_ZERO=="native-zero")
                    assert(AAC_COMMAND_ZERO=="native-zero")
                    assert(type(AAC_NATIVE_BUTTON)=="string")
                ''')
                if locale.stem == 'DE':
                    self.assertEqual(lua.globals().AAC_TAB_OVERVIEW, 'Übersicht')
                    self.assertEqual(lua.globals().AAC_NATIVE_BUTTON, 'Original-AH')

    def test_modules_load_in_toc_order_under_current_engine_constants(self):
        lua=LuaRuntime()
        alltext='\n'.join(p.read_text(encoding='utf-8-sig') for p in ROOT.rglob('*.lua'))
        # Engine translated constants only; do not manufacture addon variables or functions.
        for key in set(re.findall(r'\b[A-Z][A-Z_0-9]+\b',alltext)):
            if not key.startswith(('AAC','ENAAC')):
                lua.globals()[key]=key
        lua.execute('''
            StaticPopupDialogs={}; SlashCmdList={};
            function TEXT(k) return _G[k] or k end
            function GetLanguage() return "ENEU" end
            function GetReplaceSystemKeyword(k) return k end
            function IsFunctionEnable() return true end
            AAH={sentinel=true}; AuctionHub={sentinel=true}
        ''')
        for line in (ROOT/'ArcadiaAuctionClassic.toc').read_text().splitlines():
            if not line or line.startswith('#') or '$language' in line or not line.endswith('.lua'):
                continue
            lua.execute((ROOT/line.replace('\\','/')).read_text(encoding='utf-8-sig'))
        lua.execute('assert(AAH.sentinel and AuctionHub.sentinel); assert(type(AAC.Session.Command)=="function")')

if __name__ == '__main__': unittest.main()
