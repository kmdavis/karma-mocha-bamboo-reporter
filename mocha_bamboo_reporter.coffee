clean = (result) ->
    title: result.description
    fullTitle: result.suite.join( " " ) + " " + result.description
    duration: result.time
    error: result.log[0] if result.log[0]?

trisect = (results) ->
    failures = []
    passes = []
    skipped = []

    for result in results
        if result.skipped
            skipped.push clean result
        else if result.success
            passes.push clean result
        else
            failures.push clean result

    [ failures, passes, skipped ]

getSuites = (results) ->
    suites = []

    for result in results
        suite = result.suite.join " "
        suites.push suite unless suite in suites

    suites

module.exports = class BambooReporter
    constructor: (logger) ->
        @_log = logger.create "bamboo.reporter"
        @_results = []

    onSpecComplete: (browser, result) ->
        @_results.push result

    # leaving these 2 in, in case we want to associate errors and (error/warning) logs with results
    #onBrowserError: (browser, error) ->
    #onBrowserLog: (browser, msg, type) ->

    onExit: (done) ->
        @_log.debug "DONE"
        fs = require "fs"

        [ failures, passes, skipped ] = trisect @_results

        fs.writeFileSync "mocha.json", JSON.stringify( {
            stats: {
                suites: getSuites( @_results ).length
                tests: @_results.length
                passes: passes.length
                pending: skipped.length
                failures: failures.length
            }
            failures: failures
            passes: passes
            skipped: skipped
        }, null, 4 ), "utf-8"
        done()

    @$inject: [
        "logger"
    ]
