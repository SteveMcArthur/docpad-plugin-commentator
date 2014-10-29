# Export Plugin
module.exports = (BasePlugin) ->
    # Define Plugin
    path = require('path')
    fs = require('safefs')
    class Commentator extends BasePlugin
        # Plugin Name
        name: 'commentator'

        config:
            collectionName: 'comments'
            relativeDirPath: 'comments'
            postUrl: '/comments'
            extension: '.html.md'
            eco: require('eco')
            basePartial: 'commentbase.html.eco'
            commentPartial: 'comment.html.eco'
            styleContent: ''


        copyFile: (source, target) ->
            cbCalled = false
            done = (err) ->
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
            rd.pipe(wr)

        #copy assets to the docpad projects 'files' path
        copyFonts: (fontsPath,fontsOut) ->
            console.log fontsPath
            console.log fontsOut
            if !fs.existsSync fontsOut
                console.log "Make fonts out dir"
                fs.mkdirSync fontsOut
            files = fs.readdirSync(fontsPath)
            console.log "copy font files"
            for filename in files
                @copyFile(path.join(fontsPath,filename),path.join(fontsOut,filename))
            fontsOut

        setAssets: (config,docpadConfig) ->
            styleContent = fs.readFileSync(path.join(__dirname,'commentator.css'),'utf8')
            styleContent = styleContent.replace(/^\s+|\n\s*|\s+$/g,'')
            config.styleContent = styleContent
            fontsPath =  path.join(__dirname,'fonts')
            #to docpad project files source path (which should, in turn, be copied to the docpad out path)
            fontsOut = path.join(docpadConfig.filesPaths[0],'fonts')
            @copyFonts(fontsPath,fontsOut)
            fontsOut

        constructor: ->
            # Prepare
            super
            docpadConfig = @docpad.getConfig()
            partialsPath = path.join(__dirname,'partials')
            config = @getConfig()
            config.commentHtml = fs.readFileSync(path.join(partialsPath,config.commentPartial),'utf8')
            config.baseHtml = fs.readFileSync(path.join(partialsPath,config.basePartial),'utf8')
            @setAssets(config,docpadConfig)

            @

        # Extend Template Data
        # Add our form to our template data
        extendTemplateData: ({templateData}) ->
            # Prepare
            docpad = @docpad
            docpadConfig = docpad.getConfig()
            config = @getConfig()

            # getCommentsBlock
            templateData.getCommentsBlock = ->

                @referencesOthers()

                pageComments = docpad.getCollection(config.collectionName).findAll({'postslug': @document.slug},[date:-1])
                obj = {baseComment:config.baseHtml,eco:config.eco,allComments: pageComments,document:@document,styleContent:config.styleContent}
                html = config.eco.render(config.commentHtml,obj)

            # getComments using the document slug
            templateData.getComments = ->
                slug = @document.slug
                return docpad.getCollection(@getConfig().collectionName).findAll({'postslug': slug},[date:-1])


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

                fops.writeFile outFile, content

                # send the update back to the page to
                # be updated client side
                res.json(documentAttributes)

            # Chain
            @
