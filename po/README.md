# Translating AppManager

## How to Contribute Translations

1. **Edit an existing translation**: Find the relevant `.po` file for your language and submit a PR with your improvements.
2. **Add a new language**: Use `app-manager.pot` as a template, save it as `po/xx.po` (where `xx` is your language code), translate the strings, and create a PR.

## Translation Status

| Language | Code | Status |
| -------- | ---- | ------ |
| Arabic | ar | 100% |
| German | de | 100% |
| Greek | el | 100% |
| Spanish | es | 100% |
| Estonian | et | 100% |
| Finnish | fi | 100% |
| French | fr | 100% |
| Italian | it | 100% |
| Japanese | ja | 100% |
| Kazakh | kk | 100% |
| Korean | ko | 100% |
| Lithuanian | lt | 100% |
| Latvian | lv | 100% |
| Norwegian Bokmål | nb | 100% |
| Dutch | nl | 100% |
| Polish | pl | 100% |
| Portuguese (Brazil) | pt_BR | 100% |
| Swedish | sv | 100% |
| Ukrainian | uk | 100% |
| Vietnamese | vi | 100% |
| Chinese (Simplified) | zh_CN | 100% |

## Note

> Some translations are machine-generated and may contain mistakes. Native speakers are welcome to review and improve them!

## Testing Translations Locally

After building with meson, translations are compiled automatically. To test:

```bash
meson setup build --prefix=$HOME/.local
meson compile -C build
meson install -C build
```

Then run the app with a specific locale:

```bash
LANGUAGE=de app-manager
```

## Further Reading

- [GNU gettext Manual](https://www.gnu.org/software/gettext/manual/gettext.html)
- [Vala i18n documentation](https://wiki.gnome.org/Projects/Vala/TranslationSample)
