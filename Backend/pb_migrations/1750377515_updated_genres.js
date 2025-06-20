/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_2683869272")

  // update field
  collection.fields.addAt(3, new Field({
    "hidden": false,
    "id": "file1704208859",
    "maxSelect": 1,
    "maxSize": 0,
    "mimeTypes": [],
    "name": "image",
    "presentable": false,
    "protected": false,
    "required": false,
    "system": false,
    "thumbs": [],
    "type": "file"
  }))

  return app.save(collection)
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_2683869272")

  // update field
  collection.fields.addAt(3, new Field({
    "hidden": false,
    "id": "file1704208859",
    "maxSelect": 1,
    "maxSize": 0,
    "mimeTypes": [],
    "name": "icon",
    "presentable": false,
    "protected": false,
    "required": false,
    "system": false,
    "thumbs": [],
    "type": "file"
  }))

  return app.save(collection)
})
