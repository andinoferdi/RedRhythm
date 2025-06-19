/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_1518973680")

  // update collection data
  unmarshal({
    "name": "shorts"
  }, collection)

  return app.save(collection)
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_1518973680")

  // update collection data
  unmarshal({
    "name": "mix"
  }, collection)

  return app.save(collection)
})
