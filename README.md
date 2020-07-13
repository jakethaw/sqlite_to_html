# SQLite WebAssembly Demo

www.jakethaw.com/sqlite_to_html

This project demonstrates usage of the [SQLite command line tool](https://sqlite.org/cli.html) compiled as [WebAssembly](https://en.wikipedia.org/wiki/WebAssembly) and called from javascript.

The [SQLite shell](https://sqlite.org/cli.html) tool has been compiled  with [Emscripten](https://emscripten.org/) (along with the [generate_series](https://www.sqlite.org/src/file?name=ext/misc/series.c) and [extension-functions](https://sqlite.org/contrib) extensions).