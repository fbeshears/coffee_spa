// spa_user_update.js


var conn = new Mongo();

var db = conn.getDB('spa');

db.user.update(
  {"_id" : ObjectId("532d1bdaa0887aa5e8c11dea") },
  {$set : {"name" : "Josh Powell"} }
);

db.user.remove(
  {"_id" : ObjectId("532d1bdaa0887aa5e8c11dec") }
);