# Export Plugin Tester
module.exports = (testers) ->
    # PRepare
    {expect} = require('chai')
    superAgent = require('superagent')
    rimraf = require('rimraf')
    pathUtil = require('path')
    {wait, repeat, doAndRepeat, waitUntil} = require('wait')

    # Define My Tester
    class MyTester extends testers.ServerTester
        docpadConfig:
            port: 9779
            enabledPlugins:
                'eco': true
                'docpad-plugin-eco':true

        cleanup: =>
            # Prepare
            tester = @
            
            # Cleanup existingcomments
            @test "clean commentator", (done) ->
                rimraf pathUtil.join(tester.getConfig().testPath, 'src', 'documents', 'comments'), (err) ->
                    return
                rimraf pathUtil.join(tester.getConfig().testPath, 'src', 'files', 'fonts'), (err) ->
                    return
                 rimraf pathUtil.join(tester.getConfig().testPath, 'out'), (err) ->
                    done()  # ignore errors
            # Chain
            @

        # Test Create
        testCreate: =>
            # Cleanup
            @cleanup()

            # Forward
            super

            # Chain
            @

        # Test Generate
        #testGenerate: testers.RendererTester::testGenerate

        # Custom test for the server
        testServer: (next) ->
            # Prepare
            tester = @
            generated = false
            fs = require('fs')
           

            # Create the server
            super
            
           

            # Test
            @suite 'commentator', (suite,test) ->
                # Prepare
                testerConfig = tester.getConfig()
                docpad = tester.docpad
                docpadConfig = docpad.getConfig()
                plugin = tester.getPlugin()
                pluginConfig = plugin.getConfig()
                output = pathUtil.join(tester.getConfig().testPath, 'src','documents','comments')
                commentPath = ""

                # Prepare
                baseUrl = "http://localhost:#{docpadConfig.port}"
                postUrl = "#{baseUrl}/comments"
          

                # Post
                test "post a new comment to #{postUrl}", (done) ->
                    now = new Date()
                    nowTime = now.getTime()
                    nowString = now.toString()
                    superAgent
                        .post(postUrl)
                        .type('json').set('Accept', 'application/json')
                        .send(
                            "author": "Author Name",
                            "slug": "post-page-title",
                            "content": "Text of comment"
                        )
                        .timeout(30*1000)
                        .end (err,res) ->
                            if err
                                console.log("ERROR.......")
                                console.log(err)
                                return done(err)

                            # Generated
                            generated = true

                            # Cleanup
                            nowTime = parseInt(nowTime/1000)
                            if res.body?.meta?.fullPath
                                commentPath = res.body.meta.fullPath
                                res.body.meta.fullPath = res.body.meta.fullPath.replace(/.+documents/, 'trimmed')

                            # Compare
                            actual = res.body
                            timeid = parseInt(actual.meta.timeid /1000)
                            actual.meta.timeid = timeid
                            
                            actual.meta.fullPath = actual.meta.fullPath.replace(/[0-9]+/, timeid)
                            
                            
                            expected =
                                data: 'Text of comment',
                                meta:
                                    postslug: "post-page-title",
                                    author: "Author Name",
                                    date: nowString,
                                    timeid: nowTime,
                                    fullPath: 'trimmed\\comments\\'+nowTime+'.html.md'
                                    
                            # Check
                            expect(actual).to.deep.equal(expected)
                            wait 2*1000, ->
                                console.log "wait ended"
                                done()
                            
                test "comments folder exists", (done) ->
                    b = fs.existsSync(output)
                    expect(b).to.equal(true)
                    done()
                    
                test "comments file exists", (done) ->
                    b = fs.existsSync(commentPath)
                    expect(b).to.equal(true)
                    done()
                    
                test "fonts folder exists", (done) ->
                    fontPath = pathUtil.join(tester.getConfig().testPath, 'out', 'fonts')
                    b = fs.existsSync(fontPath)
                    expect(b).to.equal(true)
                    done()
                    
                test "fonts files exists", (done) ->
                    fontPath = pathUtil.join(tester.getConfig().testPath, 'out', 'fonts')
                    files = fs.readdirSync(fontPath)
                    expect(files).to.have.length(5)
                    done()
                
                test "docpad generate", (done) ->
                    docpad.action('generate')
                    done()

    

            # Chain
            @
            
        testCustom: (next) ->
            tester = @
            fs = require('fs')
            # Test
            @suite 'output', (suite,test) ->
                
                cheerio = require('cheerio')
                output = pathUtil.join(tester.getConfig().testPath, 'out', 'index.html')
                $ = {}

                test "index.html exists", (done) ->
                  
                    b = fs.existsSync(output)
                    expect(b).to.equal(true)
                    done()
                    
                 test "check style tag first child of div.com", (done) ->
                   
                    content = fs.readFileSync(output,{encoding:'utf8'})
                    $ = cheerio.load(content)
                    el = $('.com > style')
                    expect(el).to.have.length(1)
                    done()
                    
                test "two script tags", (done) ->
                    el = $('script')
                    expect(el).to.have.length(1)
                    done()
                 
                test "have comment template", (done) ->
                    el = $('#comment-template')
                    expect(el).to.have.length(1)
                    done()
                        
                test "have comment main form", (done) ->
                    el = $('#main-form')
                    expect(el).to.have.length(1)
                    done()
                        
                test "have comment second form", (done) ->
                    el = $('#second-form')
                    expect(el).to.have.length(1)
                    done()
                        
                test "have comment two forms", (done) ->
                    el = $('form')
                    expect(el).to.have.length(2)
                    done()
                        
                test "have comments div", (done) ->
                    el = $('#comments')
                    expect(el).to.have.length(1)
                    el = $('div.comments')
                    expect(el).to.have.length(1)
                    done()
                test "forms have action attribute '/comments", (done) ->
                    el = $('form[action="/comments"]')
                    expect(el).to.have.length(2)
                    done()
                        
            
                 
                
                
                    
            # Cleanup
            @cleanup()
            
            
