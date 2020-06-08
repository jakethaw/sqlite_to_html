emcc -Oz sqlite3.c shell.c extension-functions.c -o sqlite3.js \
  -ldl -lpthread -lm \
  -DSQLITE_OMIT_POPEN \
  -DSQLITE_THREADSAFE=0 \
  -DSQLITE_CORE -s \
  ASSERTIONS=1 -s EXPORTED_FUNCTIONS='["_sqlite_main"]'