# Run Elastic Search Server on start and stop it on exit
#
child_process = require 'child_process'
path = require 'path'
fs = require 'fs'
tempfile = require 'tempfile'
unzip = require 'adm-zip'
http = require 'http'

module.exports = (opts) ->
  {port, dataDir, logsDir, installDir, version} = opts

  port       ?= 9211
  dataDir    ?= path.resolve(__dirname, '../var/data')
  logsDir    ?= path.resolve(__dirname, '../var/logs')
  installDir ?= path.resolve(__dirname, '../vendor')
  version    ?= '2.3.3'

  es_command  = path.resolve __dirname, installDir, "elasticsearch-#{version}", 'bin/elasticsearch'

  startElasticSearchServer = ->
    elasticsearch = child_process.spawn es_command, [
      '--http.port', port,
      '--path.data', dataDir,
      '--path.logs', logsDir
      ]

    process.on 'exit', ->
      elasticsearch.kill()

  elasticSearchReady = new Promise (resolve, reject) ->
    if not fs.existsSync es_command

      url = 'http://download.elastic.co/elasticsearch/release/org/elasticsearch' +
        "/distribution/zip/elasticsearch/#{version}/elasticsearch-#{version}.zip"

      mkdirs = (dir) ->
        if not fs.existsSync dir
          mkdirs path.dirname dir
          fs.mkdirSync dir

      mkdirs installDir

      zipFileName = tempfile('.zip')

      console.log "download #{url} to #{zipFileName}"

      zipFileStream = fs.createWriteStream zipFileName

      req = http.request url, (res) ->
        console.log "  connected (#{res.statusCode})"

        res.pipe(zipFileStream)
        res.on 'end', ->
          zipFileStream.end()

        zipFileStream.on 'finish', ->
          zipFileStream.close ->
            console.log "unzip #{zipFileName}"
            unzipper = new unzip zipFileName
            unzipper.extractAllTo installDir
            console.log "remove #{zipFileName}"
            fs.unlinkSync zipFileName

            resolve()
        zipFileStream.on 'error', (err) ->
          reject(err)

      req.on 'error', (err) ->
        console.log "error getting elasticsearch from #{url}", err
        console.log "You can do this manually:"
        console.log "1. fetch it from #{url}"
        console.log "2. extract to #{installDir}"
        reject(err)

      req.end()

  elasticSearchReady.then ->
    startElasticSearchServer()
