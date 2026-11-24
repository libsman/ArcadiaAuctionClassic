from pathlib import Path
import re
import unittest
import xml.etree.ElementTree as ET
from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1] / 'addon/ArcadiaAuctionClassic'

class ClassicPackageTests(unittest.TestCase):
    def test_exchange_tints_preserve_native_texture_path(self):
        root = ET.parse(ROOT/'Xml/aac_exchange.xml').getroot()
        tints = [n for n in root.iter() if n.attrib.get('name', '').endswith('Tint')]
        self.assertEqual(len(tints), 2)
        for tint in tints:
            self.assertEqual(tint.attrib['file'], r'interface\icons\rankings\BarFill')

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
