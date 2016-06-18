# Run Elastic Search Server on start and stop it on exit
#
child_process = require 'child_process'
path = require 'path'
fs = require 'fs'
tempfile = require 'tempfile'
unzip = require 'adm-zip'
http = require 'http'

module.exports = (opts) ->
  {port, dataDir, logsDir, installDir} = opts

  port       ?= 9211
  dataDir    ?= path.resolve(__dirname, '../var/data')
  logsDir     ?= path.resolve(__dirname, '../var/logs')
  installDir ?= path.resolve(__dirname, '../vendor/elasticsearch')
  es_command  = path.resolve __dirname, installDir, 'bin/elasticsearch'

  startElasticSearchServer = ->
    elasticsearch = child_process.spawn es_command, [
      '--http.port', port,
      '--path.data', dataDir,
      '--path.logs', logsDir
      ]

    process.on 'exit', ->
      elasticsearch.kill()

  if not fs.existsSync es_command
    url = 'http://download.elastic.co/elasticsearch/release/org/elasticsearch' +
      '/distribution/zip/elasticsearch/2.3.3/elasticsearch-2.3.3.zip'

    mkdirs = (dir) ->
      if not fs.existsSync dir
        mkdirs path.dirname dir
        fs.mkdirSync dir

    mkdirs installDir
    zipFileName = tempfile('.zip')

    console.log "#{es_command} does not exist, fetching from #{url} to #{zipFileName}"
    zipfile = fs.openSync zipFileName, 'w'

    req = http.request url, (res) ->
      console.log "res status code: #{res.statusCode}"
      res.on 'data', (chunk) ->
        fs.writeSync zipfile, chunk
      res.on 'end', ->
        fs.closeSync zipfile

        unzipper = new AdmZip zipFileName
        unzipper.extractAllTo installDir

        startElasticSearchServer()

    req.on 'error', (err) ->
      console.log "error getting elasticsearch from #{url}", err
      console.log "You can do this manually:"
      console.log "1. fetch it from #{url}"
      console.log "2. extract to #{installDir}"

  else
    startElasticSearchServer()
