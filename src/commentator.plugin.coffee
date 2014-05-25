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
            
        copyFile: (source, target, cb) ->
            console.log('copyFile')
            cbCalled = false
            done: (err) ->
                console.log(err)
                if !cbCalled
                    cb(err)
                    cbCalled = true
                    
            rd = fs.createReadStream(source)
            rd.on "error", (err) ->
                done(err)

            wr = fs.createWriteStream(target)
            wr.on "error", (err) ->
                done(err)
            wr.on "close", (ex) ->
                done()

            rd.pipe(wr)


        setConfigPaths:(pathToPartial) ->
            pathToBase = pathToPartial.replace('comment.html.eco','commentbase.html.eco')
            stylePath = pathToPartial.replace(/partials(\/|\\)comment\.html\.eco/,'commentator.css')
            fontsPath =  pathToPartial.replace(/partials(\/|\\)comment\.html\.eco/,'fonts')
            commentsPath = pathUtil.join(@docpad.config.documentsPaths[0],'comments')
            if !fs.existsSync(commentsPath)
                fs.mkdirSync(commentsPath)
            @.setConfig({pathToPartial:pathToPartial,pathToBase:pathToBase,stylePath:stylePath,fontsPath:fontsPath})
        
        setPartialPaths: ->
            plugin = @
            docpad = plugin.docpad
            pathToPartial = pathUtil.join(docpad.config.rootPath,plugin.getConfig().partial)
            if !fs.existsSync(pathToPartial)
                pathToPartial = pathToPartial.replace('node_modules','plugins')
                if !fs.existsSync(pathToPartial)
                    pathToPartial = pathUtil.join(docpad.config.pluginPaths[0],'src','partials','comment.html.eco')

            plugin.setConfigPaths(pathToPartial)
            
        # Extend Template Data
        # Add our form to our template data
        extendTemplateData: ({templateData}) ->
            # Prepare
            plugin = @
            docpad = plugin.docpad
            @setPartialPaths()
            config = plugin.getConfig()
            style = config.stylePath
            styleContent = fs.readFileSync(style,'utf8')
            styleContent = styleContent.replace(/^\s+|\n\s*|\s+$/g,'')
            console.log("Copying fonts...")
            console.log(docpad.config.filesPaths[0])
            fontsOut = pathUtil.join(docpad.config.filesPaths[0],'fonts')
            console.log(fontsOut)
            if !fs.existsSync(docpad.config.filesPaths[0])
                fs.mkdirSync(docpad.config.filesPaths[0])
            if !fs.existsSync(fontsOut)
                fs.mkdirSync(fontsOut)
            files = ['commentator.eot','commentator.svg','commentator.ttf','commentator.woff']
            for filename in files
                plugin.copyFile(pathUtil.join(config.fontsPath,filename),pathUtil.join(fontsOut,filename))
                
            
            # getCommentsBlock
            templateData.getCommentsBlock = ->
                @referencesOthers()
                
                eco = require('eco')
                blockHtml = fs.readFileSync(plugin.getConfig().pathToPartial,'utf8')
                baseComment = fs.readFileSync(plugin.getConfig().pathToBase,'utf8')
                pageComments = docpad.getCollection(plugin.getConfig().collectionName).findAll({'postslug': @document.slug},[date:-1])
                obj = {baseComment:baseComment,eco:eco,allComments: pageComments,document:@document,styleContent:styleContent}
                blockHtml = eco.render(blockHtml,obj)
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
                now = new Date()
                nowTime = now.getTime()
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
                # Write source which will trigger the regeneration
                # but we don't have to wait for the page to be regenerated
                # as the page will be updated by ajax
                meta = ""
                for key, val of documentAttributes.meta
                    meta+= key+": "+val+"\r\n"
                content = '---\r\n'+meta+'\r\n---\r\n'+documentAttributes.data
                safefs = require('safefs')
                safefs.writeFile outFile, content, (err2) ->
                    return next(err2)  if err2
                
                # send the update back to the page to
                # be updated client side
                res.json(documentAttributes)

            # Chain
            @