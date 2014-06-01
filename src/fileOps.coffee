fs = require('safefs')
pathUtil = require('path')

fileOps =
    config:
        collectionName: 'comments'
        relativeDirPath: 'comments'
        postUrl: '/comments'
        extension: '.html.md'
        partial: pathUtil.join('node_modules','docpad-plugin-commentator','out','partials','comment.html.eco')
        files: ['commentator.eot','commentator.svg','commentator.ttf','commentator.woff','default-avatar.png']
                
    copyFile: (source, target, cb) ->
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
    
    #copy assets to the docpad projects 'files' path
    copyFonts: (docpad,fontsPath) ->
        fontsOut = pathUtil.join docpad.config.filesPaths[0],'fonts'
        files = @config.files
        copyFile = @copyFile
        fs.ensurePath fontsOut,(next) ->
            for filename in files
                copyFile(pathUtil.join(fontsPath,filename),pathUtil.join(fontsOut,filename))

    #find where the comment partials are stored
    #may be in the standard 'node_modules' or 'plugin' folders, or the 'out' folder for tests
    findPathToPartial: (docpad) ->
        pathToPartial = pathUtil.join docpad.config.rootPath,@config.partial
        console.log pathToPartial
        if !fs.existsSync pathToPartial
            pathToPartial = pathToPartial.replace 'node_modules','plugins'
            if !fs.existsSync pathToPartial
                pathToPartial = pathUtil.join docpad.config.pluginPaths[0],'out','partials','comment.html.eco'
                if !fs.existsSync pathToPartial
                    throw new Error("Cannot find path to commentator partial")
        pathToPartial
    
    #make sure the comments folder exists in the 'documents' folder
    checkCommentsPath: (docpad) ->
        commentsPath = pathUtil.join docpad.config.documentsPaths[0],'comments'
        console.log "comments path"
        console.log commentsPath
        fs.ensurePath commentsPath,(err) ->
            return throw err  if err
    
    #find the .eco partials and styles required for comments
    getTemplateData: (docpad) ->
        pathToPartial = @findPathToPartial docpad
        pathToBase = pathToPartial.replace 'comment.html.eco','commentbase.html.eco'
        blockHtml = fs.readFileSync pathToPartial,'utf8'
        baseComment = fs.readFileSync pathToBase,'utf8'
        
        #css file should be in next to the partials folder
        stylePath = pathToPartial.replace /partials(\/|\\)comment\.html\.eco/,'commentator.css'
        styleContent = fs.readFileSync  stylePath,'utf8'
        styleContent = styleContent.replace /^\s+|\n\s*|\s+$/g,''
        
        fontsPath =  pathToPartial.replace /partials(\/|\\)comment\.html\.eco/,'fonts'
        @copyFonts(docpad,fontsPath)
        @checkCommentsPath(docpad)

        styleContent:styleContent
        blockHtml: blockHtml
        baseComment: baseComment
        
    writeFile: (outFile,content) ->
        fs.writeFile outFile, content, (err) ->
            if err
                console.log(err)
                return next(err)

module.exports = fileOps
