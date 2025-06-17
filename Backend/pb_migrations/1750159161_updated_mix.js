/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_1518973680")

  // add field
  collection.fields.addAt(2, new Field({
    "hidden": false,
    "id": "file2093472300",
    "maxSelect": 1,
    "maxSize": 0,
    "mimeTypes": [],
    "name": "video",
    "presentable": false,
    "protected": false,
    "required": false,
    "system": false,
    "thumbs": [],
    "type": "file"
  }))

  return app.save(collection)
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_1518973680")

  // remove field
  collection.fields.removeById("file2093472300")

  return app.save(collection)
})
