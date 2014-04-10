//spa_db_init.js

// can load within mongo shell with
// load("spa_db_init.js")

// can run with:
// c:> mongo spa_db_init.js

var conn = new Mongo();

// assumes that spa db already exists
var db = conn.getDB('spa');

// uncomment if user does not exit
// db.createCollection('user');


var rec,
    spa_db = [
  {
    "name": "Mike Mikowski",
    "is_online": false,
    "css_map": {
      "top": 100,
      "left": 120,
      "background-color": "rgb(136, 255, 136)"
    }
  },
  {
    "name": "Mr. Josh c. Powell, humble humanitarian",
    "is_online": false,
    "css_map": {
      "top": 150,
      "left": 120,
      "background-color": "rgb(136, 255, 136)"
    }
  },
  {
    "name": "Fred Beshears",
    "is_online": false,
    "css_map": {
      "top": 50,
      "left": 120,
      "background-color": "rgb(136, 255, 136)"
    },

  },
  {
    "name": "Hapless interloper",
    "is_online": false,
    "css_map": {
      "top": 100,
      "left": 120,
      "background-color": "rgb(136, 255, 136)"
    }
  }  
];


for(rec in spa_db) {
  //console.log('inserting: ' + spa_db[rec].name);
  db.user.insert(spa_db[rec]);
}