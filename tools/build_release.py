"""Build a deterministic installable addon ZIP; no Git history or settings."""
from pathlib import Path
import hashlib
import re
import zipfile

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'addon/ArcadiaAuctionClassic'
ALLOWED = {'.lua', '.xml', '.toc', '.md', '.json', '.txt'}

def build():
    version = re.search(r'local VERSION = "([0-9]+\.[0-9]+\.[0-9]+(?:-[a-z0-9.]+)?)"',
                        (SOURCE/'Lua/aac_main.lua').read_text(encoding='utf-8-sig')).group(1)
    files = sorted(p for p in SOURCE.rglob('*') if p.is_file())
    for p in files:
        if p.is_symlink() or p.suffix not in ALLOWED or any(part.startswith('.') for part in p.relative_to(SOURCE).parts):
            raise ValueError(f'Unexpected package file: {p.relative_to(SOURCE)}')
    out = ROOT / 'dist'
    out.mkdir(exist_ok=True)
    archive = out / f'ArcadiaAuctionClassic-{version}.zip'
    with zipfile.ZipFile(archive, 'w', compression=zipfile.ZIP_DEFLATED) as z:
        for p in files:
            info = zipfile.ZipInfo('ArcadiaAuctionClassic/' + p.relative_to(SOURCE).as_posix(), (2020,1,1,0,0,0))
            info.create_system = 3
            info.external_attr = 0o100644 << 16
            info.compress_type = zipfile.ZIP_DEFLATED
            data = p.read_bytes()
            if p.suffix in {'.lua', '.xml', '.toc'}:
                data = data.replace(b'\r\n', b'\n').replace(b'\n', b'\r\n')
            else:
                data = data.replace(b'\r\n', b'\n')
            z.writestr(info, data)
    with zipfile.ZipFile(archive) as z:
        assert z.testzip() is None
        assert 'ArcadiaAuctionClassic/ArcadiaAuctionClassic.toc' in z.namelist()
        assert 'ArcadiaAuctionClassic/LICENSE.txt' in z.namelist()
    digest = hashlib.sha256(archive.read_bytes()).hexdigest()
    archive.with_suffix('.zip.sha256').write_text(f'{digest}  {archive.name}\n', encoding='ascii')
    print(f'{archive.name}: {len(files)} files; SHA256 {digest}')
    return archive

if __name__ == '__main__':
    build()
