# Setup configuration required to grab authentification token from environment
# generated by the Cozy Home. It considers that your application is accessed
# via an iframe from the Cozy Home.
getToken = (callback)->
    receiveToken = (event) ->
        window.removeEventListener 'message', receiveToken
        {appName, token}  = event.data
        callback? null, {appName, token}
        callback = null

    unless window.parent?
        return callback new Error('no parent window')

    unless window.parent?.postMessage
        return callback new Error('get a real browser')

    window.addEventListener 'message', receiveToken, false
    window.parent.postMessage { action: 'getToken' }, '*'


# Run the HTTP request on given path with given Method. It fires a callback
# when the request succeeds of fails.
playRequest = (method, path, attributes, callback) ->

    getToken (err, auth) ->
        return callback err if err

        xhr = new XMLHttpRequest
        xhr.open method, "/ds-api/#{path}", true
        xhr.onload = ->
            callback null, xhr, xhr.response

        xhr.onerror = (e) ->
            err = 'Request failed : #{e.target.status}'
            callback err

        xhr.setRequestHeader 'Content-Type', 'application/json'
        basicHeader = "Basic #{btoa(auth.appName + ':' + auth.token)}"
        xhr.setRequestHeader 'Authorization', basicHeader

        if attributes?
            xhr.send JSON.stringify attributes
        else
            xhr.send()


# Helpers to perform traditional http request properly authenticated, so it can
# deal with the Data System API. It follows the Node.js convention, termination
# is handled through a callback that returns the error object as first
# parameter.
module.exports =


    get: (path, attributes, callback)->
        playRequest 'GET', path, attributes, (error, response, body) ->
            callback error, response, body


    post: (path, attributes, callback) ->
        playRequest 'POST', path, attributes, (error, response, body) ->
            callback error, response, body


    put: (path, attributes, callback) ->
        playRequest 'PUT', path, attributes, (error, response, body) ->
            callback error, response, body


    del: (path, attributes, callback) ->
        playRequest 'DELETE', path, attributes, (error, response, body) ->
            callback error, response, body

