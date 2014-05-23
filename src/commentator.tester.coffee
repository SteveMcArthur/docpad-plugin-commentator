# Export Plugin Tester
module.exports = (testers) ->
    # PRepare
    {expect} = require('chai')
    superAgent = require('superagent')
    rimraf = require('rimraf')
    pathUtil = require('path')

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
            
            # Cleanup native comments
            @test "clean commentator", (done) ->
                rimraf pathUtil.join(tester.getConfig().testPath, 'src', 'documents', 'comments'), (err) ->
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
        testGenerate: testers.RendererTester::testGenerate

        # Custom test for the server
        testServer: (next) ->
            # Prepare
            tester = @
            generated = false

            # Create the server
            super

            ###
            # Watch
            @test 'watch', (done) ->
                tester.docpad.action 'watch', (err) ->
                    return done(err)  if err
                    # Ensure enough time for watching to complete
                    setTimeout(
                        -> done()
                        5*1000
                    )
            ###

            # Test
            @suite 'commentator', (suite,test) ->
                # Prepare
                testerConfig = tester.getConfig()
                docpad = tester.docpad
                docpadConfig = docpad.getConfig()
                plugin = tester.getPlugin()
                pluginConfig = plugin.getConfig()

                # Prepare
                baseUrl = "http://localhost:#{docpadConfig.port}"
                postUrl = "#{baseUrl}/comments"
                now = new Date()
                nowTime = now.getTime()
                nowString = now.toString()

                # Post
                test "post a new comment to #{postUrl}", (done) ->
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
                            return done(err)  if err

                            # Generated
                            generated = true

                            # Cleanup
                            nowTime = parseInt(nowTime/1000)
                            if res.body?.meta?.fullPath
                                res.body.meta.fullPath = res.body.meta.fullPath.replace(/.+documents/, 'trimmed')

                            # Compare
                            actual = res.body
                            timeid = parseInt(actual.meta.timeid /1000)
                            actual.meta.timeid = timeid
                            actual.meta.fullPath = actual.meta.fullPath.replace(/[0-9]+/, timeid)
                            
                            console.log(actual)
                            
                            expected =
                                data: 'Text of comment',
                                meta:
                                    postslug: "post-page-title",
                                    author: "Author Name",
                                    date: nowString,
                                    timeid: nowTime,
                                    fullPath: 'trimmed\\comments\\'+nowTime+'.html.md'
                                    
                            console.log(expected)
                            # Check
                            expect(actual).to.deep.equal(expected)
                            done()

            # Cleanup
            @cleanup()

            # Chain
            @
