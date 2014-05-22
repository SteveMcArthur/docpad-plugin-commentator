# Export Plugin
module.exports = (BasePlugin) ->
    # Define Plugin
    pathUtil = require('path')
    fs = require('fs')
    class Commentator extends BasePlugin
        # Plugin Name
        name: 'commentator'
      
        config:
            collectionName: 'comments'
            relativeDirPath: 'comments'
            postUrl: '/comments'
            extension: '.html.md'
            partial: pathUtil.join('node_modules','docpad-plugin-commentator','src','partials','comment.html.eco')

        
        # Extend Template Data
        # Add our form to our template data
        extendTemplateData: ({templateData}) ->
            # Prepare
            plugin = @
            docpad = plugin.docpad

            pathToPartial = pathUtil.join(docpad.config.rootPath,plugin.getConfig().partial)
            fs.exists pathToPartial,(exists) ->
                pathToPartial = pathToPartial.replace('node_modules','plugins') if !exists
                plugin.setConfig({pathToPartial:pathToPartial})
                    
            # getCommentsBlock
            templateData.getCommentsBlock = ->
                @referencesOthers()
                blockHtml = fs.readFileSync(plugin.getConfig().pathToPartial)
                return blockHtml

            # getComments using the document slug
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

            # Comment Handing
            server.post  @getConfig().postUrl, (req,res,next) ->
                # Prepare
                console.log("POST COMMENTS")
                console.log(req.body.slug)
                now = new Date()
                nowTime = now.getTime()
                console.log(nowTime)
                nowString = now.toString()
                
                outPath =  pathUtil.join(docpad.config.documentsPaths[0],"comments")
                outFile =  pathUtil.join(outPath,nowTime.toString()+".html.md")
               
                # Prepare
                documentAttributes =
                    data: req.body.content or ''
                    meta:
                        postslug:req.body.slug
                        author: req.body.author or ''
                        date: nowString
                        timeid: nowTime
                        fullPath: outFile
                if req.body.responseid
                    documentAttributes.meta.responseid = req.body.responseid
                    
                meta = ""
                for key, val of documentAttributes.meta
                    meta+= key+": "+val+"\r\n"
                content = '---\r\n'+meta+'\r\n---\r\n'+documentAttributes.data
                safefs = require('safefs')
                safefs.writeFile outFile, content, (err2) ->
                    return next(err2)  if err2
                    
                res.json(documentAttributes)

            # Chain
            @