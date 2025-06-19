/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_1518973680")

  // add field
  collection.fields.addAt(3, new Field({
    "cascadeDelete": false,
    "collectionId": "pbc_4185980916",
    "hidden": false,
    "id": "relation3080129784",
    "maxSelect": 1,
    "minSelect": 0,
    "name": "artist_id",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "relation"
  }))

  return app.save(collection)
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_1518973680")

  // remove field
  collection.fields.removeById("relation3080129784")

  return app.save(collection)
})
