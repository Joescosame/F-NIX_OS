#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-or-later
"""Patch limitado ao Ubiquity GTK; recusa layout desconhecido e guarda original."""
import ast
import pathlib
import sys
import textwrap

CALLBACK = '''
def geoname_cb(self, session, result, user_data=None):
    # FENIX_GEOIP_GUARD_V1: erro de rede não impede seleção local do fuso.
    message, text, model = user_data
    if self.geoname_timeout_id is not None:
        GLib.source_remove(self.geoname_timeout_id)
        self.geoname_timeout_id = None
    self.geoname_add_tzdb(text, model)
    try:
        payload = session.send_and_read_finish(result)
        if payload is not None and message.get_status() == Soup.Status.OK:
            rows = json.loads(payload.get_data().decode('utf-8'))
            if not isinstance(rows, list):
                raise ValueError('GeoIP deve retornar lista')
            parsed = []
            for row in rows:
                parsed.append([row['name'], row['admin1'], row['country'],
                               row['latitude'], row['longitude']])
            for row in parsed:
                model.append(row)
            if parsed:
                self.geoname_cache[text] = model
    except (GLib.Error, ValueError, TypeError, KeyError, UnicodeError):
        syslog.syslog('FENIX: GeoIP indisponível; seleção local preservada.')
    if self.city_entry.get_text() == text:
        self.city_entry.get_completion().set_model(model)
'''

def patch(source):
    if 'FENIX_GEOIP_GUARD_V1' in source:
        ast.parse(source)
        return source
    tree = ast.parse(source)
    cls = next(n for n in tree.body if isinstance(n, ast.ClassDef) and n.name == 'PageGtk')
    callback = next(n for n in cls.body if isinstance(n, ast.FunctionDef) and n.name == 'geoname_cb')
    original = ast.get_source_segment(source, callback)
    if '_bytes.get_data()' not in original or 'send_and_read_finish' not in original:
        raise ValueError('Callback upstream mudou: revisar patch')
    lines = source.splitlines(keepends=True)
    lines[callback.lineno-1:callback.end_lineno] = [textwrap.indent(CALLBACK.strip(), '    ')+'\n']
    result = ''.join(lines)
    anchor = '            if self.geoname_session is None:\n'
    if result.count(anchor) != 1:
        raise ValueError('Entrada de GeoIP upstream mudou')
    result = result.replace(anchor, '''            if not self.online or os.environ.get('FENIX_INSTALL_OFFLINE') == '1':
                self.geoname_add_tzdb(text, model)
                self.city_entry.get_completion().set_model(model)
                return
''' + anchor)
    condition = '        if not self.ui.online:\n'
    if result.count(condition) != 1:
        raise ValueError('Preseed upstream mudou')
    result = result.replace(condition, "        if not self.ui.online or os.environ.get('FENIX_INSTALL_OFFLINE') == '1':\n")
    ast.parse(result)
    return result

if __name__ == '__main__':
    path = pathlib.Path(sys.argv[1])
    original = path.read_text(encoding='utf-8')
    result = patch(original)
    backup = path.with_suffix(path.suffix+'.fenix-original')
    if not backup.exists():
        backup.write_text(original, encoding='utf-8')
    path.write_text(result, encoding='utf-8', newline='\n')
    print('Patch aplicado; instalação integral ainda precisa de QA.')
