# Export Plugin
module.exports = (BasePlugin) ->
    # Define Plugin
    pathUtil = require('path')
    fops = require('./fileOps')
    class Commentator extends BasePlugin
        # Plugin Name
        name: 'commentator'
      
        config:
            collectionName: 'comments'
            relativeDirPath: 'comments'
            postUrl: '/comments'
            extension: '.html.md'

        testFunction: ->
            txt = "In test Function"
            console.log txt
            return txt
        # Extend Template Data
        # Add our form to our template data
        extendTemplateData: ({templateData}) ->
            # Prepare
            plugin = @
            docpad = plugin.docpad
            
            config = fops.getTemplateData docpad
            plugin.setConfig(config)
                
            # getCommentsBlock
            templateData.getCommentsBlock = ->
                @referencesOthers()
                config = plugin.getConfig()
                eco = require('eco')
                pageComments = docpad.getCollection(plugin.getConfig().collectionName).findAll({'postslug': @document.slug},[date:-1])
                obj = {baseComment:config.baseComment,eco:eco,allComments: pageComments,document:@document,styleContent:config.styleContent}
                eco.render(config.blockHtml,obj)

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
             
                fops.writeFile outFile, content
                
                # send the update back to the page to
                # be updated client side
                res.json(documentAttributes)

            # Chain
            @