/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_674179655")

  // remove field
  collection.fields.removeById("bool989355118")

  return app.save(collection)
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_674179655")

  // add field
  collection.fields.addAt(4, new Field({
    "hidden": false,
    "id": "bool989355118",
    "name": "completed",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "bool"
  }))

  return app.save(collection)
})
