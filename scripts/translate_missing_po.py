#!/usr/bin/env python3
import re
import time
from pathlib import Path

import polib
from deep_translator import GoogleTranslator

PO_DIR = Path('po')
LANG_MAP = {
    'pt_BR': 'pt',
    'zh_CN': 'zh-CN',
    'nb': 'no',
}

PRINTF_RE = re.compile(r'%(?:\d+\$)?[+#0\- ]*(?:\d+|\*)?(?:\.(?:\d+|\*))?(?:hh|h|l|ll|L|z|j|t)?[diuoxXfFeEgGaAcCsSpn%]')
XML_TAG_RE = re.compile(r'</?[^>]+?>')


def protect(text: str):
    tokens = []

    def repl(match):
        idx = len(tokens)
        tokens.append(match.group(0))
        return f'__TOK{idx}__'

    text = PRINTF_RE.sub(repl, text)
    text = XML_TAG_RE.sub(repl, text)
    return text, tokens


def unprotect(text: str, tokens):
    for i, token in enumerate(tokens):
        text = text.replace(f'__TOK{i}__', token)
    return text


def needs_translation(entry):
    if entry.obsolete:
        return False
    if 'fuzzy' in entry.flags:
        return True
    if entry.msgid_plural:
        if not entry.msgstr_plural:
            return True
        return any(not value.strip() for value in entry.msgstr_plural.values())
    return not entry.msgstr.strip()


def translate_po(po_path: Path):
    code = po_path.stem
    target = LANG_MAP.get(code, code)
    po = polib.pofile(str(po_path))
    translator = GoogleTranslator(source='en', target=target)

    cache = {}
    updated = 0
    failed = 0

    def tr(text: str):
        key = (target, text)
        if key in cache:
            return cache[key]
        protected, tokens = protect(text)
        translated = translator.translate(protected)
        translated = unprotect(translated, tokens)
        cache[key] = translated
        time.sleep(0.1)
        return translated

    for entry in po:
        if not needs_translation(entry):
            continue
        try:
            if entry.msgid_plural:
                singular = tr(entry.msgid)
                plural = tr(entry.msgid_plural)
                indices = sorted(entry.msgstr_plural.keys()) if entry.msgstr_plural else [0, 1]
                if not indices:
                    indices = [0, 1]
                entry.msgstr_plural[indices[0]] = singular
                for idx in indices[1:]:
                    entry.msgstr_plural[idx] = plural
            else:
                entry.msgstr = tr(entry.msgid)

            if 'fuzzy' in entry.flags:
                entry.flags = [flag for flag in entry.flags if flag != 'fuzzy']
            updated += 1
        except Exception:
            failed += 1

    po.save(str(po_path))
    return code, updated, failed


def main():
    files = sorted(PO_DIR.glob('*.po'))
    for po_file in files:
        code, updated, failed = translate_po(po_file)
        print(f'{code}: updated={updated} failed={failed}')


if __name__ == '__main__':
    main()
