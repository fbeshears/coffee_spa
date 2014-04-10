// spa_user_print.js



var conn = new Mongo();

var db = conn.getDB('spa');

var cursor = db.user.find();

while(cursor.hasNext()) {
  printjson( cursor.next() );
}
