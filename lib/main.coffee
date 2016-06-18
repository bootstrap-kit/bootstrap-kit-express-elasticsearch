
module.exports =
  backend: ({app}) ->
    opts = app.get('elasticsearch-opts') or {}

    unless opts.host
      require('./server')(opts)

    elasticsearch = require 'elasticsearch'

    client = require('elasticsearch').Client {
      hosts: [
        host: opts.host ? 'localhost',
        port: opts.port ? 9211,
      ]
    }
    client.api = elasticsearch

    elasticSearch = (req, res, next) ->
      req.elastic = client
      next()

    if opts.dataProvider
      # search data
      app.get  "/data/", (req, res, next, id) ->

      # get data by id
      app.get  "/data/:id", (req, res, next, id) ->

      # update data by id
      app.post "/data/:id", (req, res, next, id) ->

    app.use(elasticSearch)
