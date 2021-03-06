emcc \
  -Os \
  sqlite3.c \
  shell.c \
  extension-functions.c \
  -o sqlite3.js \
  -ldl -lpthread -lm \
  -DSQLITE_OMIT_POPEN \
  -DSQLITE_THREADSAFE=0 \
  -DSQLITE_ENABLE_JSON1 \
  -DSQLITE_ENABLE_RTREE \
  -DSQLITE_ENABLE_GEOPOLY \
  -DSQLITE_CORE \
  -DEMCC \
  -s EXPORTED_FUNCTIONS='["_main"]' \
  -s AGGRESSIVE_VARIABLE_ELIMINATION=1 \
  -s ASSERTIONS=1