# Export Plugin
module.exports = (BasePlugin) ->
    # Define Plugin
    util = require('util')
    pathUtil = require('path')
    fs = require('fs')
    class Commentator extends BasePlugin
        # Plugin Name
        name: 'commentator'
      
        config:
            collectionName: 'comments'
            relativeDirPath: 'comments'
            postUrl: '/comment'
            extension: '.html.md'
            partial: pathUtil.join('plugins','docpad-plugin-commentator','src','partials','comment.html.eco')
        
        
        # Extend Template Data
        # Add our form to our template data
        extendTemplateData: ({templateData}) ->
            # Prepare
            plugin = @
            docpad = @docpad
            

            # getCommentsBlock
            templateData.getCommentsBlock = ->
                @referencesOthers()
                pathToPartial = pathUtil.join(docpad.initialConfig.rootPath,plugin.getConfig().partial)
                blockHtml = fs.readFileSync(pathToPartial)
                return blockHtml

            # getComments
            templateData.getComments = ->
                slug = @document.slug
                return docpad.getCollection(plugin.getConfig().collectionName).findAll({'postslug': slug},[date:-1])

            # Chain
            @
            
        # Extend Collections
        # Create our live collection for our comments
        extendCollections: ->
            # Prepare
            config = @getConfig()
            docpad = @docpad
            database = docpad.getDatabase()

            # Create the collection
            #comments = database.findAllLive({relativeDirPath: $startsWith: config.relativeDirPath}, [date:-1])
            comments = database.findAllLive({relativeOutDirPath: 'comments'},[date:-1])
            # Set the collection
            docpad.setCollection(config.collectionName, comments)

            # Chain
            @



        
        # Server Extend
        # Used to add our own custom routes to the server before the docpad routes are added
        serverExtend: (opts) ->
            {server} = opts
            docpad = @docpad
            database = docpad.getDatabase()
            path = require('path')
            safefs = require('safefs')

            # Comment Handing
            server.post '/comments', (req,res,next) ->
                # Prepare
                console.log("POST COMMENTS")
                console.log(req.body.slug)
                now = new Date()
                nowTime = now.getTime()
                console.log(nowTime)
                nowString = now.toString()
                redirect = req.body.redirect ? req.query.redirect ? 'back'
                
                outPath = path.join(docpad.config.documentsPaths[0],"comments")
                outFile = path.join(outPath,nowTime.toString()+".html.md")
               
                # Prepare
                documentAttributes =
                    data: req.body.content or ''
                    meta:
                        postslug:req.body.slug
                        author: req.body.author or ''
                        date: nowString
                        timeid: nowTime
                        responseid:req.body.responseid or undefined
                        fullPath: outFile

                # No need to call next here as res.send/redirect will do it for us

                # Write source which will trigger the regeneration
                meta = JSON.stringify(documentAttributes.meta, null, 0)
                meta = meta.replace('{','').replace('}','').replace(/,/gi,',\r\n').replace(/:/gi,': ')
                content = '---\r\n'+meta+'\r\n---\r\n'+documentAttributes.data
                console.log "writing file..."
                safefs.writeFile outFile, content, (err2) ->
                    return next(err2)  if err2
                    
                res.json(documentAttributes)

            # Chain
            @